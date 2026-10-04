import SwiftUI
import LiftCore

/// Overview numbers plus the list of exercises that appear in history.
@MainActor
struct ProgressTab: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            Group {
                if model.history.isEmpty {
                    ContentUnavailableView(
                        "No progress yet",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Finish a workout and your lifts will be charted here.")
                    )
                } else {
                    content
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progress")
        }
    }

    private var content: some View {
        let history = model.history
        let records = Stats.personalRecords(in: history)
        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                overview(history)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exercises")
                        .font(.headline)
                        .padding(.horizontal, 4)
                    if records.isEmpty {
                        Text("Log at least one rep in a workout to see exercise charts.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .card()
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                                if index > 0 { Divider().padding(.leading, 16) }
                                NavigationLink {
                                    ExerciseProgressView(exercise: record.exercise)
                                } label: {
                                    recordRow(record)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func overview(_ history: [CompletedWorkout]) -> some View {
        let thisWeek = Stats.workoutsThisWeek(in: history, now: model.now())
        let volume = Stats.totalVolume(in: history)
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
            StatTile(title: "Workouts", value: "\(history.count)", symbol: "figure.strengthtraining.traditional")
            StatTile(title: "This week", value: "\(thisWeek)", symbol: "calendar")
            StatTile(title: "Total volume", value: LiftFormat.volume(volume, unit: model.unit), symbol: "scalemass")
        }
    }

    private func recordRow(_ record: Stats.PersonalRecord) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.exercise.name)
                    .font(.body.weight(.semibold))
                Text(record.exercise.equipment.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(LiftFormat.weightLabel(record.heaviestWeight, equipment: record.exercise.equipment, unit: model.unit))
                    .font(.numeric(.subheadline, weight: .bold))
                Text("Heaviest")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

/// Small number tile used on the Progress overview and exercise detail.
struct StatTile: View {
    let title: String
    let value: String
    var symbol: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
            }
            Text(value)
                .font(.numeric(.title2, weight: .bold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }
}
