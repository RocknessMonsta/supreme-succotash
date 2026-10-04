import XCTest
@testable import LiftCore

final class SyncReducerTests: XCTestCase {
    let rest = RestSettings()

    /// Logs every set of every exercise at target reps.
    func logAll(_ state: inout AppState, at t: TimeInterval) {
        let s = state.activeSession!
        for e in s.exercises {
            for i in e.sets.indices {
                state.activeSession!.setReps(8, exerciseID: e.id, setIndex: i, rest: rest, now: Fixture.at(t))
            }
        }
    }

    func apply(_ m: SyncMessage, _ state: inout AppState, _ role: DeviceKind) -> SyncEffects {
        SyncReducer.apply(m, to: &state, role: role)
    }

    // MARK: Phone receives watch session

    func testPhoneAdoptsWatchSession() {
        var phone = AppState.fresh()
        var watch = phone
        let ws = watch.startWorkout(device: .watch, now: Fixture.at(1))!
        let fx = apply(.session(ws), &phone, .phone)
        XCTAssertEqual(phone.activeSession, ws)
        XCTAssertTrue(fx.stateChanged)
        XCTAssertNil(fx.sendSession)
        XCTAssertFalse(fx.sendContext)
    }

    func testPhoneMergesSnapshotOfTheSameSession() {
        var phone = AppState.fresh()
        let ps = phone.startWorkout(device: .phone, now: Fixture.at(1))!
        var watch = phone
        let eid = ps.exercises[0].id
        phone.activeSession!.setReps(8, exerciseID: eid, setIndex: 0, rest: rest, now: Fixture.at(10))
        watch.activeSession!.setReps(6, exerciseID: eid, setIndex: 1, rest: rest, now: Fixture.at(20))

        let fx = apply(.session(watch.activeSession!), &phone, .phone)
        XCTAssertEqual(phone.activeSession?.exercises[0].sets.map(\.reps), [8, 6, nil, nil])
        XCTAssertTrue(fx.stateChanged)
        XCTAssertEqual(fx.sendSession, phone.activeSession, "watch is missing set 0, send the merge back")
        XCTAssertFalse(fx.sendContext)

        // The watch applies the merged snapshot and has nothing more to send.
        let fx2 = apply(.session(phone.activeSession!), &watch, .watch)
        XCTAssertEqual(watch.activeSession, phone.activeSession)
        XCTAssertTrue(fx2.stateChanged)
        XCTAssertNil(fx2.sendSession)

        // Re-delivery of an identical snapshot is a no-op.
        let fx3 = apply(.session(phone.activeSession!), &phone, .phone)
        XCTAssertEqual(fx3, SyncEffects())
    }

    func testConflictingSessionsKeepTheOneWithMoreSetsAndTombstoneTheOther() {
        var phone = AppState.fresh()
        let p = phone.startWorkout(device: .phone, now: Fixture.at(1))!
        var watch = AppState.fresh()
        watch.program = phone.program
        let w = watch.startWorkout(device: .watch, now: Fixture.at(2))!
        watch.activeSession!.setReps(8, exerciseID: w.exercises[0].id, setIndex: 0, rest: rest, now: Fixture.at(3))
        XCTAssertNotEqual(p.id, w.id)

        let fx = apply(.session(watch.activeSession!), &phone, .phone)
        XCTAssertEqual(phone.activeSession?.id, w.id)
        XCTAssertTrue(phone.isTombstoned(p.id))
        XCTAssertFalse(phone.isTombstoned(w.id))
        XCTAssertTrue(fx.sendContext)
        XCTAssertNil(fx.sendSession, "watch already has the winner")
        XCTAssertTrue(fx.stateChanged)
    }

    func testConflictWhereLocalWinsSendsLocalBack() {
        var phone = AppState.fresh()
        let p = phone.startWorkout(device: .phone, now: Fixture.at(1))!
        phone.activeSession!.setReps(8, exerciseID: p.exercises[0].id, setIndex: 0, rest: rest, now: Fixture.at(5))
        phone.activeSession!.setReps(8, exerciseID: p.exercises[0].id, setIndex: 1, rest: rest, now: Fixture.at(6))
        var watch = AppState.fresh()
        let w = watch.startWorkout(device: .watch, now: Fixture.at(2))!
        let before = phone.activeSession

        let fx = apply(.session(w), &phone, .phone)
        XCTAssertEqual(phone.activeSession, before)
        XCTAssertTrue(phone.isTombstoned(w.id))
        XCTAssertEqual(fx.sendSession, before)
        XCTAssertTrue(fx.sendContext)
        XCTAssertTrue(fx.stateChanged, "the new tombstone has to be persisted")
    }

