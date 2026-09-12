// A camera frame that can cross an isolation boundary.
//
// `CVPixelBuffer` is a Core Foundation object with no Sendable annotation.
// The camera queue produces it and the reader consumes it, and nothing
// writes to it in between — the app measures it and, if it is ready, hands
// it to the classifier, then releases it. That is the whole contract, and it
// is stated here once rather than with `@unchecked` scattered at every use.
import CoreVideo

struct Frame: @unchecked Sendable {
    let pixels: CVPixelBuffer
}
