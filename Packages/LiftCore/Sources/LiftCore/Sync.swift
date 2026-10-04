import Foundation

// MARK: - Wire format

/// What the phone pushes to the watch via `updateApplicationContext`.
public struct WatchContext: Codable, Hashable, Sendable {
    public static let recentHistoryLimit = 20

    public var program: Program
    public var settings: Settings
    public var activeSession: WorkoutSession?
    public var recentHistory: [CompletedWorkout]
    public var discardedSessionIDs: [UUID]
    public var generatedAt: Date

    public init(state: AppState, generatedAt: Date) {
        program = state.program
        settings = state.settings
        activeSession = state.activeSession
        recentHistory = Array(state.history.prefix(Self.recentHistoryLimit))
        discardedSessionIDs = state.discardedSessionIDs
        self.generatedAt = generatedAt
    }
}

public enum SyncMessage: Codable, Hashable, Sendable {
    /// Phone → watch full snapshot.
    case context(WatchContext)
    /// Either direction: latest live session snapshot (merged on receipt).
    case session(WorkoutSession)
    /// Either direction: a finished workout (applied idempotently).
    case completed(CompletedWorkout)
    /// Either direction: the session with this id was discarded.
    case discarded(UUID)
    /// Watch → phone: please send a fresh context (e.g. watch app just launched).
    case requestContext
}

public struct SyncEnvelope: Codable, Hashable, Sendable {
    public static let schemaVersion = 1
    /// Key under which the encoded envelope is stored in WatchConnectivity dictionaries.
    public static let payloadKey = "lift48.payload"

    public var schemaVersion: Int
    public var sender: DeviceKind
    public var sentAt: Date
    public var message: SyncMessage

    public init(sender: DeviceKind, sentAt: Date, message: SyncMessage) {
        self.schemaVersion = Self.schemaVersion
        self.sender = sender
        self.sentAt = sentAt
        self.message = message
    }

    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        return try encoder.encode(self)
    }

    public static func decode(_ data: Data) throws -> SyncEnvelope {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return try decoder.decode(SyncEnvelope.self, from: data)
    }

    /// Dictionary form for `sendMessage` / `transferUserInfo` / `updateApplicationContext`.
    public func dictionary() throws -> [String: Any] { [Self.payloadKey: try encoded()] }

    /// Returns nil for foreign/unknown payloads or a newer schema this build can't read.
    public static func from(dictionary: [String: Any]) -> SyncEnvelope? {
        guard let data = dictionary[payloadKey] as? Data,
              let envelope = try? decode(data),
              envelope.schemaVersion <= schemaVersion else { return nil }
        return envelope
    }
}

// MARK: - Merge

public enum SessionMerge {
    /// Merges two snapshots of the SAME session (same id). Per-field last-writer-wins on `updatedAt`
    /// with a deterministic value tiebreak, so `merge(a, b) == merge(b, a)`.
    public static func merge(_ a: WorkoutSession, _ b: WorkoutSession) -> WorkoutSession {
        precondition(a.id == b.id, "merge requires the same session")
        var out = a
        out.startedAt = min(a.startedAt, b.startedAt)
        out.startedOn = a.startedAt <= b.startedAt ? a.startedOn : b.startedOn
        if a.startedAt == b.startedAt && a.startedOn != b.startedOn { out.startedOn = .phone }
        out.restTimer = pick(a.restTimer, b.restTimer, at: \.updatedAt) { x, y in
            let xEnd = x.endsAt ?? .distantPast, yEnd = y.endsAt ?? .distantPast
            return xEnd != yEnd ? xEnd > yEnd : x.duration >= y.duration
        }
        (out.note, out.noteUpdatedAt) = pickNote(a.note, a.noteUpdatedAt, b.note, b.noteUpdatedAt)

        var exercises: [SessionExercise] = []
        for ea in a.exercises {
            if let eb = b.exercises.first(where: { $0.id == ea.id }) {
                exercises.append(mergeExercise(ea, eb))
            } else {
                exercises.append(ea)
            }
        }
        for eb in b.exercises where !a.exercises.contains(where: { $0.id == eb.id }) {
            exercises.append(eb)
        }
        out.exercises = exercises
        return out
    }

