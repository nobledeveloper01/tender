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
    static let tryAWindow = "Try near a window."
    static let howSure = "How sure?"
    static let startTally = "Start a tally"
    static let stopTally = "Stop the tally"
    static let tallyStarted = "Counting. Each note is added. Shake to start over."
    static let checkChange = "Check change"
    static let paid = "Paid"
    static let cost = "Cost"
    static let start = "Start"
    static let changeStarted = "Checking change. Show me each note."
    static let firstLaunchHint = "Point the camera at a note. Tap anywhere to hear it again."
    static let sounds = "Sounds"
    static let speechGroup = "Speech"
    static let feelGroup = "Haptics and sounds"
    static let screenGroup = "Screen"
    static let hapticStrength = "Haptic strength"
    static let strengthHalf = "Half"
    static let strengthNormal = "Normal"
    static let strengthStrong = "Strong"
    static let speechRate = "Speech rate"
    static let rateSlow = "Slow"
    static let rateNormal = "Normal"
    static let rateFast = "Fast"
    static let hideNumber = "Hide the number"
    static let dimScreen = "Dim the screen"
    static let privacy = "What Tender knows about you"
    static let privacyAnswer = "Nothing. Tender has no network access, keeps no photographs, and stores no answers. What you hold is your business."
    static let quiz = "Quiz"
    static let quizHint = "Feel a pattern, then tap the value you think it is."
    static let quizPlay = "Play the pattern"
    static let quizRight = "Right."
    static func quizWrong(_ answer: String) -> String { "Not quite. That was \(answer)." }
    static func quizScore(_ right: Int, of total: Int) -> String { "\(right) of \(total) right." }
}
