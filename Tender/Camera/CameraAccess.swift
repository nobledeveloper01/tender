// Whether the app may use the camera. The system prompt is the only
// permission the app ever asks for; if it is refused, the app says so once,
// in one sentence, with one button — never a blank camera and never a
// "can't see a note" that is really "not allowed to look".
import AVFoundation

enum CameraAccess: Sendable, Equatable {
    case allowed
    case denied
    case none   // no camera on this device: the simulator

    /// `-cameraDenied` on the command line, for the UI tests: the permission
    /// dialog cannot be driven from a test and the denied state must be seen.
    static func current() async -> CameraAccess {
        if CommandLine.arguments.contains("-cameraDenied") { return .denied }
        guard CameraSession.isAvailable else { return .none }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return .allowed
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .video) ? .allowed : .denied
        default: return .denied
        }
    }
}
