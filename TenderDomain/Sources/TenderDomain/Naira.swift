// The eight values. No imports: this file, like every file in this package,
// depends on the Swift standard library and nothing else. ADR-0002.

/// A denomination of the naira, by value.
public enum Naira: Int, CaseIterable, Sendable, Comparable {
    case n5 = 5, n10 = 10, n20 = 20, n50 = 50, n100 = 100, n200 = 200, n500 = 500, n1000 = 1000

    public static func < (lhs: Naira, rhs: Naira) -> Bool { lhs.rawValue < rhs.rawValue }

    /// The words the synthesiser says. Never a numeral: "500" is read as
    /// "five zero zero" by some voices and as "five hundred" by others, and
    /// the app should not depend on which.
    public var spoken: String {
        switch self {
        case .n5: "five"
        case .n10: "ten"
        case .n20: "twenty"
        case .n50: "fifty"
        case .n100: "one hundred"
        case .n200: "two hundred"
        case .n500: "five hundred"
        case .n1000: "one thousand"
        }
    }
}
