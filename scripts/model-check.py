#!/usr/bin/env python3
"""Refuse the model if the report says it is not good enough.

Reads docs/MODEL-REPORT.md, which `make model` writes from the held-out set,
and applies Phase 2's exit gate: every class's recall at or above 95%, and
zero confusions between a ₦500 and a ₦1000 in either direction, whichever
design. Yellow when there is no report yet — allowed while building, blocks
Phase 2 — so a fresh clone's `make ci` is green and honest.

Also refuses a report that lists classes the code does not have, or misses
one it does, so a stale report cannot pass for a current model.
"""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REPORT = Path(os.environ.get("MODEL_REPORT", ROOT / "docs" / "MODEL-REPORT.md"))
GREEN, YEL, RED, RESET = "\033[0;32m", "\033[0;33m", "\033[0;31m", "\033[0m"
FLOOR = 95.0


def note_classes() -> set[str]:
    src = re.sub(r"//.*", "", (ROOT / "TenderDomain/Sources/TenderDomain/Note.swift").read_text())
    body = src[src.index("enum Note"):]
    body = body[:body.index("\n}")]
    out = set()
    for line in re.findall(r"^\s*case ([^\n]+)", body, re.MULTILINE):
        out |= {c.strip() for c in line.split(",") if re.match(r"^\s*\w+\s*$", c)}
    return out


def main() -> int:
    if not REPORT.exists():
        print(f"{YEL}!{RESET} no model report — the app is wired to UntrainedClassifier, which recognises nothing")
        print("  Allowed while building. Blocks Phase 2 — `make model` writes docs/MODEL-REPORT.md.")
        return 0
    text = REPORT.read_text()
    rows = re.findall(r"^\| (\w+) \| (\d+) \| ([\d.]+)% \| ([\d.]+)% \|", text, re.MULTILINE)
    cross = re.search(r"₦500 ↔ ₦1000 confusions.*?\*\*(\d+)\*\*", text)
    failures: list[str] = []
    seen = {r[0] for r in rows}
    classes = note_classes()
    if seen != classes:
        failures.append(f"the report covers {sorted(seen)} and the code has {sorted(classes)} — retrain")
    for cls, held, recall, precision in rows:
        if float(recall) < FLOOR:
            failures.append(f"{cls}: recall {recall}% is below the {FLOOR:.0f}% floor")
        if int(held) < 50:
            failures.append(f"{cls}: only {held} held out — the number means little")
    if not cross:
        failures.append("the report does not state the ₦500 ↔ ₦1000 confusion count")
    elif int(cross.group(1)) > 0:
        failures.append(f"{cross.group(1)} ₦500 ↔ ₦1000 confusions — the one mistake that costs money")
    for line in failures:
        print(f"{RED}✗{RESET} {line}")
    if failures:
        print(f"\n{RED}the model is not good enough to wire{RESET} — UntrainedClassifier stays")
        return 1
    worst = min(float(r[2]) for r in rows)
    print(f"{GREEN}✓{RESET} the model clears Phase 2: {len(rows)} classes, worst recall {worst:.1f}%, no ₦500 ↔ ₦1000 confusion")
    return 0


if __name__ == "__main__":
    sys.exit(main())
