import XCTest
@testable import LiftCore

final class SyncEnvelopeTests: XCTestCase {
    func roundTrip(_ message: SyncMessage, sender: DeviceKind = .watch) throws -> SyncEnvelope {
        let envelope = SyncEnvelope(sender: sender, sentAt: Fixture.at(5), message: message)
        let dict = try envelope.dictionary()
        XCTAssertEqual(Array(dict.keys), [SyncEnvelope.payloadKey])
        let decoded = try XCTUnwrap(SyncEnvelope.from(dictionary: dict))
        XCTAssertEqual(decoded, envelope)
        return decoded
    }

    func testEveryMessageRoundTripsThroughDictionary() throws {
        var state = AppState.fresh()
        state.startWorkout(device: .phone, now: Fixture.at(1.5))
        let session = state.activeSession!
        let workout = Fixture.workout(exercises: [Fixture.result(reps: [8, nil, 3, 0], note: "x")])
        _ = try roundTrip(.context(WatchContext(state: state, generatedAt: Fixture.at(2))), sender: .phone)
        _ = try roundTrip(.session(session))
        _ = try roundTrip(.completed(workout))
        _ = try roundTrip(.discarded(Fixture.uuid(9)))
        _ = try roundTrip(.requestContext)
    }

    func testContextCarriesRecentHistoryOnly() {
        var state = AppState.fresh()
        state.history = (0..<30).map { Fixture.workout(id: $0 + 1, finishedAt: Fixture.at(Double(100 - $0)), exercises: []) }
        let ctx = WatchContext(state: state, generatedAt: Fixture.t0)
        XCTAssertEqual(ctx.recentHistory.count, WatchContext.recentHistoryLimit)
        XCTAssertEqual(ctx.recentHistory.first?.id, state.history.first?.id)
    }

    func testForeignAndFutureDictionariesAreRejected() throws {
        XCTAssertNil(SyncEnvelope.from(dictionary: [:]))
        XCTAssertNil(SyncEnvelope.from(dictionary: ["other": 1]))
        XCTAssertNil(SyncEnvelope.from(dictionary: [SyncEnvelope.payloadKey: "not data"]))
        XCTAssertNil(SyncEnvelope.from(dictionary: [SyncEnvelope.payloadKey: Data("garbage".utf8)]))
        var future = SyncEnvelope(sender: .phone, sentAt: Fixture.t0, message: .requestContext)
        future.schemaVersion = SyncEnvelope.schemaVersion + 1
        XCTAssertNil(SyncEnvelope.from(dictionary: try future.dictionary()))
    }

    func testDatesSurviveAtMillisecondPrecision() throws {
        let envelope = SyncEnvelope(sender: .phone, sentAt: Date(timeIntervalSince1970: 1_700_000_000.25), message: .requestContext)
        let decoded = try SyncEnvelope.decode(try envelope.encoded())
        XCTAssertEqual(decoded.sentAt, envelope.sentAt)
    }
}

final class SessionMergeTests: XCTestCase {
    let eid = Fixture.uuid(100)
    let rest = RestSettings()

    /// Asserts commutativity and idempotence, returns the merge.
    @discardableResult
    func merged(_ a: WorkoutSession, _ b: WorkoutSession, file: StaticString = #filePath, line: UInt = #line) -> WorkoutSession {
        let ab = SessionMerge.merge(a, b)
        let ba = SessionMerge.merge(b, a)
        XCTAssertEqual(ab, ba, "merge must be commutative", file: file, line: line)
        XCTAssertEqual(SessionMerge.merge(ab, a), ab, "absorbs its inputs", file: file, line: line)
        XCTAssertEqual(SessionMerge.merge(ab, b), ab, "absorbs its inputs", file: file, line: line)
        XCTAssertEqual(SessionMerge.merge(a, a), a, "idempotent", file: file, line: line)
        return ab
    }

    func testDisjointSetEditsBothSurvive() {
        let base = Fixture.session()
        var a = base, b = base
        a.setReps(8, exerciseID: eid, setIndex: 0, rest: rest, now: Fixture.at(10))
        b.setReps(6, exerciseID: eid, setIndex: 1, rest: rest, now: Fixture.at(20))
        let m = merged(a, b)
        XCTAssertEqual(m.exercises[0].sets.map(\.reps), [8, 6, nil, nil])
    }

