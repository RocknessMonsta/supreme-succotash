import XCTest
@testable import LiftCore

final class StatsTests: XCTestCase {
    func testEpley() {
        XCTAssertEqual(Stats.estimatedOneRepMax(weight: 100, reps: 0), 0)
        XCTAssertEqual(Stats.estimatedOneRepMax(weight: 100, reps: 1), 100)
        XCTAssertEqual(Stats.estimatedOneRepMax(weight: 100, reps: 5), 100 * (1 + 5.0 / 30), accuracy: 1e-9)
        XCTAssertEqual(Stats.estimatedOneRepMax(weight: 135, reps: 8), 171, accuracy: 1e-9)
        XCTAssertEqual(Stats.estimatedOneRepMax(weight: 0, reps: 8), 0)
        XCTAssertEqual(Stats.estimatedOneRepMax(weight: 100, reps: -3), 0)
    }

    var history: [CompletedWorkout] {
        let bench = "barbell-bench-press"
        return [
            Fixture.workout(id: 3, finishedAt: Fixture.at(2 * 86_400), exercises: [
                Fixture.result(bench, weight: 110, reps: [8, 8, 6, nil]),
                Fixture.result("squat", weight: 200, reps: [8, 8, 8, 8]),
            ]),
            Fixture.workout(id: 1, finishedAt: Fixture.at(0), exercises: [
                Fixture.result(bench, weight: 100, reps: [8, 8, 8, 8]),
                Fixture.result("squat", weight: 150, reps: [8, 8, 8, 8], skipped: true),
            ]),
            Fixture.workout(id: 2, finishedAt: Fixture.at(86_400), exercises: [
                Fixture.result(bench, weight: 105, reps: [nil, nil, nil, nil]),
                Fixture.result("squat", weight: 155, reps: [8, 8, 8, 8]),
            ]),
        ]
    }

    func testSeriesIsOldestFirstAndAttemptedOnly() {
        let bench = Stats.series(for: "barbell-bench-press", in: history)
        XCTAssertEqual(bench.map(\.weight), [100, 110])
        XCTAssertEqual(bench.map(\.date), [Fixture.at(0), Fixture.at(2 * 86_400)])
        XCTAssertEqual(bench.map(\.success), [true, false])
        XCTAssertEqual(bench[0].estimated1RM, 100 * (1 + 8.0 / 30), accuracy: 1e-9)
        XCTAssertEqual(bench[1].estimated1RM, 110 * (1 + 8.0 / 30), accuracy: 1e-9, "best set")
        XCTAssertEqual(Stats.series(for: "squat", in: history).map(\.weight), [155, 200])
        XCTAssertTrue(Stats.series(for: "deadlift", in: history).isEmpty)
        XCTAssertTrue(Stats.series(for: "squat", in: []).isEmpty)
    }

    func testPersonalRecordsSortedByName() {
        let prs = Stats.personalRecords(in: history)
        XCTAssertEqual(prs.map(\.id), ["barbell-bench-press", "squat"])
        XCTAssertEqual(prs.map(\.exercise.name), ["Barbell Bench Press", "Squat"])
        XCTAssertEqual(prs[0].heaviestWeight, 110)
        XCTAssertEqual(prs[0].heaviestDate, Fixture.at(2 * 86_400))
        XCTAssertEqual(prs[0].best1RM, 110 * (1 + 8.0 / 30), accuracy: 1e-9)
        XCTAssertEqual(prs[1].heaviestWeight, 200)
        XCTAssertTrue(Stats.personalRecords(in: []).isEmpty)
    }

    func testPersonalRecordSeparatesHeaviestFromBest1RM() {
        let h = [
            Fixture.workout(id: 1, finishedAt: Fixture.at(0), exercises: [Fixture.result(weight: 100, reps: [8, 8, 8, 8])]),
            Fixture.workout(id: 2, finishedAt: Fixture.at(100), exercises: [Fixture.result(weight: 120, reps: [1, 0, nil, nil])]),
        ]
        let pr = Stats.personalRecords(in: h)[0]
        XCTAssertEqual(pr.heaviestWeight, 120)
        XCTAssertEqual(pr.heaviestDate, Fixture.at(100))
        XCTAssertEqual(pr.best1RM, 100 * (1 + 8.0 / 30), accuracy: 1e-9, "100 x 8 (126.7) beats 120 x 1")
        XCTAssertEqual(pr.best1RMDate, Fixture.at(0))
    }

    func testTotalVolume() {
        // bench 100*32 + 110*22 + 105*0, squat 200*32 + 150*32 + 155*32
        XCTAssertEqual(Stats.totalVolume(in: history), 3200 + 2420 + 6400 + 4800 + 4960)
        XCTAssertEqual(Stats.totalVolume(in: []), 0)
    }

