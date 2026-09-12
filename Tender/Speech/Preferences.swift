// The two settings, read where they are used. `@AppStorage` in the sheet
// writes them; the announcer and the haptic engine read them here at the
// moment of speaking or pulsing, so a change takes effect on the next
// sentence. Absent means on: the app speaks and pulses until told not to.
import Foundation

enum Preferences {
    static let speechKey = "speech.enabled"
    static let hapticsKey = "haptics.enabled"
    static let soundsKey = "sounds.enabled"
    static let strengthKey = "haptics.strength"       // 0.5, 1.0, 1.5
    static let rateKey = "speech.rate"                // 0.4 … 0.6, AVSpeechUtterance units
    static let hideNumberKey = "screen.hideNumber"
    static let dimKey = "screen.dim"
    static let hintGivenKey = "hint.given"

    static func soundsEnabled(_ d: UserDefaults = .standard) -> Bool {
        d.object(forKey: soundsKey) == nil ? false : d.bool(forKey: soundsKey)   // off until asked for
    }
    static func hapticStrength(_ d: UserDefaults = .standard) -> Double {
        d.object(forKey: strengthKey) == nil ? 1.0 : d.double(forKey: strengthKey)
    }
    static func speechRate(_ d: UserDefaults = .standard) -> Float {
        d.object(forKey: rateKey) == nil ? 0.5 : Float(d.double(forKey: rateKey))
    }
    static func hideNumber(_ d: UserDefaults = .standard) -> Bool { d.bool(forKey: hideNumberKey) }
    static func dimScreen(_ d: UserDefaults = .standard) -> Bool { d.bool(forKey: dimKey) }

    static func speechEnabled(_ defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: speechKey) == nil ? true : defaults.bool(forKey: speechKey)
    }

    static func hapticsEnabled(_ defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: hapticsKey) == nil ? true : defaults.bool(forKey: hapticsKey)
    }
}