    static func mergeExercise(_ a: SessionExercise, _ b: SessionExercise) -> SessionExercise {
        var out = a
        if a.weightUpdatedAt != b.weightUpdatedAt {
            if b.weightUpdatedAt > a.weightUpdatedAt { out.weight = b.weight; out.weightUpdatedAt = b.weightUpdatedAt }
        } else {
            out.weight = max(a.weight, b.weight)
        }
        if a.skippedUpdatedAt != b.skippedUpdatedAt {
            if b.skippedUpdatedAt > a.skippedUpdatedAt { out.isSkipped = b.isSkipped; out.skippedUpdatedAt = b.skippedUpdatedAt }
        } else {
            out.isSkipped = a.isSkipped && b.isSkipped
        }
        (out.note, out.noteUpdatedAt) = pickNote(a.note, a.noteUpdatedAt, b.note, b.noteUpdatedAt)

        let setCount = max(a.sets.count, b.sets.count)
        out.sets = (0..<setCount).map { i in
            switch (a.sets[safe: i], b.sets[safe: i]) {
            case let (x?, y?): return pick(x, y, at: \.updatedAt) { ($0.reps ?? -1) >= ($1.reps ?? -1) }
            case let (x?, nil): return x
            case let (nil, y?): return y
            case (nil, nil): fatalError("unreachable")
            }
        }

        // Warm-ups may have been regenerated after a weight change; only merge index-wise when the plans match.
        if a.warmups.map(\.weight) == b.warmups.map(\.weight) && a.warmups.map(\.reps) == b.warmups.map(\.reps) {
            out.warmups = zip(a.warmups, b.warmups).map { x, y in
                pick(x, y, at: \.updatedAt) { $0.isDone || !$1.isDone }
            }
        } else {
            // The side whose weight edit won also wins the plan. On a full tie (same weight, same time, but
            // plans diverged because ticked warm-ups stopped regeneration) pick by a symmetric ranking.
            let aWins: Bool
            if a.weightUpdatedAt != b.weightUpdatedAt {
                aWins = a.weightUpdatedAt > b.weightUpdatedAt
            } else if a.weight != b.weight {
                aWins = a.weight > b.weight
            } else {
                aWins = warmupPlanRanksHigher(a.warmups, b.warmups)
            }
            out.warmups = aWins ? a.warmups : b.warmups
        }
        return out
    }

    /// Symmetric ordering of two differing warm-up plans: more ticked sets first, then heavier/longer plan.
    private static func warmupPlanRanksHigher(_ x: [WarmupSet], _ y: [WarmupSet]) -> Bool {
        let xDone = x.filter(\.isDone).count, yDone = y.filter(\.isDone).count
        if xDone != yDone { return xDone > yDone }
        for (p, q) in zip(x, y) {
            if p.weight != q.weight { return p.weight > q.weight }
            if p.reps != q.reps { return p.reps > q.reps }
        }
        return x.count >= y.count
    }

    /// Two different sessions were started while the devices were apart. Keep the one with more
    /// logged sets; tie → earlier start; tie → the phone's; final tie → smaller id string.
    public static func resolveConflict(_ a: WorkoutSession, _ b: WorkoutSession) -> WorkoutSession {
        if a.loggedSetCount != b.loggedSetCount { return a.loggedSetCount > b.loggedSetCount ? a : b }
        if a.startedAt != b.startedAt { return a.startedAt < b.startedAt ? a : b }
        if a.startedOn != b.startedOn { return a.startedOn == .phone ? a : b }
        return a.id.uuidString < b.id.uuidString ? a : b
    }

    private static func pick<T>(_ x: T, _ y: T, at time: KeyPath<T, Date>, tiebreakPrefersFirst: (T, T) -> Bool) -> T {
        if x[keyPath: time] != y[keyPath: time] { return x[keyPath: time] > y[keyPath: time] ? x : y }
        return tiebreakPrefersFirst(x, y) ? x : y
    }

    private static func pickNote(_ a: String, _ at: Date, _ b: String, _ bt: Date) -> (String, Date) {
        if at != bt { return at > bt ? (a, at) : (b, bt) }
        return (max(a, b), at)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}

// MARK: - Reducer

/// Side effects the platform layer must perform after applying an incoming message.
public struct SyncEffects: Equatable, Sendable {
    /// Local state changed and should be persisted / re-rendered.
    public var stateChanged = false
    /// Phone only: push a fresh `WatchContext`.
    public var sendContext = false
    /// Send this merged session back (the other side is missing some of our edits).
    public var sendSession: WorkoutSession?
    /// Send this completed workout to the other device (it finished here but the other side still has it live).
    public var sendCompleted: CompletedWorkout?
    /// A workout this device didn't finish was just recorded (e.g. to end a Health session / show a toast).
    public var completedRemotely: CompletedWorkout?
    /// The active session was ended by the other device (finished or discarded).
    public var activeSessionEndedRemotely = false

