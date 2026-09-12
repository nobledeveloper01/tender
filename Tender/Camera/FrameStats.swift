// A frame reduced to the four numbers the domain judges.
//
// The app measures; the domain decides. Nothing here knows what "too dark"
// means — it computes a mean luminance and hands it over.
import Accelerate
import CoreVideo

struct FrameStats: Sendable, Equatable {
    /// Fraction of the frame whose colour is plausibly a banknote.
    let coverage: Double
    /// Mean luminance, 0…1.
    let luminance: Double
    /// Fraction of pixels at the top of the range.
    let clipped: Double
    /// High-frequency energy as a share of the frame's own contrast.
    let detail: Double

    /// Compute from a BGRA pixel buffer. Coarse on purpose: a 640×480 frame is
    /// sampled every fourth pixel, which is more than enough to judge light
    /// and blur and keeps this under a millisecond on an A12.
    static func measure(_ buffer: CVPixelBuffer) -> FrameStats {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(buffer),
              CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_32BGRA else {
            return FrameStats(coverage: 0, luminance: 0, clipped: 0, detail: 0)
        }
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let stride = CVPixelBufferGetBytesPerRow(buffer)
        let p = base.assumingMemoryBound(to: UInt8.self)
        let step = 4

        var sum = 0.0, sumSq = 0.0, clippedCount = 0, noteLike = 0, n = 0
        var lapSum = 0.0, lapN = 0
        var prevRow: [Double] = []
        for y in Swift.stride(from: 0, to: height, by: step) {
            var row: [Double] = []
            row.reserveCapacity(width / step + 1)
            for x in Swift.stride(from: 0, to: width, by: step) {
                let i = y * stride + x * 4
                let b = Double(p[i]), g = Double(p[i + 1]), r = Double(p[i + 2])
                let l = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255
                row.append(l)
                sum += l; sumSq += l * l; n += 1
                if l > 0.97 { clippedCount += 1 }
                // A banknote is paper: moderately saturated, mid-luminance,
                // not a white wall and not the dark. A coarse gate that a hand
                // also passes — warm skin sits in the same band as the ₦5,
                // ₦10 and ₦1000, and a test proved it — so what this excludes
                // is walls, tables and the dark, and a hand reaches the
                // classifier, whose answer for a hand is "I don't recognise
                // this". The thresholds are provisional until a handset (R2).
                let mx = max(r, g, b), mn = min(r, g, b)
                let sat = mx == 0 ? 0 : (mx - mn) / mx
                if l > 0.12, l < 0.9, sat > 0.12, sat < 0.85 { noteLike += 1 }
            }
            if !prevRow.isEmpty, row.count == prevRow.count, row.count > 2 {
                for x in 1..<(row.count - 1) {
                    let lap = row[x - 1] + row[x + 1] + prevRow[x] - 3 * row[x]
                    lapSum += lap * lap; lapN += 1
                }
            }
            prevRow = row
        }
        guard n > 0 else { return FrameStats(coverage: 0, luminance: 0, clipped: 0, detail: 0) }
        let mean = sum / Double(n)
        let variance = max(sumSq / Double(n) - mean * mean, 1e-6)
        let detail = lapN > 0 ? (lapSum / Double(lapN)) / variance : 0
        return FrameStats(
            coverage: Double(noteLike) / Double(n),
            luminance: mean,
            clipped: Double(clippedCount) / Double(n),
            detail: detail
        )
    }
}
