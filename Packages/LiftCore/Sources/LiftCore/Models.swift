import Foundation

// MARK: - Basic enums

public enum WeightUnit: String, Codable, CaseIterable, Sendable {
    case lb, kg

    public var symbol: String { rawValue }

    /// Multiply a value in `self` by this factor to get the value in `other`.
    public func factor(to other: WeightUnit) -> Double {
        switch (self, other) {
        case (.lb, .kg): return 0.45359237
        case (.kg, .lb): return 1 / 0.45359237
        default: return 1
        }
    }
}

public enum BodyPart: String, Codable, CaseIterable, Sendable, Identifiable {
    case chest, back, shoulders, legs, arms, core

    public var id: String { rawValue }
    public var displayName: String { rawValue.capitalized }
}

public enum Equipment: String, Codable, CaseIterable, Sendable {
    case barbell, dumbbell, cable, machine, bodyweight

    public var displayName: String { rawValue.capitalized }
    /// Barbell lifts get plate breakdowns and warm-up ramps.
    public var usesPlates: Bool { self == .barbell }
}

/// Which device produced a value. Used for sync bookkeeping and Health de-duplication.
public enum DeviceKind: String, Codable, Sendable {
    case phone, watch
}

// MARK: - Program definition

public struct Exercise: Codable, Hashable, Identifiable, Sendable {
    /// Stable slug, e.g. "barbell-bench-press". Custom exercises use "custom-<uuid>".
    public var id: String
    public var name: String
    public var bodyPart: BodyPart
    public var equipment: Equipment
    /// Isolation lifts get the smaller default increment.
    public var isIsolation: Bool

    public init(id: String, name: String, bodyPart: BodyPart, equipment: Equipment, isIsolation: Bool) {
        self.id = id
        self.name = name
        self.bodyPart = bodyPart
        self.equipment = equipment
        self.isIsolation = isIsolation
    }
}

/// One exercise position inside a day, carrying its own progression state.
public struct ExerciseSlot: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var exercise: Exercise
    public var sets: Int
    public var targetReps: Int
    /// Weight for the next session, in `Settings.unit`. For dumbbells this is per hand.
    public var nextWeight: Double
    /// Weight added after a successful session, in `Settings.unit`.
    public var increment: Double
    /// Consecutive failed sessions at the current weight. 3 triggers a deload.
    public var consecutiveFailures: Int

    public init(
        id: UUID = UUID(),
        exercise: Exercise,
        sets: Int = ProgramDefaults.sets,
        targetReps: Int = ProgramDefaults.targetReps,
        nextWeight: Double,
        increment: Double,
        consecutiveFailures: Int = 0
    ) {
        self.id = id
        self.exercise = exercise
        self.sets = sets
        self.targetReps = targetReps
        self.nextWeight = nextWeight
        self.increment = increment
        self.consecutiveFailures = consecutiveFailures
    }
}

public struct BodyPartDay: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var bodyPart: BodyPart
    public var isEnabled: Bool
    public var slots: [ExerciseSlot]

    public init(id: UUID = UUID(), name: String, bodyPart: BodyPart, isEnabled: Bool = true, slots: [ExerciseSlot]) {
        self.id = id
        self.name = name
        self.bodyPart = bodyPart
        self.isEnabled = isEnabled
        self.slots = slots
    }
}

public struct Program: Codable, Hashable, Sendable {
    /// Rotation order. Disabled days are skipped.
    public var days: [BodyPartDay]
    /// The day the next workout will use. Falls back to the first enabled day.
    public var nextDayID: UUID?

    public init(days: [BodyPartDay], nextDayID: UUID? = nil) {
        self.days = days
        self.nextDayID = nextDayID ?? days.first(where: \.isEnabled)?.id
    }

    public var enabledDays: [BodyPartDay] { days.filter(\.isEnabled) }

    public var nextDay: BodyPartDay? {
        if let id = nextDayID, let day = days.first(where: { $0.id == id && $0.isEnabled }) {
            return day
        }
        return enabledDays.first
    }

    /// The enabled day that follows `dayID` in rotation (wrapping around).
    public func day(after dayID: UUID) -> BodyPartDay? {
        guard !enabledDays.isEmpty else { return nil }
        guard let index = days.firstIndex(where: { $0.id == dayID }) else { return enabledDays.first }
        for offset in 1...days.count {
            let candidate = days[(index + offset) % days.count]
            if candidate.isEnabled { return candidate }
        }
        return nil
    }

