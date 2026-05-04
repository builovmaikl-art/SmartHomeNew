FUNCTION_BLOCK FB_State_Snapshot_Manager
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_Trigger_Event  : BOOL; // Сигнал на создание снимка
    VI_Event_Code     : WORD;
    VI_Current_State  : ST_State_Snapshot;
END_VAR
VAR_OUTPUT
    VO_Snapshot_Saved : BOOL;
END_VAR
VAR
    L_Snapshot_Buffer : ARRAY[1..GVL_CONSTANTS.C_MAX_STATE_SNAPSHOTS] OF ST_State_Snapshot;
    L_Write_Idx       : INT := 1;
END_VAR

IF VI_Trigger_Event THEN
    L_Snapshot_Buffer[L_Write_Idx] := VI_Current_State;
    L_Snapshot_Buffer[L_Write_Idx].timestamp_ms := VI_System_Time_MS;
    
    // NOTE:
    // ST_State_Snapshot no longer contains trigger_event_code in live project.
    // VI_Event_Code is reserved for future snapshot metadata extension.
    
    L_Write_Idx := (L_Write_Idx MOD GVL_CONSTANTS.C_MAX_STATE_SNAPSHOTS) + 1;
    VO_Snapshot_Saved := TRUE;
ELSE
    VO_Snapshot_Saved := FALSE;
END_IF;
END_FUNCTION_BLOCK