    func testWorkoutsThisWeekAndStreak() {
        let cal = Fixture.utcCalendar
        let now = Fixture.t0  // Tuesday; Monday-based week starts 2023-11-13 00:00 UTC
        func w(_ id: Int, _ offsetDays: Double) -> CompletedWorkout {
            Fixture.workout(id: id, finishedAt: now.addingTimeInterval(offsetDays * 86_400), exercises: [])
        }
        let h = [w(1, 0), w(2, -1), w(3, -2), w(4, -7), w(5, -21)]
        XCTAssertEqual(Stats.workoutsThisWeek(in: h, now: now, calendar: cal), 2, "Sunday belongs to the previous week")
        XCTAssertEqual(Stats.currentStreakWeeks(in: h, now: now, calendar: cal), 2)
        // Nothing yet this week: streak still counts from last week.
        XCTAssertEqual(Stats.currentStreakWeeks(in: [w(4, -7), w(6, -14)], now: now, calendar: cal), 2)
        // A gap week breaks it.
        XCTAssertEqual(Stats.currentStreakWeeks(in: [w(4, -14)], now: now, calendar: cal), 0)
        XCTAssertEqual(Stats.currentStreakWeeks(in: [], now: now, calendar: cal), 0)
        XCTAssertEqual(Stats.workoutsThisWeek(in: [], now: now, calendar: cal), 0)
    }
}

final class CSVExporterTests: XCTestCase {
    func testHeaderAndRow() {
        let w = Fixture.workout(exercises: [Fixture.result(weight: 135, reps: [8, 8, 7, nil], note: "easy")])
        let lines = CSVExporter.csv(for: [w]).split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        XCTAssertEqual(lines[0], "Date,Workout,Exercise,Weight,Unit,Set 1,Set 2,Set 3,Set 4,Skipped,Notes")
        XCTAssertEqual(lines[1], "2023-11-14T22:13:20Z,Chest,Barbell Bench Press,135,lb,8,8,7,,false,easy")
        XCTAssertEqual(lines[2], "", "ends with a newline")
        XCTAssertEqual(lines.count, 3)
    }

    func testEmptyHistoryHasHeaderOnly() {
        XCTAssertEqual(CSVExporter.csv(for: []), "Date,Workout,Exercise,Weight,Unit,Set 1,Set 2,Set 3,Set 4,Skipped,Notes\n")
    }

    func testSetColumnsFollowMaxSetCountAndRowsArePadded() {
        let w = Fixture.workout(exercises: [
            Fixture.result(weight: 100, reps: [8, 8, 8, 8, 5, 3]),
            Fixture.result("squat", weight: 60.5, reps: [8, 8]),
        ])
        let lines = CSVExporter.csv(for: [w]).split(separator: "\n").map(String.init)
        XCTAssertEqual(lines[0], "Date,Workout,Exercise,Weight,Unit,Set 1,Set 2,Set 3,Set 4,Set 5,Set 6,Skipped,Notes")
        XCTAssertTrue(lines[1].hasSuffix(",100,lb,8,8,8,8,5,3,false,"))
        XCTAssertTrue(lines[2].hasSuffix(",Squat,60.5,lb,8,8,,,,,false,"))
        XCTAssertEqual(lines.map { $0.filter { $0 == "," }.count }, [12, 12, 12])
    }

    func testFewerThanFourSetsUsesActualMax() {
        let w = Fixture.workout(exercises: [Fixture.result(reps: [8, 8, 8])])
        XCTAssertTrue(CSVExporter.csv(for: [w]).hasPrefix("Date,Workout,Exercise,Weight,Unit,Set 1,Set 2,Set 3,Skipped,Notes\n"))
    }

    func testEscaping() {
        XCTAssertEqual(CSVExporter.escape("plain"), "plain")
        XCTAssertEqual(CSVExporter.escape("a,b"), "\"a,b\"")
        XCTAssertEqual(CSVExporter.escape("say \"hi\""), "\"say \"\"hi\"\"\"")
        XCTAssertEqual(CSVExporter.escape("two\nlines"), "\"two\nlines\"")
        XCTAssertEqual(CSVExporter.escape("cr\rhere"), "\"cr\rhere\"")
        XCTAssertEqual(CSVExporter.escape(""), "")

        let w = Fixture.workout(dayName: "Push, Pull", exercises: [Fixture.result(reps: [8, 8, 8, 8], skipped: true, note: "He said \"ok\", then\nstopped")])
        let csv = CSVExporter.csv(for: [w])
        XCTAssertTrue(csv.contains(",\"Push, Pull\","))
        XCTAssertTrue(csv.hasSuffix(",true,\"He said \"\"ok\"\", then\nstopped\"\n"))
    }

