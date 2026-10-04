import Foundation

/// Built-in exercise catalogue (~45 common gym lifts). Ids are stable kebab-case slugs.
public enum ExerciseLibrary {
    public static let all: [Exercise] = [
        // Chest
        ex("barbell-bench-press", "Barbell Bench Press", .chest, .barbell, false),
        ex("incline-barbell-press", "Incline Barbell Press", .chest, .barbell, false),
        ex("dumbbell-bench-press", "Dumbbell Bench Press", .chest, .dumbbell, false),
        ex("incline-dumbbell-press", "Incline Dumbbell Press", .chest, .dumbbell, false),
        ex("machine-chest-press", "Machine Chest Press", .chest, .machine, false),
        ex("cable-fly", "Cable Fly", .chest, .cable, true),
        ex("pec-deck", "Pec Deck", .chest, .machine, true),
        ex("chest-dip", "Chest Dip", .chest, .bodyweight, false),
        ex("push-up", "Push-Up", .chest, .bodyweight, false),

        // Back
        ex("barbell-row", "Barbell Row", .back, .barbell, false),
        ex("deadlift", "Deadlift", .back, .barbell, false),
        ex("dumbbell-row", "Dumbbell Row", .back, .dumbbell, false),
        ex("lat-pulldown", "Lat Pulldown", .back, .cable, false),
        ex("seated-cable-row", "Seated Cable Row", .back, .cable, false),
        ex("straight-arm-pulldown", "Straight-Arm Pulldown", .back, .cable, true),
        ex("pull-up", "Pull-Up", .back, .bodyweight, false),
        ex("chin-up", "Chin-Up", .back, .bodyweight, false),

        // Shoulders
        ex("overhead-press", "Overhead Press", .shoulders, .barbell, false),
        ex("upright-row", "Upright Row", .shoulders, .barbell, false),
        ex("dumbbell-shoulder-press", "Dumbbell Shoulder Press", .shoulders, .dumbbell, false),
        ex("machine-shoulder-press", "Machine Shoulder Press", .shoulders, .machine, false),
        ex("dumbbell-lateral-raise", "Dumbbell Lateral Raise", .shoulders, .dumbbell, true),
        ex("dumbbell-front-raise", "Dumbbell Front Raise", .shoulders, .dumbbell, true),
        ex("cable-lateral-raise", "Cable Lateral Raise", .shoulders, .cable, true),
        ex("reverse-pec-deck", "Reverse Pec Deck", .shoulders, .machine, true),
        ex("face-pull", "Face Pull", .shoulders, .cable, true),

        // Legs
        ex("squat", "Squat", .legs, .barbell, false),
        ex("front-squat", "Front Squat", .legs, .barbell, false),
        ex("romanian-deadlift", "Romanian Deadlift", .legs, .barbell, false),
        ex("hip-thrust", "Hip Thrust", .legs, .barbell, false),
        ex("leg-press", "Leg Press", .legs, .machine, false),
        ex("walking-lunge", "Walking Lunge", .legs, .dumbbell, false),
        ex("bulgarian-split-squat", "Bulgarian Split Squat", .legs, .dumbbell, false),
        ex("leg-extension", "Leg Extension", .legs, .machine, true),
        ex("leg-curl", "Leg Curl", .legs, .machine, true),
        ex("standing-calf-raise", "Standing Calf Raise", .legs, .machine, true),

        // Arms
        ex("barbell-curl", "Barbell Curl", .arms, .barbell, true),
        ex("dumbbell-curl", "Dumbbell Curl", .arms, .dumbbell, true),
        ex("hammer-curl", "Hammer Curl", .arms, .dumbbell, true),
        ex("cable-curl", "Cable Curl", .arms, .cable, true),
        ex("triceps-pushdown", "Triceps Pushdown", .arms, .cable, true),
        ex("skull-crusher", "Skull Crusher", .arms, .barbell, true),
        ex("close-grip-bench-press", "Close-Grip Bench Press", .arms, .barbell, false),
        ex("overhead-triceps-extension", "Overhead Triceps Extension", .arms, .dumbbell, true),

        // Core
        ex("cable-crunch", "Cable Crunch", .core, .cable, true),
        ex("hanging-leg-raise", "Hanging Leg Raise", .core, .bodyweight, true),
        ex("ab-wheel-rollout", "Ab Wheel Rollout", .core, .bodyweight, true),
        ex("plank", "Plank", .core, .bodyweight, true),
        ex("crunch", "Crunch", .core, .bodyweight, true),
    ]

    private static let byID: [String: Exercise] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    public static func exercise(id: String) -> Exercise? { byID[id] }

    public static func exercises(for bodyPart: BodyPart) -> [Exercise] {
        all.filter { $0.bodyPart == bodyPart }
    }

    private static func ex(_ id: String, _ name: String, _ part: BodyPart, _ equipment: Equipment, _ isolation: Bool) -> Exercise {
        Exercise(id: id, name: name, bodyPart: part, equipment: equipment, isIsolation: isolation)
    }
}
