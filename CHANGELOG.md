# Changelog

All notable changes to Tender, in the style of
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioned by
[semver](https://semver.org/spec/v2.0.0.html).

Entries say *why*, not just what.

## [Unreleased]

### Added

- **The app builds and tests from the command line on a simulator**, which is
  Phase 0's exit gate. A hand-written Xcode project with synchronized folders,
  because no project generator is installed and nothing gets installed without
  asking; a pure-Swift domain package that imports nothing; the placeholder
  classifier that recognises nothing, on purpose; VoiceOver announcements and
  the haptic vocabulary; the splash.
- **The gates, ported to Swift**, every one proved to fire: `doc-check`,
  `design-check`, `counts-check`, `splash-check`, `domain-purity`, and two the
  ADRs promise — `copy-check` (ADR-0003's word list over every string the app
  can say) and `network-check` (nothing leaves the device, made checkable).
  `coverage-gate` holds the domain at 95%; it is at 98.2%.
- **An accessibility audit in the UI tests**, which found two defects on its
  first run: fixed-size fonts that ignored Dynamic Type, and a contrast
  failure that turned out to be the audit's inability to read a gradient.
- CI on push, on a macOS runner with a pinned Xcode, running the same `make ci`.
- **Phase 1's tooling, ahead of the photographs.** `make dataset-check` counts
  the dataset against the gate and reads the classes from the `Note` enum;
  `make dataset-import` files a batch by the naming convention and holds every
  seventh out, by position rather than choice; `make dataset-manifest` writes
  the counts. [`docs/DATASET-GUIDE.md`](docs/DATASET-GUIDE.md) is what the
  photographer is handed. Proved on 3,960 synthetic images, which found a
  cross-class duplicate bug in the import tool before any real photograph did.

- **Phase 2's tooling, ahead of the model.** `make model` trains with Create ML
  and writes `docs/MODEL-REPORT.md` from the held-out set — per-class recall
  and precision, what each was confused with, and the ₦500 ↔ ₦1000 count;
  `make model-check` refuses to wire it below 95% on any class or on a single
  cross-value confusion. `CoreMLClassifier` is written and not wired.
- **A fixture source**, so the simulator can push a photograph through the
  whole pipeline, and three UI tests that walk it end to end.

- **Phase 4 groundwork a simulator can prove**: the largest accessibility
  text size without a clipped word on either screen, the splash sweeping with
  Reduce Motion on, a tap that repeats and changes nothing.
- The App Store text, in `docs/APPSTORE.md`, read by `copy-check`.
- The reader's rules tested directly — speak once, classify once, throttle
  the same framing to once a second, abandon a slow classifier and never speak
  its late answer — through injectable output channels and spies, with two
  mutations proving the tests can fail.
- Screenshots in the README, taken on the simulator from fixture photographs
  and captioned as such; `make screenshot` to retake, and `doc-check` warns
  when they fall behind the app.
- **The camera preview**, dimmed behind the numeral; **the permission-denied
  state** — one sentence, one 64 pt button to Settings, spoken on appearance,
  and never dressed as *"I can't see a note"*; and **shake to start over**.
  Three things the FRD required and the app did not do.
- `docs/SPEECH.md` — everything the app says, derived from the source, gated by
  `make speech-check`. What a native speaker is handed in v1.1.

### Changed

- **Phase 0 cleared; `PHASE` is 1.**
- Settings' *Done* is a 64 pt row, not a toolbar item — toolbar items are sized
  by the bar and stopped scaling at the largest text size.
- The judge decides *too dark* before *nothing*: in the dark, coverage means
  nothing, and *"I can't see a note"* sent a blind user checking their grip
  when the problem was the light. Found by the dark fixture.

### Fixed

- `splash-check` compared the icon byte for byte and failed on CI, whose Pillow
  encodes the same picture differently. It compares pixels now, with a
  tolerance proved in both directions.
- The documents: product statement, roadmap with an exit gate per phase, the
  release ledger, the design system, and three ADRs — why this project is
  native and iOS-only, why the domain imports nothing, and why the app names
  a denomination and never its authenticity.
