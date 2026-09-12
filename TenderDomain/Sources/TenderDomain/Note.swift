// The eleven designs.
//
// Eight values, but three of them — ₦200, ₦500 and ₦1000 — were redesigned in
// 2022 and both designs circulate. The classifier tells designs apart, because
// that is what it can see; the app pools by value before it speaks, because
// that is what the user cares about. See `Verdict`.

/// Which printing of a note this is.
public enum Design: Sendable, Equatable {
    case original
    case redesign2022
}

/// One of the eleven visually distinct notes in circulation.
///
/// The raw values are the class labels the model is trained with, so the
/// dataset folders, the model's output and this enum are one list.
/// `make counts-check` reads `allCases.count` from this file.
public enum Note: String, CaseIterable, Sendable {
    case n5, n10, n20, n50, n100
    case n200, n200new
    case n500, n500new
    case n1000, n1000new

    public var value: Naira {
        switch self {
        case .n5: .n5
        case .n10: .n10
        case .n20: .n20
        case .n50: .n50
        case .n100: .n100
        case .n200, .n200new: .n200
        case .n500, .n500new: .n500
        case .n1000, .n1000new: .n1000
        }
    }

    public var design: Design {
        switch self {
        case .n200new, .n500new, .n1000new: .redesign2022
        default: .original
        }
    }
}
