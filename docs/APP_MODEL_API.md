# AppModel & LiftCore API — reference for UI work

Read `docs/SPEC.md` for product rules. This file is what views may call. **Views never mutate
`AppState` directly — only through `AppModel` intents.** Shared code lives in `App/Shared/`
(read `AppModel.swift` if anything here is unclear); logic lives in `Packages/LiftCore`.

## Getting the model
```swift
@Environment(AppModel.self) private var model        // injected at the App root
@Bindable var model = model                           // only if you need $bindings
```
`AppModel` is `@MainActor @Observable`. Both apps use `AppModel.shared`.

## Read-only properties
| Property | Meaning |
|---|---|
| `state: AppState` | Full persisted state (prefer the conveniences below) |
| `program: Program` | `days: [BodyPartDay]` in rotation order, `nextDay`, `enabledDays` |
| `settings: Settings` | unit, barWeight, availablePlates, dumbbellIncrement, `rest` (afterSuccess/afterFailure/afterRepeatedFailure seconds), warmupsEnabled, soundEnabled, hapticsEnabled, healthKitEnabled |
| `unit: WeightUnit` | `.lb` / `.kg`; `unit.symbol` |
| `history: [CompletedWorkout]` | newest first |
| `activeSession: WorkoutSession?` / `isWorkoutActive` | the live workout, if any (may have been started on the other device) |
| `nextDay: BodyPartDay?` | the day "Start workout" will use |
| `syncStatus: SyncStatus` | `isReachable`, `isPaired`, `isCounterpartInstalled`, `isActivated` |
| `health: HealthKitService` | Watch: `heartRate: Double?`, `activeEnergy: Double`, `isRunning` |
| `restFinishedCount: Int` | increments when a rest ends in-app (use `.onChange` to flash UI; haptic is already played) |
| `remoteCompletion: CompletedWorkout?` | other device finished a workout; show a toast/sheet, then set to nil |
| `activeSessionEndedRemotely: Bool` | other device finished/discarded the session on screen; dismiss workout UI, then set false |

## Helpers
- `model.now() -> Date`
- `model.restRemaining(at: Date) -> TimeInterval`
- `model.plates(for: weight) -> PlateLoad` → `.perSide: [Double]`, `.summary` ("45 + 25" / "Empty bar"), `.isExact`, `.remainder`
- `model.format(_ weight: Double) -> String` → "135 lb". `Weight.format(Double)` → "135" (no unit).
- `model.finishPreview() -> [UUID: (ProgressionOutcome, Double)]` keyed by `SessionExercise.id`:
  outcome `.increased / .repeated / .deloaded / .unchanged` and the next weight. Use on the finish confirmation.

## Workout intents
| Call | Effect |
|---|---|
| `startWorkout(dayID: UUID? = nil)` | starts `nextDay` (or a specific day). No-op if one is active. |
| `tapSet(exerciseID:setIndex:)` | StrongLifts tap cycle: empty → 8 → 7 … → 0 → empty. Starts the rest timer (90 s hit / 180 s miss / 300 s second miss), plays a haptic. |
| `setReps(_ reps: Int?, exerciseID:setIndex:)` | direct entry (long-press / crown). nil clears. |
| `setWeight(_:exerciseID:)` | this session's weight (rounded to loadable); regenerates warm-ups if none ticked |
| `toggleWarmup(exerciseID:index:)` | |
| `setSkipped(_:exerciseID:)` | skip / unskip exercise |
| `setExerciseNote(_:exerciseID:)`, `setWorkoutNote(_:)` | |
| `adjustRest(by: TimeInterval)` | ±15 s buttons; going below 0 stops it; + when idle starts one |
| `skipRest()` | |
| `finishWorkout() -> CompletedWorkout?` | applies progression, saves history, Health, syncs. Unlogged sets count as misses; an exercise with no sets logged counts as skipped. |
| `discardWorkout()` | deletes the session on both devices |

