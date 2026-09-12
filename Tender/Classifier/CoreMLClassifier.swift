// The trained classifier. Not wired until `make model-check` passes — the
// switch is one line in `Wiring`, and RELEASE-GATES R3 is where it is
// recorded. Until then `UntrainedClassifier` runs and says so.
//
// Loads the compiled model by name at runtime rather than through Xcode's
// generated class, so that the app builds from a fresh clone where the
// model — an artefact of `make model`, not source — does not exist.
import CoreML
import CoreVideo
import TenderDomain
@preconcurrency import Vision

// `VNCoreMLModel` is not marked Sendable; it is immutable after loading and
// Vision documents it as safe to share across requests, which is the whole
// contract here.
struct CoreMLClassifier: NoteClassifier, @unchecked Sendable {
    private let model: VNCoreMLModel

    /// `nil` when the compiled model is not in the bundle. The wiring falls
    /// back to the placeholder explicitly and says so; it never guesses.
    init?() {
        guard let url = Bundle.main.url(forResource: "Tender", withExtension: "mlmodelc"),
              let ml = try? MLModel(contentsOf: url),
              let vn = try? VNCoreMLModel(for: ml) else { return nil }
        model = vn
    }

    func classify(_ frame: Frame) async -> [Note: Double]? {
        let request = VNCoreMLRequest(model: model)
        request.imageCropAndScaleOption = .centerCrop
        let handler = VNImageRequestHandler(cvPixelBuffer: frame.pixels, orientation: .right)
        do { try handler.perform([request]) } catch { return nil }
        guard let results = request.results as? [VNClassificationObservation] else { return nil }
        var out: [Note: Double] = [:]
        for r in results {
            if let note = Note(rawValue: r.identifier) { out[note] = Double(r.confidence) }
        }
        // Labels the code does not know are dropped; the domain pools and
        // decides over what is left, and a model with the wrong labels
        // produces "not sure" rather than a wrong number.
        let total = out.values.reduce(0, +)
        guard total > 0 else { return nil }
        return out.mapValues { $0 / total }
    }
}
