import SwiftUI
import LiftCore

/// Edit one exercise slot: swap the exercise, override the next weight, change the increment.
@MainActor
struct SlotEditorView: View {
    @Environment(AppModel.self) private var model
    let slotID: UUID

    private var slot: ExerciseSlot? { model.program.slot(id: slotID) }

    private var dayBodyPart: BodyPart? {
        model.program.days.first(where: { day in day.slots.contains(where: { $0.id == slotID }) })?.bodyPart
    }

    var body: some View {
        Group {
            if let slot {
                form(slot)
            } else {
                ContentUnavailableView("Exercise not found", systemImage: "questionmark.folder")
            }
        }
    }

    private func form(_ slot: ExerciseSlot) -> some View {
        let unit = model.unit
        return Form {
            Section {
                NavigationLink {
                    ExercisePickerView(slotID: slotID, currentExerciseID: slot.exercise.id, homeBodyPart: dayBodyPart ?? slot.exercise.bodyPart)
                } label: {
                    LabeledContent("Exercise", value: slot.exercise.name)
                }
            } footer: {
                Text("Swapping resets the weight to a starting weight and clears the fail streak.")
            }

            Section {
                Stepper(value: nextWeightBinding, in: 0...1000, step: slot.increment > 0 ? slot.increment : (unit == .lb ? 5 : 2.5)) {
                    LabeledContent("Next weight", value: LiftFormat.weightLabel(slot.nextWeight, equipment: slot.exercise.equipment, unit: unit))
                }
                HStack {
                    Text("Enter weight (\(unit.symbol))")
                    Spacer()
                    TextField("Weight", value: nextWeightBinding, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.numeric(.body, weight: .bold))
                        .frame(maxWidth: 110)
                }
                Stepper(value: incrementBinding, in: 0...50, step: unit == .lb ? 2.5 : 0.5) {
                    LabeledContent("Increment", value: "+\(Weight.format(slot.increment)) \(unit.symbol)")
                }
            } header: {
                Text("Progression")
            } footer: {
                Text("Hit all \(slot.sets)×\(slot.targetReps) and the weight goes up by the increment. Three failed sessions in a row deloads 10%.")
            }

            Section("Fail streak") {
                LabeledContent("Failed sessions in a row") {
                    HStack(spacing: 6) {
                        ForEach(0..<ProgressionEngine.failuresBeforeDeload, id: \.self) { index in
                            Image(systemName: index < slot.consecutiveFailures ? "xmark.circle.fill" : "circle")
                                .foregroundStyle(index < slot.consecutiveFailures ? Theme.miss : Color.secondary)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(slot.consecutiveFailures) of \(ProgressionEngine.failuresBeforeDeload)")
                }
                if slot.consecutiveFailures > 0 {
                    Button("Clear Fail Streak") {
                        model.updateProgram { program in
                            program.updateSlot(id: slotID) { $0.consecutiveFailures = 0 }
                        }
                    }
                }
            }
        }
        .navigationTitle(slot.exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var nextWeightBinding: Binding<Double> {
        Binding(
            get: { slot?.nextWeight ?? 0 },
            set: { newValue in
                model.updateProgram { $0.setNextWeight(slotID: slotID, weight: newValue) }
            }
        )
    }

    private var incrementBinding: Binding<Double> {
        Binding(
            get: { slot?.increment ?? 0 },
            set: { newValue in
                model.updateProgram { $0.setIncrement(slotID: slotID, increment: newValue) }
            }
        )
    }
}

/// Exercise library picker: the day's body part first, then every other body part.
@MainActor
struct ExercisePickerView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let slotID: UUID
    let currentExerciseID: String
    let homeBodyPart: BodyPart

    private var otherBodyParts: [BodyPart] {
        BodyPart.allCases.filter { $0 != homeBodyPart }
    }

    var body: some View {
        List {
            Section(homeBodyPart.displayName) {
                ForEach(ExerciseLibrary.exercises(for: homeBodyPart)) { exercise in
                    row(exercise)
                }
            }
            ForEach(otherBodyParts) { part in
                let exercises = ExerciseLibrary.exercises(for: part)
                if !exercises.isEmpty {
                    Section("Other · \(part.displayName)") {
                        ForEach(exercises) { exercise in
                            row(exercise)
                        }
                    }
                }
            }
        }
        .navigationTitle("Choose Exercise")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ exercise: Exercise) -> some View {
        Button {
            select(exercise)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .foregroundStyle(.primary)
                    Text(exercise.equipment.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if exercise.id == currentExerciseID {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .contentShape(Rectangle())
        }
    }

    private func select(_ exercise: Exercise) {
        if exercise.id != currentExerciseID {
            // Read the unit before mutating: the model must not be read inside its own update closure.
            let unit = model.unit
            model.updateProgram { $0.replaceExercise(slotID: slotID, with: exercise, unit: unit) }
        }
        dismiss()
    }
}
