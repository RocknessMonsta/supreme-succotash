import SwiftUI
import LiftCore

/// Shared look & feel: colours, number font, card container, body-part icons.
enum Theme {
    /// Missed-target colour. Deliberately not red/orange so it stays distinct from the coral accent.
    static let miss = Color(red: 0.96, green: 0.70, blue: 0.10)
    static let success = Color.green
    static let cardRadius: CGFloat = 20
}

extension Font {
    /// Rounded, bold-ish, monospaced digits so numbers don't jiggle while counting.
    static func numeric(_ style: Font.TextStyle = .body, weight: Font.Weight = .semibold) -> Font {
        Font.system(style, design: .rounded, weight: weight).monospacedDigit()
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }
}

extension View {
    /// Rounded grouped-background card.
    func card() -> some View { modifier(CardStyle()) }
}

extension BodyPart {
    var symbolName: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rower"
        case .shoulders: return "figure.strengthtraining.functional"
        case .legs: return "figure.run"
        case .arms: return "dumbbell.fill"
        case .core: return "figure.core.training"
        }
    }
}

extension Array {
    /// Bounds-checked element access.
    func element(at index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
