import SwiftUI
import Charts
import LiftCore

private enum ProgressMetric: String, CaseIterable, Identifiable {
    case weight = "Weight"
    case estimatedOneRepMax = "Est. 1RM"

    var id: String { rawValue }
}

/// Weight (or estimated 1RM) over time for one exercise, with records and recent sessions.
@MainActor
struct ExerciseProgressView: View {
    @Environment(AppModel.self) private var model
    let exercise: Exercise

    @State private var metric: ProgressMetric = .weight

    var body: some View {
        let series = Stats.series(for: exercise.id, in: model.history)
        let record = Stats.personalRecords(in: model.history).first(where: { $0.id == exercise.id })
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if series.isEmpty {
                    ContentUnavailableView(
                        "No sessions yet",
                        systemImage: "chart.xyaxis.line",
                        description: Text("Log \(exercise.name) in a workout to chart it.")
                    )
                } else {
                    chartCard(series)
                    if let record { recordsRow(record) }
                    recentSessions
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Chart

    private func plotValue(_ point: Stats.WeightPoint) -> Double {
        switch metric {
        case .weight: return point.weight
        case .estimatedOneRepMax: return point.estimated1RM
        }
    }

    private func chartCard(_ series: [Stats.WeightPoint]) -> some View {
        let values = series.map { plotValue($0) }
        let low = values.min() ?? 0
        let high = values.max() ?? 0
        let padding = max(2.5, (high - low) * 0.15)
        let lower = max(0, low - padding)
        let upper = high + padding
        return VStack(alignment: .leading, spacing: 12) {
            Picker("Metric", selection: $metric) {
                ForEach(ProgressMetric.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)

            Chart(Array(series.enumerated()), id: \.offset) { item in
                LineMark(
                    x: .value("Date", item.element.date),
                    y: .value(metric.rawValue, plotValue(item.element))
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(Color.accentColor)
                PointMark(
                    x: .value("Date", item.element.date),
                    y: .value(metric.rawValue, plotValue(item.element))
                )
                .foregroundStyle(item.element.success ? Color.accentColor : Theme.miss)
            }
            .chartYScale(domain: lower...upper)
            .frame(height: 220)

            HStack(spacing: 14) {
                legendDot(color: Color.accentColor, text: "All sets hit")
                legendDot(color: Theme.miss, text: "Missed reps")
                Spacer(minLength: 0)
                Text(model.unit.symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .card()
    }

    private func legendDot(color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text).font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: Records

    private func recordsRow(_ record: Stats.PersonalRecord) -> some View {
        HStack(spacing: 12) {
            recordTile(
                title: "Heaviest",
                value: LiftFormat.weightLabel(record.heaviestWeight, equipment: exercise.equipment, unit: model.unit),
                date: record.heaviestDate
            )
            recordTile(
                title: "Best est. 1RM",
                value: LiftFormat.estimate(record.best1RM, unit: model.unit),
                date: record.best1RMDate
            )
        }
    }

    private func recordTile(title: String, value: String, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: "trophy.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentColor)
            Text(value)
                .font(.numeric(.title3, weight: .bold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(LiftFormat.fullDate(date))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    // MARK: Recent sessions

    private struct SessionEntry: Identifiable {
        let id: String
        let date: Date
        let result: ExerciseResult
    }

    private var recentEntries: [SessionEntry] {
        var entries: [SessionEntry] = []
        for workout in model.history {
            for result in workout.exercises where result.exercise.id == exercise.id && result.wasAttempted {
                entries.append(SessionEntry(id: "\(workout.id.uuidString)-\(result.id.uuidString)", date: workout.finishedAt, result: result))
            }
        }
        entries.sort { $0.date > $1.date }
        return Array(entries.prefix(10))
    }

    private var recentSessions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent sessions")
                .font(.headline)
                .padding(.horizontal, 4)
            VStack(spacing: 0) {
                let entries = recentEntries
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    if index > 0 { Divider() }
                    HStack(spacing: 12) {
                        Image(systemName: entry.result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(entry.result.isSuccess ? Theme.success : Theme.miss)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LiftFormat.fullDate(entry.date))
                                .font(.subheadline.weight(.semibold))
                            Text(LiftFormat.reps(entry.result.reps))
                                .font(.numeric(.caption))
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        Text(LiftFormat.weightLabel(entry.result.weight, equipment: exercise.equipment, unit: model.unit))
                            .font(.numeric(.subheadline, weight: .bold))
                    }
                    .padding(.vertical, 10)
                }
            }
            .card()
        }
    }
}
