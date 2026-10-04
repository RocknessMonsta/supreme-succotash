import Foundation
import LiftCore

/// Small formatting helpers shared by the watch views.
enum WatchFormat {
    /// "m:ss" for a whole number of seconds.
    static func clock(_ totalSeconds: Int) -> String {
        let s = max(0, totalSeconds)
        let seconds = s % 60
        return "\(s / 60):\(seconds < 10 ? "0" : "")\(seconds)"
    }

    /// Countdown text; rounds up so the display reaches 0:00 exactly when the rest ends.
    static func restClock(_ remaining: TimeInterval) -> String {
        clock(Int(max(0, remaining).rounded(.up)))
    }

    /// "52 min" or "1h 05m".
    static func duration(_ interval: TimeInterval) -> String {
        let minutes = max(0, Int(interval / 60))
        if minutes < 60 { return "\(minutes) min" }
        let rest = minutes % 60
        return "\(minutes / 60)h \(rest < 10 ? "0" : "")\(rest)m"
    }

    /// "Barbell Bench Press" -> "Bench Press", "Dumbbell Lateral Raise" -> "DB Lateral Raise".
    static func shortName(_ name: String) -> String {
        var short = name
        if short.hasPrefix("Barbell ") { short.removeFirst("Barbell ".count) }
        short = short.replacingOccurrences(of: "Dumbbell ", with: "DB ")
        return short
    }

    /// "135", "67.5" (no unit).
    static func weight(_ value: Double) -> String {
        LiftCore.Weight.format(value)
    }

    /// Total volume as a grouped integer, e.g. "12,340".
    static func volume(_ value: Double) -> String {
        Int(max(0, value).rounded()).formatted()
    }

    /// "45 + 25 / side", "~ 45 + 10 / side" when not exactly loadable, or "Empty bar".
    static func plates(_ load: PlateLoad) -> String {
        if load.perSide.isEmpty { return load.isExact ? "Empty bar" : "Under bar weight" }
        return load.isExact ? "\(load.summary) / side" : "~ \(load.summary) / side"
    }
}