    public init() {}
}

public enum SyncReducer {
    /// Applies one incoming message to local state. Pure and deterministic.
    public static func apply(_ message: SyncMessage, to state: inout AppState, role: DeviceKind) -> SyncEffects {
        var fx = SyncEffects()
        switch message {
        case .requestContext:
            fx.sendContext = role == .phone

        case .discarded(let id):
            let wasActive = state.activeSession?.id == id
            if !state.isTombstoned(id) { state.addTombstone(id); fx.stateChanged = true }
            if wasActive {
                state.activeSession = nil
                fx.stateChanged = true
                fx.activeSessionEndedRemotely = true
            }
            if role == .phone && fx.stateChanged { fx.sendContext = true }

        case .completed(let workout):
            let wasActive = state.activeSession?.id == workout.id
            let applied = state.applyCompleted(workout)
            if applied || wasActive {
                fx.stateChanged = true
                fx.completedRemotely = applied ? workout : nil
                fx.activeSessionEndedRemotely = wasActive
                if role == .phone { fx.sendContext = true }
            }

        case .session(let remote):
            fx = applyRemoteSession(remote, to: &state, role: role)

        case .context(let context):
            guard role == .watch else { break }
            fx = applyContext(context, to: &state)
        }
        return fx
    }

    static func applyRemoteSession(_ remote: WorkoutSession, to state: inout AppState, role: DeviceKind) -> SyncEffects {
        var fx = SyncEffects()
        if state.isTombstoned(remote.id) {
            fx.sendContext = role == .phone
            return fx
        }
        if let done = state.history.first(where: { $0.id == remote.id }) {
            // We already finished it; make sure the other side knows.
            if role == .phone { fx.sendContext = true } else { fx.sendCompleted = done }
            return fx
        }
        guard let local = state.activeSession else {
            state.activeSession = remote
            fx.stateChanged = true
            return fx
        }
        let resolved: WorkoutSession
        if local.id == remote.id {
            resolved = SessionMerge.merge(local, remote)
        } else {
            resolved = SessionMerge.resolveConflict(local, remote)
            let loser = resolved.id == local.id ? remote.id : local.id
            state.addTombstone(loser)
            if role == .phone { fx.sendContext = true }
        }
        if resolved != local {
            state.activeSession = resolved
            fx.stateChanged = true
        }
        if resolved != remote { fx.sendSession = resolved }
        return fx
    }

    static func applyContext(_ context: WatchContext, to state: inout AppState) -> SyncEffects {
        var fx = SyncEffects()
        let before = state
        let local = state.activeSession

        state.program = context.program
        state.settings = context.settings
        for id in context.discardedSessionIDs { state.addTombstone(id) }

        // Keep watch-only finished workouts the phone hasn't acknowledged yet (still in transit).
        let phoneIDs = Set(context.recentHistory.map(\.id))
        let oldestInContext = context.recentHistory.last?.finishedAt ?? .distantPast
        let pending = before.history.filter { !phoneIDs.contains($0.id) && $0.finishedAt > oldestInContext && $0.finishedOn == .watch }
        state.history = (context.recentHistory + pending).sorted { $0.finishedAt > $1.finishedAt }

        // Re-apply progression for pending watch workouts so the watch shows correct next weights
        // until the phone's own context catches up.
        for workout in pending.sorted(by: { $0.finishedAt < $1.finishedAt }) {
            state.history.removeAll { $0.id == workout.id }
            state.applyCompleted(workout)
        }

        switch (local, context.activeSession) {
        case (nil, nil):
            break
        case (nil, let remote?):
            if !state.isTombstoned(remote.id) && !state.hasHistory(id: remote.id) { state.activeSession = remote }
        case (let mine?, nil):
            if state.isTombstoned(mine.id) || phoneIDs.contains(mine.id) {
                state.activeSession = nil
                fx.activeSessionEndedRemotely = true
            } else {
                // Started on the watch while apart, or the phone hasn't received it yet.
                fx.sendSession = mine
            }
        case (let mine?, let remote?):
            var sub = state
            sub.activeSession = mine
            let inner = applyRemoteSession(remote, to: &sub, role: .watch)
            state = sub
            if state.activeSession?.id != mine.id { fx.activeSessionEndedRemotely = true }
            fx.sendSession = inner.sendSession
        }
        // The phone's context is newer than any completed state we may have sent; nothing to resend.
        fx.stateChanged = state != before
        return fx
    }
}
