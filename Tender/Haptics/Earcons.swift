// The haptic vocabulary, as sound. A short is an 80 ms tick, a long a
// 220 ms note, synthesised on an AVAudioEngine — no assets to bundle, no
// recordings to wait for. For earphones in a bag and hands in a coat.
import AVFoundation
import TenderDomain

@MainActor
final class Earcons: Pulsing {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var ready = false

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        ready = (try? engine.start()) != nil
    }

    var enabled: Bool { Preferences.soundsEnabled() }

    func play(_ pulses: [Pulse], intensity: Double) {
        guard enabled, ready, let buffer = Self.render(pulses, gain: Float(0.35 * intensity), format: format) else { return }
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        player.play()
    }

    /// One buffer for the whole pattern: sine at 660 Hz for a short, 440 Hz
    /// for a long, 120 ms of silence between, a 5 ms ramp at each end so
    /// nothing clicks.
    static func render(_ pulses: [Pulse], gain: Float, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sr = format.sampleRate
        let gap = Int(0.12 * sr)
        let lengths = pulses.map { $0 == .short ? Int(0.08 * sr) : Int(0.22 * sr) }
        let total = lengths.reduce(0, +) + gap * max(pulses.count - 1, 0)
        guard total > 0, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(total)) else { return nil }
        buffer.frameLength = AVAudioFrameCount(total)
        let out = buffer.floatChannelData![0]
        var i = 0
        let ramp = Int(0.005 * sr)
        for (pulse, len) in zip(pulses, lengths) {
            let hz = pulse == .short ? 660.0 : 440.0
            for n in 0..<len {
                let env = min(Float(n) / Float(ramp), Float(len - n) / Float(ramp), 1)
                out[i + n] = gain * env * Float(sin(2 * .pi * hz * Double(n) / sr))
            }
            i += len + gap
        }
        return buffer
    }
}

/// Several channels, one call. The reader pulses once; haptics and earcons
/// each decide whether they are on.
@MainActor
final class Channels: Pulsing {
    private let all: [Pulsing]
    init(_ all: [Pulsing]) { self.all = all }
    func play(_ pulses: [Pulse], intensity: Double) {
        for c in all { c.play(pulses, intensity: intensity) }
    }
}
