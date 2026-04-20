#!/usr/bin/env python3
from pathlib import Path

prg_path = Path("PRG_System.st")
fb_path = Path("FB_Persist_Builder.st")

text = prg_path.read_text(encoding="utf-8")

start_marker = "// === NVRAM SNAPSHOT VIA STRUCT ADAPTER ==="
end_marker = "GVL_PERSISTENT.P_Valid := L_Persist_Struct.Valid;"

if start_marker not in text or end_marker not in text:
    raise SystemExit("Persist builder block not found")

start = text.index(start_marker)
end = text.index(end_marker, start) + len(end_marker)

block = text[start:end]

# заменить блок на вызов FB
replacement = """fbPersistBuilder(
    VI_State := GVL_STATE,
    VIO_PersistStruct := L_Persist_Struct
);"""

text = text[:start] + replacement + text[end:]

# добавить instance если нет
if "fbPersistBuilder : FB_Persist_Builder;" not in text:
    insert_anchor = "VAR"
    idx = text.find(insert_anchor)
    if idx == -1:
        raise SystemExit("VAR section not found")

    insert_pos = text.find("\n", idx) + 1
    text = text[:insert_pos] + "    fbPersistBuilder : FB_Persist_Builder;\n" + text[insert_pos:]

prg_path.write_text(text, encoding="utf-8")

# создаём FB
fb_code = f"""FUNCTION_BLOCK FB_Persist_Builder
VAR_INPUT
    VI_State : ST_System_State;
END_VAR

VAR_IN_OUT
    VIO_PersistStruct : ST_Persist;
END_VAR

// === BUILD STRUCT FROM STATE ===
{block}
"""

fb_path.write_text(fb_code, encoding="utf-8")

print("OK: extracted persist builder")
