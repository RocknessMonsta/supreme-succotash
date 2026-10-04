import SwiftUI
import LiftCore

/// Per-exercise ✓ / ✗ / – marks for a finished workout.
struct ResultMarks: View {
    let results: [ExerciseResult]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(results) { result in
                Image(systemName: symbol(for: result))
                    .foregroundStyle(color(for: result))
            }
        }
        .font(.subheadline)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private func symbol(for result: ExerciseResult) -> String {
        if !result.wasAttempted { return "minus.circle.fill" }
        return result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill"
    }

    private func color(for result: ExerciseResult) -> Color {
        if !result.wasAttempted { return Color.secondary.opacity(0.5) }
        return result.isSuccess ? Theme.success : Theme.miss
    }

    private var accessibilityText: String {
        let hit = results.filter(\.isSuccess).count
        return "\(hit) of \(results.count) exercises hit target"
    }
}

/// A static rep-count circle used in history detail and summaries (same colours as the live set buttons).
struct RepsBadge: View {
    let reps: Int?
    let target: Int
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            Circle().fill(fill)
            Circle().strokeBorder(stroke, lineWidth: 2)
            Text(reps.map(String.init) ?? "–")
                .font(.numeric(.callout, weight: .bold))
                .foregroundStyle(textColor)
        }
        .frame(width: size, height: size)
    }

    private var isSuccess: Bool { (reps ?? -1) >= target }

    private var fill: Color {
        guard reps != nil else { return Color.clear }
        return isSuccess ? Color.accentColor : Theme.miss
    }

    private var stroke: Color {
        guard reps != nil else { return Color.secondary.opacity(0.4) }
        return isSuccess ? Color.accentColor : Theme.miss
    }

    private var textColor: Color {
        guard reps != nil else { return Color.secondary }
        return isSuccess ? Color.white : Color.black
    }
}

/// Weight-sync state with the Apple Watch, shown subtly.
struct WatchStatusLabel: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let info = describe(model.syncStatus)
        HStack(spacing: 6) {
            Image(systemName: "applewatch")
            Text(info.text)
            Circle().fill(info.color).frame(width: 7, height: 7)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
    }

    private func describe(_ status: SyncStatus) -> (text: String, color: Color) {
        if !status.isSupported || !status.isPaired { return ("No Apple Watch paired", Color.secondary) }
        if !status.isCounterpartInstalled { return ("Watch app not installed", Theme.miss) }
        if status.isReachable { return ("Watch connected", Theme.success) }
        return ("Watch not in range", Color.secondary)
    }
}
