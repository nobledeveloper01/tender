// Two numbers decide how sure the app sounds.
//
// The classifier returns a distribution over the eleven designs. This file
// turns it into one of three sentences. It never sees an image, a model or a
// clock — it sees `[Note: Double]` — so a test can hand it 0.51 and ask.

/// What the app will say about a note.
public enum Verdict: Sendable, Equatable {
    /// Said plainly: "five hundred naira."
    case sure(Note)
    /// Said with a caveat: "I think five hundred naira. Check."
    case probably(Note)
    /// "I don't recognise this."
    case notSure
}

public enum ConfidenceRule {
    /// Top pooled probability at or above which the answer is `sure`…
    public static let sureTop = 0.90
    /// …provided the margin over the second value is at least this.
    public static let sureMargin = 0.50
    /// Top pooled probability at or above which the answer is `probably`.
    public static let probablyTop = 0.60

    /// Decide. Pools the two designs of a value before comparing, because the
    /// user cares about the value; the design reported is the likelier of the
    /// two. Total: an empty or all-zero distribution is `notSure`.
    public static func decide(_ distribution: [Note: Double]) -> Verdict {
        var byValue: [Naira: (total: Double, best: Note, bestScore: Double)] = [:]
        for (note, p) in distribution {
            let v = note.value
            if let current = byValue[v] {
                let best = p > current.bestScore ? (note, p) : (current.best, current.bestScore)
                byValue[v] = (current.total + p, best.0, best.1)
            } else {
                byValue[v] = (p, note, p)
            }
        }
        let ranked = byValue.values.sorted { $0.total > $1.total }
        guard let top = ranked.first, top.total > 0 else { return .notSure }
        let second = ranked.dropFirst().first?.total ?? 0
        if top.total >= sureTop && top.total - second >= sureMargin { return .sure(top.best) }
        if top.total >= probablyTop { return .probably(top.best) }
        return .notSure
    }
}
