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

## 2026-09-12 — Three things the FRD required and the app did not do

Read the camera screen against `02-FRD.md` and found three gaps. No preview
— DESIGN.md's dimmed 40% behind the numeral, the low-vision user's way to
aim. No permission-denied state — a refused camera produced no frames, so
the app said *"I can't see a note"* forever, the silent dead end CLAUDE.md
forbids, and dressed as an empty scene. No shake to start over.

All three built. The denied state is one sentence and one 64 pt button that
opens Settings, spoken the moment it appears, with a launch-argument hook so
a UI test can see it — the permission dialog itself cannot be driven from a
test — and the test asserts it never masquerades as *"I can't see a note"*.

### What surprised us

**"Not allowed to look" and "nothing to see" had the same sentence.** A
blind user told *"I can't see a note"* with the camera refused would have
tried better light, a flatter hand, a different note, and never the one thing
that would help. The FRD had the requirement from the start; the code did
not, and nothing on the simulator would ever have shown it, because the
simulator has no camera to refuse.

## 2026-09-12 — The wiring, heard and felt

`Reader` — the thing that turns frames into sentences — had no unit tests.
Its budget, its once-per-second throttle and its speak-once rule were only
exercised through UI tests, which cannot hear what was said. The two output
channels are protocols now, `Speaking` and `Pulsing`, and four tests drive
the reader with scripted frames and a scripted classifier and read back what
the spies heard: ten white frames say *"I can't see a note"* once; twenty
ready frames classify once and speak once and pulse the right pattern; a
classifier that takes five seconds is abandoned and the answer is *not sure*
and the late answer is never spoken; start over forgets and repeat repeats.

All four passed first time, which is when to check they can fail. Two
mutations — the throttle removed, the budget made infinite — each failed
exactly the test that guards it and no other.

## 2026-09-12 — The four numbers, and a comment that overclaimed

`FrameStats` tested on frames built to move each number: sharp beats blurred
by more than four times on detail, a note covering a quarter of a table
scores a quarter, half a frame of white counts as half clipped, and a
640×480 frame measures in well under a tenth of a camera frame on a debug
build on the simulator.

### What surprised us

**The code said the colour gate excluded "a skin tone". It does not.** A
hand filling the frame scored coverage 1.0, because warm skin sits in the
same luminance and saturation band as the ₦5, ₦10 and ₦1000. There is no
threshold that removes the hand and keeps those notes. So the comment now
says what the gate does exclude — walls, tables and the dark — and a test
asserts the limitation, so that a later "improvement" that starts excluding
hands also starts excluding three notes in the test rather than in a
market. R2's row on the ledger says it too. A hand reaches the classifier,
whose answer for a hand is *"I don't recognise this"*; whether that holds in
a market is a question for the handset.

## 2026-09-12 — The vocabulary had nowhere to be learned

Said "nothing left to build from this desk" and then read the ledger again.
R4 asks blind users to judge the haptic vocabulary, and the app gave them no
way to meet a pattern except by holding the note it belongs to. DESIGN.md
said "learnable in a minute" and there was no minute. So: Settings → *Learn
the patterns*, eight rows, each saying its value and pulsing its pattern
through the reader's own two channels, so learning feels exactly like the
thing being learned. VoiceOver reads a row as *"five hundred naira, long
long"*. Tested through the spies and under the audit at both text sizes.

And R2 needs a handset that does not exist yet, but the test that will run
on it can: `make device-check D=<id>`, two tests — a note named within the
budget, a covered lens said to be dark and never a number — that skip by name
on a simulator. The summary line now counts skips so one can never read as
a pass.

### What surprised us

**The settings sheet was system blue.** Every action in the palette is yellow;
SwiftUI's default tint put a blue *Done* on a screen no test could object
to, because the audit checks contrast and size, not whether a colour is in
the palette. A person looking at the screen caught it. One `.tint()`.

## 2026-09-12 — The test simulator talked through the speakers

Moved the tests to a second simulator, "Tender Tests", so they stop driving
the one a person is looking at — the largest-text launches were alarming to
watch. Then the headless simulator's audio came out of the Mac's speakers:
VoiceOver is not running in a test, so the app used the synthesiser, and
after the suite the app was still open on a device nobody could see, saying
*"I can't see a note"* to the room.

Every UI test now launches with `-silent`, which keeps the synthesiser quiet
— a test reads what was said through a spy, never through a speaker — and
`make test-app` terminates the app and shuts "Tender Tests" down when the
suite ends. The device tests are the exception: the person holding the note
should hear the phone.

## 2026-09-12 — The metronome

The voice that kept coming out of the speakers was not the second simulator.
It was the app saying *"I can't see a note"* **once a second, for as long as no
note appeared** — the throttle suppressed a repeat *within* a second and
allowed one the moment a second had passed. A blind user with the phone in a
pocket would hear it until they closed the app. The FRD said "not more than
once per second"; what it meant was *on change, and never faster than once a
second*. The letter was implemented and a metronome shipped.

The test that guarded it listened for 300 ms and passed. It listens for 2.6 s
now and, against the old code, hears three sentences and fails. A second test
asserts that a change is said, and a change back is said again.

### What surprised us

**A person heard it from the next room before any test did.** Nothing on the
simulator's screen changes when a sentence repeats, so no screenshot and no
audit could see it, and the unit test had the wrong duration. The bug was
audible and only audible. Which is the channel this product lives in.
