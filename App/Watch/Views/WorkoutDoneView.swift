import SwiftUI
import LiftCore

/// Short success screen shown after finishing on the watch.
struct WorkoutDoneView: View {
    let workout: CompletedWorkout
    let onDone: () -> Void

    var body: some View {
        let attempted = workout.exercises.filter { $0.wasAttempted }.count
        let hits = workout.exercises.filter { $0.isSuccess }.count
        return ScrollView {
            VStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.green)
                Text("Workout done")
                    .font(.headline)
                Text(workout.dayName)
                    .font(.footnote)
                    .foregroundStyle(Color.accentColor)
                Text("\(WatchFormat.duration(workout.duration)) \u{00B7} \(WatchFormat.volume(workout.volume)) \(workout.unit.symbol)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("\(hits)/\(attempted) exercises hit target")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                Button(action: onDone) {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
    }
}
