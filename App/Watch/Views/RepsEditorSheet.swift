import SwiftUI
import LiftCore

/// Direct rep entry for one set (long-press). The wheel is driven by the Digital Crown.
struct RepsEditorSheet: View {
    let setNumber: Int
    let canClear: Bool
    let onSave: (Int?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var reps: Int

    init(setNumber: Int, initialReps: Int?, targetReps: Int, onSave: @escaping (Int?) -> Void) {
        self.setNumber = setNumber
        self.canClear = initialReps != nil
        self.onSave = onSave
        _reps = State(initialValue: min(20, max(0, initialReps ?? targetReps)))
    }

    var body: some View {
        VStack(spacing: 6) {
            Text("Set \(setNumber) reps")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Picker("Reps", selection: $reps) {
                ForEach(0...20, id: \.self) { value in
                    Text("\(value)").tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 70)
            HStack(spacing: 6) {
                Button {
                    onSave(nil)
                    dismiss()
                } label: {
                    Image(systemName: "trash")
                        .frame(maxWidth: .infinity)
                }
                .tint(.red)
                .disabled(!canClear)
                .accessibilityLabel("Clear set")

                Button {
                    onSave(reps)
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .tint(.green)
                .accessibilityLabel("Save reps")
            }
        }
    }
}
