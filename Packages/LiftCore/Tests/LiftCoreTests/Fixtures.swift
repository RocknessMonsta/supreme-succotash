import Foundation
@testable import LiftCore

/// Deterministic builders. Tests never call `Date()`.
enum Fixture {
    static let t0 = Date(timeIntervalSince1970: 1_700_000_000)  // Tue 2023-11-14 22:13:20 UTC
    static func at(_ seconds: TimeInterval) -> Date { t0.addingTimeInterval(seconds) }

    static func uuid(_ n: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", n))!
    }

    static let lb = Settings.defaults(for: .lb)
    static let kg = Settings.defaults(for: .kg)

    static func exercise(_ id: String) -> Exercise { ExerciseLibrary.exercise(id: id)! }

    static func slot(_ id: String = "barbell-bench-press", weight: Double = 100, increment: Double = 5, failures: Int = 0) -> ExerciseSlot {
        ExerciseSlot(exercise: exercise(id), nextWeight: weight, increment: increment, consecutiveFailures: failures)
    }

    static func result(_ id: String = "barbell-bench-press", slotID: UUID = UUID(), weight: Double = 100,
                       reps: [Int?] = [8, 8, 8, 8], skipped: Bool = false, note: String = "") -> ExerciseResult {
        ExerciseResult(id: slotID, exercise: exercise(id), weight: weight, targetReps: 8, reps: reps, isSkipped: skipped, note: note)
    }

    /// One-exercise session with `setCount` empty 8-rep sets. Exercise id is `uuid(100)`.
    static func session(id: Int = 1, exerciseID: String = "barbell-bench-press", weight: Double = 100, setCount: Int = 4,
                        startedAt: Date = t0, device: DeviceKind = .phone, dayID: UUID? = nil) -> WorkoutSession {
        let sets = (0..<setCount).map { _ in LoggedSet(targetReps: 8, updatedAt: startedAt) }
        let e = SessionExercise(id: uuid(100), exercise: exercise(exerciseID), weight: weight, sets: sets, warmups: [], createdAt: startedAt)
        return WorkoutSession(id: uuid(id), dayID: dayID ?? uuid(500), dayName: "Chest", bodyPart: .chest,
                              startedAt: startedAt, startedOn: device, unit: .lb, exercises: [e])
    }

    static func workout(id: Int = 1, finishedAt: Date = t0, dayName: String = "Chest", unit: WeightUnit = .lb,
                        exercises: [ExerciseResult], finishedOn: DeviceKind = .phone, dayID: UUID? = nil) -> CompletedWorkout {
        CompletedWorkout(id: uuid(id), dayID: dayID ?? uuid(500), dayName: dayName, bodyPart: .chest,
                         startedAt: finishedAt.addingTimeInterval(-3600), finishedAt: finishedAt, unit: unit,
                         exercises: exercises, note: "", finishedOn: finishedOn)
    }

    static var utcCalendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        c.firstWeekday = 2
        c.minimumDaysInFirstWeek = 4
        return c
    }
}
