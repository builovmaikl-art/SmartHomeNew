#!/usr/bin/env python3
from pathlib import Path

builder_path = Path("FB_Persist_Builder.st")
prg_path = Path("PRG_System.st")

builder = builder_path.read_text(encoding="utf-8")
prg = prg_path.read_text(encoding="utf-8")

old_builder = """FUNCTION_BLOCK FB_Persist_Builder
VAR_INPUT
    VI_State : ST_System_State;
END_VAR

VAR_IN_OUT
    VIO_PersistStruct : ST_Persist;
END_VAR
"""

new_builder = """FUNCTION_BLOCK FB_Persist_Builder
VAR_IN_OUT
    VIO_PersistStruct : ST_Persist;
END_VAR
"""

if old_builder not in builder:
    raise SystemExit("FB_Persist_Builder interface pattern not found")

builder = builder.replace(old_builder, new_builder, 1)
builder = builder.replace("VI_State.", "GVL_STATE.")

old_call = """fbPersistBuilder(
    VI_State := GVL_STATE,
    VIO_PersistStruct := L_Persist_Struct
);"""

new_call = """fbPersistBuilder(
    VIO_PersistStruct := L_Persist_Struct
);"""

if old_call not in prg:
    raise SystemExit("fbPersistBuilder call pattern not found in PRG_System.st")

prg = prg.replace(old_call, new_call, 1)

builder_path.write_text(builder, encoding="utf-8")
prg_path.write_text(prg, encoding="utf-8")

print("OK: repaired FB_Persist_Builder interface to use GVL_STATE directly")
