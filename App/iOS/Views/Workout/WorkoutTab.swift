import SwiftUI
import LiftCore

/// Idle workout screen: the next workout, a Start button, and the most recent session.
@MainActor
struct WorkoutTab: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let day = model.nextDay {
                        NextWorkoutCard(day: day)
                    } else {
                        noDayCard
                    }
                    recentSection
                    WatchStatusLabel()
                        .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Workout")
        }
    }

    private var noDayCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No workout days enabled")
                .font(.headline)
            Text("Enable at least one day under Settings › Program.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .card()
    }

    @ViewBuilder
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last workout")
                .font(.headline)
                .padding(.horizontal, 4)
            if let workout = model.history.first {
                NavigationLink {
                    HistoryDetailView(workoutID: workout.id)
                } label: {
                    HistoryRowContent(workout: workout)
                        .card()
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("No workouts yet")
                        .font(.headline)
                    Text("Finish your first workout and it will show up here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .card()
            }
        }
    }
}

/// "Next workout" hero card: day, exercises with prescriptions, day picker and the big Start button.
@MainActor
struct NextWorkoutCard: View {
    @Environment(AppModel.self) private var model
    let day: BodyPartDay

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            VStack(spacing: 0) {
                ForEach(Array(day.slots.enumerated()), id: \.element.id) { index, slot in
                    if index > 0 { Divider() }
                    exerciseRow(slot)
                }
            }
            Button {
                model.startWorkout(dayID: day.id)
            } label: {
                Label("Start Workout", systemImage: "play.fill")
                    .font(.title3.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .card()
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("NEXT WORKOUT")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(day.name)
                    .font(.largeTitle.weight(.bold))
                Label(day.bodyPart.displayName, systemImage: day.bodyPart.symbolName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            dayMenu
        }
    }

    @ViewBuilder
    private var dayMenu: some View {
        let days = model.program.enabledDays
        if days.count > 1 {
            Menu {
                ForEach(days) { option in
                    Button {
                        model.updateProgram { $0.setNextDay(option.id) }
                    } label: {
                        if option.id == day.id {
                            Label(option.name, systemImage: "checkmark")
                        } else {
                            Text(option.name)
                        }
                    }
                }
            } label: {
                Label("Change", systemImage: "arrow.triangle.2.circlepath")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.15), in: Capsule())
            }
            .accessibilityLabel("Choose a different day")
        }
    }

    private func exerciseRow(_ slot: ExerciseSlot) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(slot.exercise.name)
                    .font(.body.weight(.semibold))
                Text(slot.exercise.equipment.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text(LiftFormat.prescription(sets: slot.sets, reps: slot.targetReps, weight: slot.nextWeight, equipment: slot.exercise.equipment, unit: model.unit))
                .font(.numeric(.subheadline))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 10)
    }
}

/// One finished workout summarised on a row: day, date, duration, volume, per-exercise marks.
@MainActor
struct HistoryRowContent: View {
    let workout: CompletedWorkout

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(workout.dayName)
                    .font(.headline)
                Text(LiftFormat.day(workout.finishedAt))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Label(LiftFormat.duration(workout.duration), systemImage: "clock")
                    Label(LiftFormat.volume(workout.volume, unit: workout.unit), systemImage: "scalemass")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            ResultMarks(results: workout.exercises)
        }
        .contentShape(Rectangle())
    }
}
