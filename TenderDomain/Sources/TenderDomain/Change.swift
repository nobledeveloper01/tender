// The conductor problem. "I paid a thousand for something costing three
// hundred and fifty. Is this six hundred and fifty?" Subtracts; never moves.
public struct Change: Sendable, Equatable {
    public let paid: Int
    public let cost: Int
    public private(set) var received = Tally()

    public init(paid: Int, cost: Int) {
        self.paid = paid
        self.cost = cost
    }

    public var due: Int { max(paid - cost, 0) }
    public var shortfall: Int { max(due - received.total, 0) }
    public var excess: Int { max(received.total - due, 0) }

    public mutating func receive(_ value: Naira) { received.add(value) }

    /// What to say after each note, or when asked.
    public var spoken: String {
        if paid < cost { return "You paid less than it cost. No change is due." }
        if due == 0 { return "No change is due." }
        if received.count == 0 { return "\(SpokenNumber.words(due).capitalisedFirst) naira is due." }
        if shortfall > 0 { return "\(SpokenNumber.words(received.total).capitalisedFirst) so far. \(SpokenNumber.words(shortfall).capitalisedFirst) naira still to come." }
        if excess > 0 { return "That's \(SpokenNumber.words(excess)) naira too much." }
        return "That's the right change. \(SpokenNumber.words(due).capitalisedFirst) naira."
    }
}
