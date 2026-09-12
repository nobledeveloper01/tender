#!/usr/bin/env python3
"""Write docs/SPEECH.md: everything the app can say, derived from the source.

v1.1 replaces VoiceOver's English with a bundled recording of the denomination
in the user's own language, and this is the list a speaker is handed. It is
derived from `Naira.swift` and `Announcement.swift` — the same files the app
compiles — so it cannot fall behind the app. `make speech-check` fails when
the tracked file is stale.

    make speech-list      writes docs/SPEECH.md
    make speech-check     fails if it is not what the source produces
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOMAIN = ROOT / "TenderDomain/Sources/TenderDomain"
OUT = ROOT / "docs/SPEECH.md"
GREEN, RED, RESET = "\033[0;32m", "\033[0;31m", "\033[0m"


def spoken_values() -> list[tuple[int, str]]:
    src = (DOMAIN / "Naira.swift").read_text()
    body = src[src.index("var spoken: String"):]
    words = re.findall(r'case \.n(\d+): "([^"]+)"', body)
    return [(int(n), w) for n, w in words]


def framings() -> list[str]:
    src = (DOMAIN / "Announcement.swift").read_text()
    body = src[src.index("text(for framing: Framing)"):src.index("text(for verdict: Verdict)")]
    return re.findall(r'case \.\w+: "([^"]+)"', body)


def render() -> str:
    values = spoken_values()
    lines = ["# Everything the app says", "",
             "Derived from the source by `make speech-list`. Do not edit by hand.", "",
             "VoiceOver speaks all of this in English in v1.0. In v1.1 the **denomination line** is",
             "replaced by a bundled recording in the user's own language, and the words below are",
             "what a native speaker is asked to record — eight values, one suffix, and three frames.", "",
             "## The eight values", "", "| value | spoken |", "|---|---|"]
    lines += [f"| ₦{n} | {w} naira |" for n, w in values]
    lines += ["", "## The suffix, for the 2022 designs of ₦200, ₦500 and ₦1000", "", "- …, new design", "",
              "## The three ways an answer is framed", "",
              "| when | sentence |", "|---|---|",
              "| sure | *{value} naira.* |",
              "| probably | *I think {value} naira. Check.* |",
              "| not sure | *I don't recognise this.* |", "",
              "## What the camera says before there is an answer", ""]
    lines += [f"- {f}" for f in framings()]
    lines += ["", f"**{len(values)} values, 1 suffix, 3 frames, {len(framings())} camera prompts.**", ""]
    return "\n".join(lines)


def main() -> int:
    text = render()
    if "--check" in sys.argv:
        if not OUT.exists():
            print(f"{RED}✗{RESET} docs/SPEECH.md is missing — run `make speech-list`")
            return 1
        if OUT.read_text() != text:
            print(f"{RED}✗{RESET} docs/SPEECH.md is not what the source produces — run `make speech-list`")
            return 1
        print(f"{GREEN}✓{RESET} docs/SPEECH.md is current: {len(spoken_values())} values, {len(framings())} camera prompts")
        return 0
    OUT.write_text(text)
    print(f"{GREEN}✓{RESET} wrote docs/SPEECH.md")
    return 0


if __name__ == "__main__":
    sys.exit(main())
