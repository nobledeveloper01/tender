#!/usr/bin/env python3
"""Write MANIFEST.md beside the dataset: what is in it, counted from the files.

Phase 2's model report quotes these figures, so they are computed, not typed.
"""

from __future__ import annotations

import os
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATASET = Path(os.environ.get("DATASET", ROOT.parent / "tender-dataset"))
NAME = re.compile(r"^(?P<cls>[a-z0-9]+)-(?P<face>[a-z]+)-(?P<cond>[a-z]+)-(?P<light>[a-z]+)-(?P<n>\d+)\.\w+$")


def main() -> int:
    if not DATASET.exists():
        print(f"no dataset at {DATASET}", file=sys.stderr)
        return 1
    rows: dict[str, dict[str, Counter]] = defaultdict(lambda: defaultdict(Counter))
    for split in ("train", "test"):
        for f in (DATASET / split).glob("*/*"):
            m = NAME.match(f.name)
            if not m:
                continue
            c = m["cls"]
            rows[c]["split"][split] += 1
            rows[c]["face"][m["face"]] += 1
            rows[c]["cond"][m["cond"]] += 1
            rows[c]["light"][m["light"]] += 1
    lines = ["# Tender dataset — manifest", "",
             "Counted from the files by `make dataset-manifest`. Do not edit by hand.", "",
             "| class | train | test | front / back | new / worn | day / tungsten / dusk / led |", "|---|---|---|---|---|---|"]
    tt = te = 0
    for c in sorted(rows, key=lambda c: (len(c), c)):
        r = rows[c]
        tt += r["split"]["train"]; te += r["split"]["test"]
        lines.append(f"| {c} | {r['split']['train']} | {r['split']['test']} | {r['face']['front']} / {r['face']['back']} | "
                     f"{r['cond']['new']} / {r['cond']['worn']} | {r['light']['day']} / {r['light']['tungsten']} / {r['light']['dusk']} / {r['light']['led']} |")
    lines += ["", f"**{tt} training, {te} held out, {len(rows)} classes.**", ""]
    (DATASET / "MANIFEST.md").write_text("\n".join(lines))
    print(f"\033[0;32m✓\033[0m wrote {DATASET / 'MANIFEST.md'}: {tt} training, {te} held out, {len(rows)} classes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
