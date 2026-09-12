// The two toggles reach the two channels. Absent means on; false means off;
// and the announcer and haptics consult the value when they act, not when
// they were made.
import XCTest
@testable import Tender

final class PreferencesTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: "ng.tender.tests.preferences")
        defaults.removePersistentDomain(forName: "ng.tender.tests.preferences")
    }

    func testAbsentMeansOn() {
        XCTAssertTrue(Preferences.speechEnabled(defaults))
        XCTAssertTrue(Preferences.hapticsEnabled(defaults))
    }

    func testFalseMeansOffAndTrueMeansOn() {
        defaults.set(false, forKey: Preferences.speechKey)
        defaults.set(false, forKey: Preferences.hapticsKey)
        XCTAssertFalse(Preferences.speechEnabled(defaults))
        XCTAssertFalse(Preferences.hapticsEnabled(defaults))
        defaults.set(true, forKey: Preferences.speechKey)
        XCTAssertTrue(Preferences.speechEnabled(defaults))
    }

    @MainActor
    func testTheAnnouncerAndHapticsReadTheSettingWhenTheyAct() {
        let announcer = Announcer(), haptics = Haptics()
        UserDefaults.standard.set(false, forKey: Preferences.speechKey)
        UserDefaults.standard.set(false, forKey: Preferences.hapticsKey)
        XCTAssertFalse(announcer.speakWhenVoiceOverOff)
        XCTAssertFalse(haptics.enabled)
        UserDefaults.standard.removeObject(forKey: Preferences.speechKey)
        UserDefaults.standard.removeObject(forKey: Preferences.hapticsKey)
        // Speech may still be silenced by the test host's own -silent flag;
        // haptics has no such flag and must read as on.
        XCTAssertTrue(haptics.enabled)
    }
}
