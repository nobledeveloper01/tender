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

### Fixed

- `splash-check` compared the icon byte for byte and failed on CI, whose Pillow
  encodes the same picture differently. It compares pixels now, with a
  tolerance proved in both directions.
- The documents: product statement, roadmap with an exit gate per phase, the
  release ledger, the design system, and three ADRs — why this project is
  native and iOS-only, why the domain imports nothing, and why the app names
  a denomination and never its authenticity.
