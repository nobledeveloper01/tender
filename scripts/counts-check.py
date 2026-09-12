#!/usr/bin/env python3
"""Fail if a document quotes a figure the code does not produce.

The documents say "eleven notes", "eight values", "four gates". The code has
`Note.allCases`, `Naira.allCases`, and the ledger has rows. A number written
once and never checked is the difference between "photograph eleven notes"
and "photograph twelve", and that is a person's day.

Numbers are read from the Swift enums — the same source the app compiles —
and the ledger's shape is checked too, because which table a row is in *is*
the claim.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GREEN, RED, RESET = "\033[0;32m", "\033[0;31m", "\033[0m"

WORDS = {w: i for i, w in enumerate(
    "zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen".split())}


def enum_cases(path: Path, name: str) -> int:
    src = path.read_text()
    src = re.sub(r"//.*", "", src)
    body = src[src.index(f"enum {name}"):]
    body = body[:body.index("\n}")]
    cases: list[str] = []
    for line in re.findall(r"^\s*case ([^\n]+)", body, re.MULTILINE):
        for c in line.split(","):
            c = c.strip().split("=")[0].strip()
            if c and re.match(r"^\w+$", c):
                cases.append(c)
    return len(cases)


def number(word: str) -> int:
    return int(word) if word.isdigit() else WORDS[word.lower()]


def main() -> int:
    notes = enum_cases(ROOT / "TenderDomain/Sources/TenderDomain/Note.swift", "Note")
    values = enum_cases(ROOT / "TenderDomain/Sources/TenderDomain/Naira.swift", "Naira")
    ledger = (ROOT / "docs/RELEASE-GATES.md").read_text()
    blocking = ledger[ledger.index("## Blocks v1.0"):ledger.index("## Cleared")]
    gates = len(re.findall(r"^\| R\d+ \|", blocking, re.MULTILINE))

    # (file, anchored regex, expected)
    claims = [
        ("README.md", r"there are (\w+) visually distinct notes", notes),
        ("README.md", r"the classifier has (\w+) classes", notes),
        ("README.md", r"(\w+) gates, in \[`docs/RELEASE-GATES.md`", gates),
        ("docs/00-PRODUCT-STATEMENT.md", r"\*\*(\w+) visually distinct notes\*\*", notes),
        ("docs/00-PRODUCT-STATEMENT.md", r"It knows (\w+) notes", notes),
        ("docs/RELEASE-GATES.md", r"The (\w+)-class dataset", notes),
        ("docs/RELEASE-GATES.md", r"(\w+) patterns for (\w+) values", values),
        ("DESIGN.md", r"(\w+) patterns for (\w+) values", values),
    ]
    failures: list[str] = []
    checked = 0
    for rel, pattern, expected in claims:
        text = (ROOT / rel).read_text()
        m = re.search(pattern, text)
        if not m:
            failures.append(f"{rel}: the sentence matching /{pattern}/ is gone — reword the gate or the document")
            continue
        for g in m.groups():
            checked += 1
            got = number(g)
            if got != expected:
                failures.append(f"{rel} says {g} where the code has {expected}: /{pattern}/")

    # The ledger's shape: every gate row in a table, numbered once.
    ids = re.findall(r"^\| (R\d+) \|", ledger, re.MULTILINE)
    if len(ids) != len(set(ids)):
        failures.append("RELEASE-GATES.md numbers a gate twice")
    loose = re.findall(r"^(?!\|)\s*R\d+ \|", ledger, re.MULTILINE)
    if loose:
        failures.append("RELEASE-GATES.md has a gate row outside a table")

    for line in failures:
        print(f"{RED}✗{RESET} {line}")
    if failures:
        return 1
    print(f"{GREEN}✓{RESET} the documents count what the code has: {notes} notes, {values} values, "
          f"{gates} gates still blocking v1.0 — {checked} figures checked")
    return 0


if __name__ == "__main__":
    sys.exit(main())
