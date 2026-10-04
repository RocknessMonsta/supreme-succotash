import Foundation
import UserNotifications
import LiftCore

/// Schedules a local notification for the end of the rest timer so the user is alerted while the
/// app is in the background or the phone is locked. In the foreground the app plays a haptic
/// itself, so foreground presentation is suppressed.
///
/// Only the iPhone schedules notifications; iOS mirrors them to the Watch when the phone is locked.
/// The Watch app relies on its workout session (which keeps it running) to play a haptic instead.
@MainActor
final class RestTimerNotifier: NSObject {
    static let identifier = "lift48.rest-timer"

    private let center: UNUserNotificationCenter?
    private var scheduledEnd: Date?
    private var authorizationRequested = false

    override init() {
        #if os(iOS)
        center = UNUserNotificationCenter.current()
        #else
        center = nil
        #endif
        super.init()
        center?.delegate = self
    }

    func requestAuthorizationIfNeeded() {
        guard let center, !authorizationRequested else { return }
        authorizationRequested = true
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// Reconciles the pending notification with the timer. Cheap to call after every change.
    func update(timer: RestTimerState, nextUp: String?, sound: Bool, now: Date) {
        guard let center else { return }
        let end = timer.isRunning(at: now) ? timer.endsAt : nil
        guard end != scheduledEnd else { return }
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
        scheduledEnd = end
        guard let end else { return }

        requestAuthorizationIfNeeded()
        let content = UNMutableNotificationContent()
        content.title = "Rest is over"
        content.body = nextUp.map { "Up next: \($0)" } ?? "Time for your next set."
        if sound { content.sound = .default }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, end.timeIntervalSince(now)), repeats: false)
        center.add(UNNotificationRequest(identifier: Self.identifier, content: content, trigger: trigger))
    }

    func cancel() {
        center?.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
        scheduledEnd = nil
    }
}

extension RestTimerNotifier: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // The in-app timer banner + haptic already cover the foreground case.
        completionHandler([])
    }
}
