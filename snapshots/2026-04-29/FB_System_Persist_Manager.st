// ==============================================================================
// System persist manager helper
//
// Internal helper for PRG_System.
// Owns persistent snapshot packing, controlled NVRAM write gating,
// FB_NVRAM_Manager call, and last-written buffer tracking.
// ==============================================================================
FUNCTION_BLOCK FB_System_Persist_Manager
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_IsActivePLC : BOOL;
END_VAR

VAR_IN_OUT
    VIO_Persist_Buffer : ARRAY[0..4] OF BYTE;
    VIO_Last_Written_Persist_Buffer : ARRAY[0..4] OF BYTE;
    VIO_Persist_Buffer_Changed : BOOL;
    VIO_Last_Persist_Write_MS : UDINT;
    VIO_NVRAM_Cmd : BYTE;
    VIO_NVRAM_Offset : UDINT;
    VIO_NVRAM_Done : BOOL;
    VIO_NVRAM_Err : BOOL;
    VIO_NVRAM_ErrID : UDINT;
END_VAR

VAR
    fbNVRAMManager : FB_NVRAM_Manager;
END_VAR

// Pack persistent snapshot into compact byte buffer for controlled NVRAM mirroring
VIO_Persist_Buffer[0] := TO_BYTE(TO_INT(GVL_STATE.G_System_Mode));
IF GVL_PERSISTENT.P_Safety_Gas_Latched THEN
    VIO_Persist_Buffer[1] := BYTE#1;
ELSE
    VIO_Persist_Buffer[1] := BYTE#0;
END_IF;
IF GVL_PERSISTENT.P_Safety_Smoke_Latched THEN
    VIO_Persist_Buffer[2] := BYTE#1;
ELSE
    VIO_Persist_Buffer[2] := BYTE#0;
END_IF;
IF GVL_PERSISTENT.P_Safety_Leak_Latched THEN
    VIO_Persist_Buffer[3] := BYTE#1;
ELSE
    VIO_Persist_Buffer[3] := BYTE#0;
END_IF;
IF GVL_PERSISTENT.P_DHW_Heating_Active THEN
    VIO_Persist_Buffer[4] := BYTE#1;
ELSE
    VIO_Persist_Buffer[4] := BYTE#0;
END_IF;

VIO_Persist_Buffer_Changed :=
    (VIO_Persist_Buffer[0] <> VIO_Last_Written_Persist_Buffer[0]) OR
    (VIO_Persist_Buffer[1] <> VIO_Last_Written_Persist_Buffer[1]) OR
    (VIO_Persist_Buffer[2] <> VIO_Last_Written_Persist_Buffer[2]) OR
    (VIO_Persist_Buffer[3] <> VIO_Last_Written_Persist_Buffer[3]) OR
    (VIO_Persist_Buffer[4] <> VIO_Last_Written_Persist_Buffer[4]);

VIO_NVRAM_Cmd := 0;
VIO_NVRAM_Offset := 0;

IF GVL_CONFIG.G_HMI_Apply_Settings THEN
    // explicit config apply may request a controlled write
    VIO_NVRAM_Cmd := 1;
    GVL_CONFIG.G_HMI_Apply_Settings := FALSE;

ELSIF VIO_Persist_Buffer_Changed THEN
    // controlled write: no more often than once per 60 seconds
    IF (VIO_Last_Persist_Write_MS = 0) OR
       ((VI_System_Time_MS - VIO_Last_Persist_Write_MS) >= 60000) THEN
        VIO_NVRAM_Cmd := 1;
    END_IF;
END_IF;

fbNVRAMManager(
    VI_Command := VIO_NVRAM_Cmd,
    VI_Offset := VIO_NVRAM_Offset,
    VI_DataRef := VIO_Persist_Buffer[0],
    VI_DataSize := 5,
    VI_System_Time_MS := VI_System_Time_MS,
    VI_Operator_ID := 'SYSTEM',
    VI_IsActivePLC := VI_IsActivePLC,
    VI_TwoPersonConfirmation := FALSE,
    VO_Done => VIO_NVRAM_Done,
    VO_Error => VIO_NVRAM_Err,
    VO_ErrorID => VIO_NVRAM_ErrID
);

IF (VIO_NVRAM_Cmd = 1) AND VIO_NVRAM_Done AND NOT VIO_NVRAM_Err THEN
    VIO_Last_Written_Persist_Buffer[0] := VIO_Persist_Buffer[0];
    VIO_Last_Written_Persist_Buffer[1] := VIO_Persist_Buffer[1];
    VIO_Last_Written_Persist_Buffer[2] := VIO_Persist_Buffer[2];
    VIO_Last_Written_Persist_Buffer[3] := VIO_Persist_Buffer[3];
    VIO_Last_Written_Persist_Buffer[4] := VIO_Persist_Buffer[4];
    VIO_Last_Persist_Write_MS := VI_System_Time_MS;
END_IF;

// >>> BULK_SYNC_ANCHOR: FB_System_Persist_Manager <<<
