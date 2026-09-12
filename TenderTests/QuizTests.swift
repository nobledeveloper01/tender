// The quiz, heard by spies: it pulses without speaking the value, scores
// an answer, says the result, and says the score at the end.
import XCTest
import TenderDomain
@testable import Tender

@MainActor
final class QuizTests: XCTestCase {
    func testTenQuestionsScoredAndSpoken() {
        let spy = ReaderTests.Spy()
        let reader = Reader(source: ReaderTests.ScriptedSource(frame: ReaderTests.Spy.blank(), count: 0, gap: .zero),
                            classifier: ReaderTests.ScriptedClassifier(answer: nil, delay: .zero, calls: ReaderTests.Counter()),
                            announcer: spy, haptics: spy)
        let quiz = Quiz(reader: reader)
        quiz.begin(seed: 42)
        XCTAssertNotNil(quiz.asked)
        XCTAssertEqual(spy.played.count, 1, "the first pattern plays on begin")
        XCTAssertTrue(spy.said.isEmpty, "the pattern is felt, never spoken — that would give the answer away")

        var right = 0
        for _ in 0..<Quiz.length {
            let asked = quiz.asked!
            // Answer correctly on even questions, wrongly on odd ones.
            let give = quiz.total % 2 == 0 ? asked : Naira.allCases.first { $0 != asked }!
            if give == asked { right += 1 }
            quiz.answer(give)
        }
        XCTAssertTrue(quiz.finished)
        XCTAssertEqual(quiz.right, right)
        XCTAssertEqual(quiz.right, 5)
        XCTAssertEqual(spy.said.filter { $0.hasPrefix("Right.") }.count, 5)
        XCTAssertEqual(spy.said.filter { $0.hasPrefix("Not quite. That was") }.count, 5)
        XCTAssertTrue(spy.said.last!.hasSuffix("5 of 10 right."), spy.said.last!)
        XCTAssertEqual(spy.played.count, Quiz.length, "one pattern per question")
    }

    func testTheSameSeedGivesTheSameOrder() {
        let a = Quiz(reader: dummy()), b = Quiz(reader: dummy())
        a.begin(seed: 7); b.begin(seed: 7)
        XCTAssertEqual(a.asked, b.asked)
    }

    private func dummy() -> Reader {
        let spy = ReaderTests.Spy()
        return Reader(source: ReaderTests.ScriptedSource(frame: ReaderTests.Spy.blank(), count: 0, gap: .zero),
                      classifier: ReaderTests.ScriptedClassifier(answer: nil, delay: .zero, calls: ReaderTests.Counter()),
                      announcer: spy, haptics: spy)
    }
}
