#!/usr/bin/env python3
"""Fail if a language is missing a clip; count the placeholders.

Reads the languages and the stems from the domain's `Language.swift` — the
same enum the app composes sentences from — so a stem added to the code
without a recording fails here, in every language, before it ships silent.

Every clip must exist and be a non-trivial AAC file: a zero-byte file is a
clip the platform will not play, and the gate should not have to decode
anything to know that. Placeholders are allowed while building and reported
in yellow; they block the release — see docs/RELEASE-GATES.md.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CLIPS = ROOT / "Tender" / "Clips"
GREEN, YEL, RED, RESET = "\033[0;32m", "\033[0;33m", "\033[0;31m", "\033[0m"


def read_enums() -> tuple[list[str], list[str]]:
    src = (ROOT / "TenderDomain/Sources/TenderDomain/Language.swift").read_text()
    lang_body = src[src.index("enum Language"):src.index("enum ClipStem")]
    codes = [c.strip() for c in re.search(r"case ([^\n]+)", lang_body).group(1).split(",") if c.strip() != "en"]
    stem_body = src[src.index("enum ClipStem"):src.index("var english")]
    stems = []
    for line in re.findall(r"^\s*case ([^\n]+)", stem_body, re.MULTILINE):
        for c in line.split(","):
            m = re.match(r"\s*(\w+)(?:\s*=\s*\"([^\"]+)\")?", c)
            if m:
                stems.append(m.group(2) or m.group(1))
    return codes, stems


def main() -> int:
    codes, stems = read_enums()
    listed = set((CLIPS / "placeholders.txt").read_text().split()) if (CLIPS / "placeholders.txt").exists() else set()
    failures: list[str] = []
    total = placeholders = 0
    for code in codes:
        for stem in stems:
            total += 1
            f = CLIPS / code / f"{code}-{stem}.m4a"
            if not f.exists():
                failures.append(f"{code}/{code}-{stem}.m4a is missing — run `make placeholders`")
                continue
            head = f.read_bytes()[:12]
            if f.stat().st_size < 1000 or b"ftyp" not in head:
                failures.append(f"{code}/{code}-{stem}.m4a is not an M4A the platform will play ({f.stat().st_size} bytes)")
            if f"{code}/{stem}" in listed:
                placeholders += 1
    for line in failures:
        print(f"{RED}✗{RESET} {line}")
    if failures:
        return 1
    if placeholders:
        print(f"{YEL}!{RESET} {placeholders} of {total} clips are placeholders, not native-speaker recordings")
        print("  Allowed while building. Blocks the release — see docs/RELEASE-GATES.md.")
    else:
        print(f"{GREEN}✓{RESET} every one of {total} clips is a recording — {len(codes)} languages, {len(stems)} stems")
    return 0


if __name__ == "__main__":
    sys.exit(main())
