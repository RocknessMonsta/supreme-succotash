import Foundation
import Observation
import LiftCore

/// The single observable object both apps bind to. Owns the persisted `AppState`, applies user
/// intents through LiftCore, keeps the rest-timer alerts and Health session in step, and syncs
/// with the other device. See docs/APP_MODEL_API.md.
@MainActor
@Observable
final class AppModel {
    static let shared = AppModel()

    // MARK: Observable state

    private(set) var state: AppState
    let role: DeviceKind
    let health = HealthKitService()
    private(set) var syncStatus = SyncStatus()
    /// Increments each time a rest period runs out while the app is running (for UI flashes).
    private(set) var restFinishedCount = 0
    /// Set when the other device finished a workout. The UI may show it, then set it to nil.
    var remoteCompletion: CompletedWorkout?
    /// Set when the other device ended (finished/discarded) the session currently on screen.
    var activeSessionEndedRemotely = false

    // MARK: Collaborators

    @ObservationIgnored private let store: AppStateStore
    @ObservationIgnored private let clock: () -> Date
    @ObservationIgnored private var sync: WatchSyncCoordinator?
    @ObservationIgnored private let notifier = RestTimerNotifier()
    @ObservationIgnored private var restEndTask: Task<Void, Never>?
    @ObservationIgnored private var restEndScheduledFor: Date?
    /// Phone only: sessions whose Health workout the Watch is recording.
    @ObservationIgnored private var watchRecordsHealth: Set<UUID> = []

    init(store: AppStateStore = AppStateStore(url: AppStateStore.defaultURL()), clock: @escaping () -> Date = Date.init, enableSync: Bool = true) {
        #if os(watchOS)
        role = .watch
        #else
        role = .phone
        #endif
        self.store = store
        self.clock = clock
        state = store.load() ?? .fresh(unit: Locale.current.measurementSystem == .metric ? .kg : .lb)
        Haptics.isEnabled = state.settings.hapticsEnabled
        guard enableSync else { return }
        let sync = WatchSyncCoordinator(
            role: role,
            onEnvelope: { [weak self] in self?.receive($0) },
            onStatus: { [weak self] in self?.syncStatus = $0 },
            onReady: { [weak self] in self?.counterpartBecameAvailable() }
        )
        self.sync = sync
        sync.activate()
        refreshRestTimer()
        #if os(watchOS)
        Task { await health.recoverActiveSession(); reconcileHealthSession() }
        #endif
    }

    // MARK: Read-only conveniences

    var program: Program { state.program }
    var settings: Settings { state.settings }
    var unit: WeightUnit { state.settings.unit }
    /// Newest first.
    var history: [CompletedWorkout] { state.history }
    var activeSession: WorkoutSession? { state.activeSession }
    var isWorkoutActive: Bool { state.activeSession != nil }
    /// The day the next workout will use (nil only if every day is disabled, which editing prevents).
    var nextDay: BodyPartDay? { state.program.nextDay }

    func now() -> Date { clock() }

    func restRemaining(at date: Date) -> TimeInterval { state.activeSession?.restTimer.remaining(at: date) ?? 0 }

    func plates(for weight: Double) -> PlateLoad { PlateCalculator.load(for: weight, settings: settings) }

    /// Formatted "135 lb".
    func format(_ weight: Double) -> String { Weight.format(weight, unit: unit) }

    /// What finishing now would do to each exercise (outcome + next weight), keyed by slot id.
    func finishPreview() -> [UUID: (ProgressionOutcome, Double)] {
        guard let session = state.activeSession else { return [:] }
        return ProgressionEngine.preview(session.completed(finishedAt: now(), device: role), program: program, settings: settings)
    }

    // MARK: Workout intents

    func startWorkout(dayID: UUID? = nil) {
        guard state.activeSession == nil, let session = state.startWorkout(dayID: dayID, device: role, now: now()) else { return }
        persist()
        sync?.send(.session(session))
        #if os(iOS)
        notifier.requestAuthorizationIfNeeded()
        if settings.healthKitEnabled && syncStatus.isCounterpartInstalled {
            let id = session.id
            Task {
                if await health.launchWatchApp() { watchRecordsHealth.insert(id) }
            }
        }
        #else
        reconcileHealthSession()
        #endif
    }

