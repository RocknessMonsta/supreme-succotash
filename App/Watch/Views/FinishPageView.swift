import SwiftUI
import LiftCore

/// Last exercise-adjacent page: per-exercise result and next weight, then Finish.
struct FinishPageView: View {
    @Environment(AppModel.self) private var model

    let onFinished: (CompletedWorkout) -> Void

    var body: some View {
        if let session = model.activeSession {
            content(session)
        } else {
            Color.clear
        }
    }

    private func content(_ session: WorkoutSession) -> some View {
        let preview = model.finishPreview()
        let unlogged = unloggedSetCount(session)
        return ScrollView {
            VStack(spacing: 6) {
                Text("Finish")
                    .font(.headline)
                ForEach(session.exercises) { ex in
                    row(ex, preview: preview[ex.id])
                }
                if unlogged > 0 {
                    Text("\(unlogged) unlogged \(unlogged == 1 ? "set counts" : "sets count") as a miss")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                Button {
                    if let workout = model.finishWorkout() {
                        onFinished(workout)
                    }
                } label: {
                    Label("Finish", systemImage: "checkmark")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding(.leading, 4)
            .padding(.trailing, 8)
        }
    }

    private func row(_ ex: SessionExercise, preview: (ProgressionOutcome, Double)?) -> some View {
        HStack(spacing: 6) {
            Image(systemName: statusSymbol(ex))
                .foregroundStyle(statusColor(ex))
            Text(WatchFormat.shortName(ex.exercise.name))
                .font(.footnote)
                .lineLimit(1)
            Spacer(minLength: 2)
            if let preview {
                HStack(spacing: 2) {
                    Image(systemName: outcomeSymbol(preview.0))
                    Text(WatchFormat.weight(preview.1))
                        .monospacedDigit()
                }
                .font(.caption2)
                .foregroundStyle(outcomeColor(preview.0))
            }
        }
    }

    // MARK: Helpers

    /// Unlogged sets inside exercises that were actually started (fully empty exercises count as skipped).
    private func unloggedSetCount(_ session: WorkoutSession) -> Int {
        session.exercises.reduce(0) { total, ex in
            guard !ex.isSkipped, ex.loggedSetCount > 0 else { return total }
            return total + (ex.sets.count - ex.loggedSetCount)
        }
    }

    private func statusSymbol(_ ex: SessionExercise) -> String {
        if ex.isSkipped || ex.loggedSetCount == 0 { return "minus.circle" }
        return ex.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill"
    }

    private func statusColor(_ ex: SessionExercise) -> Color {
        if ex.isSkipped || ex.loggedSetCount == 0 { return Color.secondary }
        return ex.isSuccess ? Color.green : Color.orange
    }

    private func outcomeSymbol(_ outcome: ProgressionOutcome) -> String {
        switch outcome {
        case .increased: return "arrow.up"
        case .repeated: return "equal"
        case .deloaded: return "arrow.down"
        case .unchanged: return "minus"
        }
    }

    private func outcomeColor(_ outcome: ProgressionOutcome) -> Color {
        switch outcome {
        case .increased: return Color.green
        case .repeated: return Color.orange
        case .deloaded: return Color.red
        case .unchanged: return Color.secondary
        }
    }
}
