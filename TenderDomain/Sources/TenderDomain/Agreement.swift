// A sure answer needs two frames that agree.
//
// One frame can be a fold, a glare, a thumb. Two consecutive classifications
// that name the same value are a note. The gate still decides per frame;
// this decides whether the gate's "sure" is said as "sure" or held back as
// "probably" until a second frame agrees. It never makes an answer more
// confident than the gate did — only less.
public struct Agreement: Sendable, Equatable {
    private var last: Verdict?
    public init() {}

    /// Feed the gate's verdict for the newest frame. Returns what to say.
    public mutating func consider(_ verdict: Verdict) -> Verdict {
        defer { last = verdict }
        switch verdict {
        case .sure(let note):
            if case .sure(let previous) = last, previous.value == note.value { return verdict }
            if case .probably(let previous) = last, previous.value == note.value { return verdict }
            return .probably(note)   // sure once is probably; sure twice is sure
        case .probably, .notSure:
            return verdict
        }
    }

    public mutating func reset() { last = nil }
}
