// The flash, as a switch the reader can flip. The domain decides when; this
// is how. A source with no torch — a fixture, the simulator — has one that
// remembers what it was told, so the tests can read it.
import AVFoundation

@MainActor
protocol Lighting: AnyObject {
    var isOn: Bool { get }
    func set(_ on: Bool)
}

@MainActor
final class Torch: Lighting {
    private(set) var isOn = false
    func set(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
            isOn = on
        } catch {}
    }
}

@MainActor
final class NoTorch: Lighting {
    private(set) var isOn = false
    func set(_ on: Bool) { isOn = on }
}
