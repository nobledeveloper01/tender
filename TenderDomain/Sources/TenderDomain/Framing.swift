// Whether a frame is worth classifying at all.
//
// The camera hands the domain four numbers and the domain says one of five
// words. The thresholds are provisional — they have never met a photograph of
// a note, only a spec — and RELEASE-GATES says so (R2). Being strict is the
// safe direction: a rejected frame costs half a second of "hold steady"; an
// accepted bad one costs a wrong answer to somebody holding cash.

/// The verdict on a single camera frame, before any classification.
public enum Framing: Sendable, Equatable, CaseIterable {
    case nothing      // no note-coloured region large enough to be a note
    case tooDark
    case tooBright
    case closer       // a note, but small in the frame: bring it nearer
    case steady       // a note, but blurred: the hand is moving
    case ready
}

public enum FramingRule {
    /// Fraction of the frame that must be note-like before it is a note at all.
    public static let leastCoverage = 0.15
    /// Below this it is a note, but a small one: "closer".
    public static let nearEnough = 0.30
    /// Mean luminance, 0…1, below which the frame is too dark.
    public static let darkest = 0.18
    /// Mean luminance above which it is too bright.
    public static let brightest = 0.82
    /// Fraction of clipped pixels above which it is too bright regardless of the mean.
    public static let mostClipped = 0.10
    /// High-frequency energy as a share of the frame's own contrast, below which it is blurred.
    public static let leastDetail = 0.012

    /// Judge one frame. Total: every input yields exactly one `Framing`.
    ///
    /// Order matters and is asserted. Darkness first: in the dark, coverage
    /// cannot be measured, so "I can't see a note" would be a claim about
    /// the note when the truth is about the light — and it sends a blind
    /// user checking their grip instead of finding a window. Found by the
    /// dark fixture on the simulator, which the first version called
    /// `nothing`. Then `nothing`, then the rest.
    public static func judge(coverage: Double, luminance: Double, clipped: Double, detail: Double) -> Framing {
        if luminance < darkest { return .tooDark }
        if coverage < leastCoverage { return .nothing }
        if luminance > brightest || clipped > mostClipped { return .tooBright }
        if coverage < nearEnough { return .closer }
        if detail < leastDetail { return .steady }
        return .ready
    }
}
