import Testing
@testable import TenderDomain

@Suite("The confidence gate")
struct VerdictTests {
    /// A distribution concentrated on one note.
    private func peaked(_ note: Note, _ p: Double) -> [Note: Double] {
        let rest = (1 - p) / Double(Note.allCases.count - 1)
        var d = Dictionary(uniqueKeysWithValues: Note.allCases.map { ($0, rest) })
        d[note] = p
        return d
    }

    @Test("Total: every distribution yields exactly one verdict, including empty and zero")
    func total() {
        #expect(ConfidenceRule.decide([:]) == .notSure)
        #expect(ConfidenceRule.decide(Dictionary(uniqueKeysWithValues: Note.allCases.map { ($0, 0.0) })) == .notSure)
        #expect(ConfidenceRule.decide(peaked(.n50, 1.0)) == .sure(.n50))
    }

    @Test("Sure needs both the top and the margin, at the boundary inclusive")
    func sureBoundary() {
        #expect(ConfidenceRule.decide(peaked(.n100, 0.90)) == .sure(.n100))
        #expect(ConfidenceRule.decide(peaked(.n100, 0.899)) == .probably(.n100))
        // Top is high enough but the margin is not: two values sharing the mass.
        var split: [Note: Double] = [.n100: 0.90, .n200: 0.10]
        #expect(ConfidenceRule.decide(split) == .sure(.n100))   // margin 0.80
        split = [.n100: 0.55, .n200: 0.45]
        #expect(ConfidenceRule.decide(split) == .notSure)        // top 0.55 < probably
        split = [.n100: 0.65, .n200: 0.35]
        #expect(ConfidenceRule.decide(split) == .probably(.n100))
    }

    @Test("Probably at the boundary inclusive, not sure below")
    func probablyBoundary() {
        #expect(ConfidenceRule.decide(peaked(.n20, 0.60)) == .probably(.n20))
        #expect(ConfidenceRule.decide(peaked(.n20, 0.599)) == .notSure)
    }

    @Test("The case that costs money: 0.51 is never said plainly")
    func fiftyOne() {
        let v = ConfidenceRule.decide([.n500: 0.51, .n1000: 0.49])
        #expect(v == .notSure)
    }

    @Test("Two designs of one value pool before the gate, and the likelier design is reported")
    func pooling() {
        // Neither design clears 0.60 alone; together they clear 0.90 with margin.
        let d: [Note: Double] = [.n500: 0.50, .n500new: 0.45, .n1000: 0.05]
        #expect(ConfidenceRule.decide(d) == .sure(.n500))
        let e: [Note: Double] = [.n500: 0.40, .n500new: 0.55, .n1000: 0.05]
        #expect(ConfidenceRule.decide(e) == .sure(.n500new))
    }

    @Test("Pooling never lowers the top: a peaked single design is unchanged by it")
    func poolingIsMonotone() {
        for note in Note.allCases {
            for p in stride(from: 0.0, through: 1.0, by: 0.05) {
                let v = ConfidenceRule.decide(peaked(note, p))
                switch v {
                case .sure(let n), .probably(let n): #expect(n.value == note.value)
                case .notSure: #expect(p < ConfidenceRule.probablyTop + 0.05)
                }
            }
        }
    }
}

@Suite("Framing")
struct FramingTests {
    @Test("Order: dark before nothing, nothing before bright, bright before blur, blur before ready")
    func order() {
        // Dark: too dark, whatever the coverage — in the dark, coverage means nothing.
        #expect(FramingRule.judge(coverage: 0.0, luminance: 0.05, clipped: 0, detail: 0) == .tooDark)
        #expect(FramingRule.judge(coverage: 0.5, luminance: 0.1, clipped: 0, detail: 0) == .tooDark)
        // Lit, no note: nothing, even if blurred.
        #expect(FramingRule.judge(coverage: 0.0, luminance: 0.5, clipped: 0, detail: 0) == .nothing)
        // A note, bright by clipping, blurred: bright wins.
        #expect(FramingRule.judge(coverage: 0.5, luminance: 0.5, clipped: 0.2, detail: 0) == .tooBright)
        // A note, fine light, blurred: steady.
        #expect(FramingRule.judge(coverage: 0.5, luminance: 0.5, clipped: 0, detail: 0.001) == .steady)
        // A note, fine light, sharp: ready.
        #expect(FramingRule.judge(coverage: 0.5, luminance: 0.5, clipped: 0, detail: 0.05) == .ready)
    }

    @Test("Boundaries are inclusive on the safe side")
    func boundaries() {
        #expect(FramingRule.judge(coverage: FramingRule.leastCoverage, luminance: 0.5, clipped: 0, detail: 1) == .ready)
        #expect(FramingRule.judge(coverage: 0.5, luminance: FramingRule.darkest, clipped: 0, detail: 1) == .ready)
        #expect(FramingRule.judge(coverage: 0.5, luminance: FramingRule.brightest, clipped: 0, detail: 1) == .ready)
        #expect(FramingRule.judge(coverage: 0.5, luminance: 0.5, clipped: 0, detail: FramingRule.leastDetail) == .ready)
    }
}

@Suite("What the app says")
struct AnnouncementTests {
    @Test("Values are words, never numerals, and the design is named only for the redesign")
    func words() {
        #expect(Announcement.text(for: .sure(.n500)) == "five hundred naira.")
        #expect(Announcement.text(for: .sure(.n500new)) == "five hundred naira, new design.")
        #expect(Announcement.text(for: .probably(.n1000new)) == "I think one thousand naira, new design. Check.")
        #expect(Announcement.text(for: .notSure) == "I don't recognise this.")
        for s in Announcement.everything {
            let hasNumeral = s.contains { $0.isNumber }
            #expect(!hasNumeral, "a numeral in speech: \(s)")
        }
    }

    @Test("Ready is not a word; the other four framings are")
    func framings() {
        #expect(Announcement.text(for: .ready) == nil)
        for f in Framing.allCases where f != .ready {
            #expect(Announcement.text(for: f) != nil)
        }
    }

    @Test("Nothing the app says implies authenticity — ADR-0003")
    func noAuthenticityWords() {
        let banned = ["genuine", "real", "fake", "counterfeit", "authentic", "verified"]
        for s in Announcement.everything {
            let lower = s.lowercased()
            for w in banned {
                #expect(!lower.contains(w), "'\(w)' in: \(s)")
            }
        }
    }
}
