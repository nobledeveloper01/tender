// San Francisco with Dynamic Type honoured to the largest accessibility size.
// Not bundled Inter, which every cross-platform project in the portfolio
// uses; DESIGN.md says why.
//
// These are *text styles*, not sizes: `Font.system(size:)` is fixed and the
// accessibility audit rightly fails it — a low-vision user who set the
// largest text size would get 17 pt. The point sizes here are what each
// style renders at the default size, and `make design-check` reads them so
// DESIGN.md cannot quote a number the app does not use.
import SwiftUI

enum Type {
    static let display: CGFloat = 34     // .largeTitle
    static let headline: CGFloat = 28    // .title
    static let body: CGFloat = 17        // .body
    static let secondary: CGFloat = 15   // .subheadline

    static func displayFont() -> Font { .system(.largeTitle, design: .rounded, weight: .bold) }
    static func headlineFont() -> Font { .system(.title, weight: .semibold) }
    static func bodyFont() -> Font { .system(.body) }
    static func secondaryFont() -> Font { .system(.subheadline) }

    /// The denomination's base size. Scaled by `@ScaledMetric(relativeTo:
    /// .largeTitle)` at the call site, so at the largest accessibility size
    /// it exceeds 200 pt and fills the width — which is the intent.
    static let numeralBase: CGFloat = 96
}
