#!/usr/bin/env python3
from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

old = "    L_Persist_Buffer_Changed : BOOL;\n"
if old not in text:
    raise SystemExit("L_Persist_Buffer_Changed declaration not found in PRG_System.st")

text = text.replace(old, "", 1)
path.write_text(text, encoding="utf-8")

print("OK: removed dead variable L_Persist_Buffer_Changed from PRG_System.st")
