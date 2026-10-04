import XCTest
@testable import LiftCore

final class ProgramEditingTests: XCTestCase {
    var program = ProgramDefaults.program(unit: .lb)
    var ids: [UUID] { program.days.map(\.id) }

    func testMoveDayMatchesSwiftUISemantics() {
        let o = ids
        var p = program
        p.moveDay(fromOffsets: IndexSet(integer: 0), toOffset: 3)
        XCTAssertEqual(p.days.map(\.id), [o[1], o[2], o[0], o[3], o[4]])

        p = program
        p.moveDay(fromOffsets: IndexSet(integer: 3), toOffset: 0)
        XCTAssertEqual(p.days.map(\.id), [o[3], o[0], o[1], o[2], o[4]])

        p = program
        p.moveDay(fromOffsets: IndexSet(integer: 0), toOffset: 5)
        XCTAssertEqual(p.days.map(\.id), [o[1], o[2], o[3], o[4], o[0]])

        p = program
        p.moveDay(fromOffsets: IndexSet([0, 1]), toOffset: 5)
        XCTAssertEqual(p.days.map(\.id), [o[2], o[3], o[4], o[0], o[1]])

        p = program
        p.moveDay(fromOffsets: IndexSet([1, 3]), toOffset: 0)
        XCTAssertEqual(p.days.map(\.id), [o[1], o[3], o[0], o[2], o[4]])

        p = program
        p.moveDay(fromOffsets: IndexSet([0, 4]), toOffset: 2)
        XCTAssertEqual(p.days.map(\.id), [o[1], o[0], o[4], o[2], o[3]])
    }

    func testMoveDayNoOpsAndBounds() {
        let o = ids
        var p = program
        p.moveDay(fromOffsets: IndexSet(integer: 1), toOffset: 1)
        p.moveDay(fromOffsets: IndexSet(integer: 1), toOffset: 2)
        XCTAssertEqual(p.days.map(\.id), o)
        p.moveDay(fromOffsets: IndexSet(integer: 99), toOffset: 0)
        p.moveDay(fromOffsets: IndexSet(), toOffset: 0)
        p.moveDay(fromOffsets: IndexSet(integer: 0), toOffset: 99)
        XCTAssertEqual(p.days.map(\.id), [o[1], o[2], o[3], o[4], o[0]])
        XCTAssertEqual(p.nextDayID, o[0], "the next day follows its day, not its position")
    }

    func testDisableNextDayMovesPointerForward() {
        let o = ids
        program.setDayEnabled(o[0], false)
        XCTAssertFalse(program.days[0].isEnabled)
        XCTAssertEqual(program.nextDayID, o[1])
        XCTAssertEqual(program.nextDay?.id, o[1])
    }

    func testDisablingOtherDayLeavesNextDay() {
        let o = ids
        program.setDayEnabled(o[2], false)
        XCTAssertEqual(program.nextDayID, o[0])
    }

    func testDisablingNextDayWrapsPastDisabledDays() {
        let o = ids
        program.setNextDay(o[4])
        program.setDayEnabled(o[0], false)
        program.setDayEnabled(o[4], false)
        XCTAssertEqual(program.nextDayID, o[1])
    }

    func testCannotDisableLastEnabledDay() {
        let o = ids
        for id in o.dropFirst() { program.setDayEnabled(id, false) }
        XCTAssertEqual(program.enabledDays.count, 1)
        program.setDayEnabled(o[0], false)
        XCTAssertEqual(program.enabledDays.map(\.id), [o[0]])
        XCTAssertEqual(program.nextDayID, o[0])
    }

    func testReEnableAndUnknownIDs() {
        let o = ids
        program.setDayEnabled(o[1], false)
        program.setDayEnabled(o[1], true)
        XCTAssertTrue(program.days[1].isEnabled)
        let before = program
        program.setDayEnabled(Fixture.uuid(12345), false)
        XCTAssertEqual(program, before)
    }

    func testReplaceExerciseResetsProgression() {
        let slot = program.days[0].slots[0]
        program.updateSlot(id: slot.id) { $0.consecutiveFailures = 2; $0.nextWeight = 200; $0.increment = 10 }
        program.replaceExercise(slotID: slot.id, with: Fixture.exercise("deadlift"), unit: .lb)
        let new = program.slot(id: slot.id)!
        XCTAssertEqual(new.id, slot.id)
        XCTAssertEqual(new.exercise.id, "deadlift")
        XCTAssertEqual(new.nextWeight, 95)
        XCTAssertEqual(new.increment, 5)
        XCTAssertEqual(new.consecutiveFailures, 0)
        XCTAssertEqual(new.sets, 4)
        XCTAssertEqual(program.days[0].slots[0].id, slot.id, "position is kept")

        program.replaceExercise(slotID: slot.id, with: Fixture.exercise("cable-curl"), unit: .kg)
        XCTAssertEqual(program.slot(id: slot.id)?.nextWeight, 15)
        XCTAssertEqual(program.slot(id: slot.id)?.increment, 1)
    }

    func testSetNextWeightAndIncrement() {
        let id = program.days[1].slots[2].id
        program.setNextWeight(slotID: id, weight: 62.5)
        program.setIncrement(slotID: id, increment: 2.5)
        XCTAssertEqual(program.slot(id: id)?.nextWeight, 62.5)
        XCTAssertEqual(program.slot(id: id)?.increment, 2.5)
        program.setNextWeight(slotID: id, weight: -10)
        program.setIncrement(slotID: id, increment: -1)
        XCTAssertEqual(program.slot(id: id)?.nextWeight, 0)
        XCTAssertEqual(program.slot(id: id)?.increment, 0)
        let before = program
        program.setNextWeight(slotID: Fixture.uuid(9), weight: 5)
        XCTAssertEqual(program, before)
    }

    func testSetNextDay() {
        let o = ids
        program.setNextDay(o[3])
        XCTAssertEqual(program.nextDay?.id, o[3])
        program.setDayEnabled(o[2], false)
        program.setNextDay(o[2])
        XCTAssertEqual(program.nextDayID, o[3], "disabled days are ignored")
        program.setNextDay(Fixture.uuid(4))
        XCTAssertEqual(program.nextDayID, o[3])
    }
}
