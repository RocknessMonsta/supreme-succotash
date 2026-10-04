import SwiftUI
import LiftCore

/// A big circular set button. Tap cycles reps (empty → target → … → 0 → empty); long-press opens the
/// reps picker. Empty = outline, success = filled accent, miss = filled amber with the rep count.
@MainActor
struct SetCircle: View {
    let set: LoggedSet
    let number: Int
    let onTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                ZStack {
                    Circle().fill(fillColor)
                    Circle().strokeBorder(strokeColor, lineWidth: 3)
                    Text(label)
                        .font(.numeric(.title, weight: .bold))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundStyle(textColor)
                }
            }
            .contentShape(Circle())
            .onTapGesture { onTap() }
            .onLongPressGesture(minimumDuration: 0.4) {
                Haptics.tap()
                onLongPress()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Set \(number)")
            .accessibilityValue(accessibilityValue)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onTap() }
            .accessibilityAction(named: "Enter reps") { onLongPress() }
    }

    private var label: String {
        if let reps = set.reps { return String(reps) }
        return String(set.targetReps)
    }

    private var accessibilityValue: String {
        guard let reps = set.reps else { return "Not done, target \(set.targetReps) reps" }
        return "\(reps) of \(set.targetReps) reps"
    }

    private var fillColor: Color {
        guard set.isLogged else { return Color.clear }
        return set.isSuccess ? Color.accentColor : Theme.miss
    }

    private var strokeColor: Color {
        guard set.isLogged else { return Color.secondary.opacity(0.45) }
        return set.isSuccess ? Color.accentColor : Theme.miss
    }

    private var textColor: Color {
        guard set.isLogged else { return Color.secondary.opacity(0.5) }
        return set.isSuccess ? Color.white : Color.black
    }
}
