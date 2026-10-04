import SwiftUI
import LiftCore

/// One set circle. Empty outline when not logged, filled accent with the reps for a hit,
/// filled red with the reps for a miss (same semantics as the phone).
struct SetCircleView: View {
    let reps: Int?
    let target: Int
    var size: CGFloat = 40

    private var isHit: Bool { (reps ?? -1) >= target }

    var body: some View {
        ZStack {
            if let reps {
                Circle().fill(isHit ? Color.accentColor : Color.red)
                Text("\(reps)")
                    .font(.system(size: size * 0.5, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(isHit ? Color.black : Color.white)
            } else {
                Circle().strokeBorder(Color.white.opacity(0.55), lineWidth: max(2, size * 0.07))
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(reps.map { "\($0) reps" } ?? "Not logged")
    }
}
