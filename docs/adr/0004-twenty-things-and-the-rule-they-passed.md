# ADR-0004 — Twenty things, and the rule each one passed

**Status:** accepted
**Date:** 2026-09-12

## Context

The product statement says Tender does one thing, and the ledger was kept
short on purpose. Then the request came to make it special — twenty more
things — and the obvious response is either to refuse on principle or to
add twenty features and let the gate list grow until nobody can ship.

Neither is right. The product's rules are not "one feature"; they are: nothing
requires sight, nothing is stored or sent, never authenticity, never the
movement of money, native because the platform is required. A feature that
passes all five and serves the person holding the note is not scope creep.
One that fails any of them is, however small.

## Decision

**Twenty features were proposed and each was checked against the five rules
before it was built.** The list, with what each is for, is in
[`FEATURE-BACKLOG.md`](../FEATURE-BACKLOG.md) under *Built, and why*. The
rules they passed:

- **Nothing requires sight.** Every one is spoken and felt; the screen is a
  courtesy. Two of them — *hide the number* and *dim the screen* — exist so
  the screen can be turned off.
- **Nothing stored, nothing sent.** The tally and the change checker hold a
  number until a shake. No history. `network-check` still passes.
- **Never authenticity.** *How sure?* reports the classifier's confidence in
  its reading of the photograph — never anything about the note.
- **Never money movement.** The tally adds; the change checker subtracts.
  Arithmetic on cash in a hand is not a financial service, and this ADR is
  where that line is drawn a second time.
- **Native for a reason.** The torch, Core Haptics intensity, App Intents,
  screen brightness, the proximity of a face-down phone — each is the
  platform's own.

**What was refused**, and why, stays in the backlog: coins, CFA francs, a
watch app, any server, and — permanently — counterfeit detection.

**The gate list did not grow.** None of the twenty adds a release gate. The
own-language clips reuse Harvest's placeholder pattern and join R1's kind of
wait without adding a row: a placeholder that announces itself is not a gate,
it is a count.

## Consequences

**The product statement's "one thing" is still true.** Every feature is in
service of hearing which note this is, or of using that answer. None opens a
second product.

**Tests before screens, as before.** Each feature's rule lives in the domain
where it can, with a property test; the app wires it; a UI test proves it
under the audit at two text sizes. A feature that cannot be proved on the
simulator is proved as far as the simulator reaches and says so.

**Phase 4 is bigger.** The users in R1 and R4 now judge a quiz, a tally and
a change checker as well as the vocabulary. That is the right place for it
to be bigger.
