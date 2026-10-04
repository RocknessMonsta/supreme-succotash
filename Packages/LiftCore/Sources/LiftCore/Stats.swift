import Foundation

public enum Stats {
    /// Epley estimate: weight × (1 + reps/30). 0 reps → 0, 1 rep → the weight itself.
    public static func estimatedOneRepMax(weight: Double, reps: Int) -> Double {
        guard reps > 0, weight > 0 else { return 0 }
        if reps == 1 { return weight }
        return weight * (1 + Double(reps) / 30)
    }

    public struct WeightPoint: Hashable, Sendable {
        public var date: Date
        public var weight: Double
        public var estimated1RM: Double
        public var success: Bool

        public init(date: Date, weight: Double, estimated1RM: Double, success: Bool) {
            self.date = date
            self.weight = weight
            self.estimated1RM = estimated1RM
            self.success = success
        }
    }

    public struct PersonalRecord: Hashable, Sendable, Identifiable {
        /// The exercise id.
        public var id: String
        public var exercise: Exercise
        public var heaviestWeight: Double
        public var heaviestDate: Date
        public var best1RM: Double
        public var best1RMDate: Date

        public init(id: String, exercise: Exercise, heaviestWeight: Double, heaviestDate: Date, best1RM: Double, best1RMDate: Date) {
            self.id = id
            self.exercise = exercise
            self.heaviestWeight = heaviestWeight
            self.heaviestDate = heaviestDate
            self.best1RM = best1RM
            self.best1RMDate = best1RMDate
        }
    }

    /// Best Epley estimate across the work sets of one result.
    static func best1RM(of result: ExerciseResult) -> Double {
        result.reps.reduce(0) { max($0, estimatedOneRepMax(weight: result.weight, reps: $1 ?? 0)) }
    }

    /// One point per workout in which the exercise was attempted, oldest first. Dates are `finishedAt`.
    public static func series(for exerciseID: String, in history: [CompletedWorkout]) -> [WeightPoint] {
        var points: [WeightPoint] = []
        for workout in history.sorted(by: { $0.finishedAt < $1.finishedAt }) {
            for result in workout.exercises where result.exercise.id == exerciseID && result.wasAttempted {
                points.append(WeightPoint(
                    date: workout.finishedAt, weight: result.weight,
                    estimated1RM: best1RM(of: result), success: result.isSuccess
                ))
            }
        }
        return points
    }

    /// Per-exercise records over attempted results with at least one rep. Ties keep the earliest date.
    /// Sorted by exercise name.
    public static func personalRecords(in history: [CompletedWorkout]) -> [PersonalRecord] {
        var records: [String: PersonalRecord] = [:]
        for workout in history.sorted(by: { $0.finishedAt < $1.finishedAt }) {
            for result in workout.exercises where result.wasAttempted && result.totalReps > 0 {
                let id = result.exercise.id
                let oneRM = best1RM(of: result)
                guard var record = records[id] else {
                    records[id] = PersonalRecord(
                        id: id, exercise: result.exercise, heaviestWeight: result.weight,
                        heaviestDate: workout.finishedAt, best1RM: oneRM, best1RMDate: workout.finishedAt
                    )
                    continue
                }
                record.exercise = result.exercise
                if result.weight > record.heaviestWeight {
                    record.heaviestWeight = result.weight
                    record.heaviestDate = workout.finishedAt
                }
                if oneRM > record.best1RM {
                    record.best1RM = oneRM
                    record.best1RMDate = workout.finishedAt
                }
                records[id] = record
            }
        }
        return records.values.sorted {
            let order = $0.exercise.name.localizedCaseInsensitiveCompare($1.exercise.name)
            return order == .orderedSame ? $0.id < $1.id : order == .orderedAscending
        }
    }

    public static func totalVolume(in history: [CompletedWorkout]) -> Double {
        history.reduce(0) { $0 + $1.volume }
    }

    /// Workouts finished in the calendar week containing `now`.
    public static func workoutsThisWeek(in history: [CompletedWorkout], now: Date, calendar: Calendar = .current) -> Int {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        return history.filter { week.contains($0.finishedAt) }.count
    }

    /// Consecutive calendar weeks with at least one workout, counting back from this week. If this
    /// week has no workout yet, the streak is still alive and counts back from last week.
    public static func currentStreakWeeks(in history: [CompletedWorkout], now: Date, calendar: Calendar = .current) -> Int {
        let weekStarts = Set(history.compactMap { calendar.dateInterval(of: .weekOfYear, for: $0.finishedAt)?.start })
        guard var cursor = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return 0 }
        if !weekStarts.contains(cursor) {
            guard let previous = calendar.date(byAdding: .weekOfYear, value: -1, to: cursor) else { return 0 }
            cursor = previous
        }
        var streak = 0
        while weekStarts.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .weekOfYear, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }
}
