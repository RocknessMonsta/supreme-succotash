import Foundation

public enum ProgressionOutcome: Equatable, Sendable {
    case unchanged      // skipped / not attempted
    case increased      // all sets hit target
    case repeated       // failed, same weight next time
    case deloaded       // third consecutive failure
}

public enum ProgressionEngine {
    public static let failuresBeforeDeload = 3
    public static let deloadFactor = 0.9

    /// Applies one exercise result to its slot. `result.weight` must be in `settings.unit`.
    /// The new weight is based on the weight actually lifted (so mid-session edits stick).
    @discardableResult
    public static func apply(_ result: ExerciseResult, to slot: inout ExerciseSlot, settings: Settings) -> ProgressionOutcome {
        guard result.wasAttempted else { return .unchanged }
        let equipment = slot.exercise.equipment
        if result.isSuccess {
            var next = Weight.loadable(result.weight + slot.increment, equipment: equipment, settings: settings)
            if next <= result.weight {
                // Increment smaller than the smallest loadable jump: take the smallest real jump instead.
                next = Weight.loadable(result.weight + smallestStep(for: equipment, settings: settings), equipment: equipment, settings: settings)
            }
            slot.nextWeight = next
            slot.consecutiveFailures = 0
            return .increased
        }
        slot.consecutiveFailures += 1
        if slot.consecutiveFailures >= failuresBeforeDeload {
            slot.nextWeight = deloadWeight(from: result.weight, slot: slot, settings: settings)
            slot.consecutiveFailures = 0
            return .deloaded
        }
        slot.nextWeight = result.weight
        return .repeated
    }

    /// The smallest weight change the equipment can actually make.
    public static func smallestStep(for equipment: Equipment, settings: Settings) -> Double {
        switch equipment {
        case .barbell: return 2 * (settings.availablePlates.filter { $0 > 0 }.min() ?? 1.25)
        case .dumbbell: return max(settings.dumbbellIncrement, 0.5)
        case .cable, .machine: return settings.unit == .lb ? 2.5 : 1
        case .bodyweight: return 0
        }
    }

    /// 10% off, rounded down to the slot increment, clamped to the equipment minimum.
    public static func deloadWeight(from weight: Double, slot: ExerciseSlot, settings: Settings) -> Double {
        let minimum = Weight.minimum(for: slot.exercise.equipment, settings: settings)
        let step = slot.increment > 0 ? slot.increment : 1
        return max(minimum, Weight.roundDown(weight * deloadFactor, to: step))
    }

    /// Preview of what finishing would do, keyed by slot id. Used for the "finish" summary UI.
    public static func preview(_ workout: CompletedWorkout, program: Program, settings: Settings) -> [UUID: (ProgressionOutcome, Double)] {
        var out: [UUID: (ProgressionOutcome, Double)] = [:]
        for result in workout.exercises {
            guard var slot = program.slot(id: result.id) else { continue }
            let outcome = apply(result, to: &slot, settings: settings)
            out[result.id] = (outcome, slot.nextWeight)
        }
        return out
    }
}
