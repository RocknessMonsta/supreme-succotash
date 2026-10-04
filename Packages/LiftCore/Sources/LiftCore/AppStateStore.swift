import Foundation

/// Persists `AppState` as JSON with atomic writes. Safe to call from any thread.
public final class AppStateStore: @unchecked Sendable {
    public let url: URL
    private let lock = NSLock()

    public init(url: URL) {
        self.url = url
    }

    /// `<Application Support>/<fileName>`; the directory is created if missing.
    public static func defaultURL(fileName: String = "lift48-state.json") -> URL {
        let fm = FileManager.default
        let base = (try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? fm.temporaryDirectory
        try? fm.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent(fileName)
    }

    /// Returns nil when there is no file yet. An unreadable/corrupt file is moved to `<name>.corrupt`
    /// (replacing any earlier one) so the data isn't lost, and nil is returned.
    public func load() -> AppState? {
        lock.lock()
        defer { lock.unlock() }
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try Self.makeDecoder().decode(AppState.self, from: data)
        } catch {
            let aside = url.appendingPathExtension("corrupt")
            let fm = FileManager.default
            try? fm.removeItem(at: aside)
            try? fm.moveItem(at: url, to: aside)
            return nil
        }
    }

    public func save(_ state: AppState) throws {
        lock.lock()
        defer { lock.unlock() }
        let data = try Self.makeEncoder().encode(state)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }

    // MARK: Coding

    /// Dates are written as integer milliseconds since 1970 (same as the sync wire format).
    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .custom { date, enc in
            var container = enc.singleValueContainer()
            try container.encode(Int64((date.timeIntervalSince1970 * 1000).rounded()))
        }
        return encoder
    }

    /// Reads either milliseconds since 1970 (number) or an ISO8601 string (with or without fractions).
    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { dec in
            let container = try dec.singleValueContainer()
            if let ms = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: ms / 1000)
            }
            let string = try container.decode(String.self)
            let plain = ISO8601DateFormatter()
            plain.formatOptions = [.withInternetDateTime]
            let fractional = ISO8601DateFormatter()
            fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = plain.date(from: string) ?? fractional.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized date: \(string)")
        }
        return decoder
    }
}
