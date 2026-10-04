import Foundation
import Observation
import HealthKit
import LiftCore

/// Apple Health integration.
///
/// - iPhone: saves finished workouts with `HKWorkoutBuilder`, and asks HealthKit to launch the
///   Watch app when a workout starts on the phone (so the Watch can run a live workout session).
/// - Watch: runs an `HKWorkoutSession` + `HKLiveWorkoutBuilder` during a workout, publishing heart
///   rate and active energy. The Watch is the source of the Health workout whenever it ran a session,
///   so the phone doesn't save a duplicate.
@MainActor
@Observable
final class HealthKitService {
    enum Phase: Equatable { case idle, starting, running, ending }

    /// Latest heart rate in BPM (Watch, during a workout).
    private(set) var heartRate: Double?
    /// Active energy in kcal for the current workout (Watch).
    private(set) var activeEnergy: Double = 0
    private(set) var phase: Phase = .idle
    /// The workout session id this Health session belongs to. May be nil briefly when the phone
    /// launched the Watch app before the session snapshot arrived.
    var linkedWorkoutID: UUID?

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }
    var isRunning: Bool { phase == .starting || phase == .running }

    @ObservationIgnored private let store = HKHealthStore()
    @ObservationIgnored private var authorizationRequested = false

    static func configuration() -> HKWorkoutConfiguration {
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor
        return config
    }

    func requestAuthorizationIfNeeded() async {
        guard isAvailable, !authorizationRequested else { return }
        authorizationRequested = true
        let share: Set<HKSampleType> = [HKObjectType.workoutType(), HKQuantityType(.activeEnergyBurned)]
        let read: Set<HKObjectType> = [HKObjectType.workoutType(), HKQuantityType(.activeEnergyBurned), HKQuantityType(.heartRate)]
        try? await store.requestAuthorization(toShare: share, read: read)
    }

    #if os(iOS)
    /// Saves a phone-finished workout to Health.
    func save(_ workout: CompletedWorkout) async {
        guard isAvailable else { return }
        await requestAuthorizationIfNeeded()
        let builder = HKWorkoutBuilder(healthStore: store, configuration: Self.configuration(), device: .local())
        do {
            try await builder.beginCollection(at: workout.startedAt)
            try await builder.addMetadata([
                HKMetadataKeyExternalUUID: workout.id.uuidString,
                HKMetadataKeyWorkoutBrandName: "Lift48 · \(workout.dayName)",
            ])
            try await builder.endCollection(at: workout.finishedAt)
            _ = try await builder.finishWorkout()
        } catch {
            builder.discardWorkout()
        }
    }

    /// Asks HealthKit to launch the Watch app with a workout configuration. Returns true if the
    /// Watch accepted, meaning it will run (and save) the Health workout.
    func launchWatchApp() async -> Bool {
        guard isAvailable else { return false }
        await requestAuthorizationIfNeeded()
        return await withCheckedContinuation { continuation in
            store.startWatchApp(with: Self.configuration()) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
    #endif

    #if os(watchOS)
    @ObservationIgnored private var session: HKWorkoutSession?
    @ObservationIgnored private var builder: HKLiveWorkoutBuilder?
    @ObservationIgnored private var proxy: WorkoutDelegateProxy?

    /// Starts a live workout session. Safe to call repeatedly; ignored while one is running.
    func startWorkout(linkedTo workoutID: UUID?, startDate: Date) async {
        guard isAvailable, phase == .idle else { return }
        phase = .starting
        linkedWorkoutID = workoutID
        await requestAuthorizationIfNeeded()
        do {
            let config = Self.configuration()
            let session = try HKWorkoutSession(healthStore: store, configuration: config)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)
            attach(session: session, builder: builder)
            session.startActivity(with: startDate)
            try await builder.beginCollection(at: startDate)
            phase = .running
        } catch {
            reset()
        }
    }

    /// Re-attaches to a session that survived an app relaunch (watchOS keeps workout sessions alive).
    func recoverActiveSession() async {
        guard isAvailable, phase == .idle else { return }
        let recovered: HKWorkoutSession? = await withCheckedContinuation { continuation in
            store.recoverActiveWorkoutSession { session, _ in continuation.resume(returning: session) }
        }
        guard let recovered else { return }
        attach(session: recovered, builder: recovered.associatedWorkoutBuilder())
        phase = .running
    }

    /// Ends the live session, saving the workout to Health or discarding it.
    func endWorkout(save: Bool) async {
        guard let session, let builder, phase == .running || phase == .starting else { return }
        phase = .ending
        if save, let id = linkedWorkoutID {
            try? await builder.addMetadata([HKMetadataKeyExternalUUID: id.uuidString])
        }
        session.end()
        do {
            try await builder.endCollection(at: Date())
            if save {
                _ = try await builder.finishWorkout()
            } else {
                builder.discardWorkout()
            }
        } catch {
            builder.discardWorkout()
        }
        reset()
    }

    private func attach(session: HKWorkoutSession, builder: HKLiveWorkoutBuilder) {
        let proxy = WorkoutDelegateProxy(
            onStats: { [weak self] bpm, kcal in
                if let bpm { self?.heartRate = bpm }
                if let kcal { self?.activeEnergy = kcal }
            },
            onEnded: { [weak self] in
                // Session ended by the system (e.g. error); drop our references.
                if self?.phase == .running { self?.reset() }
            }
        )
        session.delegate = proxy
        builder.delegate = proxy
        self.session = session
        self.builder = builder
        self.proxy = proxy
    }

    private func reset() {
        session = nil
        builder = nil
        proxy = nil
        heartRate = nil
        activeEnergy = 0
        linkedWorkoutID = nil
        phase = .idle
    }
    #endif
}

#if os(watchOS)
/// NSObject delegate that forwards HealthKit callbacks (delivered on arbitrary queues) to the main actor.
private final class WorkoutDelegateProxy: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate, @unchecked Sendable {
    private let onStats: @MainActor (Double?, Double?) -> Void
    private let onEnded: @MainActor () -> Void

    init(onStats: @escaping @MainActor (Double?, Double?) -> Void, onEnded: @escaping @MainActor () -> Void) {
        self.onStats = onStats
        self.onEnded = onEnded
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        if toState == .ended || toState == .stopped {
            Task { @MainActor in self.onEnded() }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        Task { @MainActor in self.onEnded() }
    }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        let heartRateType = HKQuantityType(.heartRate)
        let energyType = HKQuantityType(.activeEnergyBurned)
        var bpm: Double?
        var kcal: Double?
        if collectedTypes.contains(heartRateType) {
            bpm = workoutBuilder.statistics(for: heartRateType)?.mostRecentQuantity()?
                .doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        }
        if collectedTypes.contains(energyType) {
            kcal = workoutBuilder.statistics(for: energyType)?.sumQuantity()?.doubleValue(for: .kilocalorie())
        }
        guard bpm != nil || kcal != nil else { return }
        Task { @MainActor in self.onStats(bpm, kcal) }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}
#endif
