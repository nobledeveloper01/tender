// Where frames come from. The real one is the camera; the simulator has no
// camera, so the app wires a source that produces nothing and says so.
import CoreVideo

protocol FrameSource: Sendable {
    /// Frames as they arrive. Ends when the source stops.
    func frames() -> AsyncStream<Frame>
    func start()
    func stop()
}

/// No camera here. Emits nothing, so the screen says "I can't see a note",
/// which is the truth about a simulator.
struct NoCameraSource: FrameSource {
    func frames() -> AsyncStream<Frame> { AsyncStream { $0.finish() } }
    func start() {}
    func stop() {}
}