    func testSameSetLastWriterWins() {
        let base = Fixture.session()
        var a = base, b = base
        a.setReps(8, exerciseID: eid, setIndex: 0, rest: rest, now: Fixture.at(10))
        b.setReps(5, exerciseID: eid, setIndex: 0, rest: rest, now: Fixture.at(20))
        XCTAssertEqual(merged(a, b).exercises[0].sets[0].reps, 5)
        // A later clear beats an earlier log.
        var c = base
        c.setReps(nil, exerciseID: eid, setIndex: 0, rest: rest, now: Fixture.at(30))
        XCTAssertNil(merged(a, c).exercises[0].sets[0].reps)
    }

    func testSameSetSameTimestampPrefersHigherReps() {
        let base = Fixture.session()
        var a = base, b = base
        a.setReps(8, exerciseID: eid, setIndex: 0, rest: rest, now: Fixture.at(10))
        b.setReps(5, exerciseID: eid, setIndex: 0, rest: rest, now: Fixture.at(10))
        XCTAssertEqual(merged(a, b).exercises[0].sets[0].reps, 8)
        var c = base
        c.setReps(nil, exerciseID: eid, setIndex: 0, rest: rest, now: Fixture.at(10))
        XCTAssertEqual(merged(a, c).exercises[0].sets[0].reps, 8, "logged beats cleared on a tie")
    }

    func testRestTimerLastWriterWins() {
        let base = Fixture.session()
        var a = base, b = base
        a.startRest(duration: 90, now: Fixture.at(10))
        b.skipRest(now: Fixture.at(20))
        XCTAssertNil(merged(a, b).restTimer.endsAt)
        var c = base
        c.startRest(duration: 180, now: Fixture.at(30))
        XCTAssertEqual(merged(a, c).restTimer.endsAt, Fixture.at(210))
    }

    func testRestTimerTiesAreDeterministic() {
        let base = Fixture.session()
        var a = base, b = base
        a.restTimer = RestTimerState(endsAt: Fixture.at(100), duration: 90, updatedAt: Fixture.at(10))
        b.restTimer = RestTimerState(endsAt: Fixture.at(160), duration: 150, updatedAt: Fixture.at(10))
        XCTAssertEqual(merged(a, b).restTimer.endsAt, Fixture.at(160))
        // Same end, different duration.
        b.restTimer = RestTimerState(endsAt: Fixture.at(100), duration: 100, updatedAt: Fixture.at(10))
        merged(a, b)
        // Running vs idle at the same instant.
        b.restTimer = RestTimerState(endsAt: nil, duration: 0, updatedAt: Fixture.at(10))
        XCTAssertEqual(merged(a, b).restTimer.endsAt, Fixture.at(100))
    }

    func testWeightSkipAndNotesLastWriterWins() {
        var base = Fixture.session(weight: 100)
        base.setNote("base", exerciseID: eid, now: Fixture.at(1))
        var a = base, b = base
        a.setWeight(110, exerciseID: eid, settings: Fixture.lb, now: Fixture.at(10))
        b.setWeight(105, exerciseID: eid, settings: Fixture.lb, now: Fixture.at(20))
        a.setSkipped(true, exerciseID: eid, now: Fixture.at(30))
        b.setSkipped(false, exerciseID: eid, now: Fixture.at(25))
        a.setNote("from phone", exerciseID: eid, now: Fixture.at(40))
        b.setNote("from watch", exerciseID: eid, now: Fixture.at(35))
        a.setWorkoutNote("A", now: Fixture.at(50))
        b.setWorkoutNote("B", now: Fixture.at(60))
        let m = merged(a, b)
        XCTAssertEqual(m.exercises[0].weight, 105)
        XCTAssertEqual(m.exercises[0].weightUpdatedAt, Fixture.at(20))
        XCTAssertTrue(m.exercises[0].isSkipped)
        XCTAssertEqual(m.exercises[0].note, "from phone")
        XCTAssertEqual(m.note, "B")
    }