    public func slot(id: UUID) -> ExerciseSlot? {
        for day in days {
            if let slot = day.slots.first(where: { $0.id == id }) { return slot }
        }
        return nil
    }

    public mutating func updateSlot(id: UUID, _ change: (inout ExerciseSlot) -> Void) {
        for d in days.indices {
            if let s = days[d].slots.firstIndex(where: { $0.id == id }) {
                change(&days[d].slots[s])
                return
            }
        }
    }
}

// MARK: - Settings

public struct RestSettings: Codable, Hashable, Sendable {
    /// After a set that hit target reps.
    public var afterSuccess: TimeInterval
    /// After a set that missed target reps.
    public var afterFailure: TimeInterval
    /// After the second (or later) consecutive missed set in the same exercise.
    public var afterRepeatedFailure: TimeInterval

    public init(afterSuccess: TimeInterval = 90, afterFailure: TimeInterval = 180, afterRepeatedFailure: TimeInterval = 300) {
        self.afterSuccess = afterSuccess
        self.afterFailure = afterFailure
        self.afterRepeatedFailure = afterRepeatedFailure
    }
}

public struct Settings: Codable, Hashable, Sendable {
    public var unit: WeightUnit
    public var barWeight: Double
    /// Plate sizes available, one entry per size (assumed unlimited pairs), in `unit`.
    public var availablePlates: [Double]
    /// Smallest jump available for dumbbells, in `unit`.
    public var dumbbellIncrement: Double
    public var rest: RestSettings
    public var warmupsEnabled: Bool
    public var soundEnabled: Bool
    public var hapticsEnabled: Bool
    public var healthKitEnabled: Bool

    public init(
        unit: WeightUnit,
        barWeight: Double,
        availablePlates: [Double],
        dumbbellIncrement: Double,
        rest: RestSettings = RestSettings(),
        warmupsEnabled: Bool = true,
        soundEnabled: Bool = true,
        hapticsEnabled: Bool = true,
        healthKitEnabled: Bool = true
    ) {
        self.unit = unit
        self.barWeight = barWeight
        self.availablePlates = availablePlates
        self.dumbbellIncrement = dumbbellIncrement
        self.rest = rest
        self.warmupsEnabled = warmupsEnabled
        self.soundEnabled = soundEnabled
        self.hapticsEnabled = hapticsEnabled
        self.healthKitEnabled = healthKitEnabled
    }

    public static func defaults(for unit: WeightUnit) -> Settings {
        switch unit {
        case .lb:
            return Settings(unit: .lb, barWeight: 45, availablePlates: [45, 35, 25, 10, 5, 2.5], dumbbellIncrement: 5)
        case .kg:
            return Settings(unit: .kg, barWeight: 20, availablePlates: [25, 20, 15, 10, 5, 2.5, 1.25], dumbbellIncrement: 2)
        }
    }
}

// MARK: - Live session

/// A single work set. `reps == nil` means not yet performed.
public struct LoggedSet: Codable, Hashable, Sendable {
    public var reps: Int?
    public var targetReps: Int
    /// Last edit time; used for last-writer-wins sync merge.
    public var updatedAt: Date

    public init(reps: Int? = nil, targetReps: Int, updatedAt: Date) {
        self.reps = reps
        self.targetReps = targetReps
        self.updatedAt = updatedAt
    }

    public var isLogged: Bool { reps != nil }
    public var isSuccess: Bool { (reps ?? -1) >= targetReps }

    /// StrongLifts tap cycle: empty → target → target-1 → … → 0 → empty.
    public static func nextRepsAfterTap(_ reps: Int?, target: Int) -> Int? {
        guard let reps else { return target }
        if reps <= 0 { return nil }
        return reps - 1
    }
}

public struct WarmupSet: Codable, Hashable, Sendable {
    public var weight: Double
    public var reps: Int
    public var isDone: Bool
    public var updatedAt: Date

    public init(weight: Double, reps: Int, isDone: Bool = false, updatedAt: Date) {
        self.weight = weight
        self.reps = reps
        self.isDone = isDone
        self.updatedAt = updatedAt
    }
}

