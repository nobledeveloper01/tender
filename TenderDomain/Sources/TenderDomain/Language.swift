// The languages the denomination can be said in, and the clips it takes.
//
// VoiceOver has no voice for any Nigerian language, so English is what
// VoiceOver speaks and the other five are bundled recordings — of the
// denomination only. Everything else the app says stays English, through
// VoiceOver, because a blind Nigerian iPhone user already lives in that.
//
// A clip is named by a stem. The stems, per language, are what a speaker
// is handed: eight values and four connecting words. `make audio-check`
// reads this enum, not a list beside it.
public enum Language: String, CaseIterable, Sendable {
    case en, pcm, ha, yo, ig, ff

    /// The name a speaker of it would say.
    public var name: String {
        switch self {
        case .en: "English"
        case .pcm: "Naijá"
        case .ha: "Hausa"
        case .yo: "Yorùbá"
        case .ig: "Igbo"
        case .ff: "Fulfulde"
        }
    }

    /// The five that need recordings. English is VoiceOver's.
    public static var recorded: [Language] { allCases.filter { $0 != .en } }
}

/// The recorded vocabulary: what a clip is for.
public enum ClipStem: String, CaseIterable, Sendable {
    case n5, n10, n20, n50, n100, n200, n500, n1000
    case newDesign = "new-design"
    case iThink = "i-think"
    case check
    case notSure = "not-sure"

    /// The English the speaker translates, one line each.
    public var english: String {
        switch self {
        case .n5: "five naira"
        case .n10: "ten naira"
        case .n20: "twenty naira"
        case .n50: "fifty naira"
        case .n100: "one hundred naira"
        case .n200: "two hundred naira"
        case .n500: "five hundred naira"
        case .n1000: "one thousand naira"
        case .newDesign: "new design"
        case .iThink: "I think"
        case .check: "Check."
        case .notSure: "I don't recognise this."
        }
    }

    static func value(_ v: Naira) -> ClipStem {
        ClipStem(rawValue: "n\(v.rawValue)")!
    }
}

public enum ClipScript {
    /// The clips to play, in order, for a verdict. The same sentence shape
    /// as the English, so a hedge sounds like a hedge in every language.
    public static func stems(for verdict: Verdict) -> [ClipStem] {
        switch verdict {
        case .sure(let note):
            [.value(note.value)] + (note.design == .redesign2022 ? [.newDesign] : [])
        case .probably(let note):
            [.iThink, .value(note.value)] + (note.design == .redesign2022 ? [.newDesign] : []) + [.check]
        case .notSure:
            [.notSure]
        }
    }
}
