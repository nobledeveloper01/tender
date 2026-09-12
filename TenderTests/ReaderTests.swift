// The wiring, heard and felt. A source that hands over scripted frames, a
// classifier that answers what it is told to, and spies for the two output
// channels — so the tests can say what was announced, how many times, and
// what was pulsed, which the UI tests cannot.
import CoreVideo
import XCTest
import TenderDomain
@testable import Tender

@MainActor
final class ReaderTests: XCTestCase {
    // MARK: doubles

    final class Spy: Speaking, Pulsing {
        var said: [String] = []
        var played: [([Pulse], Double)] = []
        func say(_ text: String) { said.append(text) }
        func play(_ pulses: [Pulse], intensity: Double) { played.append((pulses, intensity)) }

        static func blank() -> Frame {
            var pb: CVPixelBuffer?
            CVPixelBufferCreate(nil, 64, 48, kCVPixelFormatType_32BGRA, nil, &pb)
            return Frame(pixels: pb!)
        }
    }

    /// Emits the same frame `count` times, `gap` apart, then ends.
    struct ScriptedSource: FrameSource {
        let frame: Frame
        let count: Int
        let gap: Duration
        func frames() -> AsyncStream<Frame> {
            AsyncStream { c in
                Task {
                    for _ in 0..<count {
                        c.yield(frame)
                        try? await Task.sleep(for: gap)
                    }
                    c.finish()
                }
            }
        }
        func start() {}
        func stop() {}
    }

    struct ScriptedClassifier: NoteClassifier {
        let answer: [Note: Double]?
        let delay: Duration
        let calls: Counter
        func classify(_ frame: Frame) async -> [Note: Double]? {
            calls.increment()
            try? await Task.sleep(for: delay)
            return answer
        }
    }

    final class Counter: @unchecked Sendable {
        private var n = 0
        private let lock = NSLock()
        func increment() { lock.lock(); n += 1; lock.unlock() }
        var value: Int { lock.lock(); defer { lock.unlock() }; return n }
    }

    private func frame(fill: UInt8) -> Frame {
        var pb: CVPixelBuffer?
        CVPixelBufferCreate(nil, 64, 48, kCVPixelFormatType_32BGRA, nil, &pb)
        CVPixelBufferLockBaseAddress(pb!, [])
        memset(CVPixelBufferGetBaseAddress(pb!), Int32(fill), CVPixelBufferGetBytesPerRow(pb!) * 48)
        CVPixelBufferUnlockBaseAddress(pb!, [])
        return Frame(pixels: pb!)
    }

    /// A frame the judge calls ready: mid-luminance, note-coloured, textured.
    private func readyFrame() -> Frame {
        var pb: CVPixelBuffer?
        CVPixelBufferCreate(nil, 64, 48, kCVPixelFormatType_32BGRA, nil, &pb)
        CVPixelBufferLockBaseAddress(pb!, [])
        let base = CVPixelBufferGetBaseAddress(pb!)!.assumingMemoryBound(to: UInt8.self)
        let stride = CVPixelBufferGetBytesPerRow(pb!)
        var seed: UInt32 = 7
        for y in 0..<48 {
            for x in 0..<64 {
                seed = seed &* 1664525 &+ 1013904223
                let noise = Int(seed >> 24) % 60 - 30
                let i = y * stride + x * 4
                base[i] = UInt8(clamping: 60 + noise)       // b
                base[i + 1] = UInt8(clamping: 120 + noise)  // g
                base[i + 2] = UInt8(clamping: 150 + noise)  // r
                base[i + 3] = 255
            }
        }
        CVPixelBufferUnlockBaseAddress(pb!, [])
        return Frame(pixels: pb!)
    }

    private func settle(_ seconds: Double) async {
        try? await Task.sleep(for: .seconds(seconds))
    }

    // MARK: tests

    func testTheSameFramingIsSaidOnceHoweverLongItLasts() async {
        // Sixty white frames over two and a half seconds. The first version
        // of this test listened for 300 ms and passed while the app said
        // the sentence again every second — a metronome a person heard from
        // the next room. So: longer than a second, by a margin.
        let spy = Spy()
        let reader = Reader(source: ScriptedSource(frame: frame(fill: 255), count: 60, gap: .milliseconds(40)),
                            classifier: ScriptedClassifier(answer: nil, delay: .zero, calls: Counter()),
                            announcer: spy, haptics: spy)
        reader.start()
        await settle(2.6)
        reader.stop()
        XCTAssertEqual(spy.said, ["I can't see a note."], "the same framing for 2.4 s; one sentence, not three")
    }

