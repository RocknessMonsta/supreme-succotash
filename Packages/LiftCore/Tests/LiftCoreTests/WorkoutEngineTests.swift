import XCTest
@testable import LiftCore

final class WorkoutEngineTests: XCTestCase {
    let rest = RestSettings()
    let eid = Fixture.uuid(100)

    func testTapCycleFunction() {
        var reps: Int? = nil
        var seen: [Int?] = []
        for _ in 0..<11 {
            reps = LoggedSet.nextRepsAfterTap(reps, target: 8)
            seen.append(reps)
        }
        XCTAssertEqual(seen, [8, 7, 6, 5, 4, 3, 2, 1, 0, nil, 8])
    }

    func testTapCycleThroughSession() {
        var s = Fixture.session()
        s.tapSet(exerciseID: eid, setIndex: 1, rest: rest, now: Fixture.at(1))
        XCTAssertEqual(s.exercises[0].sets[1].reps, 8)
        XCTAssertNil(s.exercises[0].sets[0].reps)
        for expected in [7, 6, 5, 4, 3, 2, 1, 0] {
            s.tapSet(exerciseID: eid, setIndex: 1, rest: rest, now: Fixture.at(2))
            XCTAssertEqual(s.exercises[0].sets[1].reps, expected)
        }
        s.tapSet(exerciseID: eid, setIndex: 1, rest: rest, now: Fixture.at(3))
        XCTAssertNil(s.exercises[0].sets[1].reps)
        XCTAssertEqual(s.exercises[0].sets[1].updatedAt, Fixture.at(3))
    }

    func testTapOutOfRangeIsIgnored() {
        var s = Fixture.session()
        let before = s
        s.tapSet(exerciseID: eid, setIndex: 9, rest: rest, now: Fixture.at(1))
        s.tapSet(exerciseID: Fixture.uuid(999), setIndex: 0, rest: rest, now: Fixture.at(1))
        XCTAssertEqual(s, before)
    }

    func testRestAfterSuccessIs90() {
        var s = Fixture.session()
        let now = Fixture.at(10)
        s.tapSet(exerciseID: eid, setIndex: 0, rest: rest, now: now)
        XCTAssertEqual(s.restTimer.endsAt, now.addingTimeInterval(90))
        XCTAssertEqual(s.restTimer.duration, 90)
        XCTAssertTrue(s.restTimer.isRunning(at: now))
        XCTAssertEqual(s.restTimer.remaining(at: now.addingTimeInterval(30)), 60)
    }

    func testRestAfterMissIs180ThenConsecutiveMissIs300() {
        var s = Fixture.session()
        s.setReps(5, exerciseID: eid, setIndex: 0, rest: rest, now: Fixture.at(10))
        XCTAssertEqual(s.restTimer.duration, 180)
        s.setReps(5, exerciseID: eid, setIndex: 1, rest: rest, now: Fixture.at(20))
        XCTAssertEqual(s.restTimer.duration, 300)
        XCTAssertEqual(s.restTimer.endsAt, Fixture.at(320))
        // A success resets to 90, and the next miss is a first miss again.
        s.setReps(8, exerciseID: eid, setIndex: 2, rest: rest, now: Fixture.at(30))
        XCTAssertEqual(s.restTimer.duration, 90)
        s.setReps(3, exerciseID: eid, setIndex: 3, rest: rest, now: Fixture.at(40))
        XCTAssertEqual(s.restTimer.duration, 180)
    }

    func testRestDurationUsesCustomSettings() {
        var s = Fixture.session()
        let custom = RestSettings(afterSuccess: 60, afterFailure: 120, afterRepeatedFailure: 240)
        s.setReps(8, exerciseID: eid, setIndex: 0, rest: custom, now: Fixture.at(1))
        XCTAssertEqual(s.restTimer.duration, 60)
        s.setReps(0, exerciseID: eid, setIndex: 1, rest: custom, now: Fixture.at(2))
        XCTAssertEqual(s.restTimer.duration, 120)
        s.setReps(0, exerciseID: eid, setIndex: 2, rest: custom, now: Fixture.at(3))
        XCTAssertEqual(s.restTimer.duration, 240)
    }

    func testClearingSetStopsTimer() {
        var s = Fixture.session()
        s.setReps(8, exerciseID: eid, setIndex: 0, rest: rest, now: Fixture.at(10))
        XCTAssertNotNil(s.restTimer.endsAt)
        s.setReps(nil, exerciseID: eid, setIndex: 0, rest: rest, now: Fixture.at(12))
        XCTAssertNil(s.restTimer.endsAt)
        XCTAssertFalse(s.restTimer.isRunning(at: Fixture.at(12)))
        XCTAssertEqual(s.restTimer.updatedAt, Fixture.at(12))
    }

    func testAdjustRest() {
        var s = Fixture.session()
        s.setReps(8, exerciseID: eid, setIndex: 0, rest: rest, now: Fixture.at(0))
        s.adjustRest(by: 15, now: Fixture.at(10))
        XCTAssertEqual(s.restTimer.endsAt, Fixture.at(105))
        XCTAssertEqual(s.restTimer.duration, 105)
        s.adjustRest(by: -15, now: Fixture.at(10))
        XCTAssertEqual(s.restTimer.endsAt, Fixture.at(90))
        XCTAssertEqual(s.restTimer.duration, 90)
        // Remaining is 80 s; removing 100 s goes past zero and stops the timer.
        s.adjustRest(by: -100, now: Fixture.at(10))
        XCTAssertNil(s.restTimer.endsAt)
        XCTAssertEqual(s.restTimer.remaining(at: Fixture.at(10)), 0)
    }

