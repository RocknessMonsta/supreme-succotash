import Foundation

// MARK: - Creating sessions

public enum WorkoutEngine {
    public static func makeSession(for day: BodyPartDay, settings: Settings, device: DeviceKind, now: Date, id: UUID = UUID()) -> WorkoutSession {
        let exercises = day.slots.map { slot -> SessionExercise in
            let sets = (0..<max(1, slot.sets)).map { _ in LoggedSet(targetReps: slot.targetReps, updatedAt: now) }
            let warmups = WarmupCalculator.plan(workWeight: slot.nextWeight, equipment: slot.exercise.equipment, settings: settings)
                .map { WarmupSet(weight: $0.weight, reps: $0.reps, updatedAt: now) }
            return SessionExercise(id: slot.id, exercise: slot.exercise, weight: slot.nextWeight, sets: sets, warmups: warmups, createdAt: now)
        }
        return WorkoutSession(
            id: id, dayID: day.id, dayName: day.name, bodyPart: day.bodyPart,
            startedAt: now, startedOn: device, unit: settings.unit, exercises: exercises
        )
    }

    /// Rest after logging set `setIndex`: success → afterSuccess; a miss → afterFailure, or
    /// afterRepeatedFailure if the previous logged set in this exercise also missed.
    public static func restDuration(afterLogging setIndex: Int, in exercise: SessionExercise, rest: RestSettings) -> TimeInterval {
        guard exercise.sets.indices.contains(setIndex) else { return rest.afterSuccess }
        let set = exercise.sets[setIndex]
        if set.isSuccess { return rest.afterSuccess }
        let previousMissed = exercise.sets[..<setIndex].last(where: \.isLogged).map { !$0.isSuccess } ?? false
        return previousMissed ? rest.afterRepeatedFailure : rest.afterFailure
    }
}

// MARK: - Mutating a live session

extension WorkoutSession {
    private mutating func withExercise(_ id: UUID, _ change: (inout SessionExercise) -> Void) {
        guard let i = exercises.firstIndex(where: { $0.id == id }) else { return }
        change(&exercises[i])
    }

    /// StrongLifts tap: empty → target → … → 0 → empty. Starts/stops the rest timer.
    public mutating func tapSet(exerciseID: UUID, setIndex: Int, rest: RestSettings, now: Date) {
        guard let e = exercises.first(where: { $0.id == exerciseID }), e.sets.indices.contains(setIndex) else { return }
        let next = LoggedSet.nextRepsAfterTap(e.sets[setIndex].reps, target: e.sets[setIndex].targetReps)
        setReps(next, exerciseID: exerciseID, setIndex: setIndex, rest: rest, now: now)
    }

    /// Sets reps directly (nil clears). Logging a set (re)starts the rest timer; clearing it stops it.
    public mutating func setReps(_ reps: Int?, exerciseID: UUID, setIndex: Int, rest: RestSettings, now: Date) {
        var duration: TimeInterval?
        withExercise(exerciseID) { e in
            guard e.sets.indices.contains(setIndex) else { return }
            e.sets[setIndex].reps = reps.map { max(0, $0) }
            e.sets[setIndex].updatedAt = now
            if reps != nil {
                // Logging a set implies the exercise isn't skipped.
                if e.isSkipped { e.isSkipped = false; e.skippedUpdatedAt = now }
                duration = WorkoutEngine.restDuration(afterLogging: setIndex, in: e, rest: rest)
            }
        }
        if let duration { startRest(duration: duration, now: now) } else { skipRest(now: now) }
    }

    /// Changes this session's working weight. Regenerates warm-ups if none have been ticked yet.
    public mutating func setWeight(_ weight: Double, exerciseID: UUID, settings: Settings, now: Date) {
        withExercise(exerciseID) { e in
            let w = Weight.loadable(weight, equipment: e.exercise.equipment, settings: settings)
            e.weight = w
            e.weightUpdatedAt = now
            if !e.warmups.contains(where: \.isDone) {
                e.warmups = WarmupCalculator.plan(workWeight: w, equipment: e.exercise.equipment, settings: settings)
                    .map { WarmupSet(weight: $0.weight, reps: $0.reps, updatedAt: now) }
            }
        }
    }

    public mutating func toggleWarmup(exerciseID: UUID, index: Int, now: Date) {
        withExercise(exerciseID) { e in
            guard e.warmups.indices.contains(index) else { return }
            e.warmups[index].isDone.toggle()
            e.warmups[index].updatedAt = now
        }
    }

    public mutating func setSkipped(_ skipped: Bool, exerciseID: UUID, now: Date) {
        withExercise(exerciseID) { e in
            e.isSkipped = skipped
            e.skippedUpdatedAt = now
        }
    }

