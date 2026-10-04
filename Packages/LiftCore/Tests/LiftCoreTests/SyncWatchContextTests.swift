import XCTest
@testable import LiftCore

final class SyncWatchContextTests: XCTestCase {
    let rest = RestSettings()

    func logAll(_ state: inout AppState, at t: TimeInterval) {
        for e in state.activeSession!.exercises {
            for i in e.sets.indices {
                state.activeSession!.setReps(8, exerciseID: e.id, setIndex: i, rest: rest, now: Fixture.at(t))
            }
        }
    }

    func context(_ state: AppState, at t: TimeInterval) -> SyncMessage {
        .context(WatchContext(state: state, generatedAt: Fixture.at(t)))
    }

    func testWatchAdoptsProgramSettingsAndSession() {
        var phone = AppState.fresh(unit: .kg)
        phone.startWorkout(device: .phone, now: Fixture.at(1))
        var watch = AppState.fresh(unit: .lb)
        let fx = SyncReducer.apply(context(phone, at: 2), to: &watch, role: .watch)
        XCTAssertEqual(watch.program, phone.program)
        XCTAssertEqual(watch.settings, phone.settings)
        XCTAssertEqual(watch.activeSession, phone.activeSession)
        XCTAssertTrue(fx.stateChanged)
        XCTAssertNil(fx.sendSession)
        XCTAssertFalse(fx.activeSessionEndedRemotely)
    }

    func testWatchKeepsPendingFinishedWorkoutAndReappliesProgression() throws {
        let phone = AppState.fresh()
        var watch = phone
        watch.startWorkout(device: .watch, now: Fixture.at(1))
        logAll(&watch, at: 10)
        let workout = try XCTUnwrap(watch.finishActiveWorkout(device: .watch, now: Fixture.at(100)))

        // The phone hasn't seen the workout yet, so its context has the old program and no history.
        let fx = SyncReducer.apply(context(phone, at: 150), to: &watch, role: .watch)

        var expected = phone
        expected.applyCompleted(workout)
        XCTAssertEqual(watch.history.map(\.id), [workout.id])
        XCTAssertEqual(watch.program, expected.program, "progression re-applied exactly once on top of the phone's program")
        XCTAssertEqual(watch.program.slot(id: workout.exercises[0].id)?.nextWeight, 50)
        XCTAssertEqual(watch.program.nextDayID, phone.program.days[1].id)
        XCTAssertNil(watch.activeSession)
        XCTAssertNil(fx.sendSession)
        XCTAssertFalse(fx.activeSessionEndedRemotely)

        // Receiving the same context again changes nothing.
        let snapshot = watch
        let again = SyncReducer.apply(context(phone, at: 151), to: &watch, role: .watch)
        XCTAssertEqual(watch, snapshot)
        XCTAssertFalse(again.stateChanged)
    }

    func testOnceThePhoneHasTheWorkoutTheWatchDoesNotApplyItTwice() throws {
        var phone = AppState.fresh()
        var watch = phone
        watch.startWorkout(device: .watch, now: Fixture.at(1))
        logAll(&watch, at: 10)
        let workout = try XCTUnwrap(watch.finishActiveWorkout(device: .watch, now: Fixture.at(100)))

        _ = SyncReducer.apply(context(phone, at: 110), to: &watch, role: .watch)
        _ = SyncReducer.apply(.completed(workout), to: &phone, role: .phone)
        _ = SyncReducer.apply(context(phone, at: 120), to: &watch, role: .watch)

        XCTAssertEqual(watch.history, phone.history)
        XCTAssertEqual(watch.program, phone.program)
        XCTAssertEqual(watch.program.slot(id: workout.exercises[0].id)?.nextWeight, 50)
    }

    func testWatchOnlyKeepsWatchFinishedWorkoutsThatThePhoneLacks() throws {
        var phone = AppState.fresh()
        phone.history = [Fixture.workout(id: 1, finishedAt: Fixture.at(-1000), exercises: [])]
        var watch = phone
        // A history entry the phone doesn't list and the watch did not finish itself is dropped.
        watch.history.append(Fixture.workout(id: 2, finishedAt: Fixture.at(-500), exercises: [], finishedOn: .phone))
        _ = SyncReducer.apply(context(phone, at: 5), to: &watch, role: .watch)
        XCTAssertEqual(watch.history.map(\.id), [Fixture.uuid(1)])
    }

