import SwiftUI
import LiftCore

/// App settings. The program editor lives one level down.
@MainActor
struct SettingsTab: View {
    @Environment(AppModel.self) private var model
    @State private var pendingUnit: WeightUnit?

    var body: some View {
        NavigationStack {
            Form {
                unitsSection
                equipmentSection
                restSection
                togglesSection
                programSection
                aboutSection
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Switch units?",
                isPresented: unitDialogPresented,
                titleVisibility: .visible,
                presenting: pendingUnit
            ) { unit in
                Button("Convert to \(unit.symbol)") {
                    model.setUnit(unit)
                }
                Button("Cancel", role: .cancel) {}
            } message: { unit in
                Text("Every weight in your program, history and plates is converted to \(unit.symbol). Increments reset to the \(unit.symbol) defaults.")
            }
            .onChange(of: model.settings.healthKitEnabled) { _, enabled in
                if enabled { requestHealthAccess() }
            }
        }
    }

    // MARK: Bindings

    private func setting<T>(_ keyPath: WritableKeyPath<LiftCore.Settings, T>) -> Binding<T> {
        Binding(
            get: { model.settings[keyPath: keyPath] },
            set: { newValue in
                model.updateSettings { $0[keyPath: keyPath] = newValue }
            }
        )
    }

    private var unitBinding: Binding<WeightUnit> {
        Binding(
            get: { model.unit },
            set: { newValue in
                if newValue != model.unit { pendingUnit = newValue }
            }
        )
    }

    private var unitDialogPresented: Binding<Bool> {
        Binding(
            get: { pendingUnit != nil },
            set: { presented in
                if !presented { pendingUnit = nil }
            }
        )
    }

    private func requestHealthAccess() {
        Task { await model.health.requestAuthorizationIfNeeded() }
    }

    // MARK: Sections

    private var unitsSection: some View {
        Section {
            Picker("Units", selection: unitBinding) {
                ForEach(WeightUnit.allCases, id: \.self) { unit in
                    Text(unit.symbol.uppercased()).tag(unit)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Units")
        } footer: {
            Text("Switching converts all stored weights and rounds them to the new unit's plates.")
        }
    }

    private var equipmentSection: some View {
        let unit = model.unit
        return Section {
            Stepper(value: setting(\.barWeight), in: 0...100, step: unit == .lb ? 5 : 2.5) {
                LabeledContent("Bar weight", value: model.format(model.settings.barWeight))
            }
            Stepper(value: setting(\.dumbbellIncrement), in: 0.5...25, step: unit == .lb ? 2.5 : 0.5) {
                LabeledContent("Dumbbell increment", value: model.format(model.settings.dumbbellIncrement))
            }
            NavigationLink {
                PlatesEditorView()
            } label: {
                LabeledContent("Plates", value: platesSummary)
            }
        } header: {
            Text("Equipment")
        }
    }

    private var platesSummary: String {
        let plates = model.settings.availablePlates.sorted(by: >)
        guard !plates.isEmpty else { return "None" }
        return plates.map { Weight.format($0) }.joined(separator: ", ")
    }

    private var restSection: some View {
        Section {
            restStepper("After a successful set", keyPath: \.rest.afterSuccess)
            restStepper("After a missed set", keyPath: \.rest.afterFailure)
            restStepper("After repeated misses", keyPath: \.rest.afterRepeatedFailure)
        } header: {
            Text("Rest timer")
        } footer: {
            Text("Adjust in 15 second steps. The timer starts automatically when you log a set.")
        }
    }

    private func restStepper(_ title: String, keyPath: WritableKeyPath<LiftCore.Settings, TimeInterval>) -> some View {
        Stepper(value: setting(keyPath), in: 15...900, step: 15) {
            LabeledContent(title, value: LiftFormat.clock(model.settings[keyPath: keyPath]))
        }
    }

    private var togglesSection: some View {
        Section {
            Toggle("Warm-up sets", isOn: setting(\.warmupsEnabled))
            Toggle("Sound", isOn: setting(\.soundEnabled))
            Toggle("Haptics", isOn: setting(\.hapticsEnabled))
            Toggle("Apple Health", isOn: setting(\.healthKitEnabled))
                .disabled(!model.health.isAvailable)
        } header: {
            Text("Workout")
        } footer: {
            Text(model.health.isAvailable
                 ? "Saves completed workouts to Apple Health as strength training."
                 : "Apple Health isn't available on this device.")
        }
    }

    private var programSection: some View {
        Section {
            NavigationLink {
                ProgramEditorView()
            } label: {
                Label("Program", systemImage: "list.bullet.rectangle")
            }
        } header: {
            Text("Program")
        } footer: {
            Text("Reorder days, swap exercises, and set weights and increments.")
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: appVersion)
            WatchStatusLabel()
            Text("Lift48 works with the Apple Watch app. Start or follow a workout from your wrist, log sets with the Digital Crown, and everything stays in sync with this iPhone.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } header: {
            Text("About")
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}

/// Toggle which standard plates you own.
@MainActor
struct PlatesEditorView: View {
    @Environment(AppModel.self) private var model

    private static let standardLb: [Double] = [100, 55, 45, 35, 25, 15, 10, 5, 2.5, 1.25]
    private static let standardKg: [Double] = [25, 20, 15, 10, 5, 2.5, 1.25, 0.5]

    /// Standard sizes for the unit plus any custom sizes already stored.
    private var options: [Double] {
        let standard = model.unit == .lb ? Self.standardLb : Self.standardKg
        var all = standard
        for plate in model.settings.availablePlates where !all.contains(plate) { all.append(plate) }
        return all.sorted(by: >)
    }

    var body: some View {
        List {
            Section {
                ForEach(options, id: \.self) { plate in
                    Toggle(isOn: binding(for: plate)) {
                        Text("\(Weight.format(plate)) \(model.unit.symbol)")
                            .font(.numeric(.body, weight: .medium))
                    }
                }
            } footer: {
                Text("Pairs are assumed unlimited. At least one plate size must stay on.")
            }
        }
        .navigationTitle("Plates")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func binding(for plate: Double) -> Binding<Bool> {
        Binding(
            get: { model.settings.availablePlates.contains(plate) },
            set: { enabled in
                model.updateSettings { settings in
                    if enabled {
                        if !settings.availablePlates.contains(plate) { settings.availablePlates.append(plate) }
                        settings.availablePlates.sort(by: >)
                    } else if settings.availablePlates.count > 1 {
                        settings.availablePlates.removeAll { $0 == plate }
                    }
                }
            }
        )
    }
}
