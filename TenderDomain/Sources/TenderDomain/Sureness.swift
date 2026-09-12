// "How sure?" — the two numbers, in words, when asked. About the photograph
// and the reading of it; never about the note. ADR-0003.
public enum Sureness {
    /// The top pooled probability and the margin over the second, in words.
    public static func describe(_ distribution: [Note: Double]) -> String {
        var byValue: [Naira: Double] = [:]
        for (note, p) in distribution { byValue[note.value, default: 0] += p }
        let ranked = byValue.values.sorted(by: >)
        guard let top = ranked.first, top > 0 else { return "I couldn't read it at all." }
        let second = ranked.dropFirst().first ?? 0
        let margin = top - second
        switch (top, margin) {
        case (0.95..., 0.7...): return "Very sure. Nothing else came close."
        case (ConfidenceRule.sureTop..., ConfidenceRule.sureMargin...): return "Sure. One other value came a distant second."
        case (ConfidenceRule.probablyTop..., _): return "Fairly sure. Another value was close, so check."
        default: return "Not sure. It could be more than one thing."
        }
    }
}
