// A running total, for counting a handful of change. Adds; never moves.
// Held until cleared, never stored. ADR-0004.
public struct Tally: Sendable, Equatable {
    public private(set) var notes: [Naira] = []
    public init() {}

    public var total: Int { notes.reduce(0) { $0 + $1.rawValue } }
    public var count: Int { notes.count }

    public mutating func add(_ value: Naira) { notes.append(value) }
    public mutating func removeLast() { _ = notes.popLast() }
    public mutating func clear() { notes.removeAll() }

    /// "Three notes. One thousand two hundred naira so far."
    public var spoken: String {
        guard !notes.isEmpty else { return "Nothing counted yet." }
        let n = count == 1 ? "One note." : "\(SpokenNumber.words(count).capitalisedFirst) notes."
        return "\(n) \(SpokenNumber.words(total).capitalisedFirst) naira so far."
    }
}
