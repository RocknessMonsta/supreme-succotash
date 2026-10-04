import SwiftUI
import LiftCore

/// Controls page: review & finish, or discard the workout (with confirmation).
struct WorkoutControlsView: View {
    @Environment(AppModel.self) private var model

    /// Jumps to the finish page.
    let onEnd: () -> Void

    @State private var confirmDiscard = false

    var body: some View {
        VStack(spacing: 8) {
            if let session = model.activeSession {
                Text(session.dayName)
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
                    .lineLimit(1)
                Text("\(session.loggedSetCount) sets logged")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Button(action: onEnd) {
                Label("End workout", systemImage: "flag.checkered")
                    .frame(maxWidth: .infinity)
            }
            Button(role: .destructive) {
                confirmDiscard = true
            } label: {
                Label("Discard", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .tint(.red)
        }
        .padding(.leading, 6)
        .padding(.trailing, 10)
        .confirmationDialog("Discard workout?", isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button("Discard", role: .destructive) {
                model.discardWorkout()
            }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("Logged sets will be lost.")
        }
    }
}
