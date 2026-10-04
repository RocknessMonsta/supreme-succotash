import SwiftUI
import WatchKit
import HealthKit
import LiftCore

@main
struct Lift48WatchApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var delegate
    @State private var model = AppModel.shared

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(model)
        }
    }
}

final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    /// HealthKit launches us here when a workout is started on the iPhone.
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        Task { @MainActor in AppModel.shared.handlePhoneStartedWorkout() }
    }
}

/// Chooses between the success screen, the live workout and the idle home screen. Navigation is
/// driven by `model.isWorkoutActive`, so a workout started on the iPhone appears here automatically.
struct WatchRootView: View {
    @Environment(AppModel.self) private var model
    /// Set right after finishing on the watch; shows the success screen until dismissed.
    @State private var completedWorkout: CompletedWorkout?

    var body: some View {
        content
            .onChange(of: model.activeSessionEndedRemotely, initial: true) { _, ended in
                // The session screen goes away on its own (isWorkoutActive == false); just reset the flag.
                if ended { model.activeSessionEndedRemotely = false }
            }
            .alert("Workout finished", isPresented: remoteCompletionBinding, presenting: model.remoteCompletion) { _ in
                Button("OK") {}
            } message: { workout in
                Text("\(workout.dayName) was finished on \(workout.finishedOn == .phone ? "iPhone" : "Apple Watch").")
            }
    }

    @ViewBuilder
    private var content: some View {
        if let workout = completedWorkout {
            WorkoutDoneView(workout: workout) {
                completedWorkout = nil
            }
        } else if model.isWorkoutActive {
            ActiveWorkoutView { completedWorkout = $0 }
        } else {
            HomeView()
        }
    }

    private var remoteCompletionBinding: Binding<Bool> {
        Binding(
            get: { model.remoteCompletion != nil },
            set: { presented in
                if !presented { model.remoteCompletion = nil }
            }
        )
    }
}