    // MARK: Completed workouts

    func testCompletedFromWatchIsAppliedExactlyOnce() throws {
        var phone = AppState.fresh()
        let session = phone.startWorkout(device: .phone, now: Fixture.at(1))!
        var watch = phone
        logAll(&watch, at: 10)
        let workout = try XCTUnwrap(watch.finishActiveWorkout(device: .watch, now: Fixture.at(100)))
        let bench = session.exercises[0].id
        let chest = phone.program.days[0], back = phone.program.days[1]

        let fx = apply(.completed(workout), &phone, .phone)
        XCTAssertEqual(phone.history.map(\.id), [workout.id])
        XCTAssertNil(phone.activeSession)
        XCTAssertEqual(phone.program.slot(id: bench)?.nextWeight, chest.slots[0].nextWeight + 5)
        XCTAssertEqual(phone.program.nextDayID, back.id)
        XCTAssertTrue(fx.stateChanged)
        XCTAssertTrue(fx.sendContext)
        XCTAssertTrue(fx.activeSessionEndedRemotely)
        XCTAssertEqual(fx.completedRemotely, workout)

        // Delivered twice (transferUserInfo retry): nothing changes.
        let snapshot = phone
        let again = apply(.completed(workout), &phone, .phone)
        XCTAssertEqual(phone, snapshot)
        XCTAssertEqual(again, SyncEffects())
        XCTAssertEqual(phone.program.slot(id: bench)?.nextWeight, chest.slots[0].nextWeight + 5, "progression not doubled")
    }

    func testCompletedWhenPhoneNeverSawTheSession() throws {
        var phone = AppState.fresh()
        var watch = phone
        watch.startWorkout(device: .watch, now: Fixture.at(1))
        logAll(&watch, at: 5)
        let workout = try XCTUnwrap(watch.finishActiveWorkout(device: .watch, now: Fixture.at(50)))
        let fx = apply(.completed(workout), &phone, .phone)
        XCTAssertEqual(phone.history.count, 1)
        XCTAssertTrue(fx.sendContext)
        XCTAssertEqual(fx.completedRemotely, workout)
        XCTAssertFalse(fx.activeSessionEndedRemotely)
    }

    func testCompletedOnWatchRoleDoesNotRequestContext() throws {
        var phone = AppState.fresh()
        phone.startWorkout(device: .phone, now: Fixture.at(1))
        var watch = phone
        logAll(&phone, at: 5)
        let workout = try XCTUnwrap(phone.finishActiveWorkout(device: .phone, now: Fixture.at(50)))
        let fx = apply(.completed(workout), &watch, .watch)
        XCTAssertNil(watch.activeSession)
        XCTAssertFalse(fx.sendContext)
        XCTAssertTrue(fx.activeSessionEndedRemotely)
        XCTAssertEqual(watch.program, phone.program, "same progression on both sides")
    }

    // MARK: Discard and late snapshots

    func testDiscardTombstonesAndClearsActiveSession() {
        var phone = AppState.fresh()
        let s = phone.startWorkout(device: .phone, now: Fixture.at(1))!
        let fx = apply(.discarded(s.id), &phone, .phone)
        XCTAssertNil(phone.activeSession)
        XCTAssertTrue(phone.isTombstoned(s.id))
        XCTAssertTrue(fx.stateChanged)
        XCTAssertTrue(fx.activeSessionEndedRemotely)
        XCTAssertTrue(fx.sendContext)
    }

    func testDiscardingUnknownSessionStillTombstones() {
        var watch = AppState.fresh()
        let fx = apply(.discarded(Fixture.uuid(77)), &watch, .watch)
        XCTAssertTrue(watch.isTombstoned(Fixture.uuid(77)))
        XCTAssertTrue(fx.stateChanged)
        XCTAssertFalse(fx.activeSessionEndedRemotely)
        XCTAssertFalse(fx.sendContext)
        // Repeat is a no-op.
        XCTAssertEqual(apply(.discarded(Fixture.uuid(77)), &watch, .watch), SyncEffects())
    }

    func testDiscardOfAnotherSessionLeavesActiveOne() {
        var phone = AppState.fresh()
        let s = phone.startWorkout(device: .phone, now: Fixture.at(1))!
        let fx = apply(.discarded(Fixture.uuid(77)), &phone, .phone)
        XCTAssertEqual(phone.activeSession?.id, s.id)
        XCTAssertFalse(fx.activeSessionEndedRemotely)
    }

