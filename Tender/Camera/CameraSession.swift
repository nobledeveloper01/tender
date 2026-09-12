// The live camera. 30 fps, 640×480, BGRA, on a serial queue. Frames are
// handed to the stream and released; nothing is retained or written.
@preconcurrency import AVFoundation
import CoreVideo

final class CameraSession: NSObject, FrameSource, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    private let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "ng.tender.frames")
    private let output = AVCaptureVideoDataOutput()
    private var continuation: AsyncStream<Frame>.Continuation?
    private let lock = NSLock()

    static var isAvailable: Bool {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil
    }

    override init() {
        super.init()
        session.beginConfiguration()
        session.sessionPreset = .vga640x480
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }
        // Low Power Mode: fifteen frames a second instead of thirty. The
        // judge does not need more, and a market day is long.
        if ProcessInfo.processInfo.isLowPowerModeEnabled,
           let device = (session.inputs.first as? AVCaptureDeviceInput)?.device,
           (try? device.lockForConfiguration()) != nil {
            device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 15)
            device.unlockForConfiguration()
        }
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: queue)
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()
    }

    func frames() -> AsyncStream<Frame> {
        AsyncStream { continuation in
            lock.withLock { self.continuation = continuation }
            continuation.onTermination = { [weak self] _ in
                self?.lock.withLock { self?.continuation = nil }
            }
        }
    }

    // `self` is @unchecked Sendable and owns the session; the queue is the
    // only place the session is started or stopped.
    func start() {
        queue.async { [self] in if !session.isRunning { session.startRunning() } }
    }

    func stop() {
        queue.async { [self] in if session.isRunning { session.stopRunning() } }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixels = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lock.lock()
        continuation?.yield(Frame(pixels: pixels))
        lock.unlock()
    }

    var captureSession: AVCaptureSession { session }
}
