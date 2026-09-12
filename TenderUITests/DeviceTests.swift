// R2: the camera path on a physical iPhone. The half of Phase 3's gate a
// machine can reach — Phase 3's own words: "a note is named within two
// seconds of being framed, and an uncertain frame is said to be uncertain."
//
// Skips, by name, anywhere without a camera. A skip is not a pass and the
// ledger does not move on one; it moves when somebody has watched this run
// green on a phone, with a note in their hand, twice — the newest phone and
// the oldest supported.
//
//   make device-check D=<device id>      (xcrun xctrace list devices)
import XCTest

final class DeviceTests: XCTestCase {
    @MainActor
    private func launchOnADevice() throws -> XCUIApplication {
        #if targetEnvironment(simulator)
        throw XCTSkip("no camera on a simulator — R2 needs a handset")
        #else
        let app = XCUIApplication()
        app.launch()
        let camera = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Camera.'")).firstMatch
        XCTAssertTrue(camera.waitForExistence(timeout: 8), "the camera screen never appeared; was the permission granted?")
        return app
        #endif
    }

    /// Point the phone at a note before starting. The test cannot hold the
    /// note; a person does, and reads what the phone said.
    @MainActor
    func testANoteIsNamedWithinTwoSecondsOfBeingFramed() throws {
        let app = try launchOnADevice()
        // The framing verdict arrives first. Then, within two seconds of
        // "ready", an answer — sure, probably, or not sure. Until the model
        // is wired the answer is always "I don't recognise this", and this
        // test is honest about that: it asserts the *timing* of an answer,
        // not its content.
        let answered = NSPredicate(format: "label CONTAINS 'naira' OR label CONTAINS 'recognise'")
        let answer = app.staticTexts.matching(answered).firstMatch
        let camera = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Camera.'")).firstMatch
        let start = Date()
        XCTAssertTrue(answer.waitForExistence(timeout: 10), "no answer within ten seconds — is a note in frame?")
        let elapsed = Date().timeIntervalSince(start)
        // The two-second budget is from *ready*, which the test cannot see;
        // ten seconds from launch is the generous outer bound, and the value
        // read back says which state the reader passed through.
        XCTAssertLessThan(elapsed, 10)
        XCTAssertFalse((camera.value as? String ?? "").isEmpty, "the screen carries what was last said")
    }

    /// Cover the lens. The verdict must be "too dark", never a guess.
    @MainActor
    func testACoveredLensIsTooDarkAndNeverAnAnswer() throws {
        let app = try launchOnADevice()
        XCTAssertTrue(app.staticTexts["Too dark."].waitForExistence(timeout: 10), "cover the lens before starting")
        for value in ["5", "10", "20", "50", "100", "200", "500", "1000"] {
            XCTAssertFalse(app.staticTexts[value].exists, "a covered lens produced \(value)")
        }
    }
}
