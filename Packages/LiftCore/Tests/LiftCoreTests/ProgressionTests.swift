import XCTest
@testable import LiftCore

final class ProgressionTests: XCTestCase {
    let settings = Fixture.lb

    func testSuccessAddsIncrement() {
        var slot = Fixture.slot(weight: 100, increment: 5, failures: 2)
        let outcome = ProgressionEngine.apply(Fixture.result(slotID: slot.id, weight: 100), to: &slot, settings: settings)
        XCTAssertEqual(outcome, .increased)
        XCTAssertEqual(slot.nextWeight, 105)
        XCTAssertEqual(slot.consecutiveFailures, 0)
    }

    func testFailureRepeatsWeight() {
        var slot = Fixture.slot(weight: 100)
        let outcome = ProgressionEngine.apply(Fixture.result(slotID: slot.id, reps: [8, 8, 7, 8]), to: &slot, settings: settings)
        XCTAssertEqual(outcome, .repeated)
        XCTAssertEqual(slot.nextWeight, 100)
        XCTAssertEqual(slot.consecutiveFailures, 1)
    }

    func testThreeFailuresDeloadTenPercentRoundedDown() {
        var slot = Fixture.slot(weight: 135, increment: 5)
        let miss = Fixture.result(slotID: slot.id, weight: 135, reps: [8, 8, 6, 5])
        XCTAssertEqual(ProgressionEngine.apply(miss, to: &slot, settings: settings), .repeated)
        XCTAssertEqual(ProgressionEngine.apply(miss, to: &slot, settings: settings), .repeated)
        XCTAssertEqual(slot.consecutiveFailures, 2)
        XCTAssertEqual(ProgressionEngine.apply(miss, to: &slot, settings: settings), .deloaded)
        // 135 * 0.9 = 121.5, rounded down to the 5 lb increment = 120.
        XCTAssertEqual(slot.nextWeight, 120)
        XCTAssertEqual(slot.consecutiveFailures, 0)
    }

    func testDeloadWeightRoundsDownToIncrement() {
        let slot = Fixture.slot(weight: 100, increment: 2.5)
        XCTAssertEqual(ProgressionEngine.deloadWeight(from: 100, slot: slot, settings: settings), 90)
        XCTAssertEqual(ProgressionEngine.deloadWeight(from: 87.5, slot: slot, settings: settings), 77.5)  // 78.75 -> 77.5
    }

    func testDeloadIsClampedToBar() {
        var slot = Fixture.slot(weight: 50, increment: 5, failures: 2)
        let outcome = ProgressionEngine.apply(Fixture.result(slotID: slot.id, weight: 50, reps: [5, 5, 5, 5]), to: &slot, settings: settings)
        XCTAssertEqual(outcome, .deloaded)
        XCTAssertEqual(slot.nextWeight, 45)  // 50 * 0.9 = 45, exactly the bar

        var bar = Fixture.slot(weight: 45, increment: 5, failures: 2)
        ProgressionEngine.apply(Fixture.result(slotID: bar.id, weight: 45, reps: [1, 0, 0, 0]), to: &bar, settings: settings)
        XCTAssertEqual(bar.nextWeight, 45)
    }

    func testNonBarbellDeloadClampsToZero() {
        var slot = Fixture.slot("lat-pulldown", weight: 2, increment: 5, failures: 2)
        ProgressionEngine.apply(Fixture.result("lat-pulldown", slotID: slot.id, weight: 2, reps: [1, 1, 1, 1]), to: &slot, settings: settings)
        XCTAssertEqual(slot.nextWeight, 0)
    }

    func testSkippedAndUnattemptedDoNotChangeState() {
        var slot = Fixture.slot(weight: 100, failures: 1)
        let before = slot
        XCTAssertEqual(ProgressionEngine.apply(Fixture.result(slotID: slot.id, reps: [8, 8, 8, 8], skipped: true), to: &slot, settings: settings), .unchanged)
        XCTAssertEqual(ProgressionEngine.apply(Fixture.result(slotID: slot.id, reps: [nil, nil, nil, nil]), to: &slot, settings: settings), .unchanged)
        XCTAssertEqual(slot, before)
    }

    func testPartialSessionCountsAsFailure() {
        var slot = Fixture.slot(weight: 100)
        let outcome = ProgressionEngine.apply(Fixture.result(slotID: slot.id, reps: [8, 8, nil, nil]), to: &slot, settings: settings)
        XCTAssertEqual(outcome, .repeated)
        XCTAssertEqual(slot.nextWeight, 100)
        XCTAssertEqual(slot.consecutiveFailures, 1)
    }

