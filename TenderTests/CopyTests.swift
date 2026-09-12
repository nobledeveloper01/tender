// No sentence anywhere says or implies whether a note is genuine. ADR-0003.
// `make copy-check` reads the source files for the same list without
// building; this test reads the strings at runtime so the two cannot drift.
import XCTest
import TenderDomain
@testable import Tender

final class CopyTests: XCTestCase {
    static let banned = ["genuine", "real", "fake", "counterfeit", "authentic", "verified"]

    func testNothingTheAppSaysImpliesAuthenticity() {
        let everything = Announcement.everything + [
            Strings.appName, Strings.cameraDenied, Strings.openSettings, Strings.noCameraHere,
            Strings.repeatAction, Strings.startOver, Strings.settings, Strings.speechWhenVoiceOverOff,
            Strings.haptics, Strings.cameraScreenLabel, Strings.newDesign,
        ]
        for s in everything {
            let words = s.lowercased().split { !$0.isLetter }.map(String.init)
            for w in Self.banned {
                XCTAssertFalse(words.contains(w), "'\(w)' in: \(s)")
            }
        }
    }

    func testNoExclamationMarksAndNoPlease() {
        for s in Announcement.everything {
            XCTAssertFalse(s.contains("!"), s)
            XCTAssertFalse(s.lowercased().contains("please"), s)
        }
    }
}
