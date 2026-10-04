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

/// PLACEHOLDER — replaced by the watch UI.
struct WatchRootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Text(model.nextDay?.name ?? "Lift48")
    }
}