    func tapSet(exerciseID: UUID, setIndex: Int) {
        mutateSession { $0.tapSet(exerciseID: exerciseID, setIndex: setIndex, rest: settings.rest, now: $1) }
        Haptics.tap()
    }

    func setReps(_ reps: Int?, exerciseID: UUID, setIndex: Int) {
        mutateSession { $0.setReps(reps, exerciseID: exerciseID, setIndex: setIndex, rest: settings.rest, now: $1) }
    }

    func setWeight(_ weight: Double, exerciseID: UUID) {
        mutateSession { $0.setWeight(weight, exerciseID: exerciseID, settings: settings, now: $1) }
    }

    func toggleWarmup(exerciseID: UUID, index: Int) {
        mutateSession { $0.toggleWarmup(exerciseID: exerciseID, index: index, now: $1) }
    }

    func setSkipped(_ skipped: Bool, exerciseID: UUID) {
        mutateSession { $0.setSkipped(skipped, exerciseID: exerciseID, now: $1) }
    }

    func setExerciseNote(_ note: String, exerciseID: UUID) {
        mutateSession { $0.setNote(note, exerciseID: exerciseID, now: $1) }
    }

    func setWorkoutNote(_ note: String) {
        mutateSession { $0.setWorkoutNote(note, now: $1) }
    }

    func adjustRest(by seconds: TimeInterval) {
        mutateSession { $0.adjustRest(by: seconds, now: $1) }
    }

    func skipRest() {
        mutateSession { $0.skipRest(now: $1) }
    }

    /// Finishes the active workout: progression, history, Health, sync. Returns the saved workout.
    @discardableResult
    func finishWorkout() -> CompletedWorkout? {
        guard let session = state.activeSession,
              let workout = state.finishActiveWorkout(device: role, now: now()) else { return nil }
        persist()
        refreshRestTimer()
        Haptics.success()
        sync?.send(.completed(workout))
        #if os(iOS)
        pushContext()
        let watchHasIt = watchRecordsHealth.contains(session.id) || session.startedOn == .watch
        if settings.healthKitEnabled && !watchHasIt {
            Task { await health.save(workout) }
        }
        watchRecordsHealth.remove(session.id)
        #else
        _ = session
        reconcileHealthSession()
        #endif
        return workout
    }

    /// Throws away the active workout on both devices.
    func discardWorkout() {
        guard let id = state.discardActiveWorkout() else { return }
        persist()
        refreshRestTimer()
        sync?.send(.discarded(id))
        #if os(iOS)
        watchRecordsHealth.remove(id)
        pushContext()
        #else
        reconcileHealthSession()
        #endif
    }

    // MARK: Program, settings, history (phone is authoritative; the Watch UI doesn't edit these)

    func updateSettings(_ change: (inout Settings) -> Void) {
        // Mutate a copy so the closure may safely read the model (no overlapping access to `state`).
        let oldUnit = state.settings.unit
        var settings = state.settings
        change(&settings)
        let target = settings.unit
        settings.unit = oldUnit
        state.settings = settings
        if target != oldUnit {
            // Route unit switches through the converter so every stored weight follows.
            state.convertUnits(to: target)
            if let session = state.activeSession { sync?.send(.session(session)) }
        }
        Haptics.isEnabled = state.settings.hapticsEnabled
        programOrSettingsChanged()
    }

    func setUnit(_ unit: WeightUnit) {
        updateSettings { $0.unit = unit }
    }

    func updateProgram(_ change: (inout Program) -> Void) {
        var program = state.program
        change(&program)
        state.program = program
        programOrSettingsChanged()
    }

    func updateHistory(_ workout: CompletedWorkout) {
        state.updateHistory(workout)
        programOrSettingsChanged()
    }

    func deleteHistory(id: UUID) {
        state.deleteHistory(id: id)
        programOrSettingsChanged()
    }

    /// Starts over with the default program; history is kept unless `clearHistory`.
    func resetProgram(clearHistory: Bool = false) {
        state.program = ProgramDefaults.program(unit: unit)
        if clearHistory { state.history.removeAll() }
        programOrSettingsChanged()
    }

