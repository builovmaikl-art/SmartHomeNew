#!/usr/bin/env python3
from pathlib import Path

path = Path("FB_Persist_Pipeline.st")
text = path.read_text(encoding="utf-8")

old1 = """IF VIO_Apply_Settings THEN
    // explicit config apply may request a controlled write
    VO_NVRAM_Cmd := 1;
    VIO_Apply_Settings := FALSE;

ELSIF L_Persist_Buffer_Changed THEN"""

new1 = """IF VIO_Apply_Settings THEN
    // explicit config apply requests a controlled write
    // keep flag set until successful write confirmation
    VO_NVRAM_Cmd := 1;

ELSIF L_Persist_Buffer_Changed THEN"""

if old1 not in text:
    raise SystemExit("Apply_Settings trigger block not found")

text = text.replace(old1, new1, 1)

old2 = """IF (VO_NVRAM_Cmd = 1) AND VO_NVRAM_Done AND NOT VO_NVRAM_Err THEN
    VIO_Last_Written_Persist_Buffer[0] := VIO_Persist_Buffer[0];
    VIO_Last_Written_Persist_Buffer[1] := VIO_Persist_Buffer[1];
    VIO_Last_Written_Persist_Buffer[2] := VIO_Persist_Buffer[2];
    VIO_Last_Written_Persist_Buffer[3] := VIO_Persist_Buffer[3];
    VIO_Last_Written_Persist_Buffer[4] := VIO_Persist_Buffer[4];
    VIO_Last_Persist_Write_MS := VI_System_Time_MS;
END_IF;"""

new2 = """IF (VO_NVRAM_Cmd = 1) AND VO_NVRAM_Done AND NOT VO_NVRAM_Err THEN
    VIO_Last_Written_Persist_Buffer[0] := VIO_Persist_Buffer[0];
    VIO_Last_Written_Persist_Buffer[1] := VIO_Persist_Buffer[1];
    VIO_Last_Written_Persist_Buffer[2] := VIO_Persist_Buffer[2];
    VIO_Last_Written_Persist_Buffer[3] := VIO_Persist_Buffer[3];
    VIO_Last_Written_Persist_Buffer[4] := VIO_Persist_Buffer[4];
    VIO_Last_Persist_Write_MS := VI_System_Time_MS;
    VIO_Apply_Settings := FALSE;
END_IF;"""

if old2 not in text:
    raise SystemExit("Successful write confirmation block not found")

text = text.replace(old2, new2, 1)

path.write_text(text, encoding="utf-8")
print("OK: Apply_Settings now resets only after successful write")