    func testLateSnapshotOfDiscardedSessionIsIgnored() {
        var phone = AppState.fresh()
        let s = phone.startWorkout(device: .watch, now: Fixture.at(1))!
        _ = apply(.discarded(s.id), &phone, .phone)
        let fx = apply(.session(s), &phone, .phone)
        XCTAssertNil(phone.activeSession)
        XCTAssertFalse(fx.stateChanged)
        XCTAssertTrue(fx.sendContext, "tell the watch it was discarded")
        XCTAssertNil(fx.sendSession)

        var watch = AppState.fresh()
        watch.addTombstone(s.id)
        let fxWatch = apply(.session(s), &watch, .watch)
        XCTAssertNil(watch.activeSession)
        XCTAssertFalse(fxWatch.stateChanged)
    }

    func testLateSnapshotOfFinishedSession() throws {
        var phone = AppState.fresh()
        let s = phone.startWorkout(device: .phone, now: Fixture.at(1))!
        logAll(&phone, at: 5)
        let done = try XCTUnwrap(phone.finishActiveWorkout(device: .phone, now: Fixture.at(50)))
        let fx = apply(.session(s), &phone, .phone)
        XCTAssertNil(phone.activeSession)
        XCTAssertTrue(fx.sendContext)
        XCTAssertFalse(fx.stateChanged)

        var watch = phone
        let fxWatch = apply(.session(s), &watch, .watch)
        XCTAssertEqual(fxWatch.sendCompleted, done)
        XCTAssertNil(watch.activeSession)
    }

    func testRequestContextOnlyAnsweredByPhone() {
        var phone = AppState.fresh(), watch = AppState.fresh()
        XCTAssertTrue(apply(.requestContext, &phone, .phone).sendContext)
        XCTAssertFalse(apply(.requestContext, &watch, .watch).sendContext)
    }

    func testPhoneIgnoresContext() {
        var phone = AppState.fresh()
        var other = AppState.fresh(unit: .kg)
        other.startWorkout(device: .watch, now: Fixture.at(1))
        let before = phone
        let fx = apply(.context(WatchContext(state: other, generatedAt: Fixture.at(2))), &phone, .phone)
        XCTAssertEqual(phone, before)
        XCTAssertEqual(fx, SyncEffects())
    }
}

final class UnitSafeSyncTests: XCTestCase {
    func testRemoteSessionInOldUnitIsConvertedBeforeAdopting() {
        let t0 = Date(timeIntervalSince1970: 1_000_000)
        var phone = AppState.fresh(unit: .lb)
        let session = phone.startWorkout(device: .watch, now: t0)!
        phone.activeSession = nil
        phone.convertUnits(to: .kg)
        let fx = SyncReducer.apply(.session(session), to: &phone, role: .phone)
        XCTAssertTrue(fx.stateChanged)
        XCTAssertEqual(phone.activeSession?.unit, .kg)
        // 45 lb bar → 20 kg bar
        XCTAssertEqual(phone.activeSession?.exercises.first?.weight, 20)
    }

    func testMergeAfterUnitSwitchIsInNewUnit() {
        let t0 = Date(timeIntervalSince1970: 1_000_000)
        var phone = AppState.fresh(unit: .lb)
        let session = phone.startWorkout(device: .phone, now: t0)!
        phone.convertUnits(to: .kg)
        let fx = SyncReducer.apply(.session(session), to: &phone, role: .phone)
        XCTAssertEqual(phone.activeSession?.unit, .kg)
        XCTAssertNil(fx.sendSession, "both sides convert identically, so nothing to resend")
        XCTAssertTrue(phone.activeSession!.exercises.allSatisfy { $0.weight < 100 })
    }
}

final class MinimumStepProgressionTests: XCTestCase {
    func testTinyIncrementStillProgresses() {
        let settings = Settings.defaults(for: .kg) // smallest plate 1.25 → 2.5 kg jump
        let bench = ExerciseLibrary.exercise(id: "barbell-bench-press")!
        var slot = ExerciseSlot(exercise: bench, nextWeight: 40, increment: 1)
        let result = ExerciseResult(id: slot.id, exercise: bench, weight: 40, targetReps: 8, reps: [8, 8, 8, 8], isSkipped: false)
        XCTAssertEqual(ProgressionEngine.apply(result, to: &slot, settings: settings), .increased)
        XCTAssertEqual(slot.nextWeight, 42.5)
    }
}
