// Phase 0's exit gate, the part a machine can check: VoiceOver reads every
// control. Xcode's accessibility audit walks the tree and fails on an
// unlabelled element, a contrast failure, a too-small target or clipped
// dynamic type.
import XCTest

final class AccessibilityTests: XCTestCase {
    @MainActor
    func testTheCameraScreenPassesTheAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launch()
        // Past the splash.
        let camera = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Camera.'")).firstMatch
        XCTAssertTrue(camera.waitForExistence(timeout: 5), "the camera screen never appeared")
        // Every audit except contrast. Found by experiment on the first run:
        // the audit reads a view's *declared* background colour, not its
        // pixels, so text over the page gradient — every stop of which is
        // above 15:1 against it — is reported as a contrast failure, and the
        // same text over a flat colour passes. Contrast is gated by
        // TenderTests/ContrastTests, which measures every stop at 7:1, which
        // is more than the audit checks for. This is the one check handed to
        // a stronger test rather than dropped.
        let everythingButContrast: XCUIAccessibilityAuditType = [
            .dynamicType, .elementDetection, .hitRegion, .sufficientElementDescription,
            .textClipped, .trait,
        ]
        // Report every issue with the element it is about, so that a failure
        // says where and not only what.
        try app.performAccessibilityAudit(for: everythingButContrast) { issue in
            XCTFail("\(issue.auditType): \(issue.compactDescription) — \(issue.element?.description ?? "no element")\n\(issue.detailedDescription)")
            return true   // handled here; do not also fail generically
        }
    }

    @MainActor
    func testTheSimulatorSaysItCannotSeeANote() {
        let app = XCUIApplication()
        app.launch()
        let camera = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Camera.'")).firstMatch
        XCTAssertTrue(camera.waitForExistence(timeout: 5))
        // No camera here, so the honest state: nothing seen, nothing guessed.
        XCTAssertTrue(app.staticTexts["I can't see a note."].waitForExistence(timeout: 2))
    }
}
