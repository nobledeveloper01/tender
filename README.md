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

**Phase 0 of 5 — foundation.** The documents are written and nothing is built. The
placeholder classifier, when it exists, will recognise nothing and say so — because a
stand-in that returned a plausible denomination would be indistinguishable from the
product to anybody not reading its source.

The pure-Swift domain — the eleven notes, the eight values, the three sentences and the
two numbers that choose between them — lives in a package that imports nothing, not even
Foundation, and tests in seconds with no simulator. `make coverage-gate` will hold it above
95%.

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
