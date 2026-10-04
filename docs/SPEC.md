# Lift48 — Product & Architecture Spec

A StrongLifts-style tracker, rebuilt for **4 sets × 8 reps** and a **body-part split**
(3 exercises per body part) with a rest timer and a full Apple Watch companion.

## 1. Product rules

### 1.1 Program
- A workout = one body-part day = **3 exercises × 4 sets × 8 reps** (mirrors StrongLifts' 3 exercises per workout).
- Days rotate in order, like StrongLifts' A/B alternation. Default rotation:

| Day | Exercise 1 | Exercise 2 | Exercise 3 |
|---|---|---|---|
| Chest | Barbell Bench Press (barbell) | Incline Dumbbell Press (dumbbell) | Cable Fly (cable) |
| Back | Barbell Row (barbell) | Lat Pulldown (cable) | Seated Cable Row (cable) |
| Shoulders | Overhead Press (barbell) | Dumbbell Lateral Raise (dumbbell) | Reverse Pec Deck (machine) |
| Legs | Squat (barbell) | Romanian Deadlift (barbell) | Leg Press (machine) |
| Arms | Barbell Curl (barbell) | Triceps Pushdown (cable) | Hammer Curl (dumbbell) |

- The user can enable/disable/reorder days and swap any exercise from a built-in library
  (~40 exercises tagged by body part + equipment) or a custom one. Sets/reps stay 4×8 by default
  but are stored per exercise slot (so a future change isn't a migration).

### 1.2 Logging (StrongLifts parity)
- Each set is a circle. Tap empty → logged at target reps (8). Each further tap decrements
  (7, 6 … 0). Tapping at 0 clears it back to empty. Long-press a set to type reps directly.
- Weight shown per exercise; tap to edit for this session. Plate breakdown shown for barbell lifts.
- Warm-up sets for barbell exercises (StrongLifts style: 2×5 empty bar, then ~40%/60%/80% ramp,
  rounded to plates, skipped when too close to the work weight). Warm-ups are optional to tick.
- Per-exercise and per-workout notes. Elapsed workout timer.
- Exercise may be skipped (no progression change).

### 1.3 Progression
- Success = all 4 work sets ≥ target reps → next session weight += increment for that exercise.
- Default increments: barbell 5 lb / 2.5 kg; dumbbell 5 lb / 2 kg (per hand); cable/machine 5 lb / 2.5 kg;
  isolation lifts (fly, raises, curls, pushdown, reverse pec deck) 2.5 lb / 1 kg. Editable per exercise.
- Fail = any work set below target → same weight next time; consecutive-fail counter += 1.
- **3 consecutive failed sessions → deload 10%**, rounded down to the increment, never below the
  exercise's minimum (bar weight for barbell, 0 otherwise). Counter resets on success or deload.
- Skipped / not-attempted exercises don't change state.
- User can manually override next weight at any time.

### 1.4 Rest timer
- Auto-starts when a work set is logged: **90 s** if the set hit target, **180 s** if it missed;
  **300 s** after a second consecutive missed set in the same exercise. All configurable.
- Controls: −15 s / +15 s / skip. Shown as a banner on the workout screen.
- Timer is anchored to an absolute end `Date` (survives backgrounding, app kill, and device hand-off).
- When it ends: local notification (sound + haptic) if app is backgrounded; haptic in-app; on the Watch
  a strong haptic.
- Timer state is part of the live session and syncs phone ⇄ watch.

### 1.5 History & progress
- History list of completed workouts (date, day, duration, volume, per-exercise result ✓/✗).
  Tap to view/edit/delete. Edits do **not** retroactively re-run progression.
- Progress: per-exercise chart of work weight over time (Swift Charts), plus estimated 1RM
  (Epley) and total volume per workout. Personal records list.
- CSV export of full history (ShareLink).

### 1.6 Settings
Units (lb/kg, converting all stored weights and rounding to the new increment), bar weight,
available plates, dumbbell increment, rest durations, sound/haptics, Apple Health on/off,
rotation editor, per-exercise increment and next-weight override, reset program.

### 1.7 Apple Health
Completed workouts saved as `HKWorkoutActivityType.traditionalStrengthTraining` with duration and
energy. On the Watch, a live `HKWorkoutSession` runs during the workout (heart rate, calories,
keeps the app frontmost); the Watch is then the source of the Health workout and the phone does
not duplicate it.

### 1.8 Apple Watch
- Shows the next workout (day + 3 exercises + weights). Start a workout on the Watch, or follow
  one started on the phone.
- Per-exercise page: weight, plate summary, 4 set circles (same tap semantics, Digital Crown to
  adjust reps), rest timer ring with ±15 s/skip, heart rate.
- Finish / discard on Watch. Works fully offline from the phone; syncs when reachable.

## 2. Architecture

```
project.yml                     XcodeGen spec (iOS app + embedded watchOS app)
Packages/LiftCore/              Pure Swift package. Foundation only. Builds & tests on Linux.
  Sources/LiftCore/             Models, ExerciseLibrary, ProgramDefaults, ProgressionEngine,
                                PlateCalculator, WarmupCalculator, WorkoutSessionEngine,
                                RestTimerState, Stats (1RM, volume, PRs), CSVExporter,
                                Sync (messages + merge), AppState + AppStateStore (JSON)
  Tests/LiftCoreTests/
App/Shared/                     Platform glue shared by both apps (Apple frameworks allowed):
                                WatchSyncCoordinator (WatchConnectivity), RestTimerNotifier,
                                HealthKitService pieces, AppModel (@Observable wrapper around
                                AppState + engines + sync)
App/iOS/                        iOS SwiftUI app
App/Watch/                      watchOS SwiftUI app
```

- iOS 17+, watchOS 10+, Swift 5.10+/6 language mode compatible, SwiftUI + Observation + Swift Charts.
- **No third-party dependencies.**
- Persistence: a single Codable `AppState` (program, settings, history, active session) stored as
  JSON in Application Support with atomic writes. Each device keeps its own copy.
- `LiftCore` must not import SwiftUI/UIKit/WatchKit/HealthKit/WatchConnectivity and must compile on
  Linux (`swift test` in Docker). All non-trivial logic lives here so it is tested.

### 2.1 Sync protocol (phone ⇄ watch)
- **Phone is the authority** for program state (next weights, fail counters, rotation) and history.
- Phone → Watch: `updateApplicationContext` with a `WatchContext` snapshot (settings, program,
  next-workout preview, active session if any, last N history summaries). Sent on every change.
- Live session (either device may start/edit): each change sends the full `WorkoutSession` snapshot
  via `sendMessage` when reachable, else `transferUserInfo`. Every set and the rest timer carry an
  `updatedAt`; receivers **merge** (per-field last-writer-wins, deterministic tiebreak by device id),
  never blindly overwrite. Merge lives in LiftCore and is unit-tested.
- Session start conflict (both started different sessions while apart): keep the one with more
  logged sets; tie → earlier `startedAt`. Loser is discarded.
- Finish: the finishing device sends `CompletedWorkout` via `transferUserInfo` (guaranteed, queued).
  Phone applies progression exactly once (dedupe by workout id), appends history, pushes new context.
  Watch shows a provisional result locally until the new context arrives.
- Discard: `sessionDiscarded(id)` message; tombstoned ids are ignored if a late snapshot arrives.
- All payloads are Codable structs encoded as `Data` under a single key with a `schemaVersion`.

## 3. Quality bar
- `LiftCore` has unit tests for progression, deload, warm-ups, plates, tap cycling, rest durations,
  session merge, unit conversion, stats, CSV.
- App code must compile under Xcode 16 for iOS 17 / watchOS 10 (it cannot be compiled in CI here,
  so code is written conservatively and reviewed).
