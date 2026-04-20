#!/usr/bin/env python3
from pathlib import Path

builder_path = Path("FB_Persist_Builder.st")
prg_path = Path("PRG_System.st")

builder = builder_path.read_text(encoding="utf-8")
prg = prg_path.read_text(encoding="utf-8")

# --- repair FB_Persist_Builder.st ---
builder = builder.replace("L_Persist_Struct.", "VIO_PersistStruct.")
builder = builder.replace("GVL_STATE.", "VI_State.")

# --- repair fbPersistPipeline call in PRG_System.st ---
old_call = """fbPersistPipeline(
    VI_PersistStruct := L_Persist_Struct,
    VIO_Apply_Settings := GVL_CONFIG.G_HMI_Apply_Settings,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VIO_Persist_Buffer := L_Persist_Buffer,
    VIO_Last_Written_Persist_Buffer := L_Last_Written_Persist_Buffer,
    VIO_Last_Persist_Write_MS := L_Last_Persist_Write_MS,
);"""

new_call = """fbPersistPipeline(
    VI_PersistStruct := L_Persist_Struct,
    VIO_Apply_Settings := GVL_CONFIG.G_HMI_Apply_Settings,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VIO_Persist_Buffer := L_Persist_Buffer,
    VIO_Last_Written_Persist_Buffer := L_Last_Written_Persist_Buffer,
    VIO_Last_Persist_Write_MS := L_Last_Persist_Write_MS
);"""

if old_call not in prg:
    raise SystemExit("Broken fbPersistPipeline call pattern not found in PRG_System.st")

prg = prg.replace(old_call, new_call, 1)

builder_path.write_text(builder, encoding="utf-8")
prg_path.write_text(prg, encoding="utf-8")

print("OK: repaired FB_Persist_Builder and fbPersistPipeline call")
