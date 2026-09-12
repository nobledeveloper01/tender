// ADR-0004's rules, through the reader, heard by spies.
import CoreVideo
import XCTest
import TenderDomain
@testable import Tender

@MainActor
final class ReaderFeatureTests: XCTestCase {
    typealias Spy = ReaderTests.Spy
    typealias Source = ReaderTests.ScriptedSource
    typealias Classifier = ReaderTests.ScriptedClassifier
    typealias Counter = ReaderTests.Counter

    final class TorchSpy: Lighting {
        var isOn = false
        var history: [Bool] = []
        func set(_ on: Bool) { isOn = on; history.append(on) }
    }

    private func flat(_ fill: UInt8) -> Frame {
        var pb: CVPixelBuffer?
        CVPixelBufferCreate(nil, 64, 48, kCVPixelFormatType_32BGRA, nil, &pb)
        CVPixelBufferLockBaseAddress(pb!, [])
        memset(CVPixelBufferGetBaseAddress(pb!), Int32(fill), CVPixelBufferGetBytesPerRow(pb!) * 48)
        CVPixelBufferUnlockBaseAddress(pb!, [])
        return Frame(pixels: pb!)
    }

    private func ready() -> Frame {
        var pb: CVPixelBuffer?
        CVPixelBufferCreate(nil, 64, 48, kCVPixelFormatType_32BGRA, nil, &pb)
        CVPixelBufferLockBaseAddress(pb!, [])
        let base = CVPixelBufferGetBaseAddress(pb!)!.assumingMemoryBound(to: UInt8.self)
        let stride = CVPixelBufferGetBytesPerRow(pb!)
        var seed: UInt32 = 7
        for y in 0..<48 { for x in 0..<64 {
            seed = seed &* 1664525 &+ 1013904223
            let n = Int(seed >> 24) % 60 - 30, i = y * stride + x * 4
            base[i] = UInt8(clamping: 60 + n); base[i + 1] = UInt8(clamping: 120 + n); base[i + 2] = UInt8(clamping: 150 + n); base[i + 3] = 255
        } }
        CVPixelBufferUnlockBaseAddress(pb!, [])
        return Frame(pixels: pb!)
    }

    private func settle(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }

    func testASureAnswerNeedsTwoAgreeingFrames() async {
        let spy = Spy(), calls = Counter()
        let reader = Reader(source: Source(frame: ready(), count: 30, gap: .milliseconds(20)),
                            classifier: Classifier(answer: [.n500: 0.97, .n1000: 0.03], delay: .zero, calls: calls),
                            announcer: spy, haptics: spy)
        reader.start(); await settle(1.2); reader.stop()
        XCTAssertEqual(reader.verdict, .sure(.n500))
        XCTAssertEqual(calls.value, 2, "the first sure is held; the second frame confirms it")
        XCTAssertEqual(spy.said.filter { $0.hasPrefix("I think five hundred") }.count, 1, "the first is hedged")
        XCTAssertEqual(spy.said.filter { $0 == "five hundred naira." }.count, 1, "the second is plain")
    }

    func testTheTorchComesOnInTheDarkAndOffOnStop() async {
        let spy = Spy(), torch = TorchSpy()
        let reader = Reader(source: Source(frame: flat(0), count: LightPolicy.framesBeforeTorch + 5, gap: .milliseconds(10)),
                            classifier: Classifier(answer: nil, delay: .zero, calls: Counter()),
                            announcer: spy, haptics: spy, torch: torch)
        reader.start(); await settle(0.6)
        XCTAssertTrue(torch.isOn, "half a second of dark and the torch is on")
        reader.stop()
        XCTAssertFalse(torch.isOn, "off when the camera stops")
        XCTAssertEqual(spy.said, ["I can't see a note.", "Too dark."])
    }

    func testStillDarkWithTheTorchSaysTryAWindowOnce() async {
        let spy = Spy(), torch = TorchSpy()
        let frames = LightPolicy.framesBeforeTorch + LightPolicy.framesBeforeAdvice + 40
        let reader = Reader(source: Source(frame: flat(0), count: frames, gap: .milliseconds(5)),
                            classifier: Classifier(answer: nil, delay: .zero, calls: Counter()),
                            announcer: spy, haptics: spy, torch: torch)
        reader.start(); await settle(1.5); reader.stop()
        XCTAssertEqual(spy.said.filter { $0 == "Try near a window." }.count, 1)
    }

    func testATallyAddsEachSureNoteAndSpeaksTheTotal() async {
        let spy = Spy()
        let reader = Reader(source: Source(frame: ready(), count: 200, gap: .milliseconds(20)),
                            classifier: Classifier(answer: [.n200: 0.99], delay: .zero, calls: Counter()),
                            announcer: spy, haptics: spy)
        reader.startTally()
        reader.start(); await settle(3.0); reader.stop()
        guard case .tally(let t) = reader.mode else { return XCTFail("not in a tally") }
        XCTAssertGreaterThanOrEqual(t.count, 2, "the answer clears itself so the next note is read without a gesture")
        XCTAssertTrue(spy.said.contains { $0.contains("naira so far.") })
        XCTAssertTrue(spy.said.contains { $0.hasPrefix("two hundred naira. Two notes.") || $0.hasPrefix("two hundred naira. One note.") })
    }

    func testChangeIsCheckedNoteByNote() async {
        let spy = Spy()
        let reader = Reader(source: Source(frame: ready(), count: 60, gap: .milliseconds(20)),
                            classifier: Classifier(answer: [.n500: 0.99], delay: .zero, calls: Counter()),
                            announcer: spy, haptics: spy)
        reader.startChange(paid: 1000, cost: 350)
        XCTAssertTrue(spy.said.last!.contains("Six hundred and fifty naira is due."))
        reader.start(); await settle(1.5); reader.stop()
        XCTAssertTrue(spy.said.contains { $0.contains("Five hundred so far. One hundred and fifty naira still to come.") }, "\(spy.said)")
    }

    func testHowSureSpeaksTheReadingNeverTheNote() async {
        let spy = Spy()
        let reader = Reader(source: Source(frame: ready(), count: 10, gap: .milliseconds(20)),
                            classifier: Classifier(answer: [.n500: 0.98, .n1000: 0.02], delay: .zero, calls: Counter()),
                            announcer: spy, haptics: spy)
        reader.start(); await settle(0.6); reader.stop()
        reader.howSure()
        XCTAssertEqual(spy.said.last, "Very sure. Nothing else came close.")
    }

    func testPausedReaderSaysNothingAndResumes() async {
        let spy = Spy()
        let reader = Reader(source: Source(frame: flat(255), count: 40, gap: .milliseconds(20)),
                            classifier: Classifier(answer: nil, delay: .zero, calls: Counter()),
                            announcer: spy, haptics: spy)
        reader.start()
        reader.pause()
        await settle(0.5)
        XCTAssertTrue(reader.paused)
        XCTAssertEqual(spy.said, ["I can't see a note."], "nothing said while paused")
        reader.resume()
        XCTAssertFalse(reader.paused)
        reader.stop()
    }
}
