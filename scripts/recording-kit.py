#!/usr/bin/env python3
"""The recording script for one language, and the way the takes come back.

    make recording-kit L=ha              writes docs/RECORDING-KIT.md's script for Hausa
    make recording-import L=ha D=<dir>   converts the takes and strikes them off placeholders.txt

Twelve lines per language — eight values, four connecting words — derived
from the domain's `ClipStem`, so the script cannot fall behind the app.
A take is a file named by its stem, in any format afconvert reads
(m4a, wav, aiff, mp3); it is converted to AAC-LC 16 kHz 32 kbps mono, the
bundled format, and placed at Tender/Clips/<lang>/<lang>-<stem>.m4a.
Refuses to overwrite a clip that is not a placeholder unless FORCE=1.
"""

from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CLIPS = ROOT / "Tender" / "Clips"
GREEN, RED, YEL, RESET = "\033[0;32m", "\033[0;31m", "\033[0;33m", "\033[0m"


def enums():
    src = (ROOT / "TenderDomain/Sources/TenderDomain/Language.swift").read_text()
    lang_body = src[src.index("enum Language"):src.index("enum ClipStem")]
    names = dict(re.findall(r'case \.(\w+): "([^"]+)"', lang_body))
    stem_body = src[src.index("enum ClipStem"):src.index("static func value")]
    order = []
    for line in re.findall(r"^\s*case ([^\n]+)", stem_body[:stem_body.index("var english")], re.MULTILINE):
        for c in line.split(","):
            m = re.match(r"\s*(\w+)(?:\s*=\s*\"([^\"]+)\")?", c)
            if m: order.append((m.group(1), m.group(2) or m.group(1)))
    english = dict(re.findall(r'case \.(\w+): "([^"]+)"', stem_body[stem_body.index("var english"):]))
    return names, [(stem, english[case]) for case, stem in order]


def script(code: str) -> str:
    names, stems = enums()
    lines = [f"## {names[code]} ({code})", "",
             "Say each line once, plainly, as you would to a person holding the note. One take",
             "per line, named by its number or its stem. Quiet room, phone at arm's length.", "",
             "| # | stem | say, in your language |", "|---|---|---|"]
    for i, (stem, english) in enumerate(stems, 1):
        lines.append(f"| {i} | `{stem}` | {english} |")
    return "\n".join(lines) + "\n"


def do_import(code: str, folder: Path, force: bool) -> int:
    names, stems = enums()
    if code not in names or code == "en":
        print(f"{RED}✗{RESET} '{code}' is not a recorded language: {', '.join(k for k in names if k != 'en')}")
        return 1
    listed_path = CLIPS / "placeholders.txt"
    listed = set(listed_path.read_text().split()) if listed_path.exists() else set()
    done = skipped = 0
    by_stem = {s: e for s, e in stems}
    for f in sorted(folder.iterdir()):
        if f.suffix.lower() not in {".m4a", ".wav", ".aiff", ".aif", ".mp3", ".caf"} or f.name.startswith("."):
            continue
        base = f.stem
        stem = base if base in by_stem else next((s for i, (s, _) in enumerate(stems, 1) if base.lstrip("0") == str(i)), None)
        if stem is None:
            print(f"{YEL}!{RESET} {f.name}: not a stem or a line number; skipped")
            skipped += 1
            continue
        out = CLIPS / code / f"{code}-{stem}.m4a"
        key = f"{code}/{stem}"
        if out.exists() and key not in listed and not force:
            print(f"{YEL}!{RESET} {out.relative_to(ROOT)} is already a recording; FORCE=1 to replace")
            skipped += 1
            continue
        out.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["afconvert", "-f", "m4af", "-d", "aac", "-b", "32000", "-c", "1", "--src-complexity", "bats", "-s", "3",
                        str(f), str(out)], check=True, capture_output=True)
        listed.discard(key)
        done += 1
    listed_path.write_text("\n".join(sorted(listed)) + ("\n" if listed else ""))
    left = sum(1 for k in listed if k.startswith(code + "/"))
    print(f"{GREEN}✓{RESET} {done} recordings filed for {names[code]}; {left} placeholders left in it"
          + (f"; {skipped} skipped" if skipped else ""))
    return 0


def main() -> int:
    args = sys.argv[1:]
    if not args:
        print("usage: recording-kit.py <lang> [--import <dir>] [--force]", file=sys.stderr)
        return 64
    code = args[0]
    if "--import" in args:
        return do_import(code, Path(args[args.index("--import") + 1]).expanduser(), "--force" in args)
    names, _ = enums()
    if code not in names or code == "en":
        print(f"{RED}✗{RESET} '{code}' is not a recorded language")
        return 1
    print(script(code))
    return 0


if __name__ == "__main__":
    sys.exit(main())
