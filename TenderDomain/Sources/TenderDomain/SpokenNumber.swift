// Whole naira amounts as words, for the tally and the change checker. The
// synthesiser reads "1,250" as "one thousand two hundred fifty" on some
// voices and "one two five zero" on others; words are the same everywhere.
public enum SpokenNumber {
    private static let ones = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
                               "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
                               "seventeen", "eighteen", "nineteen"]
    private static let tens = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]

    public static func words(_ n: Int) -> String {
        if n < 0 { return "minus " + words(-n) }
        if n < 20 { return ones[n] }
        if n < 100 { return tens[n / 10] + (n % 10 == 0 ? "" : " " + ones[n % 10]) }
        if n < 1000 { return ones[n / 100] + " hundred" + (n % 100 == 0 ? "" : " and " + words(n % 100)) }
        if n < 1_000_000 { return words(n / 1000) + " thousand" + (n % 1000 == 0 ? "" : (n % 1000 < 100 ? " and " : " ") + words(n % 1000)) }
        return words(n / 1_000_000) + " million" + (n % 1_000_000 == 0 ? "" : " " + words(n % 1_000_000))
    }
}

extension String {
    var capitalisedFirst: String {
        guard let f = first else { return self }
        return f.uppercased() + dropFirst()
    }
}
