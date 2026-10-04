import XCTest
@testable import LiftCore

final class ExerciseLibraryTests: XCTestCase {
    func testSizeAndUniqueKebabIDs() {
        XCTAssertGreaterThanOrEqual(ExerciseLibrary.all.count, 40)
        let ids = ExerciseLibrary.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
        for id in ids {
            XCTAssertNotNil(id.range(of: "^[a-z0-9]+(-[a-z0-9]+)*$", options: .regularExpression), id)
        }
        XCTAssertEqual(Set(ExerciseLibrary.all.map(\.name)).count, ids.count)
    }

    func testEveryBodyPartIsCovered() {
        for part in BodyPart.allCases {
            XCTAssertGreaterThanOrEqual(ExerciseLibrary.exercises(for: part).count, 4, part.rawValue)
            XCTAssertTrue(ExerciseLibrary.exercises(for: part).allSatisfy { $0.bodyPart == part })
        }
    }

    func testRequiredDefaultProgramIDsAndEquipment() {
        let expected: [String: (BodyPart, Equipment)] = [
            "barbell-bench-press": (.chest, .barbell), "incline-dumbbell-press": (.chest, .dumbbell), "cable-fly": (.chest, .cable),
            "barbell-row": (.back, .barbell), "lat-pulldown": (.back, .cable), "seated-cable-row": (.back, .cable),
            "overhead-press": (.shoulders, .barbell), "dumbbell-lateral-raise": (.shoulders, .dumbbell), "reverse-pec-deck": (.shoulders, .machine),
            "squat": (.legs, .barbell), "romanian-deadlift": (.legs, .barbell), "leg-press": (.legs, .machine),
            "barbell-curl": (.arms, .barbell), "triceps-pushdown": (.arms, .cable), "hammer-curl": (.arms, .dumbbell),
        ]
        for (id, (part, equipment)) in expected {
            let e = ExerciseLibrary.exercise(id: id)
            XCTAssertEqual(e?.bodyPart, part, id)
            XCTAssertEqual(e?.equipment, equipment, id)
        }
    }

    func testIsolationFlags() {
        for id in ["cable-fly", "dumbbell-lateral-raise", "reverse-pec-deck", "barbell-curl", "triceps-pushdown", "hammer-curl"] {
            XCTAssertEqual(ExerciseLibrary.exercise(id: id)?.isIsolation, true, id)
        }
        for id in ["barbell-bench-press", "squat", "barbell-row", "lat-pulldown", "leg-press", "deadlift", "pull-up"] {
            XCTAssertEqual(ExerciseLibrary.exercise(id: id)?.isIsolation, false, id)
        }
    }

    func testLookup() {
        XCTAssertEqual(ExerciseLibrary.exercise(id: "squat")?.name, "Squat")
        XCTAssertNil(ExerciseLibrary.exercise(id: "nope"))
    }
}

final class ProgramDefaultsTests: XCTestCase {
    func testIncrements() {
        func inc(_ id: String, _ unit: WeightUnit) -> Double { ProgramDefaults.defaultIncrement(for: Fixture.exercise(id), unit: unit) }
        XCTAssertEqual(inc("barbell-bench-press", .lb), 5)
        XCTAssertEqual(inc("barbell-bench-press", .kg), 2.5)
        XCTAssertEqual(inc("barbell-curl", .lb), 5, "barbell step even for isolation")
        XCTAssertEqual(inc("barbell-curl", .kg), 2.5)
        XCTAssertEqual(inc("incline-dumbbell-press", .lb), 5)
        XCTAssertEqual(inc("incline-dumbbell-press", .kg), 2)
        XCTAssertEqual(inc("lat-pulldown", .lb), 5)
        XCTAssertEqual(inc("lat-pulldown", .kg), 2.5)
        XCTAssertEqual(inc("leg-press", .kg), 2.5)
        XCTAssertEqual(inc("cable-fly", .lb), 2.5)
        XCTAssertEqual(inc("cable-fly", .kg), 1)
        XCTAssertEqual(inc("dumbbell-lateral-raise", .lb), 2.5)
        XCTAssertEqual(inc("hammer-curl", .kg), 1)
        XCTAssertEqual(inc("reverse-pec-deck", .lb), 2.5)
        XCTAssertEqual(inc("triceps-pushdown", .kg), 1)
        XCTAssertEqual(inc("pull-up", .lb), 0)
    }

