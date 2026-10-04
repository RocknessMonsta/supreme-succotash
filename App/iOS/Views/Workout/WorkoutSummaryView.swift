import SwiftUI
import LiftCore

/// Brief "nice work" screen shown after finishing a workout.
@MainActor
struct WorkoutSummaryView: View {
    @Environment(AppModel.self) private var model
    let workout: CompletedWorkout
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: workout.isSuccess ? "checkmark.seal.fill" : "flag.checkered")
                    .font(.system(size: 72))
                    .foregroundStyle(Color.accentColor)
                    .padding(.top, 32)
                    .accessibilityHidden(true)
                VStack(spacing: 4) {
                    Text("Workout complete")
                        .font(.largeTitle.weight(.bold))
                    Text(workout.isSuccess ? "Every set hit target. Nice work." : "Logged. Consistency beats perfection.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                statsRow
                VStack(spacing: 0) {
                    ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, result in
                        if index > 0 { Divider() }
                        resultRow(result)
                    }
                }
                .card()
                if let day = model.nextDay {
                    Label("Next up: \(day.name)", systemImage: "calendar")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Button(action: onDone) {
                    Text("Done")
                        .font(.title3.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statTile(title: "Time", value: LiftFormat.duration(workout.duration))
            statTile(title: "Volume", value: LiftFormat.volume(workout.volume, unit: workout.unit))
            statTile(title: "Reps", value: "\(workout.exercises.reduce(0) { $0 + $1.totalReps })")
        }
    }

    private func statTile(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.numeric(.headline, weight: .bold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .card()
    }

    private func resultRow(_ result: ExerciseResult) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon(for: result))
                .font(.title3)
                .foregroundStyle(color(for: result))
            VStack(alignment: .leading, spacing: 2) {
                Text(result.exercise.name)
                    .font(.body.weight(.semibold))
                Text(detail(for: result))
                    .font(.numeric(.caption))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if let next = nextWeightText(for: result) {
                Text(next)
                    .font(.numeric(.caption, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
    }

    private func icon(for result: ExerciseResult) -> String {
        if !result.wasAttempted { return "minus.circle.fill" }
        return result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill"
    }

    private func color(for result: ExerciseResult) -> Color {
        if !result.wasAttempted { return Color.secondary }
        return result.isSuccess ? Theme.success : Theme.miss
    }

    private func detail(for result: ExerciseResult) -> String {
        if result.isSkipped { return "Skipped" }
        let weight = LiftFormat.weightLabel(result.weight, equipment: result.exercise.equipment, unit: workout.unit)
        return "\(weight) · \(LiftFormat.reps(result.reps))"
    }

    /// The weight progression set for next time, read from the (already updated) program.
    private func nextWeightText(for result: ExerciseResult) -> String? {
        guard result.wasAttempted, let slot = model.program.slot(id: result.id) else { return nil }
        return "Next \(LiftFormat.weightLabel(slot.nextWeight, equipment: slot.exercise.equipment, unit: model.unit))"
    }
}
