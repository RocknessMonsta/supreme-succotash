import SwiftUI
import LiftCore

/// One finished workout: every exercise with weight and reps per set. Supports simple editing
/// (weights, reps, skipped) and deletion. Edits don't re-run progression.
@MainActor
struct HistoryDetailView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let workoutID: UUID

    /// Non-nil while editing.
    @State private var draft: CompletedWorkout?
    @State private var showDeleteDialog = false

    private var stored: CompletedWorkout? {
        model.history.first(where: { $0.id == workoutID })
    }

    private var isEditing: Bool { draft != nil }

    var body: some View {
        Group {
            if let workout = draft ?? stored {
                content(workout)
            } else {
                ContentUnavailableView("Workout not found", systemImage: "questionmark.folder")
            }
        }
        .navigationTitle((draft ?? stored)?.dayName ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isEditing)
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { draft = nil }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveDraft() }
                        .fontWeight(.bold)
                }
            } else if stored != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            draft = stored
                        } label: {
                            Label("Edit Reps & Weights", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            showDeleteDialog = true
                        } label: {
                            Label("Delete Workout", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .confirmationDialog("Delete this workout?", isPresented: $showDeleteDialog, titleVisibility: .visible) {
            Button("Delete Workout", role: .destructive) {
                model.deleteHistory(id: workoutID)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your program's weights won't change.")
        }
    }

    // MARK: Content

    private func content(_ workout: CompletedWorkout) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                headerCard(workout)
                ForEach(Array(workout.exercises.indices), id: \.self) { index in
                    if isEditing {
                        editCard(workout.exercises[index], index: index)
                    } else {
                        displayCard(workout.exercises[index], unit: workout.unit)
                    }
                }
                if !workout.note.isEmpty {
                    Label(workout.note, systemImage: "note.text")
                        .font(.subheadline)
                        .card()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func headerCard(_ workout: CompletedWorkout) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(workout.bodyPart.displayName, systemImage: workout.bodyPart.symbolName)
                    .font(.headline)
                Spacer()
                ResultMarks(results: workout.exercises)
            }
            Text(workout.finishedAt.formatted(date: .complete, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                Label(LiftFormat.duration(workout.duration), systemImage: "clock")
                Label(LiftFormat.volume(workout.volume, unit: workout.unit), systemImage: "scalemass")
                Label(workout.finishedOn == .watch ? "Watch" : "iPhone", systemImage: workout.finishedOn == .watch ? "applewatch" : "iphone")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .card()
    }

    private func displayCard(_ result: ExerciseResult, unit: WeightUnit) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(result.exercise.name)
                    .font(.headline)
                Spacer()
                if result.isSkipped {
                    Text("Skipped")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else {
                    Text(LiftFormat.weightLabel(result.weight, equipment: result.exercise.equipment, unit: unit))
                        .font(.numeric(.headline, weight: .bold))
                }
            }
            if !result.isSkipped {
                HStack(spacing: 8) {
                    ForEach(Array(result.reps.indices), id: \.self) { index in
                        RepsBadge(reps: result.reps[index], target: result.targetReps)
                    }
                }
                Text("\(result.totalReps) reps · \(LiftFormat.volume(result.volume, unit: unit))")
                    .font(.numeric(.caption))
                    .foregroundStyle(.secondary)
            }
            if !result.note.isEmpty {
                Label(result.note, systemImage: "note.text")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .card()
    }

    // MARK: Editing

    private func editCard(_ result: ExerciseResult, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(result.exercise.name)
                .font(.headline)
            Toggle("Skipped", isOn: skippedBinding(index))
            HStack {
                Text("Weight (\(draft?.unit.symbol ?? ""))")
                Spacer()
                TextField("Weight", value: weightBinding(index), format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.numeric(.body, weight: .bold))
                    .frame(maxWidth: 110)
                    .padding(8)
                    .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            if !result.isSkipped {
                HStack(spacing: 8) {
                    ForEach(Array(result.reps.indices), id: \.self) { setIndex in
                        repsMenu(exercise: index, set: setIndex, target: result.targetReps)
                    }
                }
            }
        }
        .card()
    }

    private func repsMenu(exercise: Int, set: Int, target: Int) -> some View {
        let binding = repsBinding(exercise: exercise, set: set)
        return Menu {
            Button("Not done") { binding.wrappedValue = nil }
            ForEach(0...20, id: \.self) { reps in
                Button(String(reps)) { binding.wrappedValue = reps }
            }
        } label: {
            RepsBadge(reps: binding.wrappedValue, target: target)
        }
        .accessibilityLabel("Set \(set + 1) reps")
    }

    private func update(_ change: (inout CompletedWorkout) -> Void) {
        guard var workout = draft else { return }
        change(&workout)
        draft = workout
    }

    private func weightBinding(_ index: Int) -> Binding<Double> {
        Binding(
            get: { draft?.exercises.element(at: index)?.weight ?? 0 },
            set: { newValue in
                update { workout in
                    guard workout.exercises.indices.contains(index) else { return }
                    workout.exercises[index].weight = max(0, Weight.clean(newValue))
                }
            }
        )
    }

    private func skippedBinding(_ index: Int) -> Binding<Bool> {
        Binding(
            get: { draft?.exercises.element(at: index)?.isSkipped ?? false },
            set: { newValue in
                update { workout in
                    guard workout.exercises.indices.contains(index) else { return }
                    workout.exercises[index].isSkipped = newValue
                }
            }
        )
    }

    private func repsBinding(exercise: Int, set: Int) -> Binding<Int?> {
        Binding(
            get: { draft?.exercises.element(at: exercise)?.reps.element(at: set) ?? nil },
            set: { newValue in
                update { workout in
                    guard workout.exercises.indices.contains(exercise),
                          workout.exercises[exercise].reps.indices.contains(set) else { return }
                    workout.exercises[exercise].reps[set] = newValue
                }
            }
        )
    }

    private func saveDraft() {
        if let workout = draft {
            model.updateHistory(workout)
        }
        draft = nil
    }
}
