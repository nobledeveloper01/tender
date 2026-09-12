// Says things. Through VoiceOver when it is on — an announcement with high
// priority, so it interrupts whatever VoiceOver was reading — and through the
// synthesiser when it is off, because a sighted user with a new ₦200 also
// benefits from being told.
import AVFoundation
import UIKit

@MainActor
final class Announcer {
    private let synthesiser = AVSpeechSynthesizer()
    var speakWhenVoiceOverOff = true

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
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            synthesiser.speak(utterance)
        }
    }
}