public struct SessionExercise: Codable, Hashable, Identifiable, Sendable {
    /// Equal to the originating `ExerciseSlot.id`.
    public var id: UUID
    public var exercise: Exercise
    public var weight: Double
    public var weightUpdatedAt: Date
    public var sets: [LoggedSet]
    public var warmups: [WarmupSet]
    public var isSkipped: Bool
    public var skippedUpdatedAt: Date
    public var note: String
    public var noteUpdatedAt: Date

    public init(
        id: UUID,
        exercise: Exercise,
        weight: Double,
        sets: [LoggedSet],
        warmups: [WarmupSet],
        isSkipped: Bool = false,
        note: String = "",
        createdAt: Date
    ) {
        self.id = id
        self.exercise = exercise
        self.weight = weight
        self.weightUpdatedAt = createdAt
        self.sets = sets
        self.warmups = warmups
        self.isSkipped = isSkipped
        self.skippedUpdatedAt = createdAt
        self.note = note
        self.noteUpdatedAt = createdAt
    }

    public var targetReps: Int { sets.first?.targetReps ?? ProgramDefaults.targetReps }
    public var loggedSetCount: Int { sets.filter(\.isLogged).count }
    public var isComplete: Bool { isSkipped || sets.allSatisfy(\.isLogged) }
    /// All work sets logged at or above target.
    public var isSuccess: Bool { !isSkipped && !sets.isEmpty && sets.allSatisfy(\.isSuccess) }
}

/// Rest timer anchored to an absolute end date so it survives backgrounding and device hand-off.
public struct RestTimerState: Codable, Hashable, Sendable {
    /// When the rest ends. `nil` means no timer running.
    public var endsAt: Date?
    /// The full duration of the current rest, for progress rings.
    public var duration: TimeInterval
    public var updatedAt: Date

    public init(endsAt: Date? = nil, duration: TimeInterval = 0, updatedAt: Date) {
        self.endsAt = endsAt
        self.duration = duration
        self.updatedAt = updatedAt
    }

    public static func idle(at date: Date) -> RestTimerState { RestTimerState(updatedAt: date) }

    public func remaining(at now: Date) -> TimeInterval {
        guard let endsAt else { return 0 }
        return max(0, endsAt.timeIntervalSince(now))
    }

    public func isRunning(at now: Date) -> Bool { remaining(at: now) > 0 }

    /// 0…1 fraction elapsed, for progress rings.
    public func progress(at now: Date) -> Double {
        guard duration > 0, endsAt != nil else { return 0 }
        return min(1, max(0, 1 - remaining(at: now) / duration))
    }
}

public struct WorkoutSession: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var dayID: UUID
    public var dayName: String
    public var bodyPart: BodyPart
    public var startedAt: Date
    public var startedOn: DeviceKind
    public var unit: WeightUnit
    public var exercises: [SessionExercise]
    public var restTimer: RestTimerState
    public var note: String
    public var noteUpdatedAt: Date

    public init(
        id: UUID = UUID(),
        dayID: UUID,
        dayName: String,
        bodyPart: BodyPart,
        startedAt: Date,
        startedOn: DeviceKind,
        unit: WeightUnit,
        exercises: [SessionExercise]
    ) {
        self.id = id
        self.dayID = dayID
        self.dayName = dayName
        self.bodyPart = bodyPart
        self.startedAt = startedAt
        self.startedOn = startedOn
        self.unit = unit
        self.exercises = exercises
        self.restTimer = .idle(at: startedAt)
        self.note = ""
        self.noteUpdatedAt = startedAt
    }

    public var loggedSetCount: Int { exercises.reduce(0) { $0 + $1.loggedSetCount } }
    /// Most recent edit anywhere in the session.
    public var lastModified: Date {
        var latest = max(startedAt, restTimer.updatedAt, noteUpdatedAt)
        for e in exercises {
            latest = max(latest, e.weightUpdatedAt, e.skippedUpdatedAt, e.noteUpdatedAt)
            for s in e.sets { latest = max(latest, s.updatedAt) }
            for w in e.warmups { latest = max(latest, w.updatedAt) }
        }
        return latest
    }
    public var isEveryExerciseComplete: Bool { exercises.allSatisfy(\.isComplete) }
}

