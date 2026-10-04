import Foundation

public enum ProgramDefaults {
    public static let sets = 4
    public static let targetReps = 8

    /// Weight added after a successful session (SPEC §1.3). Isolation dumbbell/cable/machine lifts get the
    /// small step. Barbell lifts always use the full barbell step (even barbell curls): a sub-plate step
    /// such as 1 kg could never round up to a loadable weight. Bodyweight lifts have no increment.
    public static func defaultIncrement(for exercise: Exercise, unit: WeightUnit) -> Double {
        let isLb = unit == .lb
        switch exercise.equipment {
        case .bodyweight:
            return 0
        case .barbell:
            return isLb ? 5 : 2.5
        case .dumbbell:
            if exercise.isIsolation { return isLb ? 2.5 : 1 }
            return isLb ? 5 : 2
        case .cable, .machine:
            if exercise.isIsolation { return isLb ? 2.5 : 1 }
            return isLb ? 5 : 2.5
        }
    }

    /// A conservative beginner starting weight, in `unit`.
    public static func startingWeight(for exercise: Exercise, unit: WeightUnit) -> Double {
        let isLb = unit == .lb
        func pick(_ lb: Double, _ kg: Double) -> Double { isLb ? lb : kg }
        if let special = specialStarts[exercise.id] { return pick(special.lb, special.kg) }
        switch exercise.equipment {
        case .bodyweight: return 0
        case .barbell: return pick(45, 20)
        case .dumbbell: return exercise.isIsolation ? pick(15, 6) : pick(20, 8)
        case .cable: return exercise.isIsolation ? pick(30, 15) : pick(50, 25)
        case .machine: return exercise.isIsolation ? pick(30, 15) : pick(50, 25)
        }
    }

    private static let specialStarts: [String: (lb: Double, kg: Double)] = [
        "squat": (65, 30),
        "front-squat": (65, 30),
        "romanian-deadlift": (65, 30),
        "deadlift": (95, 40),
        "hip-thrust": (65, 30),
        "leg-press": (90, 40),
        "dumbbell-lateral-raise": (10, 4),
        "dumbbell-front-raise": (10, 4),
        "overhead-triceps-extension": (15, 6),
        "leg-extension": (40, 20),
        "leg-curl": (40, 20),
        "standing-calf-raise": (60, 30),
    ]

    public static func makeSlot(for exercise: Exercise, unit: WeightUnit) -> ExerciseSlot {
        ExerciseSlot(
            exercise: exercise,
            nextWeight: startingWeight(for: exercise, unit: unit),
            increment: defaultIncrement(for: exercise, unit: unit)
        )
    }

    /// The default 5-day body-part rotation with starting weights and increments in `unit`.
    public static func program(unit: WeightUnit) -> Program {
        let table: [(String, BodyPart, [String])] = [
            ("Chest", .chest, ["barbell-bench-press", "incline-dumbbell-press", "cable-fly"]),
            ("Back", .back, ["barbell-row", "lat-pulldown", "seated-cable-row"]),
            ("Shoulders", .shoulders, ["overhead-press", "dumbbell-lateral-raise", "reverse-pec-deck"]),
            ("Legs", .legs, ["squat", "romanian-deadlift", "leg-press"]),
            ("Arms", .arms, ["barbell-curl", "triceps-pushdown", "hammer-curl"]),
        ]
        let days = table.map { name, part, ids in
            BodyPartDay(
                name: name, bodyPart: part,
                slots: ids.compactMap { ExerciseLibrary.exercise(id: $0) }.map { makeSlot(for: $0, unit: unit) }
            )
        }
        return Program(days: days, nextDayID: days.first?.id)
    }
}
