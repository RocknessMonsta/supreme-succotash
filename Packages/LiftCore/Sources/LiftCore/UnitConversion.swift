import Foundation

extension AppState {
    /// Converts every stored weight (settings, program, history, active session) to `unit`.
    /// Settings weights become the new unit's defaults; non-weight settings are preserved.
    /// Slot increments reset to the new unit's defaults. No-op if already in `unit`.
    public mutating func convertUnits(to unit: WeightUnit) {
        let old = settings.unit
        guard old != unit else { return }
        let factor = old.factor(to: unit)

        var new = Settings.defaults(for: unit)
        new.rest = settings.rest
        new.warmupsEnabled = settings.warmupsEnabled
        new.soundEnabled = settings.soundEnabled
        new.hapticsEnabled = settings.hapticsEnabled
        new.healthKitEnabled = settings.healthKitEnabled
        settings = new

        for d in program.days.indices {
            for s in program.days[d].slots.indices {
                var slot = program.days[d].slots[s]
                slot.nextWeight = Weight.loadable(slot.nextWeight * factor, equipment: slot.exercise.equipment, settings: new)
                slot.increment = ProgramDefaults.defaultIncrement(for: slot.exercise, unit: unit)
                program.days[d].slots[s] = slot
            }
        }

        for w in history.indices {
            // A workout stored in a different unit than the old setting is converted from its own unit.
            let f = history[w].unit.factor(to: unit)
            for e in history[w].exercises.indices {
                history[w].exercises[e].weight = Weight.clean(history[w].exercises[e].weight * f)
            }
            history[w].unit = unit
        }

        if let session = activeSession {
            activeSession = session.converted(to: unit, settings: new)
        }
    }
}

extension WorkoutSession {
    /// The same session with weights and warm-ups expressed in `unit`, rounded to loadable weights
    /// for `settings`. Deterministic, so both devices produce identical values. Timestamps are kept.
    public func converted(to unit: WeightUnit, settings: Settings) -> WorkoutSession {
        guard self.unit != unit else { return self }
        let f = self.unit.factor(to: unit)
        var session = self
        for e in session.exercises.indices {
            let equipment = session.exercises[e].exercise.equipment
            session.exercises[e].weight = Weight.loadable(session.exercises[e].weight * f, equipment: equipment, settings: settings)
            for w in session.exercises[e].warmups.indices {
                let warm = session.exercises[e].warmups[w].weight * f
                session.exercises[e].warmups[w].weight = Weight.loadable(warm, equipment: .barbell, settings: settings)
            }
        }
        session.unit = unit
        return session
    }
}
