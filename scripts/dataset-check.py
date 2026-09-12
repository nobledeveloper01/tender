#!/usr/bin/env python3
"""Count the dataset against Phase 1's exit gate, reading the classes from the code.

The class list is `Note` in the domain — the same enum the model is trained
with and the app pools by — so a folder that is not a `Note` is a mistake and
a `Note` with no folder is a gap. Both fail.

Per class, Phase 1 asks for: at least 300 training photographs and 50 held
out; both faces; at least a third worn; at least three lighting conditions.
The filename carries the facts — `<class>-<face>-<condition>-<light>-<n>.jpg`
— so the gate reads them rather than trusting a manifest somebody wrote.

The held-out set is sacred: no file in test/ may share content with any file
in train/, by hash. A model evaluated on a photograph it trained on publishes
a number that means nothing.

    make dataset-check                    ../tender-dataset
    make dataset-check DATASET=/path      elsewhere

Yellow when the dataset is absent — allowed while building, blocks Phase 1 —
so a fresh clone's `make ci` is green and honest. Red when it is present and
short, because then the number is a claim.
"""

from __future__ import annotations

import hashlib
import os
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATASET = Path(os.environ.get("DATASET", ROOT.parent / "tender-dataset"))
GREEN, YEL, RED, RESET = "\033[0;32m", "\033[0;33m", "\033[0;31m", "\033[0m"

TRAIN_MIN, TEST_MIN, WORN_SHARE, LIGHTS_MIN = 300, 50, 1 / 3, 3
FACES = {"front", "back"}
CONDITIONS = {"new", "worn"}
LIGHTS = {"day", "tungsten", "dusk", "led"}
NAME = re.compile(r"^(?P<cls>[a-z0-9]+)-(?P<face>[a-z]+)-(?P<cond>[a-z]+)-(?P<light>[a-z]+)-(?P<n>\d{3,})\.(jpe?g|heic|png)$")


def note_classes() -> list[str]:
    src = (ROOT / "TenderDomain/Sources/TenderDomain/Note.swift").read_text()
    src = re.sub(r"//.*", "", src)
    body = src[src.index("enum Note"):]
    body = body[:body.index("\n}")]
    cases = []
    for line in re.findall(r"^\s*case ([^\n]+)", body, re.MULTILINE):
        cases += [c.strip() for c in line.split(",") if re.match(r"^\s*\w+\s*$", c)]
    return cases


def sha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    classes = note_classes()
    if not DATASET.exists():
        print(f"{YEL}!{RESET} no dataset at {DATASET} — {len(classes)} classes, 0 photographs")
        print("  Allowed while building. Blocks Phase 1 — see docs/DATASET-GUIDE.md.")
        return 0

    failures: list[str] = []
    counts: dict[str, dict[str, int]] = {c: {"train": 0, "test": 0} for c in classes}
    facts: dict[str, dict[str, Counter]] = {c: {"face": Counter(), "cond": Counter(), "light": Counter()} for c in classes}
    hashes: dict[str, dict[str, Path]] = {"train": {}, "test": {}}

    for split in ("train", "test"):
        d = DATASET / split
        if not d.is_dir():
            failures.append(f"{split}/ is missing")
            continue
        for folder in sorted(p for p in d.iterdir() if p.is_dir()):
            if folder.name not in classes:
                failures.append(f"{split}/{folder.name}/ is not a Note — the classes are {', '.join(classes)}")
                continue
            for f in sorted(folder.iterdir()):
                if f.name.startswith("."):
                    continue
                m = NAME.match(f.name)
                if not m:
                    failures.append(f"{split}/{folder.name}/{f.name} does not follow <class>-<face>-<condition>-<light>-<n>.jpg")
                    continue
                if m["cls"] != folder.name:
                    failures.append(f"{split}/{folder.name}/{f.name} is filed under the wrong class")
                for key, allowed in (("face", FACES), ("cond", CONDITIONS), ("light", LIGHTS)):
                    if m[key] not in allowed:
                        failures.append(f"{split}/{folder.name}/{f.name}: {key} '{m[key]}' is not one of {sorted(allowed)}")
                counts[folder.name][split] += 1
                for key in ("face", "cond", "light"):
                    facts[folder.name][key][m[key]] += 1
                hashes[split][sha(f)] = f
        for c in classes:
            if not (d / c).is_dir():
                failures.append(f"{split}/{c}/ is missing")

    leaked = set(hashes["train"]) & set(hashes["test"])
    for h in sorted(leaked):
        failures.append(f"held-out leak: {hashes['test'][h].name} is also in train/ as {hashes['train'][h].name}")

    total_train = sum(v["train"] for v in counts.values())
    total_test = sum(v["test"] for v in counts.values())
    short: list[str] = []
    for c in classes:
        tr, te = counts[c]["train"], counts[c]["test"]
        f = facts[c]
        if tr < TRAIN_MIN: short.append(f"{c}: {tr}/{TRAIN_MIN} training")
        if te < TEST_MIN: short.append(f"{c}: {te}/{TEST_MIN} held out")
        if tr and not FACES <= set(f["face"]): short.append(f"{c}: only {sorted(f['face'])} faces")
        if tr and f["cond"]["worn"] < WORN_SHARE * (tr + te): short.append(f"{c}: {f['cond']['worn']} worn of {tr + te}, need a third")
        if tr and len(f["light"]) < LIGHTS_MIN: short.append(f"{c}: {len(f['light'])} lighting conditions, need {LIGHTS_MIN}")

    for line in failures:
        print(f"{RED}✗{RESET} {line}")
    if failures:
        print(f"\n{RED}the dataset is malformed{RESET} — fix the files before counting them")
        return 1
    if short:
        for line in short:
            print(f"{YEL}!{RESET} {line}")
        print(f"\n{YEL}Phase 1 is not cleared{RESET}: {total_train} training, {total_test} held out, across {len(classes)} classes")
        return 1
    print(f"{GREEN}✓{RESET} the dataset clears Phase 1: {total_train} training and {total_test} held-out photographs, "
          f"{len(classes)} classes, both faces, a third worn, {LIGHTS_MIN}+ lights, no held-out leak")
    return 0


if __name__ == "__main__":
    sys.exit(main())
