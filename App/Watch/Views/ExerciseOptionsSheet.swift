import SwiftUI
import LiftCore

/// Secondary actions for one exercise: skip / unskip and the (optional) warm-up checklist.
struct ExerciseOptionsSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    let exerciseID: UUID

    private var exercise: SessionExercise? {
        model.activeSession?.exercises.first { $0.id == exerciseID }
    }

    var body: some View {
        ScrollView {
            if let ex = exercise {
                VStack(spacing: 8) {
                    Text(WatchFormat.shortName(ex.exercise.name))
                        .font(.headline)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    Button {
                        model.setSkipped(!ex.isSkipped, exerciseID: ex.id)
                        dismiss()
                    } label: {
                        Label(
                            ex.isSkipped ? "Unskip" : "Skip exercise",
                            systemImage: ex.isSkipped ? "arrow.uturn.backward" : "forward.end.fill"
                        )
                        .frame(maxWidth: .infinity)
                    }

                    if !ex.warmups.isEmpty {
                        Text("Warm-ups")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(ex.warmups.indices, id: \.self) { index in
                            warmupRow(ex, index: index)
                        }
                    }
                }
            }
        }
    }

    private func warmupRow(_ ex: SessionExercise, index: Int) -> some View {
        let warmup = ex.warmups[index]
        return Button {
            model.toggleWarmup(exerciseID: ex.id, index: index)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: warmup.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(warmup.isDone ? Color.green : Color.secondary)
                Text("\(WatchFormat.weight(warmup.weight)) \u{00D7} \(warmup.reps)")
                    .font(.footnote.monospacedDigit())
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
