// The one screen. One accessibility element in the camera state, so a swipe
// never lands on something surprising; a tap repeats; the magic tap starts
// over. The numeral fills the width at the largest accessibility size.
import SwiftUI
import TenderDomain

struct CameraScreen: View {
    @Bindable var reader: Reader
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    /// One sheet modifier, one enum: SwiftUI honours only one `.sheet` on a
    /// view, and two of them meant the change sheet never opened — found by
    /// the UI test that tried to.
    enum Sheet: String, Identifiable { case settings, change; var id: String { rawValue } }
    @State private var sheet: Sheet?
    @State private var posture = Posture()
    @AppStorage(Preferences.hideNumberKey) private var hideNumber = false
    @AppStorage(Preferences.dimKey) private var dim = false
    @AppStorage(Preferences.speechKey) private var speechEnabled = true
    @AppStorage(Preferences.hapticsKey) private var hapticsEnabled = true
    @ScaledMetric(relativeTo: .largeTitle) private var numeralSize = Type.numeralBase

    var body: some View {
        let palette = Palette.current(scheme)
        ZStack {
            LinearGradient(colors: palette.canvas, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            // The preview, dimmed 40% so the numeral reads over it and a
            // low-vision user gains aim without losing contrast. Only when
            // there is a live session; the simulator shows the canvas.
            if let session = reader.captureSession {
                CameraPreview(session: session)
                    .ignoresSafeArea()
                    .opacity(0.6)
                    .accessibilityHidden(true)
            }
            ShakeDetector { reader.startOver() }
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
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
        .accessibilityAction(named: Strings.howSure) { reader.howSure() }
        .accessibilityAction(named: reader.mode == .identify ? Strings.startTally : Strings.stopTally) {
            if case .tally = reader.mode { reader.stopMode() } else { reader.startTally() }
        }
        .accessibilityAction(named: Strings.checkChange) { sheet = .change }
        .accessibilityAction(.magicTap) { reader.startOver() }
        .overlay(alignment: .topTrailing) {
            Button {
                sheet = .settings
            } label: {
                Image(systemName: "gearshape")
                    .font(.title2.weight(.semibold))   // a text style, so it scales with the rest
                    .foregroundStyle(palette.textSecondary)
                    .frame(width: Target.standard, height: Target.standard)
            }
            .accessibilityLabel(Strings.settings)
            .padding(Gap.s)
        }
        .sheet(item: $sheet) { which in
            switch which {
            case .settings: SettingsSheet(reader: reader, speechEnabled: $speechEnabled, hapticsEnabled: $hapticsEnabled)
            case .change: ChangeSheet(reader: reader)
            }
        }
        .onAppear {
            reader.start()
            // Test hooks: XCUITest cannot invoke a VoiceOver custom action,
            // and cannot flip a preference before launch.
            if CommandLine.arguments.contains("-openChange") { sheet = .change }
            if CommandLine.arguments.contains("-hideNumber") { hideNumber = true }
            // One sentence, once, on the first launch ever. Not a screen.
            if !UserDefaults.standard.bool(forKey: Preferences.hintGivenKey) || CommandLine.arguments.contains("-firstLaunch") {
                UserDefaults.standard.set(true, forKey: Preferences.hintGivenKey)
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(600))
                    reader.say(Strings.firstLaunchHint)
                }
            }
            posture.watch { faceDown in faceDown ? reader.pause() : reader.resume() }
            applyDim()
        }
        .onDisappear { reader.stop(); posture.stop(); restoreBrightness() }
        .onChange(of: scenePhase) { _, phase in
            // Back from a call or the lock screen: the last answer, again.
            if phase == .active, reader.verdict != nil { reader.repeatLast() }
        }
        .onChange(of: dim) { _, _ in applyDim() }
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
            // "Hide the number": nobody in the bus reads a blind person's
            // screen. Spoken and felt regardless; shown as a dot.
            Text(hideNumber ? "•" : String(note.value.rawValue))
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
            case .steady, .closer: palette.caution
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

extension CameraScreen {
    /// Dim: the screen to its minimum while the camera is up. A blind user
    /// saves a day's battery; a low-vision one keeps the numeral, which is
    /// drawn at full contrast regardless of brightness.
    @MainActor private static var savedBrightness: CGFloat?

    func applyDim() {
        if dim {
            if Self.savedBrightness == nil { Self.savedBrightness = UIScreen.main.brightness }
            UIScreen.main.brightness = 0.05
        } else {
            restoreBrightness()
        }
    }

    func restoreBrightness() {
        if let b = Self.savedBrightness { UIScreen.main.brightness = b; Self.savedBrightness = nil }
    }
}

struct SettingsSheet: View {
    let reader: Reader
    @Binding var speechEnabled: Bool
    @Binding var hapticsEnabled: Bool
    @AppStorage(Preferences.soundsKey) private var sounds = false
    @AppStorage(Preferences.strengthKey) private var strength = 1.0
    @AppStorage(Preferences.rateKey) private var speechRate = 0.5
    @AppStorage(Preferences.hideNumberKey) private var hideNumber = false
    @AppStorage(Preferences.dimKey) private var dim = false
    @AppStorage(Preferences.languageKey) private var language = "en"
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let palette = Palette.current(scheme)
        NavigationStack {
            // Every row 64 pt. Done is a row rather than a toolbar item
            // because toolbar items are sized by the bar, which caps them at
            // the largest text sizes — the audit found it — and below 64.
            // Seven rows, so the sheet fits without a fold at the default
            // size and a blind user is never twelve swipes from a setting.
            // Each group is its own short screen.
            List {
                Section {
                    NavigationLink(Strings.learn) { LearnView(reader: reader) }
                        .frame(minHeight: Target.standard)
                    NavigationLink(Strings.quiz) { QuizView(reader: reader) }
                        .frame(minHeight: Target.standard)
                }
                Section {
                    NavigationLink(Strings.speechGroup) {
                        List {
                            Toggle(Strings.speechWhenVoiceOverOff, isOn: $speechEnabled)
                                .frame(minHeight: Target.standard)
                            ChoiceRow(title: Strings.speechRate, choices: [
                                Choice(label: Strings.rateSlow, value: 0.4),
                                Choice(label: Strings.rateNormal, value: 0.5),
                                Choice(label: Strings.rateFast, value: 0.6),
                            ], selection: $speechRate)
                            LanguageRow(selection: $language)
                        }
                        .font(Type.bodyFont()).tint(palette.ready).navigationTitle(Strings.speechGroup)
                    }
                    .frame(minHeight: Target.standard)
                    NavigationLink(Strings.feelGroup) {
                        List {
                            Toggle(Strings.haptics, isOn: $hapticsEnabled)
                                .frame(minHeight: Target.standard)
                            ChoiceRow(title: Strings.hapticStrength, choices: [
                                Choice(label: Strings.strengthHalf, value: 0.5),
                                Choice(label: Strings.strengthNormal, value: 1.0),
                                Choice(label: Strings.strengthStrong, value: 1.5),
                            ], selection: $strength)
                            Toggle(Strings.sounds, isOn: $sounds)
                                .frame(minHeight: Target.standard)
                        }
                        .font(Type.bodyFont()).tint(palette.ready).navigationTitle(Strings.feelGroup)
                    }
                    .frame(minHeight: Target.standard)
                    NavigationLink(Strings.screenGroup) {
                        List {
                            Toggle(Strings.hideNumber, isOn: $hideNumber)
                                .frame(minHeight: Target.standard)
                            Toggle(Strings.dimScreen, isOn: $dim)
                                .frame(minHeight: Target.standard)
                        }
                        .font(Type.bodyFont()).tint(palette.ready).navigationTitle(Strings.screenGroup)
                    }
                    .frame(minHeight: Target.standard)
                }
                Section {
                    Button(Strings.privacy) { reader.say(Strings.privacyAnswer) }
                        .frame(maxWidth: .infinity, minHeight: Target.standard, alignment: .leading)
                        .foregroundStyle(palette.textPrimary)
                        .accessibilityHint(Strings.privacyAnswer)
                    Button(Strings.done) { dismiss() }
                        .frame(maxWidth: .infinity, minHeight: Target.standard)
                        .fontWeight(.semibold)
                }
            }
            .font(Type.bodyFont())
            .tint(palette.ready)   // the palette's action colour, not the system blue
            .navigationTitle(Strings.settings)
        }
    }
}
