// Says things. Through VoiceOver when it is on — an announcement with high
// priority, so it interrupts whatever VoiceOver was reading — and through the
// synthesiser when it is off, because a sighted user with a new ₦200 also
// benefits from being told.
import AVFoundation
import TenderDomain
import UIKit

/// Something that says sentences. The app's is `Announcer`; a test's records them.
@MainActor
protocol Speaking: AnyObject {
    func say(_ text: String)
    /// A verdict: the same as `say(text)` unless a language with recordings
    /// is chosen, in which case the denomination is played from clips.
    func say(_ verdict: Verdict, text: String)
}

extension Speaking {
    func say(_ verdict: Verdict, text: String) { say(text) }
}

@MainActor
final class Announcer: Speaking {
    private let synthesiser = AVSpeechSynthesizer()
    private let clips = ClipPlayer()
    /// `-silent` on the command line keeps the synthesiser quiet: the UI
    /// tests launch the app dozens of times on a headless simulator whose
    /// audio still comes out of the Mac's speakers, and a test reads what
    /// was said through a spy, never through a speaker. VoiceOver
    /// announcements are unaffected — VoiceOver is not running in a test.
    private let silent = CommandLine.arguments.contains("-silent")
    /// The setting, read at the moment of speaking so a change takes effect
    /// on the next sentence. The first version stored a `var` the settings
    /// sheet never reached, so the toggle changed nothing.
    var speakWhenVoiceOverOff: Bool { !silent && Preferences.speechEnabled() }

    /// The denomination in the user's own language, when there are clips
    /// for it; English otherwise. Through the speaker, not VoiceOver — a
    /// recording is not text VoiceOver can read — so VoiceOver is not
    /// posted to as well, which would say the English over the top.
    func say(_ verdict: Verdict, text: String) {
        let language = Preferences.language()
        guard ClipPlayer.canSay(verdict, in: language) else { return say(text) }
        synthesiser.stopSpeaking(at: .immediate)
        clips.play(verdict, in: language)
    }

    func say(_ text: String) {
        if UIAccessibility.isVoiceOverRunning {
            let attributed = NSAttributedString(
                string: text,
                attributes: [.accessibilitySpeechAnnouncementPriority: UIAccessibilityPriority.high]
            )
            UIAccessibility.post(notification: .announcement, argument: attributed)
        } else if speakWhenVoiceOverOff {
            synthesiser.stopSpeaking(at: .immediate)
            let utterance = AVSpeechUtterance(string: text)
            utterance.rate = Preferences.speechRate()
            synthesiser.speak(utterance)
        }
    }
}
