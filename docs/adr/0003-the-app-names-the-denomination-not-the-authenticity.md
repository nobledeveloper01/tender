# ADR-0003 — The app names the denomination, never the authenticity

**Status:** accepted
**Date:** 2026-09-12

## Context

The first question anybody asks about a currency reader is whether it spots
fakes. Counterfeit naira are real, the person most exposed to them is the
person who cannot see the note, and a classifier that has learned what a ₦1000
looks like will, in some sense, respond differently to a bad copy.

The obvious product move is to say something about it — a confidence figure,
a "looks unusual", a hedge. It would be the most-wanted feature in the app.

It would also be a lie. An image classifier trained to tell eleven designs
apart has learned the features that separate them, which are colour, layout
and the portrait — exactly the features a passable counterfeit reproduces
first. Security features are microprint, watermark, security thread, and
raised ink, none of which a phone camera at arm's length in a market
resolves. A model that says "genuine" is guessing with a confident voice, and
the person it is guessing to cannot check.

## Decision

**Tender says which denomination a note is designed as. It says nothing about
whether the note is genuine, and no sentence in the app may imply that it
could.**

- The announcement is *"five hundred naira"*, not *"a genuine five hundred
  naira note"* and not *"five hundred naira, looks real"*.
- The words *genuine*, *real*, *fake*, *counterfeit*, *authentic* and
  *verified* do not appear in any user-facing string. `make copy-check` reads
  every string the app can say and fails on any of them. This is a phase-0
  gate, not a release gate, because the copy exists from the first commit.
- The App Store description and the README say the same thing in the first
  paragraph that mentions the classifier.
- A future feature that *does* look at security features is a different
  product with a different name and its own evidence, not a v1.x of this one.

## Consequences

**The most-requested feature is refused, permanently**, and the reason is
written where the request will be made.

**The uncertainty vocabulary carries the weight.** The app has three things it
can say — the denomination, the denomination with *check*, and *I don't
recognise this* — and the middle one exists so that a worn, folded or oddly
lit note gets a hedged answer rather than a confident wrong one. That is as
close as this app comes to "something is off about this note", and it is
about the photograph, not the note.

**Not fintech, stated.** The product touches no money. Naming a piece of paper
is not a financial service, and this ADR is where that line is drawn so the
question does not have to be re-argued.
