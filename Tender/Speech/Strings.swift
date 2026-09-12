// Every string the app can say or show that is not built by the domain.
// One enum, so the copy gate, the tests and the v1.1 recording kit read one
// list. `make copy-check` reads this file and the domain's Announcement.
//
// Voice: plain, short, present tense, no exclamation marks, no "please".
import TenderDomain

enum Strings {
    static let appName = "Tender"
    static let cameraDenied = "Tender needs the camera to see the note. Open Settings to allow it."
    static let openSettings = "Open Settings"
    static let noCameraHere = "There is no camera on this device."
    static let repeatAction = "Repeat"
    static let startOver = "Start over"
    static let settings = "Settings"
    static let done = "Done"
    static let learn = "Learn the patterns"
    static let learnHint = "Tap a value to hear it and feel it."
    static func pulseWords(_ pulses: [Pulse]) -> String {
        pulses.map { $0 == .short ? "short" : "long" }.joined(separator: " ")
    }
    static let speechWhenVoiceOverOff = "Speak when VoiceOver is off"
    static let haptics = "Haptics"
    static let cameraScreenLabel = "Camera. Point at a note. Tap to repeat. Two-finger double-tap to start over."
    static let newDesign = "new design"
}
