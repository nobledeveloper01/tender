// The pipeline end to end on the simulator, from a fixture photograph
// instead of a camera: measured, judged, classified by the placeholder,
// decided, said. Three fixtures, three different sentences — and the one
// that reaches the classifier gets "I don't recognise this", which is the
// only thing the placeholder may ever say.
import XCTest

final class PipelineTests: XCTestCase {
    @MainActor
    private func launch(fixture: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-fixture", fixture]
        app.launch()
        let camera = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Camera.'")).firstMatch
        XCTAssertTrue(camera.waitForExistence(timeout: 5))
        return app
    }

    @MainActor
    func testANoteLikeFrameReachesTheClassifierAndThePlaceholderDoesNotGuess() {
        let app = launch(fixture: "note-like")
        XCTAssertTrue(app.staticTexts["I don't recognise this."].waitForExistence(timeout: 5),
                      "a ready frame should reach the placeholder, which recognises nothing")
        XCTAssertFalse(app.staticTexts["I can't see a note."].exists)
        // Whatever the frame, the placeholder never names a value.
        for value in ["5", "10", "20", "50", "100", "200", "500", "1000"] {
            XCTAssertFalse(app.staticTexts[value].exists, "the placeholder said \(value)")
        }
    }

    @MainActor
    func testADarkFrameIsSaidToBeDark() {
        let app = launch(fixture: "dark")
        XCTAssertTrue(app.staticTexts["Too dark."].waitForExistence(timeout: 5))
    }

    @MainActor
    func testAWhiteWallIsNotANote() {
        let app = launch(fixture: "blank")
        XCTAssertTrue(app.staticTexts["I can't see a note."].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Too bright."].exists, "nothing is decided before light")
    }
}
