// The portfolio's splash: the mark, a warm bloom, the wordmark, about 1.2 s,
// with the camera initialising behind it.
//
// Driven by a timer, never by an animation: with Reduce Motion on, an
// animation-driven splash completes instantly and never draws a frame. Here
// Reduce Motion gets the finished frame for the same 1.2 s. VoiceOver
// announces "Tender" over it and nothing else until the first framing verdict.
import SwiftUI
import UIKit

struct SplashView: View {
    let onSwept: @MainActor () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @State private var grown = false
    @State private var bloomed = false

    static let duration: TimeInterval = 1.2

    var body: some View {
        let palette = Palette.current(scheme)
        ZStack {
            LinearGradient(colors: palette.canvas, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            Circle()
                .fill(palette.ready.opacity(bloomed ? 0.18 : 0))
                .frame(width: 260, height: 260)
                .blur(radius: 40)
            VStack(spacing: Gap.m) {
                Mark(size: 120, color: palette.ready)
                    .scaleEffect(grown ? 1 : 0.85)
                    .opacity(grown ? 1 : 0)
                Text("Tender")
                    .font(Type.headlineFont())
                    .foregroundStyle(palette.textPrimary)
                    .opacity(grown ? 1 : 0)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tender")
        .onAppear {
            if reduceMotion {
                grown = true; bloomed = true
            } else {
                withAnimation(.easeOut(duration: 0.45)) { grown = true }
                withAnimation(.easeOut(duration: 0.8).delay(0.2)) { bloomed = true }
            }
            UIAccessibility.post(notification: .announcement, argument: "Tender")
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(Self.duration))
                onSwept()
            }
        }
    }
}
