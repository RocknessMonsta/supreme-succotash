import SwiftUI
import LiftCore

/// Rotation editor: reorder days, enable/disable them, choose the next day, reset the program.
@MainActor
struct ProgramEditorView: View {
    @Environment(AppModel.self) private var model
    @State private var showResetDialog = false

    var body: some View {
        List {
            nextDaySection
            Section {
                ForEach(model.program.days) { day in
                    NavigationLink {
                        DayEditorView(dayID: day.id)
                    } label: {
                        dayRow(day)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            model.updateProgram { $0.setDayEnabled(day.id, !day.isEnabled) }
                        } label: {
                            Label(day.isEnabled ? "Disable" : "Enable", systemImage: day.isEnabled ? "eye.slash" : "eye")
                        }
                        .tint(day.isEnabled ? Color.gray : Color.green)
                    }
                }
                .onMove { source, destination in
                    model.updateProgram { $0.moveDay(fromOffsets: source, toOffset: destination) }
                }
            } header: {
                Text("Rotation")
            } footer: {
                Text("Days repeat in this order. Tap Edit to reorder; swipe a day to enable or disable it.")
            }
            Section {
                Button(role: .destructive) {
                    showResetDialog = true
                } label: {
                    Label("Reset Program…", systemImage: "arrow.counterclockwise")
                }
            } footer: {
                Text("Restores the default five-day split with starting weights.")
            }
        }
        .navigationTitle("Program")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .confirmationDialog("Reset your program?", isPresented: $showResetDialog, titleVisibility: .visible) {
            Button("Reset Program", role: .destructive) {
                model.resetProgram(clearHistory: false)
            }
            Button("Reset Program and Delete History", role: .destructive) {
                model.resetProgram(clearHistory: true)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Exercises, weights and rotation go back to the defaults. You can keep your workout history.")
        }
    }

    private var nextDaySection: some View {
        Section {
            Picker("Next workout", selection: nextDayBinding) {
                ForEach(model.program.enabledDays) { day in
                    Text(day.name).tag(day.id)
                }
            }
        } footer: {
            Text("The day the Start button and Apple Watch will use next.")
        }
    }

    private var nextDayBinding: Binding<UUID> {
        Binding(
            get: { model.nextDay?.id ?? model.program.enabledDays.first?.id ?? UUID() },
            set: { newValue in
                model.updateProgram { $0.setNextDay(newValue) }
            }
        )
    }

    private func dayRow(_ day: BodyPartDay) -> some View {
        HStack(spacing: 12) {
            Image(systemName: day.bodyPart.symbolName)
                .font(.title3)
                .foregroundStyle(day.isEnabled ? Color.accentColor : Color.secondary)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(day.name)
                        .font(.headline)
                    if day.id == model.nextDay?.id {
                        Text("NEXT")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor, in: Capsule())
                            .foregroundStyle(Color.white)
                    }
                    if !day.isEnabled {
                        Text("OFF")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.25), in: Capsule())
                            .foregroundStyle(.secondary)
                    }
                }
                Text(day.slots.map(\.exercise.name).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .opacity(day.isEnabled ? 1 : 0.6)
        .padding(.vertical, 2)
    }
}

/// One day: enable/disable, make it next, and its exercise slots.
@MainActor
struct DayEditorView: View {
    @Environment(AppModel.self) private var model
    let dayID: UUID

    private var day: BodyPartDay? {
        model.program.days.first(where: { $0.id == dayID })
    }

    var body: some View {
        Group {
            if let day {
                Form {
                    Section {
                        Toggle("Enabled", isOn: enabledBinding(day))
                        Button {
                            model.updateProgram { $0.setNextDay(dayID) }
                        } label: {
                            Label(
                                model.nextDay?.id == dayID ? "This is the next workout" : "Make this the next workout",
                                systemImage: model.nextDay?.id == dayID ? "checkmark.circle.fill" : "arrow.right.circle"
                            )
                        }
                        .disabled(!day.isEnabled || model.nextDay?.id == dayID)
                    } footer: {
                        if day.isEnabled && model.program.enabledDays.count == 1 {
                            Text("At least one day must stay enabled.")
                        }
                    }
                    Section("Exercises") {
                        ForEach(day.slots) { slot in
                            NavigationLink {
                                SlotEditorView(slotID: slot.id)
                            } label: {
                                slotRow(slot)
                            }
                        }
                    }
                }
                .navigationTitle(day.name)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ContentUnavailableView("Day not found", systemImage: "questionmark.folder")
            }
        }
    }

    private func enabledBinding(_ day: BodyPartDay) -> Binding<Bool> {
        Binding(
            get: { self.day?.isEnabled ?? false },
            set: { newValue in
                model.updateProgram { $0.setDayEnabled(dayID, newValue) }
            }
        )
    }

    private func slotRow(_ slot: ExerciseSlot) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(slot.exercise.name)
                .font(.body.weight(.semibold))
            HStack(spacing: 10) {
                Text("\(slot.sets)×\(slot.targetReps) · \(LiftFormat.weightLabel(slot.nextWeight, equipment: slot.exercise.equipment, unit: model.unit))")
                    .font(.numeric(.caption))
                    .foregroundStyle(.secondary)
                if slot.consecutiveFailures > 0 {
                    Label("\(slot.consecutiveFailures) failed", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.miss)
                }
            }
        }
    }
}