    func testRowsAreOldestFirst() {
        let a = Fixture.workout(id: 1, finishedAt: Fixture.at(0), dayName: "Old", exercises: [Fixture.result()])
        let b = Fixture.workout(id: 2, finishedAt: Fixture.at(86_400), dayName: "New", exercises: [Fixture.result()])
        let lines = CSVExporter.csv(for: [b, a]).split(separator: "\n").map(String.init)
        XCTAssertTrue(lines[1].contains(",Old,"))
        XCTAssertTrue(lines[2].contains(",New,"))
    }

    func testKgUnitColumn() {
        let w = Fixture.workout(unit: .kg, exercises: [Fixture.result(weight: 61.235)])
        XCTAssertTrue(CSVExporter.csv(for: [w]).contains(",61.24,kg,") || CSVExporter.csv(for: [w]).contains(",61.23,kg,"))
    }
}

final class AppStateStoreTests: XCTestCase {
    var dir: URL!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent("liftcore-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    func richState() -> AppState {
        var state = AppState.fresh()
        state.startWorkout(device: .watch, now: Fixture.t0)
        let eid = state.activeSession!.exercises[0].id
        state.activeSession!.setReps(8, exerciseID: eid, setIndex: 0, rest: state.settings.rest, now: Fixture.at(12.5))
        state.addTombstone(Fixture.uuid(42))
        state.history = [Fixture.workout(exercises: [Fixture.result(weight: 62.5, reps: [8, nil, 3, 0], note: "n")])]
        return state
    }

    func testMissingFileLoadsNil() {
        XCTAssertNil(AppStateStore(url: dir.appendingPathComponent("none.json")).load())
    }

    func testRoundTrip() throws {
        let store = AppStateStore(url: dir.appendingPathComponent("state.json"))
        let state = richState()
        try store.save(state)
        XCTAssertEqual(store.load(), state)
        // Overwrite works and leaves no temp files behind.
        var changed = state
        changed.settings.soundEnabled = false
        try store.save(changed)
        XCTAssertEqual(store.load(), changed)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: dir.path), ["state.json"])
    }

    func testSaveCreatesMissingDirectory() throws {
        let url = dir.appendingPathComponent("nested/deeper/state.json")
        try AppStateStore(url: url).save(.fresh())
        XCTAssertNotNil(AppStateStore(url: url).load())
    }

    func testCorruptFileIsMovedAside() throws {
        let url = dir.appendingPathComponent("state.json")
        try Data("{ definitely not json".utf8).write(to: url)
        let store = AppStateStore(url: url)
        XCTAssertNil(store.load())
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        let aside = dir.appendingPathComponent("state.json.corrupt")
        XCTAssertEqual(try String(contentsOf: aside, encoding: .utf8), "{ definitely not json")
        // The store is usable again afterwards.
        try store.save(.fresh())
        XCTAssertNotNil(store.load())
        // A second corruption replaces the earlier .corrupt copy.
        try Data("again".utf8).write(to: url)
        XCTAssertNil(store.load())
        XCTAssertEqual(try String(contentsOf: aside, encoding: .utf8), "again")
    }

    func testValidJSONOfWrongShapeIsTreatedAsCorrupt() throws {
        let url = dir.appendingPathComponent("state.json")
        try Data("{\"hello\": 1}".utf8).write(to: url)
        XCTAssertNil(AppStateStore(url: url).load())
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path + ".corrupt"))
    }

    func testDecoderAcceptsISO8601AndMilliseconds() throws {
        struct Box: Codable { var d: Date }
        let decoder = AppStateStore.makeDecoder()
        let ms = try decoder.decode(Box.self, from: Data("{\"d\":1700000000123}".utf8))
        XCTAssertEqual(ms.d, Date(timeIntervalSince1970: 1_700_000_000.123))
        let iso = try decoder.decode(Box.self, from: Data("{\"d\":\"2023-11-14T22:13:20Z\"}".utf8))
        XCTAssertEqual(iso.d, Fixture.t0)
        let frac = try decoder.decode(Box.self, from: Data("{\"d\":\"2023-11-14T22:13:20.500Z\"}".utf8))
        XCTAssertEqual(frac.d.timeIntervalSince1970, 1_700_000_000.5, accuracy: 0.001)
        XCTAssertThrowsError(try decoder.decode(Box.self, from: Data("{\"d\":\"yesterday\"}".utf8)))
    }

    func testDefaultURL() {
        let url = AppStateStore.defaultURL()
        XCTAssertEqual(url.lastPathComponent, "lift48-state.json")
        var isDir: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path, isDirectory: &isDir))
        XCTAssertTrue(isDir.boolValue)
        XCTAssertEqual(AppStateStore.defaultURL(fileName: "x.json").lastPathComponent, "x.json")
    }
}
