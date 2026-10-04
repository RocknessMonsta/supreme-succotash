import SwiftUI
import LiftCore

/// Full-screen rest countdown. Driven only by `RestTimerState.endsAt` through the `now` supplied by
/// the parent's `TimelineView`; there is no local countdown state.
struct RestTimerOverlay: View {
    @Environment(AppModel.self) private var model

    let timer: RestTimerState
    let now: Date
    /// Hides the overlay (the rest keeps running; the metrics strip shows a pill to bring it back).
    let onHide: () -> Void

    private let ringSize: CGFloat = 108

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 9)
                Circle()
                    .trim(from: 0, to: max(0, min(1, 1 - timer.progress(at: now))))
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text(WatchFormat.restClock(timer.remaining(at: now)))
                        .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                    Text("Rest")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: ringSize, height: ringSize)
            .contentShape(Circle())
            .onTapGesture(perform: onHide)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Rest, \(WatchFormat.restClock(timer.remaining(at: now))) remaining")
            .accessibilityHint("Tap to hide")
            .accessibilityAddTraits(.isButton)

            HStack(spacing: 6) {
                controlButton("\u{2212}15", label: "Subtract 15 seconds") { model.adjustRest(by: -15) }
                controlButton("+15", label: "Add 15 seconds") { model.adjustRest(by: 15) }
                controlButton("Skip", label: "Skip rest") { model.skipRest() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }

    private func controlButton(_ title: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.weight(.semibold).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 32)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel(label)
    }
}
