// The whole screen is the target. Where a control exists, it is this big.
import CoreGraphics

enum Target {
    /// Nothing in this app is 44. DESIGN.md.
    static let standard: CGFloat = 64
}

enum Radius {
    static let card: CGFloat = 20
    static let chip: CGFloat = 12
}

enum Gap {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
}
