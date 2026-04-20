#!/usr/bin/env python3
from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

vars_to_remove = [
    "L_NVRAM_Cmd",
    "L_NVRAM_Offset",
    "L_NVRAM_Done",
    "L_NVRAM_Err",
    "L_NVRAM_ErrID"
]

lines = text.splitlines()
new_lines = []

for line in lines:
    if any(var in line for var in vars_to_remove):
        continue
    new_lines.append(line)

new_text = "\n".join(new_lines) + "\n"
path.write_text(new_text, encoding="utf-8")

print("OK: removed unused NVRAM interface variables from PRG_System.st")