// MARK: - History

public struct ExerciseResult: Codable, Hashable, Identifiable, Sendable {
    /// Equal to the originating `ExerciseSlot.id`.
    public var id: UUID
    public var exercise: Exercise
    public var weight: Double
    public var targetReps: Int
    /// One entry per work set; `nil` = not performed.
    public var reps: [Int?]
    public var isSkipped: Bool
    public var note: String

    public init(id: UUID, exercise: Exercise, weight: Double, targetReps: Int, reps: [Int?], isSkipped: Bool, note: String = "") {
        self.id = id
        self.exercise = exercise
        self.weight = weight
        self.targetReps = targetReps
        self.reps = reps
        self.isSkipped = isSkipped
        self.note = note
    }

    /// At least one work set logged and not skipped.
    public var wasAttempted: Bool { !isSkipped && reps.contains { $0 != nil } }
    public var isSuccess: Bool { wasAttempted && reps.allSatisfy { ($0 ?? -1) >= targetReps } }
    public var totalReps: Int { reps.reduce(0) { $0 + ($1 ?? 0) } }
    /// weight × reps summed over work sets (dumbbell weights are per hand and not doubled).
    public var volume: Double { weight * Double(totalReps) }
}

public struct CompletedWorkout: Codable, Hashable, Identifiable, Sendable {
    /// Equal to the originating `WorkoutSession.id`.
    public var id: UUID
    public var dayID: UUID
    public var dayName: String
    public var bodyPart: BodyPart
    public var startedAt: Date
    public var finishedAt: Date
    public var unit: WeightUnit
    public var exercises: [ExerciseResult]
    public var note: String
    /// Device that finished the workout. A watch-finished workout was already saved to Health by the watch.
    public var finishedOn: DeviceKind

    public init(
        id: UUID, dayID: UUID, dayName: String, bodyPart: BodyPart, startedAt: Date, finishedAt: Date,
        unit: WeightUnit, exercises: [ExerciseResult], note: String, finishedOn: DeviceKind
    ) {
        self.id = id
        self.dayID = dayID
        self.dayName = dayName
        self.bodyPart = bodyPart
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.unit = unit
        self.exercises = exercises
        self.note = note
        self.finishedOn = finishedOn
    }

    public var duration: TimeInterval { finishedAt.timeIntervalSince(startedAt) }
    public var volume: Double { exercises.reduce(0) { $0 + $1.volume } }
    public var isSuccess: Bool { exercises.filter(\.wasAttempted).allSatisfy(\.isSuccess) }
}

// MARK: - Root state

public struct AppState: Codable, Hashable, Sendable {
    public static let currentSchemaVersion = 1
    /// Max tombstones kept for discarded sessions.
    public static let maxTombstones = 50

    public var schemaVersion: Int
    public var program: Program
    public var settings: Settings
    /// Newest first.
    public var history: [CompletedWorkout]
    public var activeSession: WorkoutSession?
    /// Ids of sessions discarded on either device; late snapshots for these are ignored.
    public var discardedSessionIDs: [UUID]

    public init(
        program: Program,
        settings: Settings,
        history: [CompletedWorkout] = [],
        activeSession: WorkoutSession? = nil,
        discardedSessionIDs: [UUID] = []
    ) {
        self.schemaVersion = Self.currentSchemaVersion
        self.program = program
        self.settings = settings
        self.history = history
        self.activeSession = activeSession
        self.discardedSessionIDs = discardedSessionIDs
    }

    public static func fresh(unit: WeightUnit = .lb) -> AppState {
        AppState(program: ProgramDefaults.program(unit: unit), settings: .defaults(for: unit))
    }

    public func hasHistory(id: UUID) -> Bool { history.contains { $0.id == id } }
    public func isTombstoned(_ id: UUID) -> Bool { discardedSessionIDs.contains(id) }

    public mutating func addTombstone(_ id: UUID) {
        guard !discardedSessionIDs.contains(id) else { return }
        discardedSessionIDs.append(id)
        if discardedSessionIDs.count > Self.maxTombstones {
            discardedSessionIDs.removeFirst(discardedSessionIDs.count - Self.maxTombstones)
        }
    }
}
