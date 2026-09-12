// Plays the denomination from bundled recordings, in the language chosen,
// in sequence — "I think", "five hundred naira", "new design", "Check." —
// so a hedge sounds like a hedge in Hausa too. Xcode flattens a
// synchronized folder's resources into the bundle root, so every clip is
// named "<lang>-<stem>.m4a" to be unique there, and kept in a per-language
// folder in the source tree for the people who record them.
import AVFoundation
import TenderDomain

@MainActor
final class ClipPlayer {
    private let queue = AVQueuePlayer()

    /// The URL of one clip, or nil if the bundle has none — in which case
    /// the caller falls back to English rather than to silence.
    static func url(_ language: Language, _ stem: ClipStem) -> URL? {
        Bundle.main.url(forResource: "\(language.rawValue)-\(stem.rawValue)", withExtension: "m4a")
    }

    /// Whether every clip a verdict needs is in the bundle.
    static func canSay(_ verdict: Verdict, in language: Language) -> Bool {
        language != .en && ClipScript.stems(for: verdict).allSatisfy { url(language, $0) != nil }
    }

    func play(_ verdict: Verdict, in language: Language) {
        queue.removeAllItems()
        for stem in ClipScript.stems(for: verdict) {
            if let u = Self.url(language, stem) { queue.insert(AVPlayerItem(url: u), after: nil) }
        }
        queue.play()
    }

    func stop() { queue.pause(); queue.removeAllItems() }

    /// The languages the app may offer: English, and any recorded language
    /// none of whose clips is a placeholder. `placeholders.txt` is bundled
    /// so the app reads the same list `make audio-check` counts — and a
    /// language with a placeholder in it is not offered at all. A user
    /// cannot choose Hausa and hear English; Hausa appears the day its
    /// twelve clips are recorded.
    static func offered() -> [Language] {
        if CommandLine.arguments.contains("-allLanguages") { return Language.allCases }
        let listed: Set<String> = {
            guard let url = Bundle.main.url(forResource: "placeholders", withExtension: "txt"),
                  let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
            return Set(text.split(whereSeparator: \.isNewline).map(String.init))
        }()
        return Language.allCases.filter { language in
            language == .en || !ClipStem.allCases.contains { listed.contains("\(language.rawValue)/\($0.rawValue)") }
        }
    }
}
