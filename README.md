# Lift48

A StrongLifts-style strength tracker for iPhone and Apple Watch, rebuilt around
**4 sets × 8 reps** and a **body-part split**. Each workout is one body-part day with 3 exercises.
The default rotation is Chest → Back → Shoulders → Legs → Arms.

## Features
- Tap-to-log set circles: tap once for 8 reps, tap again to count down a missed set.
- Automatic progression: hit 4×8 and the weight goes up next time. Fail three sessions in a row and it deloads 10%.
- Rest timer that starts itself: 90 s after a good set, 3 min after a miss, 5 min after a second miss.
  It keeps running in the background and alerts you with a notification and haptics.
- Warm-up sets and a plate calculator for barbell lifts.
- History, per-exercise progress charts, personal records and CSV export.
- Program editor: reorder or disable days, swap exercises, set increments and next weights.
- Apple Watch app: start or follow a workout, log sets, run the rest timer, see heart rate.
  It works away from the phone and syncs when the two reconnect.
- Apple Health: workouts are saved as Traditional Strength Training.

## Project layout
| Path | What it is |
|---|---|
| `Packages/LiftCore` | All workout logic as a pure Swift package with unit tests |
| `App/Shared` | App model, Watch sync, HealthKit, notifications. Compiled into both apps |
| `App/iOS` | iPhone SwiftUI app |
| `App/Watch` | watchOS SwiftUI app |
| `project.yml` | XcodeGen spec that generates `Lift48.xcodeproj` |
| `docs/` | Product spec and the app model API reference |

## Build and run (Mac)
Requirements: Xcode 16 or newer, iOS 17+, watchOS 10+.

```bash
brew install xcodegen
xcodegen generate
open Lift48.xcodeproj
```

1. In Xcode, select the **Lift48** target, open *Signing & Capabilities* and pick your team.
   Do the same for **Lift48Watch**.
2. If your team needs unique bundle ids, change `com.example.lift48` in `project.yml`.
   Keep the watch id as `<phone id>.watchkitapp` and update `WKCompanionAppBundleIdentifier` to match.
3. Run the **Lift48** scheme on your iPhone. The Watch app installs with it.
   For the Simulator, pick a paired iPhone + Apple Watch simulator pair.

## Tests
```bash
cd Packages/LiftCore && swift test
```

## How Watch sync works
The iPhone owns the program, settings and history and pushes them to the Watch.
A live workout can be started or edited on either device. Each set carries its own timestamp,
so edits from both sides merge instead of overwriting each other.
A finished workout is queued for guaranteed delivery and applied exactly once.
Details are in `docs/SPEC.md`, section 2.1.