    /// Writes the history CSV to a temporary file for ShareLink.
    func exportCSV() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Lift48-history.csv")
        try CSVExporter.csv(for: history).write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    #if os(watchOS)
    /// Called when HealthKit launches the Watch app for a workout started on the phone.
    func handlePhoneStartedWorkout() {
        guard settings.healthKitEnabled else { return }
        Task {
            await health.startWorkout(linkedTo: state.activeSession?.id, startDate: state.activeSession?.startedAt ?? now())
            reconcileHealthSession()
        }
        sync?.send(.requestContext)
    }
    #endif

    // MARK: - Internals

    private func mutateSession(_ body: (inout WorkoutSession, Date) -> Void) {
        guard var session = state.activeSession else { return }
        body(&session, now())
        guard session != state.activeSession else { return }
        state.activeSession = session
        persist()
        refreshRestTimer()
        sync?.send(.session(session))
    }

    private func programOrSettingsChanged() {
        persist()
        if role == .phone { pushContext() }
    }

    private func persist() {
        try? store.save(state)
    }

    private func pushContext() {
        guard role == .phone else { return }
        sync?.send(.context(WatchContext(state: state, generatedAt: now())))
    }

    private func counterpartBecameAvailable() {
        switch role {
        case .phone:
            pushContext()
        case .watch:
            sync?.send(.requestContext)
        }
        if let session = state.activeSession { sync?.send(.session(session)) }
    }

    private func receive(_ envelope: SyncEnvelope) {
        var next = state
        let fx = SyncReducer.apply(envelope.message, to: &next, role: role)
        if fx.stateChanged {
            state = next
            persist()
            refreshRestTimer()
            Haptics.isEnabled = state.settings.hapticsEnabled
        }
        if fx.sendContext { pushContext() }
        if let session = fx.sendSession { sync?.send(.session(session)) }
        if let workout = fx.sendCompleted { sync?.send(.completed(workout)) }
        if let workout = fx.completedRemotely { remoteCompletion = workout }
        if fx.activeSessionEndedRemotely { activeSessionEndedRemotely = true }
        #if os(watchOS)
        reconcileHealthSession()
        #endif
    }

    /// Keeps the notification + in-app haptic aligned with the current rest timer.
    private func refreshRestTimer() {
        let timer = state.activeSession?.restTimer ?? .idle(at: now())
        let current = now()
        notifier.update(timer: timer, nextUp: nextUpDescription(), sound: settings.soundEnabled, now: current)

        let end = timer.isRunning(at: current) ? timer.endsAt : nil
        guard end != restEndScheduledFor else { return }
        restEndTask?.cancel()
        restEndScheduledFor = end
        guard let end else { return }
        restEndTask = Task { [weak self] in
            let delay = end.timeIntervalSince(Date())
            if delay > 0 { try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
            guard !Task.isCancelled, let self, self.restEndScheduledFor == end else { return }
            self.restEndScheduledFor = nil
            self.restFinishedCount += 1
            Haptics.restFinished()
        }
    }

    /// "Bench Press · set 3 · 135 lb" for the first unlogged set.
    private func nextUpDescription() -> String? {
        guard let session = state.activeSession else { return nil }
        for e in session.exercises where !e.isSkipped {
            if let i = e.sets.firstIndex(where: { !$0.isLogged }) {
                return "\(e.exercise.name) · set \(i + 1) · \(format(e.weight))"
            }
        }
        return nil
    }

    #if os(watchOS)
    /// Starts/ends/relinks the live Health workout so it follows the active session.
    private func reconcileHealthSession() {
        if let session = state.activeSession {
            if health.isRunning {
                if health.linkedWorkoutID == nil { health.linkedWorkoutID = session.id }
            } else if health.phase == .idle && settings.healthKitEnabled {
                Task { await health.startWorkout(linkedTo: session.id, startDate: session.startedAt) }
            }
        } else if health.phase == .running {
            let id = health.linkedWorkoutID
            let save = settings.healthKitEnabled && id.map { state.hasHistory(id: $0) } == true
            Task { await health.endWorkout(save: save) }
        }
    }
    #endif
}
