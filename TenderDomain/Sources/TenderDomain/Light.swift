// What to do about the dark, decided in the domain and acted on by the app.
//
// A blind user does not know it is dark. So after the frame has been too
// dark for a moment, the app turns the torch on for them; if it is still
// too dark with the torch on, it says the one thing that might help. The
// counts are frames, not seconds, so the rule has no clock.
public enum LightAdvice: Sendable, Equatable {
    case nothing
    case torchOn
    case tryAWindow
}

public struct LightPolicy: Sendable, Equatable {
    /// Frames of darkness before the torch. About half a second at 30 fps.
    public static let framesBeforeTorch = 15
    /// Frames of darkness with the torch on before the advice. About three seconds.
    public static let framesBeforeAdvice = 90

    private var darkFrames = 0
    private var torchIsOn = false
    private var advised = false
    public init() {}

    public var torch: Bool { torchIsOn }

    /// Feed each frame's judgement. Returns what, if anything, to do now.
    public mutating func consider(_ framing: Framing) -> LightAdvice {
        guard framing == .tooDark else {
            darkFrames = 0
            advised = false
            return .nothing
        }
        darkFrames += 1
        if !torchIsOn, darkFrames >= Self.framesBeforeTorch {
            torchIsOn = true
            darkFrames = 0
            return .torchOn
        }
        if torchIsOn, !advised, darkFrames >= Self.framesBeforeAdvice {
            advised = true
            return .tryAWindow
        }
        return .nothing
    }

    /// The torch goes off when the app leaves the camera, and starts over.
    public mutating func reset() { self = LightPolicy() }
}
