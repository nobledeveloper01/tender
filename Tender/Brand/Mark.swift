// The Tender mark: a banknote, its portrait window, and three pulses.
// Drawn in code so the splash can bloom it; `scripts/brandmark.py` draws
// the same shape for the icon and docs/mark.png.
import SwiftUI

struct Mark: View {
    var size: CGFloat = 96
    var color: Color

    var body: some View {
        Canvas { context, bounds in
            let w = bounds.width, h = bounds.height
            // The note.
            let note = CGRect(x: w * 0.08, y: h * 0.26, width: w * 0.84, height: h * 0.48)
            let stroke = max(2, w * 0.045)
            context.stroke(Path(roundedRect: note, cornerRadius: w * 0.07), with: .color(color), lineWidth: stroke)
            // The portrait window.
            let r = h * 0.11
            let c = CGPoint(x: w * 0.30, y: h * 0.50)
            context.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)), with: .color(color))
            // Three pulses: short, short, long.
            let x0 = w * 0.50, y = h * 0.50, gap = w * 0.09
            let heights: [CGFloat] = [0.12, 0.12, 0.22]
            for (i, k) in heights.enumerated() {
                let bh = h * k
                let bar = CGRect(x: x0 + CGFloat(i) * gap, y: y - bh / 2, width: stroke, height: bh)
                context.fill(Path(roundedRect: bar, cornerRadius: stroke / 2), with: .color(color))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