    func testAChangeOfFramingIsSaidAndAChangeBackIsSaidAgain() async {
        // White, then black, then white: three sentences, in order.
        let spy = Spy()
        let white = frame(fill: 255), black = frame(fill: 0)
        struct Sequence: FrameSource {
            let script: [Frame]
            func frames() -> AsyncStream<Frame> {
                AsyncStream { c in
                    Task {
                        for f in script { c.yield(f); try? await Task.sleep(for: .milliseconds(120)) }
                        c.finish()
                    }
                }
            }
            func start() {}
            func stop() {}
        }
        let reader = Reader(source: Sequence(script: [white, white, black, black, white, white]),
                            classifier: ScriptedClassifier(answer: nil, delay: .zero, calls: Counter()),
                            announcer: spy, haptics: spy)
        reader.start()
        await settle(1.2)
        reader.stop()
        XCTAssertEqual(spy.said, ["I can't see a note.", "Too dark.", "I can't see a note."])
    }

    func testAReadyFrameIsClassifiedUntilTwoAgreeAndTheVerdictSpokenOnceAndFelt() async {
        let spy = Spy(), calls = Counter()
        let reader = Reader(source: ScriptedSource(frame: readyFrame(), count: 20, gap: .milliseconds(20)),
                            classifier: ScriptedClassifier(answer: [.n500: 0.97, .n1000: 0.03], delay: .zero, calls: calls),
                            announcer: spy, haptics: spy)
        reader.start()
        await settle(1.0)
        reader.stop()
        XCTAssertEqual(reader.verdict, .sure(.n500))
        // Two: the first "sure" is held until a second frame agrees (ADR-0004),
        // then the answer sticks and the remaining frames are not classified.
        XCTAssertEqual(calls.value, 2, "twenty ready frames; two classifications, then the answer sticks")
        XCTAssertEqual(spy.said.filter { $0 == "five hundred naira." }.count, 1)
        XCTAssertEqual(spy.played.last?.0, HapticPattern.pulses(for: .n500))
        XCTAssertEqual(spy.played.last?.1, 1.0)
    }

    func testASlowClassifierIsAbandonedAndTheAnswerIsNotSure() async {
        let spy = Spy()
        let reader = Reader(source: ScriptedSource(frame: readyFrame(), count: 3, gap: .milliseconds(20)),
                            classifier: ScriptedClassifier(answer: [.n500: 1.0], delay: .seconds(5), calls: Counter()),
                            announcer: spy, haptics: spy, budget: .milliseconds(200))
        reader.start()
        await settle(0.8)
        reader.stop()
        XCTAssertEqual(reader.verdict, .notSure, "an answer that arrives too late is no answer")
        XCTAssertTrue(spy.said.contains("I don't recognise this."))
        XCTAssertFalse(spy.said.contains("five hundred naira."), "the late answer must never be spoken")
    }

    func testStartOverForgetsTheAnswerAndSaysTheFramingAgain() async {
        let spy = Spy()
        let reader = Reader(source: ScriptedSource(frame: readyFrame(), count: 5, gap: .milliseconds(20)),
                            classifier: ScriptedClassifier(answer: [.n100: 0.99], delay: .zero, calls: Counter()),
                            announcer: spy, haptics: spy)
        reader.start()
        await settle(0.5)
        XCTAssertEqual(reader.verdict, .sure(.n100))
        reader.startOver()
        XCTAssertNil(reader.verdict)
        reader.repeatLast()
        reader.stop()
        XCTAssertEqual(spy.said.last, spy.said[spy.said.count - 2], "repeat says the last thing again, unchanged")
    }

    func testDemonstratingAValueSaysItAndPulsesItLikeASureAnswer() {
        let spy = Spy()
        let reader = Reader(source: ScriptedSource(frame: frame(fill: 0), count: 0, gap: .zero),
                            classifier: ScriptedClassifier(answer: nil, delay: .zero, calls: Counter()),
                            announcer: spy, haptics: spy)
        for value in Naira.allCases {
            reader.demonstrate(value)
        }
        XCTAssertEqual(spy.said, Naira.allCases.map { "\($0.spoken) naira." })
        XCTAssertEqual(spy.played.map(\.0), Naira.allCases.map { HapticPattern.pulses(for: $0) })
        XCTAssertTrue(spy.played.allSatisfy { $0.1 == 1.0 }, "learning plays at full strength, like a sure answer")
        XCTAssertFalse(spy.said.contains { $0.contains("new design") }, "learning uses the original design's sentence")
    }
}
