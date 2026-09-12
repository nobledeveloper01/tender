// Renders the domain's [Pulse] through Core Haptics. A short is a sharp
// 60 ms transient; a long is a 220 ms continuous with a soft attack; 120 ms
// between pulses. If the device has no haptic engine the app continues
// without it and never mentions it.
import CoreHaptics
import TenderDomain

@MainActor
final class Haptics {
    private var engine: CHHapticEngine?
    var enabled = true

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        engine?.resetHandler = { [weak self] in try? self?.engine?.start() }
        try? engine?.start()
    }

    func play(_ pulses: [Pulse], intensity: Double) {
        guard enabled, let engine else { return }
        var events: [CHHapticEvent] = []
        var t: TimeInterval = 0
        let strength = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(intensity))
        for pulse in pulses {
            switch pulse {
            case .short:
                let sharp = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [strength, sharp], relativeTime: t))
                t += 0.06
            case .long:
                let soft = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                let attack = CHHapticEventParameter(parameterID: .attackTime, value: 0.05)
                events.append(CHHapticEvent(eventType: .hapticContinuous, parameters: [strength, soft, attack], relativeTime: t, duration: 0.22))
                t += 0.22
            }
            t += 0.12
        }
        guard let pattern = try? CHHapticPattern(events: events, parameters: []),
              let player = try? engine.makePlayer(with: pattern) else { return }
        try? player.start(atTime: CHHapticTimeImmediate)
    }
}