    func testStartingWeights() {
        func start(_ id: String, _ unit: WeightUnit) -> Double { ProgramDefaults.startingWeight(for: Fixture.exercise(id), unit: unit) }
        XCTAssertEqual(start("barbell-bench-press", .lb), 45)
        XCTAssertEqual(start("barbell-bench-press", .kg), 20)
        XCTAssertEqual(start("overhead-press", .kg), 20)
        XCTAssertEqual(start("squat", .lb), 65)
        XCTAssertEqual(start("romanian-deadlift", .kg), 30)
        XCTAssertEqual(start("leg-press", .lb), 90)
        XCTAssertEqual(start("leg-press", .kg), 40)
        XCTAssertEqual(start("incline-dumbbell-press", .lb), 20)
        XCTAssertEqual(start("incline-dumbbell-press", .kg), 8)
        XCTAssertEqual(start("pull-up", .lb), 0)
    }

    func testEveryStartingWeightIsLoadableAndAtLeastTheMinimum() {
        for unit in WeightUnit.allCases {
            let settings = Settings.defaults(for: unit)
            for e in ExerciseLibrary.all {
                let w = ProgramDefaults.startingWeight(for: e, unit: unit)
                XCTAssertEqual(Weight.loadable(w, equipment: e.equipment, settings: settings), w, "\(e.id) \(unit)")
                if e.equipment == .barbell {
                    XCTAssertTrue(PlateCalculator.load(for: w, settings: settings).isExact, "\(e.id) \(unit)")
                }
            }
        }
    }

    func testEveryIncrementCanActuallyProgress() {
        for unit in WeightUnit.allCases {
            let settings = Settings.defaults(for: unit)
            for e in ExerciseLibrary.all where e.equipment != .bodyweight {
                let start = ProgramDefaults.startingWeight(for: e, unit: unit)
                var slot = ProgramDefaults.makeSlot(for: e, unit: unit)
                let r = ExerciseResult(id: slot.id, exercise: e, weight: start, targetReps: 8, reps: [8, 8, 8, 8], isSkipped: false)
                ProgressionEngine.apply(r, to: &slot, settings: settings)
                XCTAssertGreaterThan(slot.nextWeight, start, "\(e.id) \(unit) would never progress")
            }
        }
    }

    func testMakeSlot() {
        let slot = ProgramDefaults.makeSlot(for: Fixture.exercise("squat"), unit: .kg)
        XCTAssertEqual(slot.nextWeight, 30)
        XCTAssertEqual(slot.increment, 2.5)
        XCTAssertEqual(slot.sets, 4)
        XCTAssertEqual(slot.targetReps, 8)
        XCTAssertEqual(slot.consecutiveFailures, 0)
    }

    func testDefaultProgramMatchesSpecTable() {
        for unit in WeightUnit.allCases {
            let p = ProgramDefaults.program(unit: unit)
            XCTAssertEqual(p.days.map(\.name), ["Chest", "Back", "Shoulders", "Legs", "Arms"])
            XCTAssertEqual(p.days.map(\.bodyPart), [.chest, .back, .shoulders, .legs, .arms])
            XCTAssertTrue(p.days.allSatisfy(\.isEnabled))
            XCTAssertEqual(p.nextDayID, p.days[0].id)
            XCTAssertEqual(p.days.map { $0.slots.map(\.exercise.id) }, [
                ["barbell-bench-press", "incline-dumbbell-press", "cable-fly"],
                ["barbell-row", "lat-pulldown", "seated-cable-row"],
                ["overhead-press", "dumbbell-lateral-raise", "reverse-pec-deck"],
                ["squat", "romanian-deadlift", "leg-press"],
                ["barbell-curl", "triceps-pushdown", "hammer-curl"],
            ])
            let allSlots = p.days.flatMap(\.slots)
            XCTAssertEqual(Set(allSlots.map(\.id)).count, 15)
            XCTAssertEqual(Set(p.days.map(\.id)).count, 5)
            XCTAssertTrue(allSlots.allSatisfy { $0.sets == 4 && $0.targetReps == 8 && $0.consecutiveFailures == 0 })
        }
    }

    func testFreshState() {
        let s = AppState.fresh(unit: .kg)
        XCTAssertEqual(s.settings, Settings.defaults(for: .kg))
        XCTAssertEqual(s.program.days.count, 5)
        XCTAssertEqual(s.program.nextDay?.name, "Chest")
        XCTAssertTrue(s.history.isEmpty)
    }
}
