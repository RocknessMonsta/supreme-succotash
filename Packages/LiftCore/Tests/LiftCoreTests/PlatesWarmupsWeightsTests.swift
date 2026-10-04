import XCTest
@testable import LiftCore

final class PlateCalculatorTests: XCTestCase {
    func testLbExactLoads() {
        let s = Fixture.lb
        XCTAssertEqual(PlateCalculator.load(for: 45, settings: s).perSide, [])
        XCTAssertEqual(PlateCalculator.load(for: 45, settings: s).summary, "Empty bar")
        XCTAssertEqual(PlateCalculator.load(for: 135, settings: s).perSide, [45])
        XCTAssertEqual(PlateCalculator.load(for: 225, settings: s).perSide, [45, 45])
        let l = PlateCalculator.load(for: 140, settings: s)
        XCTAssertEqual(l.perSide, [45, 2.5])
        XCTAssertEqual(l.summary, "45 + 2.5")
        XCTAssertTrue(l.isExact)
        XCTAssertEqual(l.totalLoaded, 140)
    }

    func testLbUsesGreedyMixedPlates() {
        // per side 57.5 = 45 + 10 + 2.5
        XCTAssertEqual(PlateCalculator.load(for: 160, settings: Fixture.lb).perSide, [45, 10, 2.5])
    }

    func testLbRemainder() {
        let l = PlateCalculator.load(for: 137, settings: Fixture.lb)
        XCTAssertEqual(l.perSide, [45])
        XCTAssertEqual(l.remainder, 2)
        XCTAssertFalse(l.isExact)
        XCTAssertEqual(l.totalLoaded, 135)
    }

    func testKg() {
        let s = Fixture.kg
        XCTAssertEqual(PlateCalculator.load(for: 60, settings: s).perSide, [20])
        let l = PlateCalculator.load(for: 62.5, settings: s)
        XCTAssertEqual(l.perSide, [20, 1.25])
        XCTAssertTrue(l.isExact)
        let r = PlateCalculator.load(for: 61, settings: s)
        XCTAssertEqual(r.perSide, [20])
        XCTAssertEqual(r.remainder, 1)
        XCTAssertEqual(PlateCalculator.load(for: 100, settings: s).perSide, [25, 15])
    }

    func testBelowBarAndLimitedPlates() {
        XCTAssertEqual(PlateCalculator.load(for: 30, settings: Fixture.lb).perSide, [])
        XCTAssertTrue(PlateCalculator.load(for: 30, settings: Fixture.lb).isExact)
        let l = PlateCalculator.load(for: 65, barWeight: 45, plates: [5, 2.5])
        XCTAssertEqual(l.perSide, [5, 5])
        XCTAssertTrue(l.isExact)
        // Unsorted/zero plates are tolerated.
        XCTAssertEqual(PlateCalculator.load(for: 55, barWeight: 45, plates: [2.5, 0, 5]).perSide, [5])
    }
}

final class WarmupCalculatorTests: XCTestCase {
    func plan(_ weight: Double, _ equipment: Equipment = .barbell, settings: Settings = Fixture.lb) -> [WarmupPlan] {
        WarmupCalculator.plan(workWeight: weight, equipment: equipment, settings: settings)
    }

    func testRampForHeavyLift() {
        let p = plan(135)
        XCTAssertEqual(p.map(\.weight), [45, 45, 55, 80, 110])
        XCTAssertEqual(p.map(\.reps), [5, 5, 5, 5, 3])
    }

    func testMediumWeightDropsStepsThatAreTooClose() {
        XCTAssertEqual(plan(95).map(\.weight), [45, 45, 55, 75])
    }

    func testLightWorkWeightOnlyBarSets() {
        XCTAssertEqual(plan(50).map(\.weight), [45, 45])
        XCTAssertEqual(plan(55).map(\.weight), [45, 45])
    }

    func testWorkWeightAtBarHasNoWarmups() {
        XCTAssertTrue(plan(45).isEmpty)
        XCTAssertTrue(plan(30).isEmpty)
    }

    func testNonBarbellHasNone() {
        for e in [Equipment.dumbbell, .cable, .machine, .bodyweight] { XCTAssertTrue(plan(200, e).isEmpty) }
    }

