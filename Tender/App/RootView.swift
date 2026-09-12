// Splash, then the camera. The camera session is built while the splash is
// up, so the first frame is being judged by the time it clears.
import SwiftUI

struct RootView: View {
    @State private var swept = false
    @State private var access: CameraAccess?
    @State private var reader: Reader?

    var body: some View {
        ZStack {
            if swept, access == .denied {
                CameraDeniedView()
                    .transition(.opacity)
            } else if let reader, swept, access != nil {
                CameraScreen(reader: reader)
                    .transition(.opacity)
            } else {
                SplashView { swept = true }
            }
        }
        .animation(.easeOut(duration: 0.25), value: swept)
        .task {
            // The permission prompt, if any, comes up over the splash; the
            // session is built once the answer is known.
            let a = await CameraAccess.current()
            access = a
            if reader == nil { reader = Wiring.reader(access: a) }
        }
    }
}

/// Where the placeholder is wired in, in one place, so nobody has to read
/// the whole app to find out which classifier is running.
@MainActor
enum Wiring {
    static func reader(access: CameraAccess) -> Reader {
        // `-fixture <name>` feeds a photograph instead of the camera: the UI
        // tests and the simulator use it. A launch argument cannot be set on
        // an installed app by its user, so this is not a path a farmer's
        // phone can take.
        let source: FrameSource
        if let name = fixtureArgument(), let fixture = FixtureSource(named: name) {
            source = fixture
        } else if access == .allowed {
            source = CameraSession()
        } else {
            source = NoCameraSource()
        }
        return Reader(
            source: source,
            classifier: UntrainedClassifier(),   // R3 replaces this. It recognises nothing, on purpose.
            announcer: Announcer(),
            haptics: Haptics()
        )
    }

    private static func fixtureArgument() -> String? {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "-fixture"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }
}
