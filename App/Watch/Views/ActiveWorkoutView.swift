import SwiftUI
import LiftCore

/// The live workout: a vertical pager (one page per exercise, then Finish, then Controls) with the
/// rest-timer overlay on top. Presented by the root whenever `model.isWorkoutActive`.
struct ActiveWorkoutView: View {
    @Environment(AppModel.self) private var model

    let onFinished: (CompletedWorkout) -> Void

    @State private var page = 0
    @State private var didPickInitialPage = false
    /// The `endsAt` of a rest whose overlay the user hid.
    @State private var hiddenRestEnd: Date?
    @State private var isFlashing = false

    var body: some View {
        ZStack {
            if let session = model.activeSession {
                pager(session)
                restLayer(session)
            }
            Color.green
                .opacity(isFlashing ? 0.6 : 0)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onAppear(perform: pickInitialPage)
        .onChange(of: model.restFinishedCount) { _, _ in
            flashScreen()
        }
    }

    // MARK: Pager

    private func pager(_ session: WorkoutSession) -> some View {
        let finishPage = session.exercises.count
        return TabView(selection: $page) {
            ForEach(Array(session.exercises.enumerated()), id: \.element.id) { index, ex in
                ExercisePageView(exerciseID: ex.id, onRestTap: { hiddenRestEnd = nil })
                    .tag(index)
            }
            FinishPageView(onFinished: onFinished)
                .tag(finishPage)
            WorkoutControlsView(onEnd: { page = finishPage })
                .tag(finishPage + 1)
        }
        .tabViewStyle(.verticalPage)
    }

    // MARK: Rest timer

    private func restLayer(_ session: WorkoutSession) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            if let end = session.restTimer.endsAt,
               session.restTimer.isRunning(at: context.date),
               hiddenRestEnd != end {
                RestTimerOverlay(timer: session.restTimer, now: context.date) {
                    hiddenRestEnd = end
                }
            }
        }
    }

    // MARK: Helpers

    private func pickInitialPage() {
        guard !didPickInitialPage else { return }
        didPickInitialPage = true
        guard let session = model.activeSession,
              let first = session.exercises.firstIndex(where: { !$0.isComplete }) else { return }
        page = first
    }

    private func flashScreen() {
        withAnimation(.easeIn(duration: 0.1)) { isFlashing = true }
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            withAnimation(.easeOut(duration: 0.4)) { isFlashing = false }
        }
    }
}
