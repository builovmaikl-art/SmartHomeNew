#!/usr/bin/env python3
from pathlib import Path

prg_path = Path("PRG_System.st")
text = prg_path.read_text(encoding="utf-8")

old_decl = "    fbNVRAMManager : FB_NVRAM_Manager;\n"
if old_decl not in text:
    raise SystemExit("fbNVRAMManager declaration not found in PRG_System.st")

text = text.replace(old_decl, "", 1)
prg_path.write_text(text, encoding="utf-8")
print("OK: removed unused fbNVRAMManager declaration from PRG_System.st")
