import SwiftUI
import LiftCore

/// One exercise of the active workout: weight, plates, and the set circles.
struct ExercisePageView: View {
    @Environment(AppModel.self) private var model

    let exerciseID: UUID
    let onRestTap: () -> Void

    @State private var showWeightEditor = false
    @State private var showOptions = false
    @State private var showRepsEditor = false
    @State private var editingSet = 0

    private var exercise: SessionExercise? {
        model.activeSession?.exercises.first { $0.id == exerciseID }
    }

    var body: some View {
        if let ex = exercise {
            content(ex)
        } else {
            Color.clear
        }
    }

    private func content(_ ex: SessionExercise) -> some View {
        VStack(spacing: 5) {
            WorkoutMetricsStrip(onRestTap: onRestTap)
            HStack(spacing: 4) {
                Text(WatchFormat.shortName(ex.exercise.name))
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                Button { showOptions = true } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Exercise options")
            }
            Button { showWeightEditor = true } label: {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(WatchFormat.weight(ex.weight))
                        .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                    Text(model.unit.symbol)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Weight \(WatchFormat.weight(ex.weight)) \(model.unit.symbol), tap to edit")
            detailLine(ex)
            setsRow(ex)
        }
        .padding(.leading, 6)
        .padding(.trailing, 10)
        .frame(maxHeight: .infinity, alignment: .center)
        .sheet(isPresented: $showWeightEditor) { weightEditor }
        .sheet(isPresented: $showOptions) { ExerciseOptionsSheet(exerciseID: exerciseID) }
        .sheet(isPresented: $showRepsEditor) { repsEditor }
    }

    // MARK: Pieces

    @ViewBuilder
    private func detailLine(_ ex: SessionExercise) -> some View {
        if ex.isSkipped {
            Label("Skipped", systemImage: "forward.end.fill")
                .font(.caption2)
                .foregroundStyle(Color.orange)
        } else if ex.exercise.equipment.usesPlates {
            Text(WatchFormat.plates(model.plates(for: ex.weight)))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        } else {
            Text("\(ex.sets.count) \u{00D7} \(ex.targetReps)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private func setsRow(_ ex: SessionExercise) -> some View {
        GeometryReader { geo in
            let count = max(1, ex.sets.count)
            let spacing: CGFloat = 4
            let available = geo.size.width - spacing * CGFloat(count - 1)
            let size = min(46, max(34, available / CGFloat(count)))
            HStack(spacing: spacing) {
                ForEach(ex.sets.indices, id: \.self) { index in
                    SetCircleView(reps: ex.sets[index].reps, target: ex.sets[index].targetReps, size: size)
                        .contentShape(Circle())
                        .onTapGesture {
                            model.tapSet(exerciseID: ex.id, setIndex: index)
                        }
                        .onLongPressGesture(minimumDuration: 0.5) {
                            editingSet = index
                            showRepsEditor = true
                        }
                        .accessibilityAddTraits(.isButton)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(height: 50)
        .opacity(ex.isSkipped ? 0.4 : 1)
    }

    // MARK: Sheets

    @ViewBuilder
    private var weightEditor: some View {
        if let ex = exercise {
            let limits = weightLimits(for: ex)
            WeightEditorSheet(
                exerciseID: ex.id,
                weight: ex.weight,
                usesPlates: ex.exercise.equipment.usesPlates,
                minimum: limits.minimum,
                maximum: limits.maximum,
                step: limits.step
            )
        }
    }

    @ViewBuilder
    private var repsEditor: some View {
        if let ex = exercise, ex.sets.indices.contains(editingSet) {
            let target = ex.sets[editingSet]
            RepsEditorSheet(setNumber: editingSet + 1, initialReps: target.reps, targetReps: target.targetReps) { reps in
                model.setReps(reps, exerciseID: ex.id, setIndex: editingSet)
            }
        }
    }

    /// Crown range and the smallest meaningful jump for this equipment (matches `Weight.loadable` rounding).
    private func weightLimits(for ex: SessionExercise) -> (minimum: Double, maximum: Double, step: Double) {
        let settings = model.settings
        let minimum = LiftCore.Weight.minimum(for: ex.exercise.equipment, settings: settings)
        let step: Double
        switch ex.exercise.equipment {
        case .barbell:
            let smallestPlate = settings.availablePlates.filter { $0 > 0 }.min() ?? 2.5
            step = smallestPlate * 2
        case .dumbbell:
            step = settings.dumbbellIncrement > 0 ? settings.dumbbellIncrement : 5
        case .cable, .machine, .bodyweight:
            let increment = model.program.slot(id: ex.id)?.increment ?? 0
            step = increment > 0 ? increment : (model.unit == .lb ? 5 : 2.5)
        }
        let maximum = max(minimum + step * 200, ex.weight * 2)
        return (minimum, maximum, step)
    }
}
