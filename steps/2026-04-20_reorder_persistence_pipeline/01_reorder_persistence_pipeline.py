#!/usr/bin/env python3
from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

build_start = "// === NVRAM SNAPSHOT VIA STRUCT ADAPTER ==="
build_end = "GVL_PERSISTENT.P_Valid := L_Persist_Struct.Valid;"

serialize_start = "// === SERIALIZE PERSIST STRUCT → BUFFER ==="
write_end = "    L_Last_Persist_Write_MS := GVL_STATUS.G_System_Time_MS;\nEND_IF;"

if build_start not in text:
    raise SystemExit("Build block start not found")
if build_end not in text:
    raise SystemExit("Build block end not found")
if serialize_start not in text:
    raise SystemExit("Serialize block start not found")
if write_end not in text:
    raise SystemExit("Write block end not found")

b_start = text.index(build_start)
b_end = text.index(build_end, b_start) + len(build_end)

s_start = text.index(serialize_start)
w_end = text.index(write_end, s_start) + len(write_end)

if b_start < s_start:
    raise SystemExit("Persistence pipeline already reordered")

build_block = text[b_start:b_end]
serialize_write_block = text[s_start:w_end]

# remove build block first
text_wo_build = text[:b_start] + text[b_end:]

# recompute serialize/write positions after removal
s_start2 = text_wo_build.index(serialize_start)
w_end2 = text_wo_build.index(write_end, s_start2) + len(write_end)

before = text_wo_build[:s_start2]
after = text_wo_build[s_start2:]

replacement = build_block.rstrip() + "\n\n" + after.lstrip()

new_text = before + replacement

path.write_text(new_text, encoding="utf-8")
print("OK: reordered persistence pipeline (build/mirror before serialize/write)")
