// The one dead end the platform can force. It must be spoken, it must have a
// forward path, and it must pass the audit like every other screen.
import XCTest

final class DeniedTests: XCTestCase {
    @MainActor
    func testADeniedCameraIsOneSentenceAndOneButton() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-cameraDenied"]
        app.launch()
        let sentence = app.staticTexts["Tender needs the camera to see the note. Open Settings to allow it."]
        XCTAssertTrue(sentence.waitForExistence(timeout: 5), "the denied state never appeared")
        XCTAssertTrue(app.buttons["Open Settings"].exists)
        XCTAssertFalse(app.staticTexts["I can't see a note."].exists, "a denied camera must not masquerade as an empty one")
        try app.performAccessibilityAudit(for: [.dynamicType, .elementDetection, .hitRegion,
                                               .sufficientElementDescription, .textClipped, .trait]) { issue in
            XCTFail("\(issue.auditType): \(issue.compactDescription) — \(issue.element?.description ?? "")")
            return true
        }
    }
}
