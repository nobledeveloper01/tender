// The two settings, read where they are used. `@AppStorage` in the sheet
// writes them; the announcer and the haptic engine read them here at the
// moment of speaking or pulsing, so a change takes effect on the next
// sentence. Absent means on: the app speaks and pulses until told not to.
import Foundation

enum Preferences {
    static let speechKey = "speech.enabled"
    static let hapticsKey = "haptics.enabled"

    static func speechEnabled(_ defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: speechKey) == nil ? true : defaults.bool(forKey: speechKey)
    }

    static func hapticsEnabled(_ defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: hapticsKey) == nil ? true : defaults.bool(forKey: hapticsKey)
    }
}