    func testTimestampTiesAreDeterministic() {
        let base = Fixture.session(weight: 100)
        var a = base, b = base
        a.setWeight(110, exerciseID: eid, settings: Fixture.lb, now: Fixture.at(10))
        b.setWeight(105, exerciseID: eid, settings: Fixture.lb, now: Fixture.at(10))
        a.setSkipped(true, exerciseID: eid, now: Fixture.at(10))
        b.setSkipped(false, exerciseID: eid, now: Fixture.at(10))
        a.setNote("a", exerciseID: eid, now: Fixture.at(10))
        b.setNote("b", exerciseID: eid, now: Fixture.at(10))
        a.setWorkoutNote("a", now: Fixture.at(10))
        b.setWorkoutNote("b", now: Fixture.at(10))
        let m = merged(a, b)
        XCTAssertEqual(m.exercises[0].weight, 110)
        XCTAssertFalse(m.exercises[0].isSkipped)
        XCTAssertEqual(m.exercises[0].note, "b")
        XCTAssertEqual(m.note, "b")
    }

    func testWarmupTicksMergeWhenPlansMatch() {
        var base = Fixture.session(weight: 135)
        base.setWeight(135, exerciseID: eid, settings: Fixture.lb, now: Fixture.at(1))
        var a = base, b = base
        a.toggleWarmup(exerciseID: eid, index: 0, now: Fixture.at(10))
        b.toggleWarmup(exerciseID: eid, index: 2, now: Fixture.at(11))
        XCTAssertEqual(merged(a, b).exercises[0].warmups.map(\.isDone), [true, false, true, false, false])
        // Untick later than a tick wins; equal timestamps keep the tick.
        var c = a
        c.toggleWarmup(exerciseID: eid, index: 0, now: Fixture.at(20))
        XCTAssertFalse(merged(a, c).exercises[0].warmups[0].isDone)
        var d = base
        d.toggleWarmup(exerciseID: eid, index: 0, now: Fixture.at(10))
        d.toggleWarmup(exerciseID: eid, index: 0, now: Fixture.at(10))
        XCTAssertTrue(merged(a, d).exercises[0].warmups[0].isDone)
    }

    func testWarmupsFollowTheNewerWeightWhenPlansDiffer() {
        var base = Fixture.session(weight: 135)
        base.setWeight(135, exerciseID: eid, settings: Fixture.lb, now: Fixture.at(1))
        var a = base, b = base
        a.setWeight(95, exerciseID: eid, settings: Fixture.lb, now: Fixture.at(10))
        b.toggleWarmup(exerciseID: eid, index: 0, now: Fixture.at(12))
        let m = merged(a, b)
        XCTAssertEqual(m.exercises[0].weight, 95)
        XCTAssertEqual(m.exercises[0].warmups.map(\.weight), [45, 45, 55, 75])
    }

    func testWarmupPlanTieWithEqualWeightTimestampIsDeterministic() {
        var base = Fixture.session(weight: 100)
        base.exercises[0].warmups = [WarmupSet(weight: 45, reps: 5, updatedAt: Fixture.at(1))]
        var a = base, b = base
        a.exercises[0].warmups = [WarmupSet(weight: 45, reps: 5, updatedAt: Fixture.at(1)), WarmupSet(weight: 65, reps: 3, updatedAt: Fixture.at(1))]
        b.exercises[0].warmups = [WarmupSet(weight: 45, reps: 5, updatedAt: Fixture.at(1)), WarmupSet(weight: 75, reps: 3, updatedAt: Fixture.at(1))]
        merged(a, b)
    }

    func testExercisesOnlyOnOneSideAreKept() {
        let base = Fixture.session()
        var a = base, b = base
        let extra = SessionExercise(id: Fixture.uuid(101), exercise: Fixture.exercise("squat"), weight: 65,
                                    sets: [LoggedSet(targetReps: 8, updatedAt: Fixture.at(5))], warmups: [], createdAt: Fixture.at(5))
        b.exercises.append(extra)
        a.setReps(8, exerciseID: eid, setIndex: 0, rest: rest, now: Fixture.at(10))
        let m = merged(a, b)
        XCTAssertEqual(Set(m.exercises.map(\.id)), [eid, Fixture.uuid(101)])
    }

    func testStartedAtTakesTheEarlierAndSetCountsGrow() {
        let a = Fixture.session(startedAt: Fixture.at(0), device: .watch)
        var b = Fixture.session(startedAt: Fixture.at(5), device: .phone, dayID: a.dayID)
        b.exercises[0].sets.append(LoggedSet(targetReps: 8, updatedAt: Fixture.at(6)))
        let m = merged(a, b)
        XCTAssertEqual(m.startedAt, Fixture.at(0))
        XCTAssertEqual(m.startedOn, .watch)
        XCTAssertEqual(m.exercises[0].sets.count, 5)
        // Identical start times on different devices resolve to the phone either way.
        let c = Fixture.session(startedAt: Fixture.at(0), device: .phone)
        XCTAssertEqual(merged(a, c).startedOn, .phone)
    }