    func testDisabledWarmups() {
        var s = Fixture.lb
        s.warmupsEnabled = false
        XCTAssertTrue(plan(225, settings: s).isEmpty)
    }

    func testKg() {
        XCTAssertEqual(plan(100, settings: Fixture.kg).map(\.weight), [20, 20, 40, 60, 80])
    }

    func testAllWarmupsAreLoadable() {
        for w in stride(from: 50.0, through: 400.0, by: 5.0) {
            for step in plan(w) {
                XCTAssertEqual(PlateCalculator.load(for: step.weight, settings: Fixture.lb).remainder, 0, "work weight \(w)")
                XCTAssertLessThan(step.weight, w)
            }
        }
    }
}

final class WeightTests: XCTestCase {
    func testLoadableBarbellLb() {
        func l(_ v: Double) -> Double { Weight.loadable(v, equipment: .barbell, settings: Fixture.lb) }
        XCTAssertEqual(l(137), 135)
        XCTAssertEqual(l(135), 135)
        XCTAssertEqual(l(47), 45)
        XCTAssertEqual(l(48), 50)
        XCTAssertEqual(l(10), 45, "never below the bar")
        XCTAssertEqual(l(142.5), 145, "ties round up")
    }

    func testLoadableBarbellKg() {
        func l(_ v: Double) -> Double { Weight.loadable(v, equipment: .barbell, settings: Fixture.kg) }
        XCTAssertEqual(l(61), 60)
        XCTAssertEqual(l(62.4), 62.5)
        XCTAssertEqual(l(5), 20)
    }

    func testLoadableDumbbellCableMachine() {
        XCTAssertEqual(Weight.loadable(17, equipment: .dumbbell, settings: Fixture.lb), 15)
        XCTAssertEqual(Weight.loadable(17.5, equipment: .dumbbell, settings: Fixture.lb), 20)
        XCTAssertEqual(Weight.loadable(9, equipment: .dumbbell, settings: Fixture.kg), 10)
        XCTAssertEqual(Weight.loadable(32.5, equipment: .cable, settings: Fixture.lb), 32.5)
        XCTAssertEqual(Weight.loadable(-5, equipment: .machine, settings: Fixture.lb), 0)
        XCTAssertEqual(Weight.loadable(22.6800000001, equipment: .cable, settings: Fixture.kg), 22.68)
    }

    func testMinimum() {
        XCTAssertEqual(Weight.minimum(for: .barbell, settings: Fixture.kg), 20)
        XCTAssertEqual(Weight.minimum(for: .dumbbell, settings: Fixture.kg), 0)
    }

    func testRoundingHelpers() {
        XCTAssertEqual(Weight.round(7.5, to: 5), 10)
        XCTAssertEqual(Weight.round(7.4, to: 5), 5)
        XCTAssertEqual(Weight.round(7.4, to: 0), 7.4)
        XCTAssertEqual(Weight.roundDown(87.4, to: 2.5), 85)
        XCTAssertEqual(Weight.roundDown(89.9999999999, to: 2.5), 90)
        XCTAssertEqual(Weight.roundDown(0.9 * 100, to: 5), 90)
        XCTAssertEqual(Weight.clean(67.50000000001), 67.5)
    }

    func testFormat() {
        XCTAssertEqual(Weight.format(135), "135")
        XCTAssertEqual(Weight.format(67.5), "67.5")
        XCTAssertEqual(Weight.format(2.25), "2.25")
        XCTAssertEqual(Weight.format(0.1 + 0.2), "0.3")
        XCTAssertEqual(Weight.format(0), "0")
        XCTAssertEqual(Weight.format(100.0000001), "100")
        XCTAssertEqual(Weight.format(1.25, unit: .kg), "1.25 kg")
        XCTAssertEqual(Weight.format(135, unit: .lb), "135 lb")
    }

    func testUnitFactor() {
        XCTAssertEqual(WeightUnit.lb.factor(to: .kg), 0.45359237, accuracy: 1e-12)
        XCTAssertEqual(WeightUnit.lb.factor(to: .lb), 1)
        XCTAssertEqual(WeightUnit.kg.factor(to: .lb) * WeightUnit.lb.factor(to: .kg), 1, accuracy: 1e-12)
    }
}
