import SwiftUI
import LiftCore

/// Rest countdown pinned to the bottom of the workout screen. Rendered purely from `timer.endsAt`
/// through a TimelineView; there is no countdown state of its own.
@MainActor
struct RestTimerBanner: View {
    @Environment(AppModel.self) private var model
    let timer: RestTimerState
    /// Briefly true after a rest ends so the banner can flash "Rest over".
    let showFinished: Bool

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            if timer.isRunning(at: context.date) {
                runningBanner(remaining: timer.remaining(at: context.date), progress: timer.progress(at: context.date))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if showFinished {
                finishedBanner
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showFinished)
    }

    private func runningBanner(remaining: TimeInterval, progress: Double) -> some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Label("Rest", systemImage: "timer")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(LiftFormat.clock(remaining, roundUp: true))
                    .font(.numeric(.largeTitle, weight: .bold))
                    .contentTransition(.numericText())
                Spacer()
                // Balances the label so the countdown stays centred.
                Label("Rest", systemImage: "timer")
                    .font(.subheadline.weight(.semibold))
                    .hidden()
            }
            ProgressView(value: min(1, max(0, progress)))
                .tint(Color.accentColor)
            HStack(spacing: 10) {
                Button {
                    model.adjustRest(by: -15)
                } label: {
                    Text("−15s").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    model.skipRest()
                } label: {
                    Text("Skip").fontWeight(.bold).frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    model.adjustRest(by: 15)
                } label: {
                    Text("+15s").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.large)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.18), radius: 12, y: 2)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .accessibilityElement(children: .contain)
    }

    private var finishedBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "bell.fill")
            Text("Rest over — next set!")
                .font(.headline)
        }
        .foregroundStyle(Color.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.accentColor.opacity(0.4), radius: 12, y: 2)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
}
