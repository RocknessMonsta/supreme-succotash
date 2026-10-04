import SwiftUI
import LiftCore

/// Edit this session's weight for one exercise: stepper by the slot increment plus a text field.
@MainActor
struct WeightEditorSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let exerciseID: UUID

    @State private var value: Double = 0
    @State private var text = ""
    @State private var loaded = false

    private var exercise: SessionExercise? {
        model.activeSession?.exercises.first(where: { $0.id == exerciseID })
    }

    private var step: Double {
        if let slotStep = model.program.slot(id: exerciseID)?.increment, slotStep > 0 { return slotStep }
        return model.unit == .lb ? 5 : 2.5
    }

    var body: some View {
        NavigationStack {
            Form {
                if let exercise {
                    Section {
                        stepperRow
                    } header: {
                        Text(exercise.exercise.name)
                    } footer: {
                        Text("Changes apply to this workout. Weights are rounded to what you can load. The next-session weight is set by progression when you finish.")
                    }
                    if exercise.exercise.equipment.usesPlates {
                        Section("Plates per side") {
                            Text(model.plates(for: value).summary)
                                .font(.numeric(.body, weight: .medium))
                        }
                    }
                } else {
                    Text("This exercise is no longer available.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        model.setWeight(value, exerciseID: exerciseID)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(exercise == nil)
                }
            }
            .onAppear(perform: loadIfNeeded)
            .onChange(of: text) { _, newText in
                if let parsed = parse(newText) { value = parsed }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var stepperRow: some View {
        HStack(spacing: 12) {
            Button {
                adjust(by: -step)
            } label: {
                Image(systemName: "minus.circle.fill").font(.largeTitle)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Decrease weight")

            VStack(spacing: 2) {
                TextField("Weight", text: $text)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.numeric(.largeTitle, weight: .bold))
                Text("\(model.unit.symbol) · step \(Weight.format(step))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Button {
                adjust(by: step)
            } label: {
                Image(systemName: "plus.circle.fill").font(.largeTitle)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Increase weight")
        }
        .padding(.vertical, 6)
    }

    private func loadIfNeeded() {
        guard !loaded, let exercise else { return }
        loaded = true
        value = exercise.weight
        text = Weight.format(exercise.weight)
    }

    private func adjust(by delta: Double) {
        value = max(0, Weight.clean(value + delta))
        text = Weight.format(value)
    }

    private func parse(_ string: String) -> Double? {
        let normalised = string.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        guard let number = Double(normalised), number >= 0, number.isFinite else { return nil }
        return number
    }
}

/// Pick exact reps for a set (0…20) or clear it.
@MainActor
struct RepsPickerSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let exerciseID: UUID
    let setIndex: Int

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    private var exercise: SessionExercise? {
        model.activeSession?.exercises.first(where: { $0.id == exerciseID })
    }

    private var currentReps: Int? {
        exercise?.sets.element(at: setIndex)?.reps
    }

    private var targetReps: Int {
        exercise?.sets.element(at: setIndex)?.targetReps ?? ProgramDefaults.targetReps
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(0...20, id: \.self) { reps in
                            repsButton(reps)
                        }
                    }
                    Button(role: .destructive) {
                        model.setReps(nil, exerciseID: exerciseID, setIndex: setIndex)
                        dismiss()
                    } label: {
                        Label("Clear Set", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(currentReps == nil)
                }
                .padding(16)
            }
            .navigationTitle("\(exercise?.exercise.name ?? "Set") · Set \(setIndex + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func repsButton(_ reps: Int) -> some View {
        let isCurrent = currentReps == reps
        return Button {
            model.setReps(reps, exerciseID: exerciseID, setIndex: setIndex)
            dismiss()
        } label: {
            Text("\(reps)")
                .font(.numeric(.title3, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(isCurrent ? Color.accentColor : Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .foregroundStyle(isCurrent ? Color.white : (reps >= targetReps ? Color.primary : Theme.miss))
        }
        .buttonStyle(.plain)
    }
}

/// Free-text note editor used for exercise and workout notes.
@MainActor
struct NoteEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let onSave: (String) -> Void
    @State private var text: String

    init(title: String, initialText: String, onSave: @escaping (String) -> Void) {
        self.title = title
        self.onSave = onSave
        _text = State(initialValue: initialText)
    }

    var body: some View {
        NavigationStack {
            TextEditor(text: $text)
                .padding(12)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            onSave(text.trimmingCharacters(in: .whitespacesAndNewlines))
                            dismiss()
                        }
                        .fontWeight(.bold)
                    }
                }
        }
        .presentationDetents([.medium, .large])
    }
}
