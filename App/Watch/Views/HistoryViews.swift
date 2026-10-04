import SwiftUI
import LiftCore

/// Recent workouts, newest first.
struct HistoryListView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Group {
            if model.history.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.title2)
                    Text("No workouts yet")
                        .font(.footnote)
                }
                .foregroundStyle(.secondary)
            } else {
                List(Array(model.history.prefix(30))) { workout in
                    NavigationLink {
                        HistoryDetailView(workout: workout)
                    } label: {
                        HistoryRow(workout: workout)
                    }
                }
            }
        }
        .navigationTitle("History")
    }
}

private struct HistoryRow: View {
    let workout: CompletedWorkout

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: workout.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(workout.isSuccess ? Color.green : Color.orange)
                Text(workout.dayName)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
            }
            Text("\(workout.finishedAt.formatted(.dateTime.month(.abbreviated).day())) \u{00B7} \(WatchFormat.duration(workout.duration))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

/// One finished workout with the sets of every exercise.
struct HistoryDetailView: View {
    let workout: CompletedWorkout

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.finishedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(WatchFormat.duration(workout.duration)) \u{00B7} \(WatchFormat.volume(workout.volume)) \(workout.unit.symbol)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                ForEach(workout.exercises) { result in
                    ExerciseResultRow(result: result, unit: workout.unit)
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle(workout.dayName)
    }
}

private struct ExerciseResultRow: View {
    let result: ExerciseResult
    let unit: WeightUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(WatchFormat.shortName(result.exercise.name))
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
                Spacer(minLength: 4)
                Text("\(WatchFormat.weight(result.weight)) \(unit.symbol)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            if result.isSkipped {
                Text("Skipped")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 3) {
                    ForEach(Array(result.reps.enumerated()), id: \.offset) { _, reps in
                        SetCircleView(reps: reps, target: result.targetReps, size: 26)
                    }
                }
            }
        }
    }
}
