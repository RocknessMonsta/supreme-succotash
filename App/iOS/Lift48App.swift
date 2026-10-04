import SwiftUI
import LiftCore

@main
struct Lift48App: App {
    @State private var model = AppModel.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
        }
    }
}

/// PLACEHOLDER — replaced by the iOS UI.
struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Text(model.nextDay?.name ?? "Lift48")
    }
}
