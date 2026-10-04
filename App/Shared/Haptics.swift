import Foundation
#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

/// Small cross-platform haptic vocabulary.
@MainActor
enum Haptics {
    static var isEnabled = true

    /// A set was logged / tapped.
    static func tap() {
        guard isEnabled else { return }
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #elseif os(watchOS)
        WKInterfaceDevice.current().play(.click)
        #endif
    }

    /// Rest period finished — make it unmistakable.
    static func restFinished() {
        guard isEnabled else { return }
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #elseif os(watchOS)
        WKInterfaceDevice.current().play(.notification)
        #endif
    }

    /// Workout finished successfully.
    static func success() {
        guard isEnabled else { return }
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #elseif os(watchOS)
        WKInterfaceDevice.current().play(.success)
        #endif
    }
}
