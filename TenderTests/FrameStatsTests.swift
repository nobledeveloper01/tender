// The four numbers the judge decides from, on frames built to move each one.
// Flat frames are in ClassifierTests; these are the frames that are not flat.
import CoreVideo
import XCTest
@testable import Tender

final class FrameStatsTests: XCTestCase {
    /// A 640×480 BGRA frame filled by a function of (x, y).
    private func frame(_ pixel: (Int, Int) -> (r: Int, g: Int, b: Int)) -> CVPixelBuffer {
        var pb: CVPixelBuffer?
        CVPixelBufferCreate(nil, 640, 480, kCVPixelFormatType_32BGRA, nil, &pb)
        CVPixelBufferLockBaseAddress(pb!, [])
        let base = CVPixelBufferGetBaseAddress(pb!)!.assumingMemoryBound(to: UInt8.self)
        let stride = CVPixelBufferGetBytesPerRow(pb!)
        for y in 0..<480 {
            for x in 0..<640 {
                let p = pixel(x, y), i = y * stride + x * 4
                base[i] = UInt8(clamping: p.b); base[i + 1] = UInt8(clamping: p.g)
                base[i + 2] = UInt8(clamping: p.r); base[i + 3] = 255
            }
        }
        CVPixelBufferUnlockBaseAddress(pb!, [])
        return pb!
    }

    private func hash(_ x: Int, _ y: Int) -> Int {
        var h = UInt32(truncatingIfNeeded: x &* 73856093 ^ y &* 19349663)
        h = h &* 2654435761
        return Int(h >> 24) - 128
    }

    func testSharpHasMoreDetailThanBlurred() {
        // A note-coloured field with fine texture, and the same field with the
        // texture varying slowly — what a moving hand does to it.
        let sharp = FrameStats.measure(frame { x, y in
            let n = hash(x, y) / 3
            return (150 + n, 120 + n, 60 + n / 2)
        })
        let blurred = FrameStats.measure(frame { x, y in
            let n = hash(x / 32, y / 32) / 3
            return (150 + n, 120 + n, 60 + n / 2)
        })
        XCTAssertGreaterThan(sharp.detail, blurred.detail * 4, "\(sharp.detail) vs \(blurred.detail)")
        XCTAssertGreaterThan(sharp.coverage, 0.9, "a frame full of note-coloured paper")
        XCTAssertGreaterThan(blurred.coverage, 0.9)
        XCTAssertEqual(sharp.luminance, blurred.luminance, accuracy: 0.05)
    }

    func testCoverageIsTheNoteNotTheTable() {
        // A note-coloured rectangle covering a quarter of a grey table.
        let stats = FrameStats.measure(frame { x, y in
            let inNote = x >= 160 && x < 480 && y >= 120 && y < 360
            return inNote ? (150, 120, 60) : (110, 110, 108)
        })
        XCTAssertEqual(stats.coverage, 0.25, accuracy: 0.03)
    }

    func testAHandIsNoteColouredToThisHeuristicAndThatIsKnown() {
        // Warm skin sits in the same luminance and saturation band as the ₦5,
        // ₦10 and ₦1000, so the colour gate does not exclude a hand — it
        // excludes walls, tables and the dark. This asserts the limitation so
        // that a later "improvement" that starts excluding hands also starts
        // excluding those three notes visibly, in this test, rather than in
        // a market.
        let hand = FrameStats.measure(frame { _, _ in (230, 180, 150) })
        let ochre = FrameStats.measure(frame { _, _ in (150, 120, 60) })   // the ₦1000's ground
        XCTAssertGreaterThan(hand.coverage, FramingRuleShim.leastCoverage)
        XCTAssertGreaterThan(ochre.coverage, FramingRuleShim.leastCoverage)
    }

    func testClippingIsCounted() {
        let stats = FrameStats.measure(frame { x, _ in x < 320 ? (255, 255, 255) : (100, 100, 100) })
        XCTAssertEqual(stats.clipped, 0.5, accuracy: 0.02)
    }

    func testMeasuringRunsAtCameraRate() {
        let f = frame { x, y in let n = hash(x, y) / 3; return (150 + n, 120 + n, 60 + n / 2) }
        _ = FrameStats.measure(f)   // warm
        let start = ContinuousClock.now
        for _ in 0..<30 { _ = FrameStats.measure(f) }
        let perFrame = (ContinuousClock.now - start) / 30
        // 30 fps is 33 ms a frame; measuring must be a small fraction of that,
        // on a simulator running a debug build, which is slower than an A12.
        XCTAssertLessThan(perFrame, .milliseconds(10), "\(perFrame) per frame")
    }
}

// The judge's threshold, reached through the domain so the test cannot
// drift from the rule.
import TenderDomain
enum FramingRuleShim { static let leastCoverage = FramingRule.leastCoverage }
