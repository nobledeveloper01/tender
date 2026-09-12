import Testing
@testable import TenderDomain

@Suite("The eleven notes")
struct NoteTests {
    @Test("There are eleven designs and eight values")
    func counts() {
        #expect(Note.allCases.count == 11)
        #expect(Naira.allCases.count == 8)
    }

    @Test("Every value has at least one design, and the redesigned three have two")
    func everyValueIsCovered() {
        for value in Naira.allCases {
            let designs = Note.allCases.filter { $0.value == value }
            let expected = [Naira.n200, .n500, .n1000].contains(value) ? 2 : 1
            #expect(designs.count == expected, "\(value) has \(designs.count) designs")
        }
    }

    @Test("Exactly three notes are the 2022 redesign")
    func redesigns() {
        #expect(Note.allCases.filter { $0.design == .redesign2022 }.count == 3)
    }

    @Test("Raw values are stable class labels")
    func labels() {
        #expect(Note.n500new.rawValue == "n500new")
        #expect(Note(rawValue: "n1000") == .n1000)
    }
}

@Suite("The haptic vocabulary")
struct HapticTests {
    @Test("Every value has a distinct pattern")
    func distinct() {
        let patterns = Naira.allCases.map { HapticPattern.pulses(for: $0) }
        for (i, a) in patterns.enumerated() {
            for (j, b) in patterns.enumerated() where i != j {
                #expect(a != b, "\(Naira.allCases[i]) and \(Naira.allCases[j]) feel the same")
            }
        }
    }

    @Test("Both designs of a value feel the same")
    func designsFeelAlike() {
        for note in Note.allCases {
            let twin = Note.allCases.first { $0.value == note.value && $0 != note }
            if let twin {
                #expect(HapticPattern.pulses(for: note.value) == HapticPattern.pulses(for: twin.value))
            }
        }
    }

    @Test("The hedged answer is the same pattern at half strength")
    func hedgedIsHalf() {
        let sure = HapticPattern.render(.sure(.n500))
        let probably = HapticPattern.render(.probably(.n500))
        #expect(sure.pulses == probably.pulses)
        #expect(sure.intensity == 1.0)
        #expect(probably.intensity == 0.5)
    }

    @Test("Not sure, too dark and too bright feel the same: the app has nothing for you yet")
    func nothingForYou() {
        let notSure = HapticPattern.render(.notSure)
        #expect(notSure.pulses == [.long])
        #expect(HapticPattern.render(.tooDark)?.pulses == [.long])
        #expect(HapticPattern.render(.tooBright)?.pulses == [.long])
        #expect(HapticPattern.render(Framing.nothing) == nil)
        #expect(HapticPattern.render(Framing.ready) == nil)
    }
}
