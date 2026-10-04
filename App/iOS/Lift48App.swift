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

enum AppTab: Hashable {
    case workout, history, progress, settings
}

/// Tab bar + the full-screen workout cover. The cover is driven by model state, so a workout started
/// on the Apple Watch appears here automatically.
@MainActor
struct RootView: View {
    @Environment(AppModel.self) private var model
    @State private var selectedTab: AppTab = .workout
    /// Set when the user finishes a workout; keeps the cover up to show the success summary.
    @State private var finishedSummary: CompletedWorkout?

    var body: some View {
        TabView(selection: $selectedTab) {
            WorkoutTab()
                .tabItem { Label("Workout", systemImage: "dumbbell.fill") }
                .tag(AppTab.workout)
            HistoryTab()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(AppTab.history)
            ProgressTab()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(AppTab.progress)
            SettingsTab()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .fullScreenCover(isPresented: coverPresented) {
            WorkoutCoverView(summary: $finishedSummary)
        }
        .overlay(alignment: .top) {
            RemoteCompletionBanner()
        }
        .onChange(of: model.activeSessionEndedRemotely) { _, ended in
            if ended { model.activeSessionEndedRemotely = false }
        }
        .onAppear {
            if model.activeSessionEndedRemotely { model.activeSessionEndedRemotely = false }
        }
    }

    private var coverPresented: Binding<Bool> {
        Binding(
            get: { model.isWorkoutActive || finishedSummary != nil },
            set: { presented in
                if !presented { finishedSummary = nil }
            }
        )
    }
}

/// Content of the full-screen cover: the live workout, then (after finishing) the success summary.
@MainActor
struct WorkoutCoverView: View {
    @Environment(AppModel.self) private var model
    @Binding var summary: CompletedWorkout?

    var body: some View {
        if model.activeSession != nil {
            ActiveWorkoutView(onFinished: { workout in summary = workout })
        } else if let workout = summary {
            WorkoutSummaryView(workout: workout, onDone: { summary = nil })
        } else {
            // Session ended elsewhere; the cover dismisses itself on the next render.
            Color(.systemGroupedBackground).ignoresSafeArea()
        }
    }
}

/// "Finished on Apple Watch" toast, shown when the other device completes a workout.
@MainActor
struct RemoteCompletionBanner: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Group {
            if let workout = model.remoteCompletion {
                HStack(spacing: 12) {
                    Image(systemName: workout.finishedOn == .watch ? "applewatch" : "iphone")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(workout.dayName) workout finished")
                            .font(.headline)
                        Text(detail(for: workout))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    Button {
                        model.remoteCompletion = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Dismiss")
                }
                .padding(14)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(0.15), radius: 10, y: 3)
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .transition(.move(edge: .top).combined(with: .opacity))
                .task(id: workout.id) {
                    await expire(workout.id)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: model.remoteCompletion?.id)
    }

    private func detail(for workout: CompletedWorkout) -> String {
        let hit = workout.exercises.filter(\.isSuccess).count
        let device = workout.finishedOn == .watch ? "Apple Watch" : "iPhone"
        return "\(device) · \(LiftFormat.duration(workout.duration)) · \(hit)/\(workout.exercises.count) exercises hit target"
    }

    @MainActor
    private func expire(_ id: UUID) async {
        try? await Task.sleep(nanoseconds: 8_000_000_000)
        if model.remoteCompletion?.id == id { model.remoteCompletion = nil }
    }
}
