#!/usr/bin/env python3
"""File a batch of photographs into the dataset, named by the convention.

You photograph one note, one face, one condition, one light at a time —
thirty or forty shots — AirDrop the folder to the Mac, and run:

    make dataset-import CLASS=n500new FACE=back COND=worn LIGHT=dusk D=~/Desktop/batch

Every image in D is renamed `<class>-<face>-<condition>-<light>-<n>.jpg`,
numbered on from what the class already has, and filed. Every seventh goes
to test/ — held out, never trained on — which lands close to the 300/50 split
Phase 1 asks for. The split is by position, not by choice, so nobody can
quietly move the hard ones to train.

Refuses a file whose content is already in the dataset, so re-importing a
batch cannot double-count it, and refuses a CLASS that is not a `Note`.
"""

from __future__ import annotations

import hashlib
import os
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATASET = Path(os.environ.get("DATASET", ROOT.parent / "tender-dataset"))
GREEN, RED, RESET = "\033[0;32m", "\033[0;31m", "\033[0m"
HOLD_OUT_EVERY = 7


def note_classes() -> list[str]:
    src = re.sub(r"//.*", "", (ROOT / "TenderDomain/Sources/TenderDomain/Note.swift").read_text())
    body = src[src.index("enum Note"):]
    body = body[:body.index("\n}")]
    out = []
    for line in re.findall(r"^\s*case ([^\n]+)", body, re.MULTILINE):
        out += [c.strip() for c in line.split(",") if re.match(r"^\s*\w+\s*$", c)]
    return out


def sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def main() -> int:
    try:
        cls, face, cond, light, src = (sys.argv[i] for i in range(1, 6))
    except IndexError:
        print("usage: dataset-import.py <class> <face> <condition> <light> <dir>", file=sys.stderr)
        return 64
    classes = note_classes()
    if cls not in classes:
        print(f"{RED}✗{RESET} '{cls}' is not a Note — the classes are {', '.join(classes)}")
        return 1
    for key, val, allowed in (("face", face, {"front", "back"}), ("condition", cond, {"new", "worn"}),
                              ("light", light, {"day", "tungsten", "dusk", "led"})):
        if val not in allowed:
            print(f"{RED}✗{RESET} {key} '{val}' is not one of {sorted(allowed)}")
            return 1
    source = Path(src).expanduser()
    files = sorted(p for p in source.iterdir() if p.suffix.lower() in {".jpg", ".jpeg", ".heic", ".png"} and not p.name.startswith("."))
    if not files:
        print(f"{RED}✗{RESET} no photographs in {source}")
        return 1

    # Every photograph already in the dataset, under any class: the same
    # picture filed as two notes is worse than a duplicate, it is a wrong label.
    existing = {}
    for split in ("train", "test"):
        for p in (DATASET / split).glob("*/*"):
            if p.is_file() and not p.name.startswith("."):
                existing[sha(p)] = p
    n = 0
    for split in ("train", "test"):
        for p in (DATASET / split / cls).glob(f"{cls}-*"):
            m = re.search(r"-(\d+)\.\w+$", p.name)
            if m:
                n = max(n, int(m.group(1)))
    total_before = sum(1 for p in existing.values() if p.parent.name == cls)

    filed = {"train": 0, "test": 0}
    skipped = 0
    for p in files:
        h = sha(p)
        if h in existing:
            skipped += 1
            if existing[h].parent.name != cls:
                print(f"{RED}✗{RESET} {p.name} is already filed as {existing[h].parent.name}/{existing[h].name} — not filing it as {cls}")
            continue
        n += 1
        split = "test" if (total_before + filed["train"] + filed["test"] + 1) % HOLD_OUT_EVERY == 0 else "train"
        dest = DATASET / split / cls
        dest.mkdir(parents=True, exist_ok=True)
        target = dest / f"{cls}-{face}-{cond}-{light}-{n:03d}{p.suffix.lower().replace('.jpeg', '.jpg')}"
        shutil.copy2(p, target)
        existing[h] = target
        filed[split] += 1
    print(f"{GREEN}✓{RESET} filed {filed['train']} into train/{cls} and {filed['test']} into test/{cls}"
          + (f"; skipped {skipped} already in the dataset" if skipped else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
