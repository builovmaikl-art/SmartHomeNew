// ==============================================================================
// System evacuation helper
//
// Internal helper for PRG_System.
// Owns evacuation guidance logic and zone targeting.
// ==============================================================================
FUNCTION_BLOCK FB_System_Evacuation
VAR
    L_i : INT;
END_VAR

FOR L_i := 1 TO 32 DO
    IF GVL_STATE.G_Evacuation_Active[L_i] THEN
        GVL_STATE.G_Evac_Guidance[L_i] := TRUE;
        GVL_STATE.G_Evac_Target_Zone_Name[L_i] := GVL_STATE.G_Zone_Names[L_i];
    ELSE
        GVL_STATE.G_Evac_Guidance[L_i] := FALSE;
        GVL_STATE.G_Evac_Target_Zone_Name[L_i] := '';
    END_IF;
END_FOR;

// >>> BULK_SYNC_ANCHOR: FB_System_Evacuation <<<
