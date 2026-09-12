// Frames from a photograph instead of a camera.
//
// The simulator has no camera, so everything below the sensor — the stats,
// the judge, the classifier, the gate, what is said and felt — is exercised
// by feeding it a picture. Launched with `-fixture <name>` the app uses this
// instead of the camera, which is how the UI tests walk the pipeline end to
// end and how a held-out photograph can be tried on a Mac in Phase 2.
//
// It emits the same frame at camera rate until stopped, because the reader
// expects a stream, and a stream of one still is what a hand holding a note
// still looks like.
import CoreGraphics
import CoreVideo
import ImageIO
import UIKit

struct FixtureSource: FrameSource {
    let image: CGImage
    private let running = Running()

    /// The fixture by name, from the app bundle's `Fixtures/` folder.
    init?(named name: String) {
        // Xcode flattens a synchronized folder's resources into the bundle
        // root, so look there first and in a subdirectory second.
        guard let url = Bundle.main.url(forResource: name, withExtension: "png")
                ?? Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Fixtures"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cg = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        image = cg
    }

    func frames() -> AsyncStream<Frame> {
        // Wrapped before the closure, so what the closure captures is Sendable.
        let frame = Self.pixelBuffer(from: image).map { Frame(pixels: $0) }
        let running = running
        return AsyncStream { continuation in
            let task = Task {
                while !Task.isCancelled, running.isRunning, let frame {
                    continuation.yield(frame)
                    try? await Task.sleep(for: .milliseconds(33))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func start() { running.isRunning = true }
    func stop() { running.isRunning = false }

    /// A BGRA buffer the same shape the camera would hand over.
    static func pixelBuffer(from image: CGImage) -> CVPixelBuffer? {
        let width = 640, height = 480
        var pb: CVPixelBuffer?
        CVPixelBufferCreate(nil, width, height, kCVPixelFormatType_32BGRA,
                            [kCVPixelBufferCGImageCompatibilityKey: true] as CFDictionary, &pb)
        guard let pb else { return nil }
        CVPixelBufferLockBaseAddress(pb, [])
        defer { CVPixelBufferUnlockBaseAddress(pb, []) }
        guard let ctx = CGContext(data: CVPixelBufferGetBaseAddress(pb), width: width, height: height,
                                  bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pb),
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        else { return nil }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pb
    }

    private final class Running: @unchecked Sendable {
        var isRunning = false
    }
}
