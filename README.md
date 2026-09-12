<p align="center">
  <img src="docs/mark.png" width="80" alt="The Tender mark: a banknote, its portrait window, and three pulses — short, short, long" />
</p>

# Tender

**A naira note identifier for blind and low-vision Nigerians. Point the camera, hear the
denomination, feel it in your hand.**

Naira notes have no tactile marking. None of the eight denominations can be told apart by
touch, and since the 2022 redesign there are eleven visually distinct notes carrying those
eight values. A blind Nigerian handling cash is trusting the other party, every time. Every
established currency reader — Seeing AI, Lookout, the rest — covers the dollar, euro, pound,
rupee and yen. None covers the currency of Africa's largest economy.

Tender does one thing. The camera opens on launch; the app says whether it can see a note;
then it says which one — *"five hundred naira"* — through VoiceOver, and pulses it through
the haptic engine in a pattern that is different for every value, so the answer arrives in a
market too loud to hear it. A tap says it again. Fully on-device, no network, no account,
nothing stored.

See [`docs/00-PRODUCT-STATEMENT.md`](docs/00-PRODUCT-STATEMENT.md) for the full analysis.

<p align="center">
  <img src="docs/screenshots/01-splash.png" width="240" alt="The splash: the mark, a warm bloom, the wordmark, over the near-black the launch screen paints" />
  <img src="docs/screenshots/04-too-dark.png" width="240" alt="The camera screen saying Too dark — spoken, felt as one soft pulse, and shown" />
  <img src="docs/screenshots/03-not-sure.png" width="240" alt="The placeholder classifier's only answer: I don't recognise this" />
</p>

> **Every screen above is the simulator, which has no camera.** The frames come from
> fixture photographs pushed through the same pipeline the camera feeds, and the
> answer is the placeholder's, which recognises nothing on purpose.

> **This is the one native, iOS-only project in a portfolio of cross-platform ones**, and
> the reason is written down before any code:
> [ADR-0001](docs/adr/0001-tender-is-native-and-ios-only.md). Tender's user does not look at
> the screen, so the accessibility layer is not a feature of the interface — it *is* the
> interface — and that layer is the platform's own.

> **It names the denomination, never the authenticity.** An image classifier learns
> colour, layout and the portrait, which are what a counterfeit copies first. No sentence
> in the app says or implies a note is genuine, and `make copy-check` fails the build on
> the words that would. [ADR-0003](docs/adr/0003-the-app-names-the-denomination-not-the-authenticity.md).

---

## Status

**Phase 1 of 5 — the dataset.** Phase 0 is cleared: the app builds and tests from the
command line, VoiceOver reads every control, CI runs on push, and the placeholder
classifier recognises nothing and says so — because a stand-in that returned a plausible
denomination would be indistinguishable from the product to anybody not reading its
source. What is missing is photographs of eleven banknotes, which is a week's work for one
person, and [`docs/DATASET-GUIDE.md`](docs/DATASET-GUIDE.md) is what that person is handed.

The pure-Swift domain — the eleven notes, the eight values, the three sentences and the
two numbers that choose between them — lives in a package that imports nothing, not even
Foundation, and tests in seconds with no simulator. `make coverage-gate` holds it above
95%.

<p align="center">
  <img src="docs/screenshots/05-largest-text.png" width="230" alt="The answer at the largest accessibility text size: the sentence wraps to three lines and fills the width, nothing clipped" />
  <img src="docs/screenshots/06-camera-refused.png" width="230" alt="The camera refused: one sentence, one 64-point button that opens Settings, spoken the moment it appears" />
  <img src="docs/screenshots/07-learn.png" width="230" alt="Learn the patterns: eight values, each with its haptic pattern in words and as a glyph; tapping one says it and pulses it" />
</p>

<p align="center">
  <img src="docs/screenshots/09-settings.png" width="230" alt="Settings: seven rows in three groups — Learn, Quiz; Speech, Haptics and sounds, Screen; What Tender knows about you, Done" />
  <img src="docs/screenshots/08-change.png" width="230" alt="Check change: Paid and Cost, then the camera reads each note and says what is still to come" />
</p>

**Nothing requires sight, and the simulator can prove part of that.** Every screen passes
Xcode's accessibility audit — every check but contrast, which the audit cannot read over a
gradient and `ContrastTests` measures at 7:1 instead — at the default text size and at the
largest. The splash sweeps with Reduce Motion on because a timer ends it, not an animation.
A refused camera is one sentence and one button, never dressed as *"I can't see a note"*.
And the haptic vocabulary has a place to be learned — Settings → *Learn the patterns* —
which says each value and pulses it through the same channels a real answer uses.

**Twenty more things, each checked against the product's rules before it was built** —
[ADR-0004](docs/adr/0004-twenty-things-and-the-rule-they-passed.md). A sure answer needs
two frames that agree. The torch comes on in the dark. *"Closer."* A tally, and a change
checker for the conductor problem. *How sure?* A quiz. Hide the number; dim the screen.
Siri and the Action button. And the denomination in Naijá, Hausa, Yorùbá, Igbo or
Fulfulde from a bundled recording — **sixty clips, all placeholders today**, each saying
in English that it is a placeholder, and the app refuses to offer a language with a
placeholder in it. [`docs/RECORDING-KIT.md`](docs/RECORDING-KIT.md) is what a speaker is
handed: twelve lines.

## The eleven notes

Eight values. Three of them — ₦200, ₦500 and ₦1000 — were redesigned in 2022 and both
designs circulate, so the classifier has eleven classes and the app names the design only
when a sighted person might argue about it: *"five hundred naira, new design."*

| Value | Designs | Felt as |
|---|---|---|
| ₦5 | 1 | short |
| ₦10 | 1 | short short |
| ₦20 | 1 | short short short |
| ₦50 | 1 | long |
| ₦100 | 1 | long short |
| ₦200 | 2 | long short short |
| ₦500 | 2 | long long |
| ₦1000 | 2 | long long long |

The haptic vocabulary is provisional until the people who will feel it have — R4 in
[`docs/RELEASE-GATES.md`](docs/RELEASE-GATES.md).

## What blocks v1.0

Four gates, in [`docs/RELEASE-GATES.md`](docs/RELEASE-GATES.md). One waits on a week of
photographing banknotes, one on a physical iPhone, and two on blind users in Nigeria
holding naira. That first one is why this project exists: every other project in this
portfolio has a hardest gate waiting on somebody else, and this one waits on nobody.

## Working on it

```
make setup      # nothing to install: Xcode 26 and the simulator runtime
make test       # swift test on the domain package, then xcodebuild test on the simulator
make ci         # everything CI runs: the gates, analyze, test, coverage
make phase      # the current phase and its exit gate
```

Every phase has a one-sentence exit gate in [`docs/ROADMAP.md`](docs/ROADMAP.md). Every
non-obvious decision has an ADR in [`docs/adr/`](docs/adr/). Every session has a journal
entry in [`docs/JOURNAL.md`](docs/JOURNAL.md), and `make doc-check` warns when code has
changed since the last one.

**Requirements.** Xcode 26.6, iOS 17 or later. Every iPhone since 2018. No Android — see
above.
