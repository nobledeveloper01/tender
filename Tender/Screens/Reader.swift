// The one thing the app does, as state: frames in, a framing verdict, a
// classification when a frame is ready, a verdict, and what was said and felt.
//
// Everything that decides is the domain's. This object is the wiring: it
// measures, asks, and then speaks and pulses what it is told.
import AVFoundation
import CoreVideo
import Observation
import TenderDomain

@MainActor
@Observable
final class Reader {
    private(set) var framing: Framing = .nothing
    private(set) var verdict: Verdict?
    private(set) var lastSaid: String = Announcement.text(for: Framing.nothing) ?? ""

    private let source: FrameSource
    private let classifier: NoteClassifier
    private let announcer: Announcer
    private let haptics: Haptics
    private var task: Task<Void, Never>?
    private var classifying = false
    private var lastFramingSaid: (Framing, ContinuousClock.Instant)?
    private let clock = ContinuousClock()

    /// How long a classification may take before it is abandoned.
    static let budget: Duration = .milliseconds(1500)

    /// The live session, for the dimmed preview. Nil for fixtures and the simulator.
    var captureSession: AVCaptureSession? { (source as? CameraSession)?.captureSession }

    init(source: FrameSource, classifier: NoteClassifier, announcer: Announcer, haptics: Haptics) {
        self.source = source
        self.classifier = classifier
        self.announcer = announcer
        self.haptics = haptics
    }

    func start() {
        source.start()
        task = Task { [weak self] in
            guard let self else { return }
            for await frame in source.frames() {
                await self.handle(frame)
            }
        }
        // A source that emits nothing still has to say so.
        announce(framing: .nothing, force: true)
    }

    func stop() {
        task?.cancel()
        source.stop()
    }

    /// A tap anywhere: say it again.
    func repeatLast() {
        announcer.say(lastSaid)
        if let verdict {
            let h = HapticPattern.render(verdict)
            haptics.play(h.pulses, intensity: h.intensity)
        }
    }

    /// The magic tap, or a shake: forget the answer and go back to framing.
    func startOver() {
        verdict = nil
        announce(framing: framing, force: true)
    }

    private func handle(_ frame: Frame) async {
        let stats = FrameStats.measure(frame.pixels)
        let judged = FramingRule.judge(
            coverage: stats.coverage, luminance: stats.luminance,
            clipped: stats.clipped, detail: stats.detail
        )
        if judged != framing || verdict == nil {
            framing = judged
            if verdict == nil { announce(framing: judged, force: false) }
        }
        guard judged == .ready, !classifying, verdict == nil else { return }
        classifying = true
        defer { classifying = false }
        let distribution = await withTimeout(Self.budget) { [classifier] in
            await classifier.classify(frame)
        }
        let decided = ConfidenceRule.decide(distribution ?? [:])
        verdict = decided
        let text = Announcement.text(for: decided)
        lastSaid = text
        announcer.say(text)
        let h = HapticPattern.render(decided)
        haptics.play(h.pulses, intensity: h.intensity)
    }

    /// Not more than once a second for the same verdict.
    private func announce(framing: Framing, force: Bool) {
        guard let text = Announcement.text(for: framing) else { return }
        let now = clock.now
        if !force, let (last, at) = lastFramingSaid, last == framing, now - at < .seconds(1) { return }
        lastFramingSaid = (framing, now)
        lastSaid = text
        announcer.say(text)
        if let h = HapticPattern.render(framing) { haptics.play(h.pulses, intensity: h.intensity) }
    }

    private func withTimeout<T: Sendable>(_ limit: Duration, _ work: @escaping @Sendable () async -> T?) async -> T? {
        await withTaskGroup(of: T?.self) { group in
            group.addTask { await work() }
            group.addTask { try? await Task.sleep(for: limit); return nil }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }
}
