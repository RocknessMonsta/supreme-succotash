import SwiftUI
import LiftCore

private struct MonthGroup: Identifiable {
    let id: Date
    let workouts: [CompletedWorkout]
}

/// Completed workouts grouped by month, with swipe-to-delete and CSV export.
@MainActor
struct HistoryTab: View {
    @Environment(AppModel.self) private var model
    @State private var exportURL: URL?
    @State private var pendingDelete: CompletedWorkout?

    var body: some View {
        NavigationStack {
            Group {
                if model.history.isEmpty {
                    ContentUnavailableView(
                        "No workouts yet",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Completed workouts will appear here, newest first.")
                    )
                } else {
                    historyList
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let url = exportURL, !model.history.isEmpty {
                        ShareLink(item: url) {
                            Label("Export CSV", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
            .onAppear(perform: prepareExport)
            .onChange(of: model.history) { _, _ in
                prepareExport()
            }
            .confirmationDialog(
                "Delete this workout?",
                isPresented: deleteDialogPresented,
                titleVisibility: .visible,
                presenting: pendingDelete
            ) { workout in
                Button("Delete Workout", role: .destructive) {
                    model.deleteHistory(id: workout.id)
                }
                Button("Cancel", role: .cancel) {}
            } message: { workout in
                Text("\(workout.dayName) on \(LiftFormat.fullDate(workout.finishedAt)) will be removed. Your program's weights won't change.")
            }
        }
    }

    private var deleteDialogPresented: Binding<Bool> {
        Binding(
            get: { pendingDelete != nil },
            set: { presented in
                if !presented { pendingDelete = nil }
            }
        )
    }

    private var groups: [MonthGroup] {
        let calendar = Calendar.current
        let byMonth = Dictionary(grouping: model.history) { workout in
            calendar.dateInterval(of: .month, for: workout.finishedAt)?.start ?? workout.finishedAt
        }
        var result: [MonthGroup] = []
        for (month, workouts) in byMonth {
            let sorted = workouts.sorted { $0.finishedAt > $1.finishedAt }
            result.append(MonthGroup(id: month, workouts: sorted))
        }
        return result.sorted { $0.id > $1.id }
    }

    private var historyList: some View {
        List {
            ForEach(groups) { group in
                Section {
                    ForEach(group.workouts) { workout in
                        NavigationLink {
                            HistoryDetailView(workoutID: workout.id)
                        } label: {
                            HistoryRowContent(workout: workout)
                                .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                pendingDelete = workout
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text(group.id.formatted(.dateTime.month(.wide).year()))
                }
            }
        }
    }

    private func prepareExport() {
        guard !model.history.isEmpty else {
            exportURL = nil
            return
        }
        exportURL = try? model.exportCSV()
    }
}
