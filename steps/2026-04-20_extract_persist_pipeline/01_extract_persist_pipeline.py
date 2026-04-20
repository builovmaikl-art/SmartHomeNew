#!/usr/bin/env python3
from pathlib import Path

prg_path = Path("PRG_System.st")
fb_path = Path("FB_Persist_Pipeline.st")

prg = prg_path.read_text(encoding="utf-8")

instance_old = "    fbNVRAMManager : FB_NVRAM_Manager;\n"
instance_new = "    fbNVRAMManager : FB_NVRAM_Manager;\n    fbPersistPipeline : FB_Persist_Pipeline;\n"

if "fbPersistPipeline : FB_Persist_Pipeline;" not in prg:
    if instance_old not in prg:
        raise SystemExit("NVRAM manager instance anchor not found in PRG_System.st")
    prg = prg.replace(instance_old, instance_new, 1)

old_block = """// === SERIALIZE PERSIST STRUCT → BUFFER ===

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

// === END SERIALIZE ===

L_Persist_Buffer_Changed :=
    (L_Persist_Buffer[0] <> L_Last_Written_Persist_Buffer[0]) OR
    (L_Persist_Buffer[1] <> L_Last_Written_Persist_Buffer[1]) OR
    (L_Persist_Buffer[2] <> L_Last_Written_Persist_Buffer[2]) OR
    (L_Persist_Buffer[3] <> L_Last_Written_Persist_Buffer[3]) OR
    (L_Persist_Buffer[4] <> L_Last_Written_Persist_Buffer[4]);

L_NVRAM_Cmd := 0;
L_NVRAM_Offset := 0;

IF GVL_CONFIG.G_HMI_Apply_Settings THEN
    // explicit config apply may request a controlled write
    L_NVRAM_Cmd := 1;
    GVL_CONFIG.G_HMI_Apply_Settings := FALSE;

ELSIF L_Persist_Buffer_Changed THEN
    // controlled write: no more often than once per 60 seconds
    IF (L_Last_Persist_Write_MS = 0) OR
       ((GVL_STATUS.G_System_Time_MS - L_Last_Persist_Write_MS) >= 60000) THEN
        L_NVRAM_Cmd := 1;
    END_IF;
END_IF;

fbNVRAMManager(
    VI_Command := L_NVRAM_Cmd,
    VI_Offset := L_NVRAM_Offset,
    VI_DataRef := L_Persist_Buffer[0],
    VI_DataSize := 5,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Operator_ID := 'SYSTEM',
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_TwoPersonConfirmation := FALSE,
    VO_Done => L_NVRAM_Done,
    VO_Error => L_NVRAM_Err,
    VO_ErrorID => L_NVRAM_ErrID
);

IF (L_NVRAM_Cmd = 1) AND L_NVRAM_Done AND NOT L_NVRAM_Err THEN
    L_Last_Written_Persist_Buffer[0] := L_Persist_Buffer[0];
    L_Last_Written_Persist_Buffer[1] := L_Persist_Buffer[1];
    L_Last_Written_Persist_Buffer[2] := L_Persist_Buffer[2];
    L_Last_Written_Persist_Buffer[3] := L_Persist_Buffer[3];
    L_Last_Written_Persist_Buffer[4] := L_Persist_Buffer[4];
    L_Last_Persist_Write_MS := GVL_STATUS.G_System_Time_MS;
END_IF;"""

new_block = """fbPersistPipeline(
    VI_PersistStruct := L_Persist_Struct,
    VIO_Apply_Settings := GVL_CONFIG.G_HMI_Apply_Settings,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VIO_Persist_Buffer := L_Persist_Buffer,
    VIO_Last_Written_Persist_Buffer := L_Last_Written_Persist_Buffer,
    VIO_Last_Persist_Write_MS := L_Last_Persist_Write_MS,
    VO_NVRAM_Cmd => L_NVRAM_Cmd,
    VO_NVRAM_Offset => L_NVRAM_Offset,
    VO_NVRAM_Done => L_NVRAM_Done,
    VO_NVRAM_Err => L_NVRAM_Err,
    VO_NVRAM_ErrID => L_NVRAM_ErrID
);"""

if old_block not in prg:
    raise SystemExit("Target persistence pipeline block not found in PRG_System.st")

prg = prg.replace(old_block, new_block, 1)
prg_path.write_text(prg, encoding="utf-8")

