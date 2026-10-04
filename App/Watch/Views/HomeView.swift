import SwiftUI
import LiftCore

/// Idle screen: next workout, Start, other days, last workout, History.
struct HomeView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    nextWorkoutCard
                    startButton
                    otherDays
                    lastWorkout
                    NavigationLink {
                        HistoryListView()
                    } label: {
                        Label("History", systemImage: "clock.arrow.circlepath")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if !model.syncStatus.isReachable {
                        Label("iPhone not reachable", systemImage: "iphone.slash")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("Lift48")
        }
    }

    // MARK: Pieces

    private var needsPhoneHint: Bool {
        if model.program.enabledDays.isEmpty { return true }
        let status = model.syncStatus
        return status.isActivated && !status.isCounterpartInstalled && model.history.isEmpty
    }

    private var nextWorkoutCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let day = model.nextDay {
                HStack {
                    Text(day.name)
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Text("NEXT \u{00B7} \(model.unit.symbol)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                ForEach(day.slots) { slot in
                    HStack(spacing: 4) {
                        Text(WatchFormat.shortName(slot.exercise.name))
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text(WatchFormat.weight(slot.nextWeight))
                            .font(.footnote.weight(.semibold).monospacedDigit())
                    }
                    .font(.footnote)
                }
            } else {
                Text("No workout yet")
                    .font(.headline)
            }
            if needsPhoneHint {
                Label("Open Lift48 on iPhone", systemImage: "iphone")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }

    private var startButton: some View {
        Button {
            model.startWorkout()
        } label: {
            Label("Start", systemImage: "play.fill")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 40)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .disabled(model.nextDay == nil)
    }

    @ViewBuilder
    private var otherDays: some View {
        let nextID = model.nextDay?.id
        let others = model.program.enabledDays.filter { $0.id != nextID }
        if !others.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Start a different day")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ForEach(others) { day in
                    Button {
                        model.startWorkout(dayID: day.id)
                    } label: {
                        HStack {
                            Text(day.name)
                                .lineLimit(1)
                            Spacer(minLength: 4)
                            Image(systemName: "play.fill")
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    @ViewBuilder
    private var lastWorkout: some View {
        if let last = model.history.first {
            NavigationLink {
                HistoryDetailView(workout: last)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last workout")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: last.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(last.isSuccess ? Color.green : Color.orange)
                        Text(last.dayName)
                            .font(.footnote.weight(.semibold))
                            .lineLimit(1)
                    }
                    Text("\(last.finishedAt.formatted(.relative(presentation: .named))) \u{00B7} \(WatchFormat.duration(last.duration))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
