import Foundation

public enum CSVExporter {
    /// One row per exercise result, oldest workout first. Columns:
    /// `Date,Workout,Exercise,Weight,Unit,Set 1…Set N,Skipped,Notes` (N = most sets in any result,
    /// at least `ProgramDefaults.sets` when history is empty). Date is the workout's `finishedAt`,
    /// ISO8601 in UTC. Unperformed sets are empty cells. Notes are the exercise note.
    public static func csv(for history: [CompletedWorkout]) -> String {
        let setCount = history.flatMap(\.exercises).map { $0.reps.count }.max() ?? ProgramDefaults.sets
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(identifier: "UTC")

        var header = ["Date", "Workout", "Exercise", "Weight", "Unit"]
        header += (1...max(1, setCount)).map { "Set \($0)" }
        header += ["Skipped", "Notes"]
        var lines = [header.joined(separator: ",")]

        for workout in history.enumerated().sorted(by: {
            $0.element.finishedAt != $1.element.finishedAt ? $0.element.finishedAt < $1.element.finishedAt : $0.offset < $1.offset
        }).map(\.element) {
            for result in workout.exercises {
                var fields = [
                    formatter.string(from: workout.finishedAt), workout.dayName, result.exercise.name,
                    Weight.format(result.weight), workout.unit.symbol,
                ]
                for i in 0..<max(1, setCount) {
                    fields.append(result.reps[safe: i].flatMap { $0 }.map(String.init) ?? "")
                }
                fields.append(result.isSkipped ? "true" : "false")
                fields.append(result.note)
                lines.append(fields.map(escape).joined(separator: ","))
            }
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// RFC 4180 style quoting.
    static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
