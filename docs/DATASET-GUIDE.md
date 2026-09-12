# The dataset — what to photograph, and how to file it

This is Phase 1, and it is the reason Tender was chosen: the one gate in the
portfolio that waits on nobody but the person holding the phone. A week's
work. This page is what that person is handed.

## What you need

- **One of every note in circulation, both designs of the three that were
  redesigned** — eleven notes: ₦5, ₦10, ₦20, ₦50, ₦100, old and new ₦200, old
  and new ₦500, old and new ₦1000. Banks hand out new-design notes on request;
  the old designs are still common in change. Ask three people for their
  wallets.
- **Worn ones as well as crisp ones.** At least a third of every class must be
  worn — creased, soft, faded, a corner gone. A worn note is the test set that
  matters; a classifier trained on bank-fresh notes fails in a market.
- **An iPhone**, any recent one. The training set should look like what the
  app will see.

## What to photograph

For **each note**, **each face** (front, back), **each condition** (new,
worn), photograph it under **at least three lights**:

| light | means |
|---|---|
| `day` | daylight, indoors by a window or outdoors in shade |
| `tungsten` | an ordinary bulb, evening, indoors |
| `dusk` | the last light, or a dim room — the hard one |
| `led` | a phone torch or a shop's LED strip — the harsh one |

Thirty to forty frames per combination: the note flat, the note held in a
hand, at arm's length and closer, straight on and at a slant, on a table, on
a palm, against a patterned cloth, half in shadow. Move between frames. The
point is variety, not volume — forty near-identical frames teach the model
one photograph.

**Do not photograph** anything that is not a note. The app decides
*"I can't see a note"* by arithmetic before the model runs; the model never
needs to learn what a receipt is.

That is 11 notes × 2 faces × 2 conditions × 3 lights = 132 batches of ~35, or
about **4,600 photographs**. `make dataset-check` asks for at least 300 in
training and 50 held out per note, both faces, a third worn, three lights.

## How to file them

Photograph **one batch at a time** — one note, one face, one condition, one
light — into one album. AirDrop that album to the Mac as a folder. Then:

```
make dataset-import CLASS=n500new FACE=back COND=worn LIGHT=dusk D=~/Desktop/batch
```

The tool renames every photograph `<class>-<face>-<condition>-<light>-<n>.jpg`,
numbers on from what the class already has, and files it. **Every seventh
goes to `test/`**, held out, never trained on. The split is by position, not
by choice, so nobody can move the hard frames to training. A photograph
already in the dataset — under any class — is skipped, and told you about if
it was filed under a different note.

The classes are the `Note` enum's raw values, and the tool refuses anything
else:

`n5 n10 n20 n50 n100 n200 n200new n500 n500new n1000 n1000new`

The dataset lives **beside** the repository, not in it: `../tender-dataset/`,
or wherever `DATASET=` points. Photographs of money are not source code.

## How to know you are done

```
make dataset-check
```

Yellow while any class is short, and it says which. Green when every class
clears — and green is Phase 1's exit gate. It also refuses, red, a file that
does not follow the naming, a folder that is not a note, and any held-out
photograph whose content also appears in training. That last one is the rule
that makes the published accuracy mean something.

Then `make dataset-manifest` writes `MANIFEST.md` beside the dataset — counts
per class, per light, per condition — which Phase 2's model report quotes.