## Program / settings / history intents (iPhone only — the Watch must not edit these)
- `updateSettings { $0.rest.afterSuccess = 120 }` — any `Settings` change. Changing `unit` here converts every stored weight.
- `setUnit(.kg)`
- `updateProgram { program in ... }` with LiftCore helpers on `Program`:
  `moveDay(fromOffsets: IndexSet, toOffset: Int)`, `setDayEnabled(_ dayID: UUID, _ enabled: Bool)` (refuses to disable the last enabled day),
  `replaceExercise(slotID: UUID, with: Exercise, unit: WeightUnit)`, `setNextWeight(slotID:weight:)`, `setIncrement(slotID:increment:)`, `setNextDay(_ dayID: UUID)`.
  Read slots via `program.days[i].slots` (`ExerciseSlot`: `exercise`, `sets`, `targetReps`, `nextWeight`, `increment`, `consecutiveFailures`).
- `updateHistory(_ workout: CompletedWorkout)` / `deleteHistory(id:)` — doesn't re-run progression.
- `resetProgram(clearHistory: Bool = false)`
- `exportCSV() throws -> URL` — temp file, hand to `ShareLink(item: url)`.

## LiftCore types you will render
- `BodyPartDay`: `id, name, bodyPart (BodyPart: .chest … .core, .displayName), isEnabled, slots`
- `Exercise`: `id (slug), name, bodyPart, equipment (Equipment: .barbell/.dumbbell/.cable/.machine/.bodyweight, .usesPlates), isIsolation`
- `ExerciseLibrary.all`, `ExerciseLibrary.exercises(for: BodyPart)`, `ExerciseLibrary.exercise(id:)` — for the exercise picker.
- `WorkoutSession`: `id, dayName, bodyPart, startedAt, startedOn, unit, exercises: [SessionExercise], restTimer, note, loggedSetCount, isEveryExerciseComplete`
- `SessionExercise`: `id, exercise, weight, sets: [LoggedSet], warmups: [WarmupSet], isSkipped, note, targetReps, isComplete, isSuccess`
- `LoggedSet`: `reps: Int?` (nil = not done), `targetReps`, `isLogged`, `isSuccess`.
  Circle display: empty outline when nil; filled accent with "8" when success; filled red/orange with the reps number when a miss.
- `WarmupSet`: `weight, reps, isDone`
- `RestTimerState`: `endsAt: Date?`, `duration`, `remaining(at:)`, `isRunning(at:)`, `progress(at:)`.
- `CompletedWorkout`: `id, dayName, bodyPart, startedAt, finishedAt, duration, unit, exercises: [ExerciseResult], note, volume, isSuccess, finishedOn`
- `ExerciseResult`: `exercise, weight, targetReps, reps: [Int?], isSkipped, note, wasAttempted, isSuccess, volume, totalReps`
- `Stats`: `estimatedOneRepMax(weight:reps:)`, `series(for exerciseID: String, in: history) -> [Stats.WeightPoint]` (date, weight, estimated1RM, success; oldest first),
  `personalRecords(in: history) -> [Stats.PersonalRecord]` (exercise, heaviestWeight, heaviestDate, best1RM, best1RMDate), `totalVolume(in:)`, `workoutsThisWeek(in:now:calendar:)`.
- `ProgramDefaults.sets` (4), `ProgramDefaults.targetReps` (8).

## Rest timer display — important
The timer is an absolute `endsAt` date. **Never** run your own countdown state. Render with
```swift
TimelineView(.periodic(from: .now, by: 1)) { ctx in
    let remaining = session.restTimer.remaining(at: ctx.date)
    ...
}
```
or `Text(timerInterval: Date.now...endsAt, countsDown: true)`. Show the banner only while
`restTimer.isRunning(at: ctx.date)`. Haptics and the background notification are already handled by `AppModel`.

## Gotchas
- `activeSession` can appear/disappear because of the other device; drive navigation from it
  (e.g. present the workout screen when `isWorkoutActive`), not from local flags.
- Weights are in `settings.unit`. Dumbbell weights are per hand.
- Use `Weight.format` for numbers — never `String(describing:)` on a Double.
- Target iOS 17 / watchOS 10 APIs only. No third-party packages. `import LiftCore` in every file that uses its types.
- App code cannot be compiled in this environment: write conservative SwiftUI, double-check every API name and signature, exhaustive switches, and `@MainActor` correctness.
