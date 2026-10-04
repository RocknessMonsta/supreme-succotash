import SwiftUI
import LiftCore

/// One exercise in the live workout: name, weight, plates, warm-ups and the four set circles.
@MainActor
struct ExerciseCard: View {
    @Environment(AppModel.self) private var model
    let exercise: SessionExercise
    let onEditWeight: () -> Void
    let onEditReps: (Int) -> Void
    let onEditNote: () -> Void

    @State private var showWarmups = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            if exercise.isSkipped {
                skippedRow
            } else {
                weightRow
                if exercise.exercise.equipment.usesPlates { plateRow }
                if !exercise.warmups.isEmpty { warmupSection }
                setsRow
            }
            if !exercise.note.isEmpty { noteRow }
        }
        .card()
        .opacity(exercise.isSkipped ? 0.65 : 1)
        .animation(.easeInOut(duration: 0.2), value: exercise.isSkipped)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.exercise.name)
                    .font(.title3.weight(.bold))
                Text("\(exercise.exercise.equipment.displayName) · \(exercise.sets.count)×\(exercise.targetReps)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if exercise.isComplete && !exercise.isSkipped {
                Image(systemName: exercise.isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(exercise.isSuccess ? Theme.success : Theme.miss)
                    .accessibilityLabel(exercise.isSuccess ? "All sets completed" : "Some sets missed")
            }
            Menu {
                exerciseActions
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Exercise options")
        }
        .contentShape(Rectangle())
        .contextMenu {
            exerciseActions
        }
    }

    @ViewBuilder
    private var exerciseActions: some View {
        Button {
            onEditNote()
        } label: {
            Label(exercise.note.isEmpty ? "Add Note" : "Edit Note", systemImage: "note.text")
        }
        Button {
            model.setSkipped(!exercise.isSkipped, exerciseID: exercise.id)
        } label: {
            if exercise.isSkipped {
                Label("Unskip Exercise", systemImage: "arrow.uturn.backward")
            } else {
                Label("Skip Exercise", systemImage: "forward.end")
            }
        }
    }

    // MARK: Weight & plates

    private var weightRow: some View {
        Button {
            onEditWeight()
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(Weight.format(exercise.weight))
                    .font(.numeric(.largeTitle, weight: .bold))
                Text(unitLabel)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                Image(systemName: "pencil.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .padding(.leading, 2)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Weight \(Weight.format(exercise.weight)) \(model.unit.symbol). Tap to change.")
    }

    private var unitLabel: String {
        exercise.exercise.equipment == .dumbbell ? "\(model.unit.symbol) / hand" : model.unit.symbol
    }

    private var plateRow: some View {
        let load = model.plates(for: exercise.weight)
        return HStack(spacing: 8) {
            Image(systemName: "circle.circle")
                .foregroundStyle(.secondary)
            Text(load.perSide.isEmpty ? "Empty bar" : "Per side: \(load.summary)")
                .font(.numeric(.subheadline, weight: .medium))
            if !load.isExact {
                Text("(\(Weight.format(load.remainder)) \(model.unit.symbol) short)")
                    .font(.caption)
                    .foregroundStyle(Theme.miss)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: Warm-ups

    private var warmupSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showWarmups.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "flame")
                    Text("Warm-up")
                    Text("\(exercise.warmups.filter(\.isDone).count)/\(exercise.warmups.count)")
                        .font(.numeric(.subheadline))
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .rotationEffect(.degrees(showWarmups ? 90 : 0))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showWarmups {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(exercise.warmups.indices), id: \.self) { index in
                            warmupChip(index)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func warmupChip(_ index: Int) -> some View {
        let warmup = exercise.warmups[index]
        return Button {
            model.toggleWarmup(exerciseID: exercise.id, index: index)
        } label: {
            HStack(spacing: 4) {
                if warmup.isDone { Image(systemName: "checkmark").font(.caption.weight(.bold)) }
                Text("\(warmup.reps)×\(Weight.format(warmup.weight))")
                    .font(.numeric(.subheadline))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(warmup.isDone ? Color.accentColor : Color(.tertiarySystemFill), in: Capsule())
            .foregroundStyle(warmup.isDone ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Warm-up \(warmup.reps) reps at \(Weight.format(warmup.weight))")
        .accessibilityValue(warmup.isDone ? "Done" : "Not done")
    }

    // MARK: Sets

    private var setsRow: some View {
        HStack(spacing: 10) {
            ForEach(Array(exercise.sets.indices), id: \.self) { index in
                SetCircle(
                    set: exercise.sets[index],
                    number: index + 1,
                    onTap: { model.tapSet(exerciseID: exercise.id, setIndex: index) },
                    onLongPress: { onEditReps(index) }
                )
                .frame(maxWidth: 96)
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: Skipped & notes

    private var skippedRow: some View {
        HStack {
            Label("Skipped", systemImage: "forward.end.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Button("Undo") {
                model.setSkipped(false, exerciseID: exercise.id)
            }
            .buttonStyle(.bordered)
        }
    }

    private var noteRow: some View {
        Button {
            onEditNote()
        } label: {
            Label(exercise.note, systemImage: "note.text")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}
