#!/usr/bin/env swift
// Train the classifier and publish what it can and cannot do.
//
//   make model            trains on DATASET/train, evaluates on DATASET/test,
//                         writes Tender/Classifier/Tender.mlmodel and docs/MODEL-REPORT.md
//
// Create ML, image classification, transfer learning on the built-in feature
// extractor. The held-out set is never seen in training; `dataset-check` has
// already refused any content shared between the two, by hash. The numbers
// this writes are the numbers in RELEASE-GATES, and `model-check` refuses
// to let the model be wired if any class is below the floor or if the two
// ₦500s and the two ₦1000s are ever confused across values.
import CreateML
import Foundation

let env = ProcessInfo.processInfo.environment
let root = URL(fileURLWithPath: env["TENDER_ROOT"] ?? FileManager.default.currentDirectoryPath)
let dataset = URL(fileURLWithPath: env["DATASET"] ?? root.deletingLastPathComponent().appendingPathComponent("tender-dataset").path)
let modelOut = URL(fileURLWithPath: env["MODEL_OUT"] ?? root.appendingPathComponent("Tender/Classifier/Tender.mlmodel").path)
let reportOut = URL(fileURLWithPath: env["REPORT_OUT"] ?? root.appendingPathComponent("docs/MODEL-REPORT.md").path)
let iterations = Int(env["ITERATIONS"] ?? "") ?? 25

let train = dataset.appendingPathComponent("train")
let test = dataset.appendingPathComponent("test")
guard FileManager.default.fileExists(atPath: train.path), FileManager.default.fileExists(atPath: test.path) else {
    FileHandle.standardError.write("no dataset at \(dataset.path) — see docs/DATASET-GUIDE.md\n".data(using: .utf8)!)
    exit(1)
}

print("training on \(train.path) …")
// Augmentation: the note will be held at a slant, in a hand, in poor light;
// the training set should be widened the same way.
let params = MLImageClassifier.ModelParameters(
    validation: .split(strategy: .automatic),
    maxIterations: iterations,
    augmentation: [.crop, .rotation, .exposure, .blur]
)
let classifier: MLImageClassifier
do {
    classifier = try MLImageClassifier(trainingData: .labeledDirectories(at: train), parameters: params)
} catch {
    FileHandle.standardError.write("training failed: \(error)\n".data(using: .utf8)!)
    exit(1)
}

print("evaluating on the held-out set …")
let evaluation = classifier.evaluation(on: .labeledDirectories(at: test))
var counts: [String: [String: Int]] = [:]
for i in 0..<evaluation.confusion.rows.count {   // columns: True Label, Predicted, Count
    let row = evaluation.confusion.rows[i]
    let t = row["True Label"]!.stringValue!, p = row["Predicted"]!.stringValue!, n = row["Count"]!.intValue!
    counts[t, default: [:]][p, default: 0] += n
}
let classes = Array(Set(counts.keys).union(counts.values.flatMap { $0.keys })).sorted { ($0.count, $0) < ($1.count, $1) }
func value(_ c: String) -> String { c.replacingOccurrences(of: "new", with: "") }

var lines: [String] = []
lines.append("# Model report")
lines.append("")
lines.append("Written by `make model` from the held-out set, which the training never saw. Do not edit by hand.")
lines.append("`make model-check` reads this file and refuses to wire the model if any class is below the floor")
lines.append("or if a ₦500 and a ₦1000 are ever confused with each other.")
lines.append("")
let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
lines.append("- Trained: \(df.string(from: Date()))")
lines.append("- Iterations: \(iterations)")
lines.append("- Held-out accuracy: \(String(format: "%.1f", (1 - evaluation.classificationError) * 100))%")
lines.append("")
lines.append("| class | held out | recall | precision | confused with |")
lines.append("|---|---|---|---|---|")
var crossValue500_1000 = 0
for c in classes {
    let row = counts[c] ?? [:]
    let total = row.values.reduce(0, +)
    let tp = row[c] ?? 0
    let predictedAs = counts.values.reduce(0) { $0 + ($1[c] ?? 0) }
    let recall = total > 0 ? Double(tp) / Double(total) : 0
    let precision = predictedAs > 0 ? Double(tp) / Double(predictedAs) : 0
    let confused = row.filter { $0.key != c && $0.value > 0 }.sorted { $0.value > $1.value }
        .map { "\($0.key) ×\($0.value)" }.joined(separator: ", ")
    for (p, n) in row where p != c {
        let a = value(c), b = value(p)
        if Set([a, b]) == Set(["n500", "n1000"]) { crossValue500_1000 += n }
    }
    lines.append("| \(c) | \(total) | \(String(format: "%.1f", recall * 100))% | \(String(format: "%.1f", precision * 100))% | \(confused.isEmpty ? "—" : confused) |")
}
lines.append("")
lines.append("- ₦500 ↔ ₦1000 confusions, either direction, any design: **\(crossValue500_1000)**")
lines.append("")
try! FileManager.default.createDirectory(at: reportOut.deletingLastPathComponent(), withIntermediateDirectories: true)
try! lines.joined(separator: "\n").write(to: reportOut, atomically: true, encoding: .utf8)

try! FileManager.default.createDirectory(at: modelOut.deletingLastPathComponent(), withIntermediateDirectories: true)
let metadata = MLModelMetadata(author: "Tender", shortDescription: "Which of the eleven naira note designs this is. Never whether it is genuine.", version: "0.1")
try! classifier.write(to: modelOut, metadata: metadata)
print("wrote \(modelOut.path) and \(reportOut.path)")
