// Face down is a pocket. The camera stops and so does the voice; face up
// again and it resumes. Orientation, not the proximity sensor, because the
// proximity sensor darkens the screen and cannot be read directly.
import UIKit

@MainActor
final class Posture {
    private var observer: NSObjectProtocol?

    func watch(_ onChange: @escaping @MainActor (Bool) -> Void) {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        observer = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { _ in
            Task { @MainActor in onChange(UIDevice.current.orientation == .faceDown) }
        }
    }

    /// Called from the screen's onDisappear; a deinit cannot touch the
    /// observer under strict concurrency, and the screen knows when it goes.
    func stop() {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        observer = nil
    }
}
