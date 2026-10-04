import SwiftUI
import LiftCore

/// Edits this session's weight for one exercise: Digital Crown or -/+ by the loadable step.
struct WeightEditorSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    let exerciseID: UUID
    let usesPlates: Bool
    let minimum: Double
    let maximum: Double
    let step: Double

    @State private var value: Double
    @FocusState private var crownFocused: Bool

    init(exerciseID: UUID, weight: Double, usesPlates: Bool, minimum: Double, maximum: Double, step: Double) {
        self.exerciseID = exerciseID
        self.usesPlates = usesPlates
        self.minimum = minimum
        self.maximum = maximum
        self.step = step
        _value = State(initialValue: min(maximum, max(minimum, weight)))
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(WatchFormat.weight(value))
                    .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(model.unit.symbol)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if usesPlates {
                Text(plateText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            HStack(spacing: 8) {
                Button { adjust(by: -step) } label: {
                    Image(systemName: "minus").frame(maxWidth: .infinity)
                }
                .accessibilityLabel("Decrease weight")
                Button { adjust(by: step) } label: {
                    Image(systemName: "plus").frame(maxWidth: .infinity)
                }
                .accessibilityLabel("Increase weight")
            }
            Button {
                model.setWeight(value, exerciseID: exerciseID)
                dismiss()
            } label: {
                Label("Set", systemImage: "checkmark").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .focusable()
        .focused($crownFocused)
        .digitalCrownRotation(
            $value,
            from: minimum,
            through: maximum,
            by: step,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onAppear { crownFocused = true }
    }

    private var plateText: String {
        WatchFormat.plates(model.plates(for: value))
    }

    private func adjust(by delta: Double) {
        value = LiftCore.Weight.clean(min(maximum, max(minimum, value + delta)))
    }
}
