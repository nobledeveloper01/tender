# Release gates

Everything here must be true before v1.0 ships. None of it blocks the next
phase — a phase gate and a release gate are different questions.

**This list is the commitment.** "We will do it before launch" is a sentiment;
this is a ledger. If it grows past what one screen holds, the product is being
built past the point anybody can honestly ship it. Tender was chosen for this
portfolio partly because its ledger is short and most of it waits on the person
building it.

## Blocks v1.0

| # | Gate | Waiting on | Expected to clear in |
|---|---|---|---|
| R1 | **A blind user has used it**, on their own phone, and identified five notes in under a minute without sighted help. Every accessibility decision in this app was made by a sighted person reading Apple's guidelines; that is a starting point and not a result | Blind and low-vision users, in Nigeria, with naira | Phase 4 |
| R2 | The camera path **on a physical iPhone** — a simulator has no camera, so the live pipeline, the framing verdicts and the two-second budget have never run against a real note held in a real hand under real light. Timed on the oldest device the app supports. **The four framing thresholds are provisional**, and so is the coverage heuristic: a test proved that warm skin sits in the same colour band as the ₦5, ₦10 and ₦1000, so a hand is not excluded before the classifier — the classifier and the confidence gate exclude it, with *"I don't recognise this"*. Whether that holds for a hand in a market is a question for the handset | A handset. Two, ideally: the newest and the oldest supported | Phase 3 |
| R3 | A **trained classifier**, with per-class precision and recall published from a held-out set the training never saw. `UntrainedClassifier` recognises nothing, always — deliberately, because a stand-in that returned a plausible denomination would be indistinguishable from the product to everybody not reading its source, and would put a wrong number in front of a blind person holding cash. The eleven-class dataset is a week of photographing notes, which is the reason this project exists: it is the one gate in the portfolio that waits on nobody | A week with a phone and one of every note in circulation, both designs of the three that were redesigned | Phase 2 |
| R4 | The **haptic vocabulary is confirmed by the people who will feel it**. Eight patterns for eight values, designed to be learnable in a minute — one short tap for ₦5 up to three long for ₦1000. Designed is the operative word: whether the difference between one long and one long plus one short is felt through a phone in a pocket in a moving bus is a question for a hand, not a spec | The same users as R1 | Phase 4 |

## Cleared

| # | Gate | How |
|---|---|---|

## How a gate leaves this list

By being true, and by somebody having watched it be true. Not by being
reworded, and not by being moved to a later phase.
