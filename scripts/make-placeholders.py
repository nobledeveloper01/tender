#!/usr/bin/env python3
"""Write a stand-in clip for every recording not yet made (macOS).

A placeholder that sounded like the product would be how a missing recording
ships. So each one says, in English, that it is a placeholder and which
language belongs there — "placeholder, Hausa, five hundred naira" — and is
listed in placeholders.txt, which `make audio-check` counts on every run and
`make recording-import` strikes lines off.

Uses macOS `say` and `afconvert`, both built in, so nothing is installed.
Output is AAC-LC, mono, 16 kHz, 32 kbps in .m4a — the same as the recordings
that replace them. Skips a clip that already exists, so re-running never
overwrites a real recording.
"""

from __future__ import annotations

import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CLIPS = ROOT / "Tender" / "Clips"
GREEN, RESET = "\033[0;32m", "\033[0m"


def stems() -> list[tuple[str, str]]:
    src = (ROOT / "TenderDomain/Sources/TenderDomain/Language.swift").read_text()
    body = src[src.index("enum ClipStem"):src.index("static func value")]
    cases = []
    for line in re.findall(r"^\s*case ([^\n]+)", body[:body.index("var english")], re.MULTILINE):
        for c in line.split(","):
            c = c.strip()
            m = re.match(r"(\w+)(?:\s*=\s*\"([^\"]+)\")?", c)
            if m:
                cases.append(m.group(2) or m.group(1))
    english = dict(re.findall(r'case \.(\w+): "([^"]+)"', body[body.index("var english"):]))
    name = {v: k for k, v in re.findall(r'case (\w+) = "([^"]+)"', body)}
    return [(stem, english[name.get(stem, stem)]) for stem in cases]


def languages() -> list[tuple[str, str]]:
    src = (ROOT / "TenderDomain/Sources/TenderDomain/Language.swift").read_text()
    body = src[src.index("enum Language"):src.index("enum ClipStem")]
    codes = [c.strip() for c in re.search(r"case ([^\n]+)", body).group(1).split(",")]
    names = dict(re.findall(r'case \.(\w+): "([^"]+)"', body))
    return [(c, names[c]) for c in codes if c != "en"]


def main() -> int:
    made = 0
    placeholders = CLIPS / "placeholders.txt"
    listed = set(placeholders.read_text().split()) if placeholders.exists() else set()
    with tempfile.TemporaryDirectory() as tmp:
        for code, lang in languages():
            for stem, english in stems():
                out = CLIPS / code / f"{code}-{stem}.m4a"   # unique across languages: Xcode flattens resources
                if out.exists():
                    continue
                out.parent.mkdir(parents=True, exist_ok=True)
                aiff = Path(tmp) / f"{code}-{stem}.aiff"
                subprocess.run(["say", "-o", str(aiff), f"placeholder, {lang}, {english}"], check=True)
                subprocess.run(["afconvert", "-f", "m4af", "-d", "aac", "-b", "32000", "-c", "1", "--src-complexity", "bats",
                                "-s", "3", str(aiff), str(out)], check=True, capture_output=True)
                listed.add(f"{code}/{stem}")
                made += 1
    placeholders.write_text("\n".join(sorted(listed)) + "\n")
    print(f"{GREEN}✓{RESET} {made} placeholder clips written; {len(listed)} listed in placeholders.txt")
    return 0


if __name__ == "__main__":
    sys.exit(main())
