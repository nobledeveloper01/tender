#!/usr/bin/env python3
"""Fail if anything the app can say implies a note is genuine.

ADR-0003: Tender names the denomination, never the authenticity. The tempting
sentence is one word long — "genuine five hundred naira" — and it would be
the most-wanted feature in the app, so the gate is a word list over every
user-facing string, run without building. `TenderTests/CopyTests` checks the
same list at runtime, so the two cannot drift; this one runs in `make gates`
so CI catches it in a second rather than after a simulator boot.

What it reads: every string literal in the files that hold user-facing copy —
the domain's `Announcement.swift`, the app's `Strings.swift`, `Config/Info.plist`
(the camera prompt), and `docs/APPSTORE.md` if it exists.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GREEN, RED, RESET = "\033[0;32m", "\033[0;31m", "\033[0m"

SOURCES = [
    ROOT / "TenderDomain" / "Sources" / "TenderDomain" / "Announcement.swift",
    ROOT / "Tender" / "Speech" / "Strings.swift",
    ROOT / "Config" / "Info.plist",
    ROOT / "docs" / "APPSTORE.md",
]

# Whole words, any inflection that matters.
BANNED = re.compile(r"\b(genuine|real|fake|counterfeit|authentic|verified|verify|verifies)\b", re.IGNORECASE)


def strings_in(path: Path) -> list[str]:
    text = path.read_text()
    if path.suffix == ".swift":
        # Strip comments; then every string literal.
        text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
        text = "\n".join(l for l in text.splitlines() if not l.lstrip().startswith("//"))
        return re.findall(r'"((?:[^"\\]|\\.)*)"', text)
    if path.suffix == ".plist":
        return re.findall(r"<string>(.*?)</string>", text, re.DOTALL)
    return [text]


def main() -> int:
    failures: list[str] = []
    counted = 0
    for path in SOURCES:
        if not path.exists():
            continue
        for s in strings_in(path):
            counted += 1
            m = BANNED.search(s)
            if m:
                failures.append(f"{path.relative_to(ROOT)}: '{m.group(0)}' in \"{s[:70]}\"")
    for line in failures:
        print(f"{RED}✗{RESET} {line}")
    if failures:
        print(f"\n{RED}copy gate failed{RESET} — the app names the denomination, never the authenticity. ADR-0003.")
        return 1
    print(f"{GREEN}✓{RESET} nothing the app says implies authenticity — {counted} strings checked against the word list")
    return 0


if __name__ == "__main__":
    sys.exit(main())
