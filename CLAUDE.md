# Tender

A naira note identifier for blind and low-vision Nigerians. **iOS only, in Swift,
by decision** — read `docs/adr/0001-tender-is-native-and-ios-only.md` before
asking why there is no Android build. Read `docs/00-PRODUCT-STATEMENT.md` for
why this exists, `docs/ROADMAP.md` for what phase the project is in and what its
exit gate is, and `docs/adr/` for the decisions that are already settled.
`PHASE` holds the current phase number.

The one sentence that decides most arguments:

> **The accessibility layer is the product, not a feature of it.**

The classifier is a few days' work. What nothing on the market has done for the
naira is the interface around it: an app a blind person operates one-handed
while holding a note in the other, that speaks before it is asked, is honest
when unsure, and works with VoiceOver's own gestures rather than against them.
Every decision favours that user, and a feature that is only reachable by
looking at the screen is not finished.

## Design system

Read `DESIGN.md` before making any visual, spoken or haptic decision. Colour,
type, targets, the announcement vocabulary and the haptic vocabulary are defined
there. Do not deviate without explicit approval.

**The design floor is a user who cannot see the screen, one hand holding a
note, a market too loud to hear a phone, and no earphones.** Everything follows
from it: the whole screen is a target, every state is spoken *and* felt, and
nothing waits for a tap that a sighted person would find obvious.

## The things that are never traded

1. **Nothing requires sight.** Every flow completes with VoiceOver and haptics
   alone. Visuals accompany; they never carry. A state that is only shown is a
   state that does not exist.
2. **The denomination, never the authenticity.** The app says which note this
   is designed as. It never says, implies or hints whether the note is genuine.
   `make copy-check` fails the build on the words that would. ADR-0003.
3. **The domain imports nothing.** Not Foundation. The Swift standard library
   only. Enforced by `make domain-purity`, which is proved to fire. ADR-0002.
4. **Honest about uncertainty.** Three things the app can say — the note, the
   note with *check*, and *I don't recognise this* — and two numbers decide
   which. *"I don't recognise this"* is a valid and frequently correct output,
   and a confident wrong number in front of a blind person holding cash is the
   worst thing this app can do.
5. **The placeholder announces itself.** `UntrainedClassifier` recognises
   nothing, always. A stand-in that returned a plausible denomination would be
   indistinguishable from the product to anybody not reading its source.
6. **Nothing is stored and nothing is sent.** No account, no server, no
   analytics, no photograph kept. The app identifies a piece of paper and
   forgets it.
7. **iOS only.** No Android. A request for one is answered by ADR-0001, not by
   a port.

## Working on this repo

- `make ci` is the gate. `make gates` runs the blocking ones alone.
- **Prove a guard fires before trusting it.** Break it on purpose, watch it
  fail, put it back. This has found real defects in every project in this
  portfolio, including gates written the same hour.
- **A gate that passes for a reason unrelated to what it checks is worse than
  one that cannot fail.** Delete the cache and re-run before believing a green
  result. Check the exit status of `make`, not of the pipeline it is in.
- ADRs live in `docs/adr/`. **Write one for any non-obvious decision, before
  the code that depends on it.**
- **`docs/JOURNAL.md` every working session.** What we did, and what surprised
  us.
- The domain package tests with `swift test` in seconds and needs no
  simulator. Run it first.
- **Run the app with VoiceOver on.** If you have not heard a screen, you have
  not seen it.

## Definition of done

- [ ] Acceptance criteria met and demonstrated on a device, with VoiceOver on
- [ ] Every flow completable without looking at the screen
- [ ] Every state spoken and felt, not only shown
- [ ] Confidence gate property-tested if the domain was touched
- [ ] Verified on a physical iPhone, including the oldest supported
- [ ] Light and dark authored; every pair contrast-asserted at 7:1 in CI
- [ ] Dynamic Type at the largest accessibility size without truncation
- [ ] Reduce Motion honoured, including the splash
- [ ] Every error path has a forward path — no dead ends, and no silent ones
- [ ] **Copy reviewed for authenticity claims** — `make copy-check` green and a
      person has read the new strings
- [ ] ADR written for any non-obvious decision
- [ ] `CHANGELOG.md` updated under `[Unreleased]`
- [ ] `make ci` green
