import Foundation
import WatchConnectivity
import LiftCore

/// Connection facts the UI may show ("Watch connected", etc.).
struct SyncStatus: Equatable, Sendable {
    var isSupported = false
    var isActivated = false
    var isReachable = false
    /// iOS: a watch is paired. watchOS: always true once activated.
    var isPaired = false
    /// iOS: the watch app is installed. watchOS: the companion iPhone app is installed.
    var isCounterpartInstalled = false
}

/// WatchConnectivity transport implementing docs/SPEC.md §2.1.
///
/// - Snapshots of program/settings/history go phone → watch through `updateApplicationContext`
///   (only the latest matters).
/// - Live session snapshots use `sendMessage` when reachable, otherwise `transferUserInfo`, keeping
///   only the newest queued session snapshot.
/// - Completed workouts and discards use `transferUserInfo` (guaranteed, ordered) and, when reachable,
///   also `sendMessage` for speed. Receivers apply them idempotently, so duplicates are harmless.
///
/// All decoding happens on the WatchConnectivity delegate queue; only decoded `Sendable` envelopes
/// hop to the main actor.
final class WatchSyncCoordinator: NSObject, WCSessionDelegate, @unchecked Sendable {
    typealias EnvelopeHandler = @MainActor (SyncEnvelope) -> Void
    typealias StatusHandler = @MainActor (SyncStatus) -> Void
    typealias ActivationHandler = @MainActor () -> Void

    private let role: DeviceKind
    private let session: WCSession?
    private let onEnvelope: EnvelopeHandler
    private let onStatus: StatusHandler
    /// Called on activation and whenever the counterpart becomes available, so the model can push
    /// its current context / active session.
    private let onReady: ActivationHandler

    /// Messages produced before activation completed; flushed once activated. Main actor only.
    private var pending: [SyncMessage] = []

    init(role: DeviceKind, onEnvelope: @escaping EnvelopeHandler, onStatus: @escaping StatusHandler, onReady: @escaping ActivationHandler) {
        self.role = role
        self.session = WCSession.isSupported() ? WCSession.default : nil
        self.onEnvelope = onEnvelope
        self.onStatus = onStatus
        self.onReady = onReady
        super.init()
    }

    @MainActor
    func activate() {
        guard let session else {
            onStatus(SyncStatus())
            return
        }
        session.delegate = self
        session.activate()
    }

    // MARK: Sending

    @MainActor
    func send(_ message: SyncMessage) {
        guard let session, session.activationState == .activated else {
            enqueuePending(message)
            return
        }
        guard canReachCounterpart(session) else { return }
        guard let payload = try? SyncEnvelope(sender: role, sentAt: Date(), message: message).dictionary() else { return }

        switch message {
        case .context:
            // Throws when the watch app isn't installed; nothing useful to do then.
            try? session.updateApplicationContext(payload)

        case .session:
            if session.isReachable {
                session.sendMessage(payload, replyHandler: nil) { [weak self] _ in
                    // Lost the connection mid-send: fall back to the queued channel.
                    self?.queueSessionTransfer(payload)
                }
            } else {
                queueSessionTransfer(payload)
            }

        case .completed, .discarded:
            session.transferUserInfo(payload)
            if session.isReachable {
                session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
            }

        case .requestContext:
            if session.isReachable {
                session.sendMessage(payload, replyHandler: nil) { _ in session.transferUserInfo(payload) }
            } else {
                session.transferUserInfo(payload)
            }
        }
    }

    @MainActor
    private func enqueuePending(_ message: SyncMessage) {
        // Only the latest context/session snapshot is worth keeping.
        switch message {
        case .context: pending.removeAll { if case .context = $0 { return true } else { return false } }
        case .session: pending.removeAll { if case .session = $0 { return true } else { return false } }
        default: break
        }
        pending.append(message)
    }

    /// Queues a session snapshot, cancelling older queued snapshots so only the newest is delivered.
    private func queueSessionTransfer(_ payload: [String: Any]) {
        guard let session else { return }
        for transfer in session.outstandingUserInfoTransfers where transfer.isTransferring {
            if let envelope = SyncEnvelope.from(dictionary: transfer.userInfo), case .session = envelope.message {
                transfer.cancel()
            }
        }
        session.transferUserInfo(payload)
    }

    private func canReachCounterpart(_ session: WCSession) -> Bool {
        #if os(iOS)
        return session.isPaired && session.isWatchAppInstalled
        #else
        return true
        #endif
    }

    private func currentStatus(_ session: WCSession) -> SyncStatus {
        var status = SyncStatus()
        status.isSupported = true
        status.isActivated = session.activationState == .activated
        status.isReachable = session.isReachable
        #if os(iOS)
        status.isPaired = session.isPaired
        status.isCounterpartInstalled = session.isWatchAppInstalled
        #else
        status.isPaired = status.isActivated
        status.isCounterpartInstalled = session.isCompanionAppInstalled
        #endif
        return status
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let status = currentStatus(session)
        // The latest context may have arrived while we weren't running.
        let stored = SyncEnvelope.from(dictionary: session.receivedApplicationContext)
        Task { @MainActor in
            self.onStatus(status)
            guard activationState == .activated else { return }
            if let stored { self.onEnvelope(stored) }
            let queued = self.pending
            self.pending.removeAll()
            queued.forEach { self.send($0) }
            self.onReady()
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        let status = currentStatus(session)
        Task { @MainActor in
            self.onStatus(status)
            if status.isReachable { self.onReady() }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        deliver(message)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        deliver(message)
        replyHandler([:])
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        deliver(userInfo)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        deliver(applicationContext)
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // The user switched to another watch; activate for the new one.
        session.activate()
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        let status = currentStatus(session)
        Task { @MainActor in
            self.onStatus(status)
            self.onReady()
        }
    }
    #endif

    #if os(watchOS)
    func sessionCompanionAppInstalledDidChange(_ session: WCSession) {
        let status = currentStatus(session)
        Task { @MainActor in self.onStatus(status) }
    }
    #endif

    private func deliver(_ dictionary: [String: Any]) {
        guard let envelope = SyncEnvelope.from(dictionary: dictionary), envelope.sender != role else { return }
        Task { @MainActor in self.onEnvelope(envelope) }
    }
}
