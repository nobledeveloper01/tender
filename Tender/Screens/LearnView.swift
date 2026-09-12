// Where the haptic vocabulary is learned. Eight rows, one per value; tapping
// one says the value and pulses its pattern, through the same two channels a
// real answer uses. DESIGN.md says the vocabulary is learnable in a minute;
// this is the minute.
import SwiftUI
import TenderDomain

struct LearnView: View {
    let reader: Reader
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let palette = Palette.current(scheme)
        List {
            Section {
                ForEach(Naira.allCases, id: \.self) { value in
                    let pulses = HapticPattern.pulses(for: value)
                    Button {
                        reader.demonstrate(value)
                    } label: {
                        HStack(spacing: Gap.m) {
                            Text("₦\(value.rawValue)")
                                .font(Type.headlineFont())
                                .foregroundStyle(palette.textPrimary)
                                .frame(minWidth: 96, alignment: .leading)
                            Text(Strings.pulseWords(pulses))
                                .font(Type.bodyFont())
                                .foregroundStyle(palette.textSecondary)
                            Spacer()
                            PulseGlyph(pulses: pulses, colour: palette.ready)
                        }
                        .frame(minHeight: Target.standard)
                    }
                    .accessibilityLabel("\(value.spoken) naira, \(Strings.pulseWords(pulses))")
                    .accessibilityHint(Strings.learnHint)
                }
            } footer: {
                Text(Strings.learnHint)
                    .font(Type.secondaryFont())
            }
        }
        .tint(palette.ready)
        .navigationTitle(Strings.learn)
    }
}

/// The pattern drawn: short bars and long bars, for the sighted.
struct PulseGlyph: View {
    let pulses: [Pulse]
    let colour: Color

    var body: some View {
        HStack(spacing: Gap.xs) {
            ForEach(Array(pulses.enumerated()), id: \.offset) { _, pulse in
                RoundedRectangle(cornerRadius: 2)
                    .fill(colour)
                    .frame(width: pulse == .short ? 6 : 18, height: 12)
            }
        }
        .accessibilityHidden(true)
    }
}
