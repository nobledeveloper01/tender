// The placeholder announces itself: whatever the frame, the gate says
// "I don't recognise this". A stand-in that could say anything else is a
// stand-in that could ship.
import CoreVideo
import XCTest
import TenderDomain
@testable import Tender

final class ClassifierTests: XCTestCase {
    private func buffer(width: Int = 64, height: Int = 48, fill: UInt8) -> CVPixelBuffer {
        var pb: CVPixelBuffer?
        CVPixelBufferCreate(nil, width, height, kCVPixelFormatType_32BGRA, nil, &pb)
        let b = pb!
        CVPixelBufferLockBaseAddress(b, [])
        memset(CVPixelBufferGetBaseAddress(b), Int32(fill), CVPixelBufferGetBytesPerRow(b) * height)
        CVPixelBufferUnlockBaseAddress(b, [])
        return b
    }

    func testUntrainedClassifierIsAlwaysNotSure() async {
        let c = UntrainedClassifier()
        for fill: UInt8 in [0, 128, 255] {
            let d = await c.classify(Frame(pixels: buffer(fill: fill)))
            XCTAssertNotNil(d)
            XCTAssertEqual(d!.values.reduce(0, +), 1.0, accuracy: 1e-9)
            XCTAssertEqual(ConfidenceRule.decide(d!), .notSure)
        }
    }

    func testFrameStatsOnFlatFrames() {
        let black = FrameStats.measure(buffer(fill: 0))
        XCTAssertEqual(black.luminance, 0, accuracy: 0.01)
        XCTAssertEqual(black.coverage, 0, accuracy: 0.01)
        XCTAssertEqual(black.clipped, 0, accuracy: 0.01)

        let white = FrameStats.measure(buffer(fill: 255))
        XCTAssertEqual(white.luminance, 1, accuracy: 0.01)
        XCTAssertEqual(white.clipped, 1, accuracy: 0.01)
        XCTAssertEqual(white.coverage, 0, accuracy: 0.01)   // a white wall is not a note

        // A black frame is too dark before it is anything else — in the dark,
        // coverage means nothing. A white wall is lit and has no note in it.
        let judgedBlack = FramingRule.judge(coverage: black.coverage, luminance: black.luminance, clipped: black.clipped, detail: black.detail)
        let judgedWhite = FramingRule.judge(coverage: white.coverage, luminance: white.luminance, clipped: white.clipped, detail: white.detail)
        XCTAssertEqual(judgedBlack, .tooDark)
        XCTAssertEqual(judgedWhite, .nothing)
    }
}
