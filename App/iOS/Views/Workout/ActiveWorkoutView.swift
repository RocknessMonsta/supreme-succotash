import SwiftUI
import LiftCore

/// Which sheet is up on the workout screen.
enum WorkoutSheet: Identifiable {
    case weight(UUID)
    case reps(UUID, Int)
    case exerciseNote(UUID)
    case workoutNote
    case finish

    var id: String {
        switch self {
        case .weight(let id): return "weight-\(id.uuidString)"
        case .reps(let id, let index): return "reps-\(id.uuidString)-\(index)"
        case .exerciseNote(let id): return "note-\(id.uuidString)"
        case .workoutNote: return "workout-note"
        case .finish: return "finish"
        }
    }
}

/// The live workout. Reads everything from `model.activeSession` so edits made on the Watch show up.
@MainActor
struct ActiveWorkoutView: View {
    @Environment(AppModel.self) private var model
    /// Called with the saved workout right after `finishWorkout()`.
    let onFinished: (CompletedWorkout) -> Void

    @State private var sheet: WorkoutSheet?
    @State private var pendingFinish = false
    @State private var showDiscardDialog = false
    @State private var showRestOver = false

    var body: some View {
        if let session = model.activeSession {
            content(session)
        } else {
            Color(.systemGroupedBackground).ignoresSafeArea()
        }
    }

    private func content(_ session: WorkoutSession) -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(session.exercises) { exercise in
                        ExerciseCard(
                            exercise: exercise,
                            onEditWeight: { sheet = .weight(exercise.id) },
                            onEditReps: { index in sheet = .reps(exercise.id, index) },
                            onEditNote: { sheet = .exerciseNote(exercise.id) }
                        )
                    }
                    workoutNoteButton(session)
                    progressFooter(session)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom, spacing: 0) {
                RestTimerBanner(timer: session.restTimer, showFinished: showRestOver)
            }
            .navigationTitle(session.dayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            sheet = .workoutNote
                        } label: {
                            Label("Workout Note", systemImage: "note.text")
                        }
                        Button(role: .destructive) {
                            showDiscardDialog = true
                        } label: {
                            Label("Discard Workout", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Workout options")
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(session.dayName)
                            .font(.headline)
                        ElapsedTimeText(startedAt: session.startedAt)
                            .font(.numeric(.caption))
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Finish") { sheet = .finish }
                        .fontWeight(.bold)
                }
            }
        }
        .sheet(item: $sheet, onDismiss: handleSheetDismiss) { item in
            sheetContent(item)
        }
        .confirmationDialog("Discard this workout?", isPresented: $showDiscardDialog, titleVisibility: .visible) {
            Button("Discard Workout", role: .destructive) {
                model.discardWorkout()
            }
            Button("Keep Training", role: .cancel) {}
        } message: {
            Text("Everything you've logged in this workout will be deleted on iPhone and Apple Watch.")
        }
        .onChange(of: model.restFinishedCount) { _, _ in
            flashRestOver()
        }
    }

    // MARK: Sheets

    @ViewBuilder
    private func sheetContent(_ item: WorkoutSheet) -> some View {
        switch item {
        case .weight(let exerciseID):
            WeightEditorSheet(exerciseID: exerciseID)
        case .reps(let exerciseID, let index):
            RepsPickerSheet(exerciseID: exerciseID, setIndex: index)
        case .exerciseNote(let exerciseID):
            NoteEditorSheet(
                title: "Exercise Note",
                initialText: model.activeSession?.exercises.first(where: { $0.id == exerciseID })?.note ?? ""
            ) { text in
                model.setExerciseNote(text, exerciseID: exerciseID)
            }
        case .workoutNote:
            NoteEditorSheet(title: "Workout Note", initialText: model.activeSession?.note ?? "") { text in
                model.setWorkoutNote(text)
            }
        case .finish:
            FinishWorkoutSheet(onConfirm: { pendingFinish = true })
        }
    }

    /// Finishing happens after the confirmation sheet has fully dismissed, because finishing removes
    /// this whole screen.
    private func handleSheetDismiss() {
        guard pendingFinish else { return }
        pendingFinish = false
        if let workout = model.finishWorkout() {
            onFinished(workout)
        }
    }

    private func flashRestOver() {
        showRestOver = true
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            showRestOver = false
        }
    }

    // MARK: Pieces

    private func workoutNoteButton(_ session: WorkoutSession) -> some View {
        Button {
            sheet = .workoutNote
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "note.text")
                    .foregroundStyle(Color.accentColor)
                Text(session.note.isEmpty ? "Add workout note" : session.note)
                    .font(.subheadline)
                    .foregroundStyle(session.note.isEmpty ? .secondary : .primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                Spacer(minLength: 0)
            }
            .card()
        }
        .buttonStyle(.plain)
    }

    private func progressFooter(_ session: WorkoutSession) -> some View {
        let total = session.exercises.reduce(0) { $0 + $1.sets.count }
        return Text("\(session.loggedSetCount) of \(total) sets logged")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }
}

/// Live elapsed time since `startedAt`.
struct ElapsedTimeText: View {
    let startedAt: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Text(LiftFormat.clock(context.date.timeIntervalSince(startedAt)))
        }
    }
}
