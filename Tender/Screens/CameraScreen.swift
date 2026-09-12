// The one screen. One accessibility element in the camera state, so a swipe
// never lands on something surprising; a tap repeats; the magic tap starts
// over. The numeral fills the width at the largest accessibility size.
import SwiftUI
import TenderDomain

struct CameraScreen: View {
    @Bindable var reader: Reader
    @Environment(\.colorScheme) private var scheme
    @State private var showSettings = false
    @AppStorage("speech.enabled") private var speechEnabled = true
    @AppStorage("haptics.enabled") private var hapticsEnabled = true
    @ScaledMetric(relativeTo: .largeTitle) private var numeralSize = Type.numeralBase

    var body: some View {
        let palette = Palette.current(scheme)
        ZStack {
            LinearGradient(colors: palette.canvas, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: Gap.l) {
                Spacer()
                answer(palette)
                Spacer()
                framing(palette)
                    .padding(.bottom, Gap.xl)
            }
            .padding(.horizontal, Gap.l)
        }
        .contentShape(Rectangle())
        .onTapGesture { reader.repeatLast() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Strings.cameraScreenLabel)
        .accessibilityValue(reader.lastSaid)
        .accessibilityAddTraits(.allowsDirectInteraction)
        .accessibilityAction(named: Strings.repeatAction) { reader.repeatLast() }
        .accessibilityAction(named: Strings.startOver) { reader.startOver() }
        .accessibilityAction(.magicTap) { reader.startOver() }
        .overlay(alignment: .topTrailing) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(palette.textSecondary)
                    .frame(width: Target.standard, height: Target.standard)
            }
            .accessibilityLabel(Strings.settings)
            .padding(Gap.s)
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(speechEnabled: $speechEnabled, hapticsEnabled: $hapticsEnabled)
        }
        .onAppear { reader.start() }
        .onDisappear { reader.stop() }
    }

    @ViewBuilder
    private func answer(_ palette: Palette) -> some View {
        switch reader.verdict {
        case .sure(let note):
            numeral(note, colour: palette.ready, palette: palette)
        case .probably(let note):
            numeral(note, colour: palette.caution, palette: palette)
        case .notSure:
            Text(Announcement.text(for: .notSure))
                .font(Type.headlineFont())
                .foregroundStyle(palette.stop)
                .multilineTextAlignment(.center)
        case nil:
            EmptyView()
        }
    }

    private func numeral(_ note: Note, colour: Color, palette: Palette) -> some View {
        VStack(spacing: Gap.s) {
            Text("\(note.value.rawValue)")
                .font(.system(size: numeralSize, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(colour)
            if note.design == .redesign2022 {
                Text(Strings.newDesign)
                    .font(Type.headlineFont())
                    .foregroundStyle(palette.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func framing(_ palette: Palette) -> some View {
        if reader.verdict == nil, let text = Announcement.text(for: reader.framing) {
            let colour: Color = switch reader.framing {
            case .steady: palette.caution
            case .nothing, .tooDark, .tooBright: palette.stop
            case .ready: palette.ready
            }
            HStack(spacing: Gap.s) {
                Circle().fill(colour).frame(width: 12, height: 12)
                    .accessibilityHidden(true)
                Text(text)
                    .font(Type.headlineFont())
                    .foregroundStyle(palette.textPrimary)
            }
            .padding(.horizontal, Gap.m)
            .padding(.vertical, Gap.s)
            .background(palette.raised, in: RoundedRectangle(cornerRadius: Radius.card))
        }
    }
}

struct SettingsSheet: View {
    @Binding var speechEnabled: Bool
    @Binding var hapticsEnabled: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Toggle(Strings.speechWhenVoiceOverOff, isOn: $speechEnabled)
                    .frame(minHeight: Target.standard)
                Toggle(Strings.haptics, isOn: $hapticsEnabled)
                    .frame(minHeight: Target.standard)
            }
            .font(Type.bodyFont())
            .navigationTitle(Strings.settings)
            .toolbar {
                Button("Done") { dismiss() }
                    .frame(minWidth: Target.standard, minHeight: Target.standard)
            }
        }
    }
}
