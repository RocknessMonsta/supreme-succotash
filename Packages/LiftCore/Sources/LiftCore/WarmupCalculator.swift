import Foundation

public struct WarmupPlan: Hashable, Sendable {
    public var weight: Double
    public var reps: Int
}

public enum WarmupCalculator {
    /// StrongLifts-style ramp: 2×5 empty bar, then ~40%, 60%, 80% of the work weight (5, 5, 3 reps),
    /// rounded to loadable plates. Steps that are not meaningfully between the previous step and the
    /// work weight are dropped. Only barbell lifts get warm-ups.
    public static func plan(workWeight: Double, equipment: Equipment, settings: Settings) -> [WarmupPlan] {
        guard equipment == .barbell, settings.warmupsEnabled else { return [] }
        let bar = settings.barWeight
        guard workWeight > bar else { return [] }

        var steps: [WarmupPlan] = [WarmupPlan(weight: bar, reps: 5), WarmupPlan(weight: bar, reps: 5)]
        let ramp: [(Double, Int)] = [(0.4, 5), (0.6, 5), (0.8, 3)]
        let minJump = settings.unit == .lb ? 10.0 : 5.0
        var last = bar
        for (fraction, reps) in ramp {
            let w = Weight.loadable(workWeight * fraction, equipment: .barbell, settings: settings)
            if w - last >= minJump && workWeight - w >= minJump {
                steps.append(WarmupPlan(weight: w, reps: reps))
                last = w
            }
        }
        return steps
    }
}
