// The palette DESIGN.md documents. `make design-check` reads this file and
// fails if the table there disagrees with the constants here, in either
// direction. Every text pair is asserted at 7:1 and every state colour at
// 4.5:1 by TenderTests/ContrastTests, on every ground including both
// gradient stops.
import SwiftUI

/// One theme's colours. The names are the roles in DESIGN.md.
struct Palette: Sendable {
    let surface: Color
    let raised: Color
    let high: Color
    let outline: Color
    let textPrimary: Color
    let textSecondary: Color
    let ready: Color
    let onReady: Color
    let caution: Color
    let stop: Color
    /// The two stops of the page gradient, top then bottom.
    let canvas: [Color]

    static let light = Palette(
        surface: Color(hex: 0xFFFFFF),
        raised: Color(hex: 0xF4F4F6),
        high: Color(hex: 0xE8E8EC),
        outline: Color(hex: 0x8A8A96),
        textPrimary: Color(hex: 0x0A0A0C),
        textSecondary: Color(hex: 0x3E3E48),
        ready: Color(hex: 0x6B4E00),
        onReady: Color(hex: 0xFFFFFF),
        caution: Color(hex: 0x7A4200),
        stop: Color(hex: 0x9E1B14),
        canvas: [Color(hex: 0xFFFFFF), Color(hex: 0xF2F2F5)]
    )

    static let dark = Palette(
        surface: Color(hex: 0x0A0A0C),
        raised: Color(hex: 0x1A1A1F),
        high: Color(hex: 0x26262D),
        outline: Color(hex: 0x62626E),
        textPrimary: Color(hex: 0xFFFFFF),
        textSecondary: Color(hex: 0xC9C9D2),
        ready: Color(hex: 0xFFD166),
        onReady: Color(hex: 0x0A0A0C),
        caution: Color(hex: 0xFFB454),
        stop: Color(hex: 0xFF8A80),
        canvas: [Color(hex: 0x121216), Color(hex: 0x0A0A0C)]
    )

    /// The system setting wins here, alone in the portfolio: a low-vision
    /// user who chose light with increased contrast did so on advice, and the
    /// app does not overrule it. DESIGN.md says why.
    static func current(_ scheme: ColorScheme) -> Palette {
        scheme == .dark ? .dark : .light
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

private struct PaletteKey: EnvironmentKey {
    static let defaultValue: Palette = .dark
}

extension EnvironmentValues {
    var palette: Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}
