// Recognises nothing, always — deliberately.
//
// A stand-in that returned a plausible denomination would be
// indistinguishable from the product to anybody not reading its source, and
// would put a wrong number in front of a blind person holding cash. This one
// returns a uniform distribution, which the confidence gate turns into
// "I don't recognise this" every time. R3 replaces it.
import CoreVideo
import TenderDomain

struct UntrainedClassifier: NoteClassifier {
    func classify(_ frame: Frame) async -> [Note: Double]? {
        let p = 1.0 / Double(Note.allCases.count)
        return Dictionary(uniqueKeysWithValues: Note.allCases.map { ($0, p) })
    }
}
