import Foundation
import LiftCore

/// Pure formatting helpers (no UI, no model access).
enum LiftFormat {
    /// "7:05" or "1:02:03". `roundUp` is for countdowns so "0:00" only shows when finished.
    static func clock(_ seconds: TimeInterval, roundUp: Bool = false) -> String {
        let clamped = max(0, seconds)
        let total = Int(roundUp ? clamped.rounded(.up) : clamped.rounded(.down))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 { return String(format: "%d:%02d:%02d", hours, minutes, secs) }
        return String(format: "%d:%02d", minutes, secs)
    }

    /// "52 min" or "1 h 05 min".
    static func duration(_ seconds: TimeInterval) -> String {
        let minutes = max(0, Int((seconds / 60).rounded()))
        if minutes < 60 { return "\(minutes) min" }
        return String(format: "%d h %02d min", minutes / 60, minutes % 60)
    }

    /// "12,450 lb"
    static func volume(_ value: Double, unit: WeightUnit) -> String {
        "\(Int(max(0, value).rounded()).formatted()) \(unit.symbol)"
    }

    /// Whole-number estimate, e.g. "153 lb".
    static func estimate(_ value: Double, unit: WeightUnit) -> String {
        "\(Weight.format(value.rounded())) \(unit.symbol)"
    }

    /// "Sat, Oct 4"
    static func day(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    /// "Oct 4, 2026"
    static func fullDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    /// "8 · 8 · 7 · –"
    static func reps(_ reps: [Int?]) -> String {
        reps.map { $0.map(String.init) ?? "–" }.joined(separator: " · ")
    }

    /// "4×8 · 135 lb" / "4×8 · Bodyweight"
    static func prescription(sets: Int, reps: Int, weight: Double, equipment: Equipment, unit: WeightUnit) -> String {
        "\(sets)×\(reps) · \(weightLabel(weight, equipment: equipment, unit: unit))"
    }

    /// Weight with equipment context ("20 lb each" for dumbbells, "Bodyweight" for 0 on bodyweight lifts).
    static func weightLabel(_ weight: Double, equipment: Equipment, unit: WeightUnit) -> String {
        if equipment == .bodyweight && weight <= 0 { return "Bodyweight" }
        let base = Weight.format(weight, unit: unit)
        return equipment == .dumbbell ? "\(base) each" : base
    }
}