    func testRandomisedCommutativity() {
        // A small deterministic LCG so the cases are reproducible.
        var seed: UInt64 = 42
        func next(_ n: Int) -> Int {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Int((seed >> 33) % UInt64(n))
        }
        for _ in 0..<200 {
            var a = Fixture.session(weight: 135), b = a
            for i in 0..<(next(6) + 1) {
                for which in 0..<2 {
                    let now = Fixture.at(Double(next(8)))
                    let setIndex = next(4)
                    switch next(6) {
                    case 0: if which == 0 { a.setReps(next(10) == 0 ? nil : next(9), exerciseID: eid, setIndex: setIndex, rest: rest, now: now) }
                            else { b.setReps(next(10) == 0 ? nil : next(9), exerciseID: eid, setIndex: setIndex, rest: rest, now: now) }
                    case 1: if which == 0 { a.setWeight(Double(95 + 5 * next(4)), exerciseID: eid, settings: Fixture.lb, now: now) }
                            else { b.setWeight(Double(95 + 5 * next(4)), exerciseID: eid, settings: Fixture.lb, now: now) }
                    case 2: if which == 0 { a.setSkipped(next(2) == 0, exerciseID: eid, now: now) } else { b.setSkipped(next(2) == 0, exerciseID: eid, now: now) }
                    case 3: if which == 0 { a.toggleWarmup(exerciseID: eid, index: next(3), now: now) } else { b.toggleWarmup(exerciseID: eid, index: next(3), now: now) }
                    case 4: if which == 0 { a.startRest(duration: Double(30 * (next(5) + 1)), now: now) } else { b.skipRest(now: now) }
                    default: if which == 0 { a.setNote("a\(i)", exerciseID: eid, now: now) } else { b.setNote("b\(i)", exerciseID: eid, now: now) }
                    }
                }
            }
            XCTAssertEqual(SessionMerge.merge(a, b), SessionMerge.merge(b, a))
        }
    }
}

final class ResolveConflictTests: XCTestCase {
    let eid = Fixture.uuid(100)
    let rest = RestSettings()

    func resolved(_ a: WorkoutSession, _ b: WorkoutSession, file: StaticString = #filePath, line: UInt = #line) -> WorkoutSession {
        let ab = SessionMerge.resolveConflict(a, b)
        XCTAssertEqual(ab, SessionMerge.resolveConflict(b, a), "must be symmetric", file: file, line: line)
        return ab
    }

    func testMoreLoggedSetsWins() {
        var a = Fixture.session(id: 1, startedAt: Fixture.at(0))
        var b = Fixture.session(id: 2, startedAt: Fixture.at(100))
        b.setReps(8, exerciseID: eid, setIndex: 0, rest: rest, now: Fixture.at(110))
        XCTAssertEqual(resolved(a, b).id, b.id, "later start but more sets")
        a.setReps(8, exerciseID: eid, setIndex: 0, rest: rest, now: Fixture.at(10))
        a.setReps(8, exerciseID: eid, setIndex: 1, rest: rest, now: Fixture.at(11))
        XCTAssertEqual(resolved(a, b).id, a.id)
    }

    func testTieGoesToEarlierStart() {
        let a = Fixture.session(id: 1, startedAt: Fixture.at(50))
        let b = Fixture.session(id: 2, startedAt: Fixture.at(10))
        XCTAssertEqual(resolved(a, b).id, Fixture.uuid(2))
    }

    func testTieThenPhoneThenSmallerID() {
        let phone = Fixture.session(id: 9, startedAt: Fixture.at(0), device: .phone)
        let watch = Fixture.session(id: 1, startedAt: Fixture.at(0), device: .watch)
        XCTAssertEqual(resolved(phone, watch).id, Fixture.uuid(9))
        let x = Fixture.session(id: 3, startedAt: Fixture.at(0), device: .watch)
        let y = Fixture.session(id: 2, startedAt: Fixture.at(0), device: .watch)
        XCTAssertEqual(resolved(x, y).id, Fixture.uuid(2))
    }
}
