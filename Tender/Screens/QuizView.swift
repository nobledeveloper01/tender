// The quiz: the app pulses a pattern, the user names the value. R4's
// session, in the app — and the way a blind user finds out for themselves
// whether "long short" and "long short short" are distinguishable through
// their own phone. Ten questions; the score is spoken and forgotten.
import SwiftUI
import TenderDomain

@MainActor
@Observable
final class Quiz {
    private(set) var asked: Naira?
    private(set) var right = 0
    private(set) var total = 0
    private(set) var lastResult: String?
    private var order: [Naira] = []
    private let reader: Reader

    static let length = 10

    init(reader: Reader) {
        self.reader = reader
    }

    /// Deterministic shuffle from a seed the caller chooses, so a test can
    /// know the order and a user cannot predict it.
    func begin(seed: UInt64 = UInt64(Date().timeIntervalSince1970)) {
        var rng = SplitMix(seed: seed)
        order = (0..<Self.length).map { _ in Naira.allCases[Int(rng.next() % UInt64(Naira.allCases.count))] }
        right = 0; total = 0; lastResult = nil
        next()
    }

    var finished: Bool { total >= Self.length }

    func play() {
        guard let asked else { return }
        reader.pulseOnly(asked)
    }

    func answer(_ value: Naira) {
        guard let asked, !finished else { return }
        total += 1
        if value == asked {
            right += 1
            lastResult = Strings.quizRight
        } else {
            lastResult = Strings.quizWrong("\(asked.spoken) naira")
        }
        reader.say(lastResult! + (finished ? " " + Strings.quizScore(right, of: total) : ""))
        if !finished { next() }
    }

    private func next() {
        asked = order[total]
        play()
    }

    struct SplitMix {
        var state: UInt64
        init(seed: UInt64) { state = seed }
        mutating func next() -> UInt64 {
            state &+= 0x9E3779B97F4A7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
    }
}

struct QuizView: View {
    @State private var quiz: Quiz
    @Environment(\.colorScheme) private var scheme

    init(reader: Reader) {
        _quiz = State(initialValue: Quiz(reader: reader))
    }

    var body: some View {
        let palette = Palette.current(scheme)
        List {
            Section {
                Button(Strings.quizPlay) { quiz.play() }
                    .frame(maxWidth: .infinity, minHeight: Target.standard)
                    .font(Type.headlineFont())
                if let r = quiz.lastResult {
                    Text(r)
                        .font(Type.bodyFont())
                        .foregroundStyle(r == Strings.quizRight ? palette.ready : palette.caution)
                        .frame(minHeight: Target.standard)
                }
                Text(Strings.quizScore(quiz.right, of: quiz.total))
                    .font(Type.bodyFont())
                    .foregroundStyle(palette.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: Target.standard, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Score. " + Strings.quizScore(quiz.right, of: quiz.total))
            } footer: {
                Text(Strings.quizHint).font(Type.secondaryFont())
            }
            Section {
                ForEach(Naira.allCases, id: \.self) { value in
                    Button("₦" + String(value.rawValue)) { quiz.answer(value) }
                        .frame(maxWidth: .infinity, minHeight: Target.standard, alignment: .leading)
                        .font(Type.headlineFont())
                        .foregroundStyle(palette.textPrimary)
                        .accessibilityLabel("\(value.spoken) naira")
                        .disabled(quiz.finished)
                }
            }
        }
        .tint(palette.ready)
        .navigationTitle(Strings.quiz)
        .onAppear { if quiz.total == 0 && quiz.asked == nil { quiz.begin() } }
    }
}
