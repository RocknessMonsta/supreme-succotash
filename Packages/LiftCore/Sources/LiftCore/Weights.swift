import Foundation

public enum Weight {
    /// Rounds to the nearest multiple of `step` (ties round up). `step <= 0` returns the value unchanged.
    public static func round(_ value: Double, to step: Double) -> Double {
        guard step > 0 else { return value }
        return clean((value / step).rounded(.toNearestOrAwayFromZero) * step)
    }

    public static func roundDown(_ value: Double, to step: Double) -> Double {
        guard step > 0 else { return value }
        // Small epsilon so 0.9 * 100 = 89.999… still floors to 90 when step is 2.5.
        return clean(((value / step) + 1e-9).rounded(.down) * step)
    }

    /// Strips floating point noise, e.g. 67.50000000001 → 67.5.
    public static func clean(_ value: Double) -> Double {
        (value * 1000).rounded() / 1000
    }

    /// "135", "67.5", "2.25" — no trailing zeros.
    public static func format(_ value: Double) -> String {
        let v = clean(value)
        if v == v.rounded() { return String(Int(v)) }
        var s = String(format: "%.2f", v)
        while s.hasSuffix("0") { s.removeLast() }
        if s.hasSuffix(".") { s.removeLast() }
        return s
    }

    public static func format(_ value: Double, unit: WeightUnit) -> String {
        "\(format(value)) \(unit.symbol)"
    }

    /// The lightest legal weight for an exercise.
    public static func minimum(for equipment: Equipment, settings: Settings) -> Double {
        equipment == .barbell ? settings.barWeight : 0
    }

    /// Rounds a weight so it is loadable for the given equipment.
    public static func loadable(_ value: Double, equipment: Equipment, settings: Settings) -> Double {
        let minimum = minimum(for: equipment, settings: settings)
        switch equipment {
        case .barbell:
            let smallestPair = 2 * (settings.availablePlates.filter { $0 > 0 }.min() ?? 0)
            guard smallestPair > 0 else { return max(minimum, value) }
            let plates = max(0, value - settings.barWeight)
            return max(minimum, clean(settings.barWeight + round(plates, to: smallestPair)))
        case .dumbbell:
            return max(minimum, round(value, to: settings.dumbbellIncrement))
        case .cable, .machine, .bodyweight:
            return max(minimum, clean(value))
        }
    }
}
