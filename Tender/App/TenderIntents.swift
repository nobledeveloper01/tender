// "Hey Siri, identify a note with Tender." The Action button, a Shortcut,
// Siri — each opens the app straight to the camera, which is the only
// thing it does anyway. No parameters, nothing returned, nothing stored.
import AppIntents

struct IdentifyNoteIntent: AppIntent {
    static let title: LocalizedStringResource = "Identify a note"
    static let description = IntentDescription("Opens Tender at the camera to say which naira note you are holding.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct TenderShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: IdentifyNoteIntent(),
            phrases: ["Identify a note with \(.applicationName)", "Which note is this, \(.applicationName)", "Read a note with \(.applicationName)"],
            shortTitle: "Identify a note",
            systemImageName: "banknote"
        )
    }
}
