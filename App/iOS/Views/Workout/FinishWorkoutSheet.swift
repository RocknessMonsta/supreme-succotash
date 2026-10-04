import SwiftUI
import LiftCore

/// Confirmation before finishing: each exercise's result and what progression will do next time.
@MainActor
struct FinishWorkoutSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    /// Invoked just before the sheet dismisses; the workout screen performs the actual finish afterwards.
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            if let session = model.activeSession {
                content(session)
            } else {
                Text("This workout has already ended.")
                    .foregroundStyle(.secondary)
            }
        }
        .presentationDetents([.large])
    }

    private func content(_ session: WorkoutSession) -> some View {
        let preview = model.finishPreview()
        let unlogged = session.exercises
            .filter { !$0.isSkipped }
            .reduce(0) { $0 + ($1.sets.count - $1.loggedSetCount) }
        return List {
            if session.loggedSetCount == 0 {
                Section {
                    Label("No sets logged yet. Finishing now records every exercise as skipped.", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.miss)
                }
            } else if unlogged > 0 {
                Section {
                    Label("\(unlogged) unlogged \(unlogged == 1 ? "set counts" : "sets count") as a miss.", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.miss)
                }
            }
            Section("Results") {
                ForEach(session.exercises) { exercise in
                    resultRow(exercise, entry: preview[exercise.id])
                }
            }
            if !session.note.isEmpty {
                Section("Workout note") {
                    Text(session.note)
                }
            }
            Section {
                Button {
                    onConfirm()
                    dismiss()
                } label: {
                    Label("Finish Workout", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Finish Workout?")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Keep Training") { dismiss() }
            }
        }
    }

    private func resultRow(_ exercise: SessionExercise, entry: (ProgressionOutcome, Double)?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(exercise.exercise.name)
                    .font(.headline)
                Spacer()
                Text(LiftFormat.weightLabel(exercise.weight, equipment: exercise.exercise.equipment, unit: model.unit))
                    .font(.numeric(.subheadline))
                    .foregroundStyle(.secondary)
            }
            if exercise.isSkipped {
                Label("Skipped", systemImage: "forward.end.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 6) {
                    ForEach(Array(exercise.sets.indices), id: \.self) { index in
                        RepsBadge(reps: exercise.sets[index].reps, target: exercise.sets[index].targetReps, size: 34)
                    }
                }
            }
            if let entry {
                outcomeLabel(outcome: entry.0, nextWeight: entry.1, equipment: exercise.exercise.equipment)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func outcomeLabel(outcome: ProgressionOutcome, nextWeight: Double, equipment: Equipment) -> some View {
        let next = LiftFormat.weightLabel(nextWeight, equipment: equipment, unit: model.unit)
        switch outcome {
        case .increased:
            Label("Next time: \(next) ↑", systemImage: "arrow.up.circle.fill")
                .foregroundStyle(Theme.success)
                .font(.subheadline.weight(.semibold))
        case .repeated:
            Label("Repeat \(next)", systemImage: "arrow.triangle.2.circlepath.circle.fill")
                .foregroundStyle(Theme.miss)
                .font(.subheadline.weight(.semibold))
        case .deloaded:
            Label("Deload to \(next)", systemImage: "arrow.down.circle.fill")
                .foregroundStyle(Color.red)
                .font(.subheadline.weight(.semibold))
        case .unchanged:
            Label("No change", systemImage: "equal.circle.fill")
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
    }
}
