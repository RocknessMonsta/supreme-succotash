import Foundation

public struct PlateLoad: Hashable, Sendable {
    /// Plates for ONE side of the bar, heaviest first.
    public var perSide: [Double]
    /// Weight that could not be made with available plates (0 when exact).
    public var remainder: Double
    public var barWeight: Double

    public var isExact: Bool { remainder < 0.001 }
    public var totalLoaded: Double { barWeight + 2 * perSide.reduce(0, +) }

    /// e.g. "45 + 25 + 2.5" or "Empty bar".
    public var summary: String {
        perSide.isEmpty ? "Empty bar" : perSide.map(Weight.format).joined(separator: " + ")
    }
}

public enum PlateCalculator {
    /// Greedy per-side plate breakdown. Assumes unlimited pairs of each available plate.
    public static func load(for total: Double, settings: Settings) -> PlateLoad {
        load(for: total, barWeight: settings.barWeight, plates: settings.availablePlates)
    }

    public static func load(for total: Double, barWeight: Double, plates: [Double]) -> PlateLoad {
        var perSideRemaining = max(0, (total - barWeight) / 2)
        var result: [Double] = []
        for plate in plates.filter({ $0 > 0 }).sorted(by: >) {
            while perSideRemaining + 1e-9 >= plate {
                result.append(plate)
                perSideRemaining -= plate
            }
        }
        return PlateLoad(perSide: result, remainder: Weight.clean(perSideRemaining * 2), barWeight: barWeight)
    }
}
