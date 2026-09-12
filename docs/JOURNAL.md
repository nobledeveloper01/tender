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

## 2026-09-12 — The dataset tools, and two gates that were wrong

Phase 1's tooling, before a single photograph exists: `make dataset-check`
counts the dataset against the gate, `make dataset-import` files a batch by
the naming convention with every seventh held out, and
`docs/DATASET-GUIDE.md` is what the photographer is handed. Proved on 3,960
synthetic images: a complete dataset passes; a re-import skips every file; a
planted held-out leak, a short class and a stray folder each go red.

### What surprised us

**The import tool had a real bug, and the proof found it.** Re-importing a
batch under a *different* class filed all sixty again, because the duplicate
check only looked inside the target class — so the same photograph could be
labelled two notes. The gate then caught the consequence as a held-out leak,
which is the gate working, but the tool should never have let it in. Now it
hashes the whole dataset and names the other class.

**The first synthetic dataset leaked, and it was the generator's fault.**
Tiny solid-colour JPEGs quantise to identical bytes, so "different"
photographs had the same content and the leak detector fired on all of them.
Right answer, wrong reason for it to have to. PNGs with unique pixels for the
proof.

**`splash-check` failed on CI for the wrong reason.** It compared the icon
byte for byte with a fresh drawing, and the runner's Pillow encodes PNGs
differently — same picture, different file. A gate that fails on encoder
trivia is the mirror of one that passes on cache trivia. It now compares
pixels with a tolerance, proved both ways: a re-encoded copy passes, a moved
palette colour fails.

**CI needed telling the runner is disposable.** Homebrew's Python refuses
`pip install` under PEP 668; `--break-system-packages` is honest on a VM that
is thrown away after the run and nowhere else.

## 2026-09-12 — Phase 0 cleared, and the tools for the next two phases

CI went green on the third run and Phase 0's last clause with it. `PHASE` is 1.

Built ahead of the photographs: a fixture source so the simulator can push a
picture through the whole pipeline, and three UI tests that do — a note-like
frame reaches the placeholder and gets *"I don't recognise this"* and never a
number; a white wall is *"I can't see a note"*; a dark frame is *"Too dark"*.
Then Phase 2's `make model` (Create ML, held-out evaluation, a per-class
report with the ₦500 ↔ ₦1000 confusion count) and `make model-check`, which
refuses the report on a low class, a thin held-out set, a cross-value
confusion, or a class list that does not match the code. Both proved on
synthetic data in a temporary directory, never near the app's model path.
`CoreMLClassifier` exists and is not wired; the switch is one line in
`Wiring`, made when `model-check` passes on real photographs.

### What surprised us

**The dark fixture found a design defect.** The judge decided *nothing*
before *too dark*, so in the dark — where coverage cannot be measured — a
blind user was told *"I can't see a note"* and sent checking their grip when
the problem was the light. Darkness first now, in the domain, asserted, and
the FRD corrected to match.

**The synthetic model was 75.8% accurate and the gate refused it**, which is
the right outcome twice: the pipeline runs end to end, and the number it
produced on coloured squares means nothing, and `model-check` said so.

## 2026-09-12 — Phase 4 groundwork on the simulator, and the store text

What a simulator can prove of Phase 4, proved: the largest accessibility text
size clips nothing on either screen, with the audit's own clipped-text check
over the longest sentence the app shows; the splash sweeps with Reduce Motion
on, because a timer ends it and not an animation — the thing Grid recorded in
its own ADR about the splash, now asserted here; and a tap repeats without changing anything.

The App Store text, written and gated. And `docs/SPEECH.md` — everything the
app says, derived from the two source files that say it, with a gate that
fails when the tracked copy is stale. It is what a native speaker is handed
in v1.1: eight values, one suffix, three frames, four camera prompts.

### What surprised us

**The toolbar capped Dynamic Type.** The settings sheet's *Done* was a toolbar
item, and the audit reported it "partially unsupported" at the largest size —
toolbar items are sized by the bar. It is a 64 pt list row now, which the
design rule wanted anyway.

**The copy gate caught its own author.** The first draft of the store text
opened with a sentence explaining which word the app never uses, using the
word. The gate does not read intent, which is the point of a gate.

**The gear did not grow.** A symbol with a fixed point size, on a screen where
everything else had scaled to three times its size. The audit did not flag it
— it is an image — but a screenshot did. A text style now.