    func testMidSessionWeightEditIsTheBase() {
        var slot = Fixture.slot(weight: 100, increment: 5)
        // Slot said 100 but the lifter did 110.
        ProgressionEngine.apply(Fixture.result(slotID: slot.id, weight: 110), to: &slot, settings: settings)
        XCTAssertEqual(slot.nextWeight, 115)
        // And on a miss the edited weight is repeated.
        var other = Fixture.slot(weight: 100, increment: 5)
        ProgressionEngine.apply(Fixture.result(slotID: other.id, weight: 90, reps: [8, 8, 8, 7]), to: &other, settings: settings)
        XCTAssertEqual(other.nextWeight, 90)
    }

    func testSuccessIsRoundedToLoadableForDumbbells() {
        var slot = Fixture.slot("incline-dumbbell-press", weight: 20, increment: 5)
        ProgressionEngine.apply(Fixture.result("incline-dumbbell-press", slotID: slot.id, weight: 20), to: &slot, settings: settings)
        XCTAssertEqual(slot.nextWeight, 25)
    }

    func testFinishingWorkoutAppliesProgressionOnceAndAdvancesRotation() {
        var state = AppState.fresh()
        let chest = state.program.days[0]
        let back = state.program.days[1]
        let session = state.startWorkout(device: .phone, now: Fixture.t0)!
        XCTAssertEqual(session.dayID, chest.id)
        for e in session.exercises {
            for i in 0..<4 { state.activeSession!.setReps(8, exerciseID: e.id, setIndex: i, rest: state.settings.rest, now: Fixture.at(10)) }
        }
        let workout = state.finishActiveWorkout(device: .phone, now: Fixture.at(3600))!
        XCTAssertNil(state.activeSession)
        XCTAssertEqual(state.history.map(\.id), [workout.id])
        XCTAssertEqual(state.program.nextDay?.id, back.id)
        XCTAssertEqual(state.program.slot(id: chest.slots[0].id)?.nextWeight, chest.slots[0].nextWeight + 5)
        // Idempotent.
        let snapshot = state
        XCTAssertFalse(state.applyCompleted(workout))
        XCTAssertEqual(state, snapshot)
    }

    func testRotationWrapsAndSkipsDisabledDays() {
        var p = ProgramDefaults.program(unit: .lb)
        let ids = p.days.map(\.id)
        XCTAssertEqual(p.day(after: ids[0])?.id, ids[1])
        XCTAssertEqual(p.day(after: ids[4])?.id, ids[0], "wraps around")
        p.setDayEnabled(ids[1], false)
        p.setDayEnabled(ids[2], false)
        XCTAssertEqual(p.day(after: ids[0])?.id, ids[3])
        p.setDayEnabled(ids[0], false)
        XCTAssertEqual(p.day(after: ids[4])?.id, ids[3])
        XCTAssertEqual(p.day(after: ids[3])?.id, ids[4])
    }

    func testFinishingSkipsDisabledDayInRotation() {
        var state = AppState.fresh()
        let ids = state.program.days.map(\.id)
        state.program.setDayEnabled(ids[1], false)
        state.startWorkout(device: .phone, now: Fixture.t0)
        state.finishActiveWorkout(device: .phone, now: Fixture.at(60))
        XCTAssertEqual(state.program.nextDayID, ids[2])
    }

    func testWorkoutFromDeletedDayDoesNotMoveRotation() {
        var state = AppState.fresh()
        let next = state.program.nextDayID
        let w = Fixture.workout(exercises: [], dayID: Fixture.uuid(777))
        XCTAssertTrue(state.applyCompleted(w))
        XCTAssertEqual(state.program.nextDayID, next)
    }

    func testApplyCompletedConvertsForeignUnit() {
        var state = AppState.fresh(unit: .kg)
        let slot = state.program.days[0].slots[0]
        let w = Fixture.workout(unit: .lb, exercises: [Fixture.result(slotID: slot.id, weight: 110, reps: [8, 8, 8, 8])])
        XCTAssertTrue(state.applyCompleted(w))
        XCTAssertEqual(state.history[0].unit, .kg)
        XCTAssertEqual(state.history[0].exercises[0].weight, Weight.clean(110 * 0.45359237))
    }
}
