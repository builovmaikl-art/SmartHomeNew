// ==============================================================================
// System history manager helper
//
// Internal helper for PRG_System.
// Owns history event detection, buffering, write index management,
// and interaction with FB_History_Manager.
// ==============================================================================
FUNCTION_BLOCK FB_System_History_Manager
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_IsActivePLC : BOOL;
    VI_First_Fault_Active : BOOL;
    VI_First_Fault_Type : INT;
    VI_First_Fault_Source : INT;
END_VAR

VAR_IN_OUT
    VIO_History_Write_Event : BOOL;
    VIO_History_Write_Idx : INT;
    VIO_History_Total_Events : DINT;
    VIO_History_Buffer : ARRAY[0..255] OF ST_History_Event;
END_VAR

VAR
    fbHistoryManager : FB_History_Manager;
END_VAR

// Detect new history event
IF VI_First_Fault_Active THEN
    VIO_History_Write_Event := TRUE;
ELSE
    VIO_History_Write_Event := FALSE;
END_IF;

// Write event into buffer
IF VIO_History_Write_Event THEN
    VIO_History_Buffer[VIO_History_Write_Idx].Timestamp := VI_System_Time_MS;
    VIO_History_Buffer[VIO_History_Write_Idx].Fault_Type := VI_First_Fault_Type;
    VIO_History_Buffer[VIO_History_Write_Idx].Fault_Source := VI_First_Fault_Source;

    VIO_History_Write_Idx := VIO_History_Write_Idx + 1;
    IF VIO_History_Write_Idx > 255 THEN
        VIO_History_Write_Idx := 0;
    END_IF;

    VIO_History_Total_Events := VIO_History_Total_Events + 1;
END_IF;

// Call history manager
fbHistoryManager(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_IsActivePLC := VI_IsActivePLC,
    VI_Write_Event := VIO_History_Write_Event,
    VIO_Write_Idx := VIO_History_Write_Idx,
    VIO_Total_Events := VIO_History_Total_Events,
    VIO_History_Buffer := VIO_History_Buffer
);

// >>> BULK_SYNC_ANCHOR: FB_System_History_Manager <<<