    func testAdjustRestWhenIdle() {
        var s = Fixture.session()
        s.adjustRest(by: -15, now: Fixture.at(5))
        XCTAssertNil(s.restTimer.endsAt)
        s.adjustRest(by: 15, now: Fixture.at(5))
        XCTAssertEqual(s.restTimer.endsAt, Fixture.at(20))
    }

    func testAdjustRestAfterTimerExpiredRestartsOnlyWhenAdding() {
        var s = Fixture.session()
        s.startRest(duration: 90, now: Fixture.at(0))
        s.adjustRest(by: -15, now: Fixture.at(200))
        XCTAssertFalse(s.restTimer.isRunning(at: Fixture.at(200)))
    }

    func testSkipRest() {
        var s = Fixture.session()
        s.startRest(duration: 90, now: Fixture.at(0))
        s.skipRest(now: Fixture.at(5))
        XCTAssertNil(s.restTimer.endsAt)
        XCTAssertEqual(s.restTimer.progress(at: Fixture.at(5)), 0)
    }

    func testRestTimerProgress() {
        let timer = RestTimerState(endsAt: Fixture.at(100), duration: 100, updatedAt: Fixture.at(0))
        XCTAssertEqual(timer.progress(at: Fixture.at(25)), 0.25, accuracy: 1e-9)
        XCTAssertEqual(timer.progress(at: Fixture.at(500)), 1, accuracy: 1e-9)
    }

    func testLoggingASetUnskipsExercise() {
        var s = Fixture.session()
        s.setSkipped(true, exerciseID: eid, now: Fixture.at(1))
        s.tapSet(exerciseID: eid, setIndex: 0, rest: rest, now: Fixture.at(2))
        XCTAssertFalse(s.exercises[0].isSkipped)
    }

    func testMakeSessionFromDay() {
        let program = ProgramDefaults.program(unit: .lb)
        let day = program.days[0]
        let s = WorkoutEngine.makeSession(for: day, settings: Fixture.lb, device: .watch, now: Fixture.t0, id: Fixture.uuid(7))
        XCTAssertEqual(s.id, Fixture.uuid(7))
        XCTAssertEqual(s.startedOn, .watch)
        XCTAssertEqual(s.exercises.count, 3)
        XCTAssertTrue(s.exercises.allSatisfy { $0.sets.count == 4 && $0.sets.allSatisfy { $0.targetReps == 8 && $0.reps == nil } })
        XCTAssertEqual(s.exercises.map(\.id), day.slots.map(\.id))
        // Barbell bench at the empty bar has no warm-ups; the dumbbell and cable lifts never do.
        XCTAssertTrue(s.exercises.allSatisfy { $0.warmups.isEmpty })
    }

    func testSetWeightRegeneratesWarmupsUntilOneIsDone() {
        var s = Fixture.session(weight: 135)
        s.setWeight(135, exerciseID: eid, settings: Fixture.lb, now: Fixture.at(1))
        XCTAssertEqual(s.exercises[0].warmups.map(\.weight), [45, 45, 55, 80, 110])
        s.toggleWarmup(exerciseID: eid, index: 0, now: Fixture.at(2))
        s.setWeight(95, exerciseID: eid, settings: Fixture.lb, now: Fixture.at(3))
        XCTAssertEqual(s.exercises[0].weight, 95)
        XCTAssertEqual(s.exercises[0].warmups.map(\.weight), [45, 45, 55, 80, 110], "ticked warm-ups are kept")
    }

    func testSetWeightRoundsToLoadable() {
        var s = Fixture.session()
        s.setWeight(137, exerciseID: eid, settings: Fixture.lb, now: Fixture.at(1))
        XCTAssertEqual(s.exercises[0].weight, 135)
        XCTAssertEqual(s.exercises[0].weightUpdatedAt, Fixture.at(1))
    }

    func testCompletedSnapshot() {
        var s = Fixture.session()
        s.setReps(8, exerciseID: eid, setIndex: 0, rest: rest, now: Fixture.at(1))
        s.setReps(6, exerciseID: eid, setIndex: 1, rest: rest, now: Fixture.at(2))
        s.setNote("felt heavy", exerciseID: eid, now: Fixture.at(3))
        s.setWorkoutNote("good day", now: Fixture.at(4))
        let w = s.completed(finishedAt: Fixture.at(100), device: .watch)
        XCTAssertEqual(w.id, s.id)
        XCTAssertEqual(w.exercises[0].reps, [8, 6, nil, nil])
        XCTAssertEqual(w.exercises[0].note, "felt heavy")
        XCTAssertEqual(w.note, "good day")
        XCTAssertEqual(w.finishedOn, .watch)
        XCTAssertEqual(w.duration, 100)
        // Finishing "before" the start clamps to the start.
        XCTAssertEqual(s.completed(finishedAt: Fixture.at(-50), device: .phone).finishedAt, s.startedAt)
    }

    func testDiscardTombstonesAndTombstoneCap() {
        var state = AppState.fresh()
        state.startWorkout(device: .phone, now: Fixture.t0)
        let id = state.activeSession!.id
        XCTAssertEqual(state.discardActiveWorkout(), id)
        XCTAssertNil(state.activeSession)
        XCTAssertTrue(state.isTombstoned(id))
        XCTAssertNil(state.discardActiveWorkout())
        for n in 0..<(AppState.maxTombstones + 10) { state.addTombstone(Fixture.uuid(1000 + n)) }
        XCTAssertEqual(state.discardedSessionIDs.count, AppState.maxTombstones)
        XCTAssertFalse(state.isTombstoned(id), "oldest tombstones are evicted")
    }
}
