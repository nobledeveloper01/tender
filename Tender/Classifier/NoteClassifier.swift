// The classifier is a protocol, so the app can be wired to a stand-in that
// recognises nothing until the model exists — and so the stand-in cannot be
// mistaken for the model by anybody reading the wiring.
import CoreVideo
import TenderDomain

protocol NoteClassifier: Sendable {
    /// A distribution over the eleven designs, summing to 1. `nil` means the
    /// classifier could not answer in time, which the app treats as not sure.
    func classify(_ frame: Frame) async -> [Note: Double]?
}