    func testWatchSessionMissingFromContextIsResent() {
        let phone = AppState.fresh()
        var watch = phone
        let s = watch.startWorkout(device: .watch, now: Fixture.at(1))!
        let fx = SyncReducer.apply(context(phone, at: 2), to: &watch, role: .watch)
        XCTAssertEqual(watch.activeSession, s, "kept")
        XCTAssertEqual(fx.sendSession, s)
        XCTAssertFalse(fx.activeSessionEndedRemotely)
    }

    func testContextMergesSameSession() {
        var phone = AppState.fresh()
        let ps = phone.startWorkout(device: .phone, now: Fixture.at(1))!
        var watch = phone
        let eid = ps.exercises[0].id
        phone.activeSession!.setReps(8, exerciseID: eid, setIndex: 0, rest: rest, now: Fixture.at(10))
        watch.activeSession!.setReps(7, exerciseID: eid, setIndex: 1, rest: rest, now: Fixture.at(20))
        let fx = SyncReducer.apply(context(phone, at: 30), to: &watch, role: .watch)
        XCTAssertEqual(watch.activeSession?.exercises[0].sets.map(\.reps), [8, 7, nil, nil])
        XCTAssertEqual(fx.sendSession, watch.activeSession, "phone is missing the watch's set")
    }

    func testContextEndingASessionThatIsInHistory() throws {
        var phone = AppState.fresh()
        let s = phone.startWorkout(device: .phone, now: Fixture.at(1))!
        var watch = phone
        logAll(&phone, at: 5)
        let done = try XCTUnwrap(phone.finishActiveWorkout(device: .phone, now: Fixture.at(50)))
        XCTAssertEqual(done.id, s.id)
        let fx = SyncReducer.apply(context(phone, at: 60), to: &watch, role: .watch)
        XCTAssertNil(watch.activeSession)
        XCTAssertTrue(fx.activeSessionEndedRemotely)
        XCTAssertNil(fx.sendSession)
        XCTAssertEqual(watch.history.map(\.id), [s.id])
    }

    func testContextEndingATombstonedSession() {
        var phone = AppState.fresh()
        let s = phone.startWorkout(device: .phone, now: Fixture.at(1))!
        var watch = phone
        phone.discardActiveWorkout()
        let fx = SyncReducer.apply(context(phone, at: 60), to: &watch, role: .watch)
        XCTAssertNil(watch.activeSession)
        XCTAssertTrue(watch.isTombstoned(s.id))
        XCTAssertTrue(fx.activeSessionEndedRemotely)
        XCTAssertNil(fx.sendSession)
    }

    func testContextThatTombstonesMySessionAndOffersAnotherAdoptsTheOther() {
        var phone = AppState.fresh()
        var watch = phone
        let mine = watch.startWorkout(device: .watch, now: Fixture.at(1))!
        for i in 0..<3 {
            watch.activeSession!.setReps(8, exerciseID: mine.exercises[0].id, setIndex: i, rest: rest, now: Fixture.at(2))
        }
        let theirs = phone.startWorkout(device: .phone, now: Fixture.at(0))!
        phone.addTombstone(mine.id)
        let fx = SyncReducer.apply(context(phone, at: 60), to: &watch, role: .watch)
        XCTAssertEqual(watch.activeSession?.id, theirs.id, "a tombstoned session must never stay active")
        XCTAssertTrue(fx.activeSessionEndedRemotely)
        XCTAssertNil(fx.sendSession)
    }

    func testContextWithNewerSessionWhenWatchHasNone() {
        var phone = AppState.fresh()
        var watch = phone
        let s = phone.startWorkout(device: .phone, now: Fixture.at(1))!
        _ = SyncReducer.apply(context(phone, at: 2), to: &watch, role: .watch)
        XCTAssertEqual(watch.activeSession?.id, s.id)
        // But a context carrying a tombstoned or finished session is not adopted.
        var other = AppState.fresh()
        other.startWorkout(device: .phone, now: Fixture.at(1))
        var fresh = other
        fresh.addTombstone(other.activeSession!.id)
        var target = AppState.fresh()
        let msg = WatchContext(state: fresh, generatedAt: Fixture.at(3))
        _ = SyncReducer.apply(.context(msg), to: &target, role: .watch)
        XCTAssertNil(target.activeSession)
    }
}
