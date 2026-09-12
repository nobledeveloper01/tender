// What the app does with the haptic engine.
//
// Eight patterns for eight values, designed to be learnable in a minute and
// felt through a pocket. Provisional until the people who will feel it have
// (R4). The domain says `[Pulse]`; the app decides what a pulse feels like.

public enum Pulse: Sendable, Equatable {
    case short   // a sharp transient
    case long    // a continuous buzz with a soft attack
}

public enum HapticPattern {
    /// The grammar: shorts count up to twenty, one long is fifty, hundreds add
    /// shorts to a long, five hundred and a thousand are longs alone. Two
    /// designs of the same value feel the same; the difference is spoken.
    public static func pulses(for value: Naira) -> [Pulse] {
        switch value {
        case .n5: [.short]
        case .n10: [.short, .short]
        case .n20: [.short, .short, .short]
        case .n50: [.long]
        case .n100: [.long, .short]
        case .n200: [.long, .short, .short]
        case .n500: [.long, .long]
        case .n1000: [.long, .long, .long]
        }
    }

    /// Intensity 0…1. The hedged answer plays at half; "not sure" and the two
    /// light verdicts play one soft long, deliberately the same: all three
    /// mean "the app has nothing for you yet".
    public static func render(_ verdict: Verdict) -> (pulses: [Pulse], intensity: Double) {
        switch verdict {
        case .sure(let note): (pulses(for: note.value), 1.0)
        case .probably(let note): (pulses(for: note.value), 0.5)
        case .notSure: ([.long], 0.4)
        }
    }

    public static func render(_ framing: Framing) -> (pulses: [Pulse], intensity: Double)? {
        switch framing {
        case .tooDark, .tooBright: ([.long], 0.4)
        case .steady: ([.short, .short], 0.4)
        case .nothing, .ready: nil
        }
    }
}
