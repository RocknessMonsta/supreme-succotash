import Foundation

extension Program {
    /// Same semantics as SwiftUI's `move(fromOffsets:toOffset:)`.
    public mutating func moveDay(fromOffsets source: IndexSet, toOffset destination: Int) {
        let valid = source.filter { days.indices.contains($0) }
        guard !valid.isEmpty else { return }
        let moving = valid.sorted().map { days[$0] }
        var remaining: [BodyPartDay] = []
        for (i, day) in days.enumerated() where !valid.contains(i) { remaining.append(day) }
        let clamped = min(max(destination, 0), days.count)
        let insertAt = clamped - valid.filter { $0 < clamped }.count
        remaining.insert(contentsOf: moving, at: insertAt)
        days = remaining
    }

    /// Enables/disables a day. The last enabled day can't be disabled. If `nextDayID` pointed at a
    /// day that is now disabled it moves to the next enabled day in rotation.
    public mutating func setDayEnabled(_ id: UUID, _ enabled: Bool) {
        guard let index = days.firstIndex(where: { $0.id == id }) else { return }
        if !enabled {
            guard days[index].isEnabled, enabledDays.count > 1 else { return }
        }
        days[index].isEnabled = enabled
        if !enabled, nextDayID == id {
            nextDayID = day(after: id)?.id
        }
        if nextDayID == nil || !days.contains(where: { $0.id == nextDayID && $0.isEnabled }) {
            nextDayID = enabledDays.first?.id
        }
    }

    /// Swaps the exercise in a slot, keeping the slot id and resetting its progression state.
    public mutating func replaceExercise(slotID: UUID, with exercise: Exercise, unit: WeightUnit) {
        updateSlot(id: slotID) { slot in
            slot.exercise = exercise
            slot.nextWeight = ProgramDefaults.startingWeight(for: exercise, unit: unit)
            slot.increment = ProgramDefaults.defaultIncrement(for: exercise, unit: unit)
            slot.consecutiveFailures = 0
        }
    }

    /// Manual override of the next session's weight (clamped to >= 0).
    public mutating func setNextWeight(slotID: UUID, weight: Double) {
        updateSlot(id: slotID) { $0.nextWeight = max(0, Weight.clean(weight)) }
    }

    public mutating func setIncrement(slotID: UUID, increment: Double) {
        updateSlot(id: slotID) { $0.increment = max(0, Weight.clean(increment)) }
    }

    /// Chooses the next day. Ignored if the day doesn't exist or is disabled.
    public mutating func setNextDay(_ id: UUID) {
        guard days.contains(where: { $0.id == id && $0.isEnabled }) else { return }
        nextDayID = id
    }
}
