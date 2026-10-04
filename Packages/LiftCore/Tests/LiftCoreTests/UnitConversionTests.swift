import XCTest
@testable import LiftCore

final class UnitConversionTests: XCTestCase {
    func makeState() -> AppState {
        var state = AppState.fresh(unit: .lb)
        state.settings.rest = RestSettings(afterSuccess: 60, afterFailure: 120, afterRepeatedFailure: 200)
        state.settings.soundEnabled = false
        state.settings.hapticsEnabled = false
        state.settings.healthKitEnabled = false
        state.settings.warmupsEnabled = false
        // Squat at 100 lb, lat pulldown at 50 lb, incline dumbbell at 20 lb.
        state.program.updateSlot(id: state.program.days[3].slots[0].id) { $0.nextWeight = 100; $0.consecutiveFailures = 2 }
        let squat = state.program.days[3].slots[0]
        let workout = Fixture.workout(exercises: [Fixture.result("squat", slotID: squat.id, weight: 135, reps: [8, 8, 8, 6])])
        state.history = [workout]
        return state
    }

    func testSettingsBecomeKgDefaultsButKeepNonWeightSettings() {
        var state = makeState()
        state.convertUnits(to: .kg)
        var expected = Settings.defaults(for: .kg)
        expected.rest = RestSettings(afterSuccess: 60, afterFailure: 120, afterRepeatedFailure: 200)
        expected.soundEnabled = false
        expected.hapticsEnabled = false
        expected.healthKitEnabled = false
        expected.warmupsEnabled = false
        XCTAssertEqual(state.settings, expected)
        XCTAssertEqual(state.settings.unit, .kg)
        XCTAssertEqual(state.settings.barWeight, 20)
        XCTAssertEqual(state.settings.dumbbellIncrement, 2)
    }

    func testSlotsAreConvertedAndLoadable() {
        var state = makeState()
        state.convertUnits(to: .kg)
        let days = state.program.days
        XCTAssertEqual(days[0].slots[0].nextWeight, 20, "45 lb bar -> 20 kg bar")
        XCTAssertEqual(days[3].slots[0].nextWeight, 45, "100 lb = 45.36 kg -> 45")
        XCTAssertEqual(days[3].slots[0].consecutiveFailures, 2, "failure counters survive")
        XCTAssertEqual(days[1].slots[1].nextWeight, 22.68, "lat pulldown 50 lb")
        XCTAssertEqual(days[0].slots[1].nextWeight, 10, "dumbbell 20 lb = 9.07 kg -> nearest 2 kg")
        for slot in days.flatMap(\.slots) {
            XCTAssertEqual(slot.increment, ProgramDefaults.defaultIncrement(for: slot.exercise, unit: .kg))
            XCTAssertEqual(Weight.loadable(slot.nextWeight, equipment: slot.exercise.equipment, settings: state.settings), slot.nextWeight, slot.exercise.id)
        }
        XCTAssertEqual(days[0].slots[0].increment, 2.5)
    }

    func testCustomIncrementIsResetToDefault() {
        var state = makeState()
        let id = state.program.days[0].slots[0].id
        state.program.setIncrement(slotID: id, increment: 10)
        state.convertUnits(to: .kg)
        XCTAssertEqual(state.program.slot(id: id)?.increment, 2.5)
    }

    func testHistoryIsConvertedAndCleaned() {
        var state = makeState()
        state.convertUnits(to: .kg)
        let w = state.history[0]
        XCTAssertEqual(w.unit, .kg)
        XCTAssertEqual(w.exercises[0].weight, Weight.clean(135 * 0.45359237))
        XCTAssertEqual(w.exercises[0].weight, 61.235)
        XCTAssertEqual(w.exercises[0].reps, [8, 8, 8, 6], "reps untouched")
    }

    func testActiveSessionIsConverted() {
        var state = AppState.fresh(unit: .lb)
        state.program.updateSlot(id: state.program.days[3].slots[0].id) { $0.nextWeight = 135 }
        state.startWorkout(dayID: state.program.days[3].id, device: .phone, now: Fixture.t0)
        XCTAssertEqual(state.activeSession?.exercises[0].warmups.map(\.weight), [45, 45, 55, 80, 110])
        state.convertUnits(to: .kg)
        let s = state.activeSession!
        XCTAssertEqual(s.unit, .kg)
        // 135 lb = 61.23 kg -> 60 kg on a bar with 2.5 kg plate pairs.
        XCTAssertEqual(s.exercises[0].weight, 60)
        XCTAssertEqual(s.exercises[0].warmups.map(\.weight), [20, 20, 25, 37.5, 50])
        XCTAssertTrue(s.exercises[0].warmups.allSatisfy { PlateCalculator.load(for: $0.weight, settings: state.settings).isExact })
        XCTAssertEqual(s.exercises[1].weight, 30, "RDL 65 lb = 29.5 kg -> 30")
    }

    func testNoOpWhenAlreadyInUnit() {
        var state = makeState()
        let before = state
        state.convertUnits(to: .lb)
        XCTAssertEqual(state, before)
    }

    func testRoundTripStaysSane() {
        var state = makeState()
        state.convertUnits(to: .kg)
        state.convertUnits(to: .lb)
        XCTAssertEqual(state.settings.unit, .lb)
        XCTAssertEqual(state.program.days[0].slots[0].nextWeight, 45)
        // Squat 100 lb -> 45 kg -> 99.2 lb -> loadable 100.
        XCTAssertEqual(state.program.days[3].slots[0].nextWeight, 100)
        XCTAssertEqual(state.history[0].exercises[0].weight, 135, accuracy: 0.01)
        XCTAssertEqual(state.history[0].unit, .lb)
    }
}