    public mutating func setNote(_ note: String, exerciseID: UUID, now: Date) {
        withExercise(exerciseID) { e in
            e.note = note
            e.noteUpdatedAt = now
        }
    }

    public mutating func setWorkoutNote(_ text: String, now: Date) {
        note = text
        noteUpdatedAt = now
    }

    public mutating func startRest(duration: TimeInterval, now: Date) {
        restTimer = RestTimerState(endsAt: now.addingTimeInterval(duration), duration: duration, updatedAt: now)
    }

    /// Adds/removes time. Removing past zero stops the timer.
    public mutating func adjustRest(by delta: TimeInterval, now: Date) {
        guard let endsAt = restTimer.endsAt, restTimer.isRunning(at: now) else {
            if delta > 0 { startRest(duration: delta, now: now) }
            return
        }
        let newEnd = endsAt.addingTimeInterval(delta)
        if newEnd <= now {
            skipRest(now: now)
        } else {
            restTimer = RestTimerState(endsAt: newEnd, duration: max(1, restTimer.duration + delta), updatedAt: now)
        }
    }

    public mutating func skipRest(now: Date) {
        restTimer = .idle(at: now)
    }

    /// Snapshot as a history entry. Unlogged sets stay nil.
    public func completed(finishedAt: Date, device: DeviceKind) -> CompletedWorkout {
        CompletedWorkout(
            id: id, dayID: dayID, dayName: dayName, bodyPart: bodyPart,
            startedAt: startedAt, finishedAt: max(finishedAt, startedAt), unit: unit,
            exercises: exercises.map {
                ExerciseResult(
                    id: $0.id, exercise: $0.exercise, weight: $0.weight, targetReps: $0.targetReps,
                    reps: $0.sets.map(\.reps), isSkipped: $0.isSkipped, note: $0.note
                )
            },
            note: note,
            finishedOn: device
        )
    }
}

// MARK: - App-level transitions

extension AppState {
    /// Starts the next (or a specific) day. Returns the existing session if one is already active.
    @discardableResult
    public mutating func startWorkout(dayID: UUID? = nil, device: DeviceKind, now: Date) -> WorkoutSession? {
        if let activeSession { return activeSession }
        let day = dayID.flatMap { id in program.days.first { $0.id == id } } ?? program.nextDay
        guard let day else { return nil }
        let session = WorkoutEngine.makeSession(for: day, settings: settings, device: device, now: now)
        activeSession = session
        return session
    }

    /// Ends the active session, applies progression and records history.
    @discardableResult
    public mutating func finishActiveWorkout(device: DeviceKind, now: Date) -> CompletedWorkout? {
        guard let session = activeSession else { return nil }
        let workout = session.completed(finishedAt: now, device: device)
        applyCompleted(workout)
        return workout
    }

    /// Idempotently records a completed workout (from this device or the other one): applies
    /// progression, advances rotation, prepends history, and clears the matching active session.
    /// Returns false if it had already been applied.
    @discardableResult
    public mutating func applyCompleted(_ workout: CompletedWorkout) -> Bool {
        if activeSession?.id == workout.id { activeSession = nil }
        guard !hasHistory(id: workout.id) else { return false }

        // A workout finished on the other device before a unit change is stored in the current unit.
        var workout = workout
        let factor = workout.unit.factor(to: settings.unit)
        if factor != 1 {
            for i in workout.exercises.indices {
                workout.exercises[i].weight = Weight.clean(workout.exercises[i].weight * factor)
            }
            workout.unit = settings.unit
        }
        for result in workout.exercises {
            program.updateSlot(id: result.id) { slot in
                ProgressionEngine.apply(result, to: &slot, settings: settings)
            }
        }
        if program.days.contains(where: { $0.id == workout.dayID }) {
            program.nextDayID = program.day(after: workout.dayID)?.id
        }
        history.append(workout)
        history.sort { $0.finishedAt > $1.finishedAt }
        return true
    }

    /// Discards the active session and tombstones it so a late sync can't resurrect it.
    @discardableResult
    public mutating func discardActiveWorkout() -> UUID? {
        guard let id = activeSession?.id else { return nil }
        activeSession = nil
        addTombstone(id)
        return id
    }

    /// Edit or delete history without re-running progression.
    public mutating func updateHistory(_ workout: CompletedWorkout) {
        guard let i = history.firstIndex(where: { $0.id == workout.id }) else { return }
        history[i] = workout
        history.sort { $0.finishedAt > $1.finishedAt }
    }

    public mutating func deleteHistory(id: UUID) {
        history.removeAll { $0.id == id }
    }
}
