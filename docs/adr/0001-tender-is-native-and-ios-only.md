# ADR-0001 — Tender is native Swift, and iOS only

**Status:** accepted
**Date:** 2026-09-12

## Context

Every other project in this portfolio ships iOS and Android from one codebase,
and the portfolio README states that as a rule. The obvious way to add a
currency reader is to follow it: a Flutter app with a camera plugin and a
TensorFlow Lite model, for both platforms, like Harvest's diagnosis feature.

That works for the classifier and fails for the user.

Tender's user does not look at the screen. Everything the app does reaches
them through VoiceOver announcements and the haptic engine, and everything
they do reaches the app through VoiceOver's own gestures. Those are not
features a cross-platform framework exposes at full depth; they are the
platform. Flutter's accessibility bridge exposes labels and hints and a
generic `announce`; it does not expose `UIAccessibility.Notification` with
its interruption semantics, custom rotor actions, `accessibilityActivate`,
or Core Haptics patterns with transient and continuous events. A framework
that reaches the accessibility layer through a seam puts the seam exactly
where this product's user lives.

There is a second, quieter reason. The portfolio is meant to prove range, and
the CV it supports claims Swift *"where the platform requires it."* Six
cross-platform apps prove one thing six times. One native app, chosen because
the platform was required, proves the claim.

## Decision

**Tender is written in Swift, with SwiftUI, and ships on iOS only.** No Android
version is planned, and the product statement says so in its last section
rather than leaving it to be inferred.

The exception is bounded. It applies to this project because its interface
*is* the accessibility layer; it does not apply to a project that would
merely be easier in Swift. The next native project in the portfolio needs its
own ADR-0001 making its own case, and if the case is "it would be nicer" the
answer is Flutter.

What stays the same as everywhere else: the pure domain in its own package
with no platform imports ([ADR-0002](0002-the-domain-imports-nothing-from-the-platform.md)),
the documentation gate, the roadmap with one-sentence exit gates, the release
ledger, the journal, the animated splash, and `make ci` as the only definition
of green.

## Consequences

**Android users are not served.** A blind Nigerian on an Android phone gets
nothing from this repository. That is a real cost, and it is accepted because
the alternative was serving nobody well.

**iPhone share in Nigeria is small**, and the product statement says so. The
audience is a minority of a minority. The thing being built for them is built
completely.

**The tooling is Apple's.** `xcodebuild` for the app, `swift test` for the
domain package, `xccov` for coverage, Create ML for the model. No Docker
target — Xcode does not run in a container — so the reproducible-build story
every other project has is replaced by a pinned Xcode version in the README
and CI running on macOS.

**VoiceOver's languages are the app's languages.** VoiceOver has no voice for
Hausa, Yoruba, Igbo or Nigerian Pidgin, and a blind Nigerian iPhone user
already operates it in English. v1.0 speaks through VoiceOver and speaks
English. The denomination in the user's own language, from a bundled
recording, is v1.1 — the recording kit exists in Harvest and the list is
eleven words — and the phase is written down so it is a step and not an
omission.
