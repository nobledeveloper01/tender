// What the app says. Every user-facing sentence the app can speak about a
// frame or a verdict is built here, so that `make copy-check` has one place
// to read and the v1.1 recording kit has one list to hand a speaker.
//
// No sentence here says or implies whether a note is genuine. ADR-0003.

public enum Announcement {
    public static func text(for framing: Framing) -> String? {
        switch framing {
        case .nothing: "I can't see a note."
        case .tooDark: "Too dark."
        case .tooBright: "Too bright."
        case .closer: "Closer."
        case .steady: "Hold steady."
        case .ready: nil   // ready is not a word; the answer follows
        }
    }

    public static func text(for verdict: Verdict) -> String {
        switch verdict {
        case .sure(let note): "\(note.value.spoken) naira\(designSuffix(note))."
        case .probably(let note): "I think \(note.value.spoken) naira\(designSuffix(note)). Check."
        case .notSure: "I don't recognise this."
        }
    }

    /// The design is named only when a sighted person might argue about it.
    private static func designSuffix(_ note: Note) -> String {
        note.design == .redesign2022 ? ", new design" : ""
    }

    /// Everything the app can say, for the copy gate and the recording kit.
    public static var everything: [String] {
        Framing.allCases.compactMap(text(for:))
            + Note.allCases.flatMap { [text(for: .sure($0)), text(for: .probably($0))] }
            + [text(for: .notSure)]
    }
}
