# Journal

What we built, what we decided, and what surprised us. The surprises are the
point — everything else is in the commit log.

---

## 2026-09-12 — Why this one is native

The portfolio has a rule: one codebase, both platforms. Six projects follow it.
This one does not, and the first thing written was the ADR saying why, before
any code, because an exception with no reason written down is a rule that has
quietly stopped existing.

The reason is not that Swift is nicer. It is that Tender's user does not look
at the screen, so the accessibility layer is not a feature of the interface —
it *is* the interface — and that layer is the platform's own. A framework
reaches it through a seam. Here the seam would be where the user lives.

### What surprised us

**The dataset is the easy part, and that is the whole reason to build it.**
Every other project in this portfolio has a hardest gate waiting on a person
who is not on the team: native speakers, a labelled disease dataset, a
handset in a market. Tender's hardest gate is photographing eleven banknotes
under a few kinds of light. Harvest's R10 — *a trained classifier with
published precision and recall* — has sat on its ledger since Phase 4 with no
path to clearing. The same sentence on Tender's ledger clears in a week.

**No currency reader covers the naira.** Seeing AI, Lookout and the rest
recognise the dollar, euro, pound, rupee and yen. Nigeria is the largest
economy in Africa. That gap is the product.

**Counterfeits came up before the first line of code**, from the first person
the idea was described to. The answer is ADR-0003, and the gate that enforces
it — a word-list over every string the app can say — is a phase-0 gate, not a
release gate, because the copy exists from the first commit and the tempting
sentence is one word long.

**The domain package imports nothing, not even Foundation.** Stricter than
Harvest, which allows a short list of `dart:` libraries. It is affordable
because the domain is small and numeric, and it is worth having because the
temptation in Swift is Foundation by name — `Date`, `String(format:)` — and
"no imports" is a rule a gate can read without a parser.

## 2026-09-12 — Built, and the audit found two defects before anyone looked

The scaffold: the domain package, the app, a hand-written Xcode project, the
gates ported to Swift, and CI. The domain tested in two milliseconds before
the app existed. The app built on the second attempt — four Swift 6 strict-
concurrency errors in one file, all real, none downgraded to warnings.

### What surprised us

**The accessibility audit failed on the first run, on real defects.** Two.
`Font.system(size:)` does not scale with Dynamic Type — the sizes were fixed,
so a low-vision user who set the largest text would have got 17 pt, on the one
product whose design floor is that user. And the audit said the framing text
failed contrast. Both were the gate working on the first screen it ever saw.

**The second one was the audit's defect, not ours.** Text at 15:1 against
every stop of the page gradient, reported as a contrast failure. Found by
experiment, not theory: the same text over a flat colour passed; over the
gradient, failed. The audit reads a view's *declared* background colour, not
its pixels, and a gradient has no single colour to read. So the audit runs
every check but contrast, and contrast is gated by `ContrastTests`, which
measures every stop at 7:1 — more than the audit asks for. The one check
handed to a stronger test rather than dropped, and DESIGN.md says so.

**`xcodebuild test -quiet` says nothing on success.** A green `make ci` with
no evidence in the log that the app suite ran is exactly the green this
portfolio distrusts. `test-app` now reads the result bundle, prints the count,
and refuses a run that executed zero tests.

**A hand-written `project.pbxproj` is about 400 lines with Xcode 26's
synchronized folders**, and it worked. No xcodegen on the machine, nothing
installed without asking. The file is small enough to own.

**Every gate was broken on purpose and every one fired** — nine, including
coverage, which went to 39% with the verdict tests removed. The break-test
found one cosmetic defect: `domain-purity` printed the raw regex instead of
the name. Fixed. A gate nobody has watched fail is a gate nobody knows the
configuration of.