fb_code = """FUNCTION_BLOCK FB_Persist_Pipeline
VAR_INPUT
    VI_PersistStruct : ST_Persist;
    VI_System_Time_MS : UDINT;
    VI_IsActivePLC : BOOL;
END_VAR
VAR_IN_OUT
    VIO_Apply_Settings : BOOL;
    VIO_Persist_Buffer : ARRAY[0..4] OF BYTE;
    VIO_Last_Written_Persist_Buffer : ARRAY[0..4] OF BYTE;
    VIO_Last_Persist_Write_MS : UDINT;
END_VAR
VAR_OUTPUT
    VO_NVRAM_Cmd : BYTE;
    VO_NVRAM_Offset : UDINT;
    VO_NVRAM_Done : BOOL;
    VO_NVRAM_Err : BOOL;
    VO_NVRAM_ErrID : UDINT;
END_VAR
VAR
    fbNVRAMManager : FB_NVRAM_Manager;
    L_Persist_Buffer_Changed : BOOL;
END_VAR

// === SERIALIZE PERSIST STRUCT → BUFFER ===

// System Mode
VIO_Persist_Buffer[0] := TO_BYTE(TO_INT(VI_PersistStruct.System_Mode));

// Gas
IF VI_PersistStruct.Safety_Gas_Latched THEN
    VIO_Persist_Buffer[1] := BYTE#1;
ELSE
    VIO_Persist_Buffer[1] := BYTE#0;
END_IF;

// Smoke
IF VI_PersistStruct.Safety_Smoke_Latched THEN
    VIO_Persist_Buffer[2] := BYTE#1;
ELSE
    VIO_Persist_Buffer[2] := BYTE#0;
END_IF;

// Leak
IF VI_PersistStruct.Safety_Leak_Latched THEN
    VIO_Persist_Buffer[3] := BYTE#1;
ELSE
    VIO_Persist_Buffer[3] := BYTE#0;
END_IF;

// DHW Pump
IF VI_PersistStruct.DHW_Heating_Pump THEN
    VIO_Persist_Buffer[4] := BYTE#1;
ELSE
    VIO_Persist_Buffer[4] := BYTE#0;
END_IF;

// === END SERIALIZE ===

L_Persist_Buffer_Changed :=
    (VIO_Persist_Buffer[0] <> VIO_Last_Written_Persist_Buffer[0]) OR
    (VIO_Persist_Buffer[1] <> VIO_Last_Written_Persist_Buffer[1]) OR
    (VIO_Persist_Buffer[2] <> VIO_Last_Written_Persist_Buffer[2]) OR
    (VIO_Persist_Buffer[3] <> VIO_Last_Written_Persist_Buffer[3]) OR
    (VIO_Persist_Buffer[4] <> VIO_Last_Written_Persist_Buffer[4]);

VO_NVRAM_Cmd := 0;
VO_NVRAM_Offset := 0;

IF VIO_Apply_Settings THEN
    // explicit config apply may request a controlled write
    VO_NVRAM_Cmd := 1;
    VIO_Apply_Settings := FALSE;

ELSIF L_Persist_Buffer_Changed THEN
    // controlled write: no more often than once per 60 seconds
    IF (VIO_Last_Persist_Write_MS = 0) OR
       ((VI_System_Time_MS - VIO_Last_Persist_Write_MS) >= 60000) THEN
        VO_NVRAM_Cmd := 1;
    END_IF;
END_IF;

fbNVRAMManager(
    VI_Command := VO_NVRAM_Cmd,
    VI_Offset := VO_NVRAM_Offset,
    VI_DataRef := VIO_Persist_Buffer[0],
    VI_DataSize := 5,
    VI_System_Time_MS := VI_System_Time_MS,
    VI_Operator_ID := 'SYSTEM',
    VI_IsActivePLC := VI_IsActivePLC,
    VI_TwoPersonConfirmation := FALSE,
    VO_Done => VO_NVRAM_Done,
    VO_Error => VO_NVRAM_Err,
    VO_ErrorID => VO_NVRAM_ErrID
);

IF (VO_NVRAM_Cmd = 1) AND VO_NVRAM_Done AND NOT VO_NVRAM_Err THEN
    VIO_Last_Written_Persist_Buffer[0] := VIO_Persist_Buffer[0];
    VIO_Last_Written_Persist_Buffer[1] := VIO_Persist_Buffer[1];
    VIO_Last_Written_Persist_Buffer[2] := VIO_Persist_Buffer[2];
    VIO_Last_Written_Persist_Buffer[3] := VIO_Persist_Buffer[3];
    VIO_Last_Written_Persist_Buffer[4] := VIO_Persist_Buffer[4];
    VIO_Last_Persist_Write_MS := VI_System_Time_MS;
END_IF;
"""
fb_path.write_text(fb_code, encoding="utf-8")

print("OK: extracted persistence pipeline into FB_Persist_Pipeline.st")
