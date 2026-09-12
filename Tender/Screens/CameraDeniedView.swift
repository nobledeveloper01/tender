// The one dead end the platform can force, given a forward path: one
// sentence and one 64 pt button that opens Settings. Spoken by VoiceOver the
// moment it appears.
import SwiftUI
import UIKit

struct CameraDeniedView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let palette = Palette.current(scheme)
        ZStack {
            LinearGradient(colors: palette.canvas, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: Gap.l) {
                Text(Strings.cameraDenied)
                    .font(Type.headlineFont())
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)
                Button(Strings.openSettings) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(Type.headlineFont())
                .foregroundStyle(palette.onReady)
                .frame(maxWidth: .infinity, minHeight: Target.standard)
                .background(palette.ready, in: RoundedRectangle(cornerRadius: Radius.card))
            }
            .padding(Gap.l)
        }
        .onAppear { UIAccessibility.post(notification: .screenChanged, argument: Strings.cameraDenied) }
    }
}
