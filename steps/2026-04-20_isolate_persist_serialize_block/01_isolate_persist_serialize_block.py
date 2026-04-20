#!/usr/bin/env python3
from pathlib import Path

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

old = """L_Persist_Buffer[0] := TO_BYTE(TO_INT(L_Persist_Struct.System_Mode));
IF L_Persist_Struct.Safety_Gas_Latched THEN
    L_Persist_Buffer[1] := BYTE#1;
ELSE
    L_Persist_Buffer[1] := BYTE#0;
END_IF;
IF L_Persist_Struct.Safety_Smoke_Latched THEN
    L_Persist_Buffer[2] := BYTE#1;
ELSE
    L_Persist_Buffer[2] := BYTE#0;
END_IF;
IF L_Persist_Struct.Safety_Leak_Latched THEN
    L_Persist_Buffer[3] := BYTE#1;
ELSE
    L_Persist_Buffer[3] := BYTE#0;
END_IF;
IF L_Persist_Struct.DHW_Heating_Pump THEN
    L_Persist_Buffer[4] := BYTE#1;
ELSE
    L_Persist_Buffer[4] := BYTE#0;
END_IF;"""

new = """// === SERIALIZE PERSIST STRUCT → BUFFER ===

// System Mode
L_Persist_Buffer[0] := TO_BYTE(TO_INT(L_Persist_Struct.System_Mode));

// Gas
IF L_Persist_Struct.Safety_Gas_Latched THEN
    L_Persist_Buffer[1] := BYTE#1;
ELSE
    L_Persist_Buffer[1] := BYTE#0;
END_IF;

// Smoke
IF L_Persist_Struct.Safety_Smoke_Latched THEN
    L_Persist_Buffer[2] := BYTE#1;
ELSE
    L_Persist_Buffer[2] := BYTE#0;
END_IF;

// Leak
IF L_Persist_Struct.Safety_Leak_Latched THEN
    L_Persist_Buffer[3] := BYTE#1;
ELSE
    L_Persist_Buffer[3] := BYTE#0;
END_IF;

// DHW Pump
IF L_Persist_Struct.DHW_Heating_Pump THEN
    L_Persist_Buffer[4] := BYTE#1;
ELSE
    L_Persist_Buffer[4] := BYTE#0;
END_IF;

// === END SERIALIZE ==="""

if old not in text:
    raise SystemExit("Target serialization block not found in PRG_System.st")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: isolated persist struct serialization block")
