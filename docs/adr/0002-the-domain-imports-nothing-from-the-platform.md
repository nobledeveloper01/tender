# ADR-0002 — The domain imports nothing from the platform

**Status:** accepted
**Date:** 2026-09-12

## Context

Tender's centre of gravity is a handful of decisions that a blind person acts
on with money in their hand. Which of eleven designs this is. Whether the
model is sure enough to say so plainly, sure enough to say so with a caveat,
or not sure enough to say anything. Whether this frame is worth classifying
at all. What sentence to say and what pattern to pulse.

None of that is a screen and none of it needs a camera. All of it is what the
product *is*.

The obvious way to build a SwiftUI app is to let those rules live beside the
views that use them, reaching for `Date()`, a `UIImage`, a `CMSampleBuffer`
or `AVSpeechSynthesizer` when convenient. Each is one line and each is
invisible in review, and together they make the arithmetic testable only on a
simulator, and reproducible only with a camera attached.

The specific failure this guards against: a confidence gate that reads the
model's output type directly cannot be tested against a hand-written
probability vector, so it does not get tested against one — and the bug that
ships is a note called *"five hundred naira"* at 0.51 confidence because
nobody ever asked the gate what it does at 0.51.

## Decision

**`TenderDomain/` is a Swift package that imports nothing.** Not Foundation,
not UIKit, not Vision, not CoreML, not CoreHaptics. The Swift standard library
only.

- The model's output arrives as `[Note: Double]`. The frame arrives as its
  measured brightness, clipped fraction and detail. The clock, when a rule
  needs one, arrives as an argument.
- The domain owns the vocabulary — `Note`, `Naira`, `Verdict`, `Framing`,
  `Announcement`, `HapticPattern` — and knows nothing about how any of it is
  captured, spoken or felt.
- `make domain-purity` reads every file under `TenderDomain/Sources/` and
  fails the build on any `import` at all, or on a call to `Date(`,
  `DispatchTime`, `ProcessInfo`, `random` or `arc4random`. It runs inside
  `make analyze`, so it cannot be skipped by running the analyzer alone.
- The package tests with `swift test` on macOS, with no simulator, in seconds.

**The gate is proved by breaking it.** Each banned thing must turn it red, and
that is checked rather than assumed.

## Consequences

**No Foundation is stricter than Harvest's rule**, which allows a short list
of `dart:` libraries. It is affordable here because the domain is small and
numeric, and it is worth having because the temptation in Swift is Foundation
specifically — `Date`, `String(format:)`, `NSNumber` — and each of those is the
platform wearing a familiar name. If a rule genuinely needs Foundation, this
ADR is amended, not bypassed.

**The 95% coverage floor is cheap.** `make coverage-gate` holds the package to
95% because pure functions with no ambient state are cheap to cover.

**It reads imports and call sites, not the dependency graph.** A package with
no imports has no transitive problem, which is the other thing "no imports"
buys.
