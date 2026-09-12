import Testing
@testable import TenderDomain

@Suite("Closer")
struct CloserTests {
    @Test("A note that is there but small is 'closer', between nothing and steady")
    func closer() {
        #expect(FramingRule.judge(coverage: 0.20, luminance: 0.5, clipped: 0, detail: 1) == .closer)
        #expect(FramingRule.judge(coverage: 0.10, luminance: 0.5, clipped: 0, detail: 1) == .nothing)
        #expect(FramingRule.judge(coverage: 0.35, luminance: 0.5, clipped: 0, detail: 0.001) == .steady)
        #expect(FramingRule.judge(coverage: 0.35, luminance: 0.5, clipped: 0, detail: 1) == .ready)
        // Light still wins over size.
        #expect(FramingRule.judge(coverage: 0.20, luminance: 0.05, clipped: 0, detail: 1) == .tooDark)
    }

    @Test("Closer is said, and felt as one short")
    func said() {
        #expect(Announcement.text(for: .closer) == "Closer.")
        #expect(HapticPattern.render(Framing.closer)?.pulses == [.short])
    }
}

@Suite("Agreement")
struct AgreementTests {
    @Test("Sure once is probably; sure twice is sure")
    func twoFrames() {
        var a = Agreement()
        #expect(a.consider(.sure(.n500)) == .probably(.n500))
        #expect(a.consider(.sure(.n500)) == .sure(.n500))
        #expect(a.consider(.sure(.n500new)) == .sure(.n500new), "the same value in the other design still agrees")
    }

    @Test("A different value in between starts over")
    func disagreement() {
        var a = Agreement()
        #expect(a.consider(.sure(.n500)) == .probably(.n500))
        #expect(a.consider(.sure(.n1000)) == .probably(.n1000))
        #expect(a.consider(.sure(.n1000)) == .sure(.n1000))
    }

    @Test("Never more confident than the gate: probably and not sure pass through unchanged")
    func neverRaises() {
        var a = Agreement()
        for v in [Verdict.probably(.n50), .notSure, .probably(.n50), .probably(.n50)] {
            #expect(a.consider(v) == v)
        }
        // Probably then sure of the same value: sure, because two frames agreed on the value.
        #expect(a.consider(.sure(.n50)) == .sure(.n50))
    }
}

@Suite("How sure")
struct SurenessTests {
    @Test("Four bands, and never a word about the note")
    func bands() {
        #expect(Sureness.describe([.n500: 0.98, .n1000: 0.02]).hasPrefix("Very sure"))
        #expect(Sureness.describe([.n500: 0.91, .n1000: 0.09]).hasPrefix("Sure"))
        #expect(Sureness.describe([.n500: 0.65, .n1000: 0.35]).hasPrefix("Fairly sure"))
        #expect(Sureness.describe([.n500: 0.5, .n1000: 0.5]).hasPrefix("Not sure"))
        #expect(Sureness.describe([:]).hasPrefix("I couldn't read"))
        for d in [[Note.n500: 0.98], [.n500: 0.65, .n1000: 0.35]] {
            let s = Sureness.describe(d).lowercased()
            for w in ["genuine", "real", "fake", "counterfeit", "authentic"] { #expect(!s.contains(w)) }
        }
    }
}

@Suite("The light policy")
struct LightPolicyTests {
    @Test("Dark for half a second: torch on. Still dark with the torch: try a window, once.")
    func escalation() {
        var p = LightPolicy()
        var advice: [LightAdvice] = []
        for _ in 0..<(LightPolicy.framesBeforeTorch + LightPolicy.framesBeforeAdvice + 30) {
            advice.append(p.consider(.tooDark))
        }
        #expect(advice.filter { $0 == .torchOn }.count == 1)
        #expect(advice.filter { $0 == .tryAWindow }.count == 1)
        #expect(advice.firstIndex(of: .torchOn)! < advice.firstIndex(of: .tryAWindow)!)
        #expect(p.torch)
    }

    @Test("A single lit frame resets the count; the torch stays on")
    func lightResets() {
        var p = LightPolicy()
        for _ in 0..<LightPolicy.framesBeforeTorch { _ = p.consider(.tooDark) }
        #expect(p.torch)
        _ = p.consider(.ready)
        for _ in 0..<(LightPolicy.framesBeforeAdvice - 1) { #expect(p.consider(.tooDark) == .nothing) }
        #expect(p.consider(.tooDark) == .tryAWindow)
    }
}

@Suite("Tally and change")
struct MoneyArithmeticTests {
    @Test("A tally adds, speaks, and clears")
    func tally() {
        var t = Tally()
        #expect(t.spoken == "Nothing counted yet.")
        t.add(.n500); t.add(.n200); t.add(.n500)
        #expect(t.total == 1200)
        #expect(t.spoken == "Three notes. One thousand two hundred naira so far.")
        t.removeLast()
        #expect(t.total == 700)
        t.clear()
        #expect(t.count == 0)
    }

    @Test("The conductor problem")
    func change() {
        var c = Change(paid: 1000, cost: 350)
        #expect(c.due == 650)
        #expect(c.spoken == "Six hundred and fifty naira is due.")
        c.receive(.n500)
        #expect(c.spoken == "Five hundred so far. One hundred and fifty naira still to come.")
        c.receive(.n100); c.receive(.n50)
        #expect(c.spoken == "That's the right change. Six hundred and fifty naira.")
        c.receive(.n20)
        #expect(c.spoken == "That's twenty naira too much.")
    }

    @Test("Never negative: paying less than it cost, or nothing due")
    func neverNegative() {
        let under = Change(paid: 200, cost: 500)
        #expect(under.due == 0 && under.shortfall == 0)
        #expect(under.spoken == "You paid less than it cost. No change is due.")
        #expect(Change(paid: 500, cost: 500).spoken == "No change is due.")
    }

    @Test("Numbers as words, the way a Nigerian voice says them")
    func words() {
        #expect(SpokenNumber.words(0) == "zero")
        #expect(SpokenNumber.words(15) == "fifteen")
        #expect(SpokenNumber.words(40) == "forty")
        #expect(SpokenNumber.words(105) == "one hundred and five")
        #expect(SpokenNumber.words(650) == "six hundred and fifty")
        #expect(SpokenNumber.words(1000) == "one thousand")
        #expect(SpokenNumber.words(1250) == "one thousand two hundred and fifty")
        #expect(SpokenNumber.words(2005) == "two thousand and five")
        #expect(SpokenNumber.words(20000) == "twenty thousand")
    }
}
