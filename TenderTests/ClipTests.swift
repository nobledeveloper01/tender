// The bundled clips: every language, every stem, in the bundle; the player
// can say every verdict in every recorded language; and English never uses
// a clip. The placeholder's self-announcement is checked by ear in the
// journal and by `make audio-check` by list — a test cannot hear.
import XCTest
import TenderDomain
@testable import Tender

@MainActor
final class ClipTests: XCTestCase {
    func testEveryRecordedLanguageHasEveryStemInTheBundle() {
        for language in Language.recorded {
            for stem in ClipStem.allCases {
                XCTAssertNotNil(ClipPlayer.url(language, stem), "\(language.rawValue)-\(stem.rawValue).m4a")
            }
        }
    }

    func testEveryVerdictCanBeSaidInEveryRecordedLanguageAndNeverInEnglish() {
        let verdicts: [Verdict] = [.sure(.n5), .sure(.n1000new), .probably(.n500), .probably(.n200new), .notSure]
        for v in verdicts {
            for language in Language.recorded {
                XCTAssertTrue(ClipPlayer.canSay(v, in: language), "\(v) in \(language.rawValue)")
            }
            XCTAssertFalse(ClipPlayer.canSay(v, in: .en), "English is VoiceOver's, never a clip")
        }
    }

    func testTheDefaultLanguageIsEnglishAndTheSettingIsRead() {
        let d = UserDefaults(suiteName: "ng.tender.tests.language")!
        d.removePersistentDomain(forName: "ng.tender.tests.language")
        XCTAssertEqual(Preferences.language(d), .en)
        d.set("ha", forKey: Preferences.languageKey)
        XCTAssertEqual(Preferences.language(d), .ha)
        d.set("xx", forKey: Preferences.languageKey)
        XCTAssertEqual(Preferences.language(d), .en, "an unknown code falls back to English, never to silence")
    }

    func testOnlyEnglishIsOfferedWhileEveryClipIsAPlaceholder() {
        // placeholders.txt is bundled and lists all sixty today.
        XCTAssertEqual(ClipPlayer.offered(), [.en], "a language with a placeholder in it must not be offered")
    }
}
