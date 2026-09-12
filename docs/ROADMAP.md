# Tender — Roadmap

`PHASE` holds the current number. `make phase` prints it and its gate.

Every phase has an **exit gate**: one sentence, machine-checkable where it can
be, that must be true before the next phase starts. A gate that cannot fail is
not a gate — so each one is broken on purpose, watched to fail, and put back.

Release gates are a different question and live in
[`RELEASE-GATES.md`](RELEASE-GATES.md). A phase gate blocks the next phase; a
release gate blocks v1.0.

**This project is iOS only, in Swift, by decision.** The portfolio's rule is
one codebase for both platforms; Tender is the recorded exception, and
[ADR-0001](adr/0001-tender-is-native-and-ios-only.md) says why. Nothing below
mentions Android because nothing below runs on it.

---

## Phase 0 — Foundation · **current**

The Xcode project, built and tested from the command line. The pure-Swift
domain as a package with no platform imports: the eleven notes, the eight
values, what the app says for each, and the two numbers that decide how sure it
sounds. A stand-in classifier that recognises nothing and says so. The
VoiceOver-first shell with the four-sentence framing vocabulary and the haptic
vocabulary. The gates — documentation, domain purity, design, counts — and CI
that runs them on push.

**Exit gate**. *The app builds and tests from the command line on a simulator,
VoiceOver reads every control, and the stand-in classifier produces "I don't
recognise this" rather than a guess.*

The last clause is the one that matters. A stand-in that returned a plausible
denomination would be indistinguishable from the product to anybody not reading
its source — and would put a wrong number in front of a blind person holding
cash. The placeholder announces itself, as it does in every project in this
portfolio.

## Phase 1 — The dataset

Photographs of every note in circulation: eleven designs, both faces, new and
worn, flat and creased, under daylight, tungsten and the light of a market at
dusk, on every background a note is likely to be held against. Labelled by
design rather than by value, so the 2022 ₦500 and the old ₦500 are separate
classes the model has to tell apart. Counted by `make dataset-check`, which
reads the class list from the domain enum, not from a list beside it.

**Exit gate**. *At least 300 labelled photographs per design, both faces, at
least a third of them worn, counted by the gate — and a held-out set of 50 per
design that the training never sees.*

This is the phase the whole project is chosen for. Every other project in this
portfolio has a hardest gate that waits on somebody else — native speakers, a
disease dataset, a handset. This one waits on a person with a phone and a
handful of naira, which is a week's work that one person can do.

## Phase 2 — The classifier

Create ML, image classification, eleven classes. INT8 if the size needs it.
Per-class precision and recall on the held-out set, published in
`RELEASE-GATES.md` and checked by `make model-check` against the numbers the
evaluation actually produced. Inference timed on the oldest device the app
supports.

**Exit gate**. *Per-class precision and recall are published from a held-out
set the model never saw; the worst class is above 95%; and the two ₦500s and
the two ₦1000s are never confused with each other in either direction.*

The last clause is specific because it is the failure that costs money. The
model confusing a ₦100 for a ₦200 is bad. The model saying *"five hundred
naira"* for a note that *is* five hundred naira but reporting the wrong design
is fine. The model confusing a ₦500 for a ₦1000 because the new ₦500 and the
old ₦1000 share a colour is the case the dataset was built to defeat.

## Phase 3 — The camera

The live pipeline. Every frame is judged before it is classified — too dark,
too bright, too blurry, no note in frame, ready — by pure arithmetic in the
domain, and only a frame worth classifying reaches the model. The verdict is
one of four sentences and one of four haptic patterns, because this is said to
somebody who is not looking at the screen. Inference on a background queue
behind a budget that abandons rather than blocks. The confidence gate: two
numbers decide whether the app says *"five hundred naira"*, *"I think five
hundred naira — check"*, or *"I don't recognise this"*.

**Exit gate**. *From the live camera, a note is named within two seconds of
being framed, and an uncertain frame is said to be uncertain rather than
guessed at.*

A simulator has no camera, so this gate needs a handset and stays open until
one has been watched — which is R2 in the release ledger.

## Phase 4 — No sight required, and v1.0

The accessibility pass, which is the product. A full VoiceOver audit: every
element labelled, every announcement interrupting correctly, the rotor useful.
Dynamic Type to the largest accessibility size without a truncated word. Voice
Control. Reduce Motion honoured, including on the splash. The haptic vocabulary
tested by people who will use it, not by the people who designed it. The app
operable with the screen face down.

**Exit gate**. *A blind user identifies five notes in under a minute without
sighted help, on their own phone, and says the haptic pattern told them the
value before the voice did.*

**v1.0 ships to the App Store.** Every gate in
[`RELEASE-GATES.md`](RELEASE-GATES.md) is true, and somebody has watched each
one be true.

## Phase 5 — Depth · *v1.1*

A stack: several notes held together, each named in turn and the total spoken
at the end — arithmetic on cash, still not the movement of it. The denomination
spoken in the user's own language from a bundled recording, with VoiceOver
carrying everything else; the recording kit from Harvest does the rest. The
Action button on phones that have one. A Shortcut.

**Exit gate**. *A stack of five mixed notes is counted correctly, and the total
is spoken in the language the user chose, from a recording, not a synthesiser.*
