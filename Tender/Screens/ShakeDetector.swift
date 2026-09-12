// Shaking the phone starts over, same as the magic tap. SwiftUI has no shake
// event, so a zero-size view controller in the hierarchy listens for the
// motion and calls back.
import SwiftUI
import UIKit

struct ShakeDetector: UIViewControllerRepresentable {
    let onShake: () -> Void

    func makeUIViewController(context: Context) -> Controller {
        let c = Controller()
        c.onShake = onShake
        return c
    }

    func updateUIViewController(_ uiViewController: Controller, context: Context) {
        uiViewController.onShake = onShake
    }

    final class Controller: UIViewController {
        var onShake: (() -> Void)?
        override var canBecomeFirstResponder: Bool { true }
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            becomeFirstResponder()
        }
        override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            if motion == .motionShake { onShake?() }
        }
    }
}
