// The one thing the app does, as state: frames in, a framing verdict, a
// classification when a frame is ready, a verdict, and what was said and felt.
//
// Everything that decides is the domain's. This object is the wiring: it
// measures, asks, and then speaks and pulses what it is told. ADR-0004 added
// three things it can be asked — how sure, a tally, a change check — and two
// things it does unasked: the torch in the dark, and holding a "sure" back
// until a second frame agrees.
import AVFoundation
import CoreVideo
import Observation
import TenderDomain

/// What the reader does with an answer once it has one.
enum Mode: Equatable {
    case identify
    case tally(Tally)
    case change(Change)
}

@MainActor
@Observable
final class Reader {
    private(set) var framing: Framing = .nothing
    private(set) var verdict: Verdict?
    private(set) var lastSaid: String = Announcement.text(for: Framing.nothing) ?? ""
    private(set) var mode: Mode = .identify
    private(set) var paused = false

    private let source: FrameSource
    private let classifier: NoteClassifier
    private let announcer: Speaking
    private let haptics: Pulsing
    private let torch: Lighting
    private var task: Task<Void, Never>?
    private var classifying = false
    private var lastFramingSaid: (Framing, ContinuousClock.Instant)?
    private var lastDistribution: [Note: Double] = [:]
    private var agreement = Agreement()
    private var light = LightPolicy()
    private let clock = ContinuousClock()

    /// How long a classification may take before it is abandoned.
    static let budget: Duration = .milliseconds(1500)
    private let budget: Duration

    /// The live session, for the dimmed preview. Nil for fixtures and the simulator.
    var captureSession: AVCaptureSession? { (source as? CameraSession)?.captureSession }

    init(source: FrameSource, classifier: NoteClassifier, announcer: Speaking, haptics: Pulsing,
         torch: Lighting = NoTorch(), budget: Duration = Reader.budget) {
        self.source = source
        self.classifier = classifier
        self.announcer = announcer
        self.haptics = haptics
        self.torch = torch
        self.budget = budget
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
        torch.set(false)
        light.reset()
    }

    /// Face down, in a pocket: the camera stops and so does the voice.
    func pause() {
        guard !paused else { return }
        paused = true
        source.stop()
        torch.set(false)
        light.reset()
    }

    func resume() {
        guard paused else { return }
        paused = false
        source.start()
    }

    /// A tap anywhere: say it again.
    func repeatLast() {
        announcer.say(lastSaid)
        if let verdict {
            let h = HapticPattern.render(verdict)
            haptics.play(h.pulses, intensity: h.intensity)
        }
    }

    /// "How sure?" — about the reading of the photograph, never the note.
    func howSure() {
        announcer.say(Sureness.describe(lastDistribution))
    }

    /// Learn a pattern: say the value and pulse it, exactly as a sure answer
    /// would. The original design's sentence, so no "new design" suffix.
    func demonstrate(_ value: Naira) {
        let note = Note.allCases.first { $0.value == value && $0.design == .original }!
        announcer.say(Announcement.text(for: .sure(note)))
        haptics.play(HapticPattern.pulses(for: value), intensity: 1.0)
    }

    /// The quiz: the pattern alone, so the value is not given away.
    func pulseOnly(_ value: Naira) {
        haptics.play(HapticPattern.pulses(for: value), intensity: 1.0)
    }

    /// A sentence that is not an answer: the hint, the quiz's result, the
    /// privacy promise. It is the last thing said, so a tap repeats it.
    func say(_ text: String) {
        lastSaid = text
        announcer.say(text)
    }

    func startTally() {
        mode = .tally(Tally())
        lastSaid = Strings.tallyStarted
        announcer.say(lastSaid)
    }

    func startChange(paid: Int, cost: Int) {
        let c = Change(paid: paid, cost: cost)
        mode = .change(c)
        lastSaid = Strings.changeStarted + " " + c.spoken
        announcer.say(lastSaid)
    }

    func stopMode() {
        mode = .identify
    }

    /// The magic tap, or a shake: forget the answer and go back to framing.
    /// In a tally or a change check, this also clears the count.
    func startOver() {
        verdict = nil
        agreement.reset()
        switch mode {
        case .tally: mode = .tally(Tally())
        case .change(let c): mode = .change(Change(paid: c.paid, cost: c.cost))
        case .identify: break
        }
        announce(framing: framing, force: true)
    }

    private func handle(_ frame: Frame) async {
        guard !paused else { return }
        let stats = FrameStats.measure(frame.pixels)
        let judged = FramingRule.judge(
            coverage: stats.coverage, luminance: stats.luminance,
            clipped: stats.clipped, detail: stats.detail
        )
        // The dark, acted on before it is advised about.
        switch light.consider(judged) {
        case .torchOn: torch.set(true)
        case .tryAWindow:
            lastSaid = Strings.tryAWindow
            announcer.say(lastSaid)
        case .nothing: break
        }
        // Announce on *change*, and never faster than once a second — not
        // "once a second". The first version re-said "I can't see a note"
        // every second for as long as no note appeared, which a person heard
        // from the next room. Same framing, no change, no sentence.
        if judged != framing {
            framing = judged
            if verdict == nil { announce(framing: judged, force: false) }
        }
        guard judged == .ready, !classifying, verdict == nil else { return }
        classifying = true
        defer { classifying = false }
        let distribution = await withTimeout(budget) { [classifier] in
            await classifier.classify(frame)
        }
        lastDistribution = distribution ?? [:]
        let gated = ConfidenceRule.decide(lastDistribution)
        // A sure answer needs two frames that agree. The first "sure" is
        // held as "probably" and the frame is not consumed: the next ready
        // frame is classified again and, if it agrees, spoken as sure.
        let decided = agreement.consider(gated)
        if case .sure = gated, case .probably = decided {
            speak(framingOnly: decided)
            return
        }
        verdict = decided
        answer(decided)
    }

    /// The first of two agreeing frames: said with the caveat, and the
    /// reader keeps looking so the second frame can confirm.
    private func speak(framingOnly verdict: Verdict) {
        let text = Announcement.text(for: verdict)
        if text != lastSaid {
            lastSaid = text
            announcer.say(text)
            let h = HapticPattern.render(verdict)
            haptics.play(h.pulses, intensity: h.intensity)
        }
    }

    private func answer(_ decided: Verdict) {
        var text = Announcement.text(for: decided)
        let h = HapticPattern.render(decided)
        if case .sure(let note) = decided {
            switch mode {
            case .tally(var t):
                t.add(note.value); mode = .tally(t)
                text += " " + t.spoken
            case .change(var c):
                c.receive(note.value); mode = .change(c)
                text += " " + c.spoken
            case .identify: break
            }
        }
        lastSaid = text
        announcer.say(text)
        haptics.play(h.pulses, intensity: h.intensity)
        // In a tally or a change check the next note should be read without
        // a gesture, so the answer does not stick.
        if mode != .identify {
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(1200))
                self?.verdict = nil
                self?.agreement.reset()
            }
        }
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
