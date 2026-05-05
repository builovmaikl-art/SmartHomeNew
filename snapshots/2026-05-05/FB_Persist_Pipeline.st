FUNCTION_BLOCK FB_Persist_Pipeline
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
    // explicit config apply requests a controlled write
    // keep flag set until successful write confirmation
    VO_NVRAM_Cmd := 1;

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
    VIO_Apply_Settings := FALSE;
END_IF;
END_FUNCTION_BLOCK
