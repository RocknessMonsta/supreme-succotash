import SwiftUI
import LiftCore

/// Compact live header: elapsed time (or the rest countdown while a rest is hidden), heart rate, kcal.
struct WorkoutMetricsStrip: View {
    @Environment(AppModel.self) private var model
    /// Tapping the rest pill asks the container to show the rest overlay again.
    let onRestTap: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            if let session = model.activeSession {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    if session.restTimer.isRunning(at: context.date) {
                        Button(action: onRestTap) {
                            Label(WatchFormat.restClock(session.restTimer.remaining(at: context.date)), systemImage: "timer")
                                .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Show rest timer")
                    } else {
                        Text(session.startedAt, style: .timer)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            HStack(spacing: 2) {
                Image(systemName: "heart.fill").foregroundStyle(Color.red)
                Text(heartRateText)
            }
            HStack(spacing: 2) {
                Image(systemName: "flame.fill").foregroundStyle(Color.orange)
                Text(energyText)
            }
        }
        .font(.caption2.monospacedDigit())
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    private var heartRateText: String {
        guard let bpm = model.health.heartRate, bpm.isFinite else { return "--" }
        return String(Int(bpm.rounded()))
    }

    private var energyText: String {
        let kcal = model.health.activeEnergy
        guard kcal.isFinite else { return "--" }
        return String(Int(max(0, kcal).rounded()))
    }
}
