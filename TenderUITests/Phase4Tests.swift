// Phase 4 groundwork that a simulator can prove: the largest accessibility
// text size without a clipped word, the splash sweeping with Reduce Motion
// on, and the tap that repeats. The audit runs every check but contrast (see
// AccessibilityTests for why) at each size.
import XCTest

final class Phase4Tests: XCTestCase {
    static let everythingButContrast: XCUIAccessibilityAuditType = [
        .dynamicType, .elementDetection, .hitRegion, .sufficientElementDescription, .textClipped, .trait,
    ]

    @MainActor
    private func launch(_ extra: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = extra + ["-silent"]
        app.launch()
        let camera = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Camera.'")).firstMatch
        XCTAssertTrue(camera.waitForExistence(timeout: 5), "the camera screen never appeared")
        return app
    }

    @MainActor
    private func audit(_ app: XCUIApplication) throws {
        try app.performAccessibilityAudit(for: Self.everythingButContrast) { issue in
            XCTFail("\(issue.auditType): \(issue.compactDescription) — \(issue.element?.description ?? "no element")")
            return true
        }
    }

    /// The largest accessibility size, with the answer on screen — the longest
    /// sentence the app shows — and the audit's clipped-text check over it.
    @MainActor
    func testTheLargestTextSizeClipsNothing() throws {
        let app = launch(["-fixture", "note-like",
                          "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        XCTAssertTrue(app.staticTexts["I don't recognise this."].waitForExistence(timeout: 5))
        try audit(app)
        // And the settings sheet, and the learn screen behind it.
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.switches.firstMatch.waitForExistence(timeout: 3))
        try audit(app)
        app.buttons["Learn the patterns"].firstMatch.tap()
        XCTAssertTrue(app.buttons["five naira, short"].waitForExistence(timeout: 3))
        try audit(app)
    }

    /// The learn screen: eight rows, each labelled with the value and its
    /// pattern in words, so VoiceOver reads "five hundred naira, long long".
    @MainActor
    func testTheLearnScreenNamesEveryValueAndItsPattern() throws {
        let app = launch(["-fixture", "blank"])
        app.buttons["Settings"].tap()
        app.buttons["Learn the patterns"].firstMatch.tap()
        let expected = [
            "five naira, short", "ten naira, short short", "twenty naira, short short short",
            "fifty naira, long", "one hundred naira, long short", "two hundred naira, long short short",
            "five hundred naira, long long", "one thousand naira, long long long",
        ]
        for label in expected {
            XCTAssertTrue(app.buttons[label].waitForExistence(timeout: 3), label)
        }
        // No thousands separator: `Text("\(Int)")` prints 1,000 for the locale,
        // and a comma is a speck to a low-vision reader. Plain digits, every value.
        XCTAssertTrue(app.staticTexts["₦1000"].exists, "the numeral should be 1000, not 1,000")
        app.buttons["five hundred naira, long long"].tap()   // says it, pulses it; must not crash or navigate
        XCTAssertTrue(app.buttons["five hundred naira, long long"].exists)
        try audit(app)
    }

    /// With Reduce Motion the splash draws no animation. It must still end,
    /// because it is a timer that ends it, not an animation.
    @MainActor
    func testTheSplashSweepsWithReduceMotion() {
        let app = XCUIApplication()
        app.launchArguments = ["-reduceMotion", "-silent"]
        app.launch()
        let camera = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Camera.'")).firstMatch
        XCTAssertTrue(camera.waitForExistence(timeout: 5), "the splash never swept with Reduce Motion on")
    }

    /// A tap anywhere says it again, and changes nothing.
    @MainActor
    func testATapRepeatsAndChangesNothing() {
        let app = launch(["-fixture", "blank"])
        let camera = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Camera.'")).firstMatch
        XCTAssertTrue(app.staticTexts["I can't see a note."].waitForExistence(timeout: 5))
        let before = camera.value as? String
        camera.tap()
        XCTAssertEqual(camera.value as? String, before)
        XCTAssertTrue(app.staticTexts["I can't see a note."].exists)
    }
}
