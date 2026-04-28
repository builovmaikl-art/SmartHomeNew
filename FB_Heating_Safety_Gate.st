// ==============================================================================
// Heating safety gate helper
//
// Internal helper for FB_Heating_System_Manager.
// Owns common safety/freeze decision calculation. The manager remains the public
// facade and still projects physical safe-state outputs.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Safety_Gate
VAR_INPUT
    VI_System_Mode : E_System_Operating_Mode;
    VI_Emergency_Stop : BOOL;
    VI_Gas_Safety_Stop : BOOL;
    VI_IO_Failsafe_Active : BOOL;
    VI_Outdoor_Temp : REAL;
    VI_Freeze_Threshold : REAL;
END_VAR

VAR_IN_OUT
    VI_Floor_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF REAL;
END_VAR

VAR_OUTPUT
    VO_Block_Normal_Heating : BOOL;
    VO_Gas_Safety_Active : BOOL;
    VO_Emergency_Safe_Stop_Active : BOOL;
    VO_IO_Failsafe_Active : BOOL;
    VO_Freeze_Mode_Active : BOOL;
    VO_Freeze_Target_Supply : REAL;
END_VAR

VAR
    L_i : INT;
END_VAR

VO_Gas_Safety_Active := VI_Gas_Safety_Stop;
VO_Emergency_Safe_Stop_Active := VI_Emergency_Stop OR (VI_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP);
VO_IO_Failsafe_Active := VI_IO_Failsafe_Active;

VO_Block_Normal_Heating := VO_Gas_Safety_Active OR VO_Emergency_Safe_Stop_Active OR VO_IO_Failsafe_Active;
VO_Freeze_Mode_Active := (VI_System_Mode = E_System_Operating_Mode.MODE_FREEZE_PROTECTION) OR (VI_Outdoor_Temp < -5.0);

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    IF VI_Floor_Temps[L_i] < 7.0 THEN
        VO_Freeze_Mode_Active := TRUE;
    END_IF;
END_FOR;

IF VO_Freeze_Mode_Active THEN
    VO_Freeze_Target_Supply := LIMIT(20.0, VI_Freeze_Threshold + 2.0, 35.0);
ELSE
    VO_Freeze_Target_Supply := 0.0;
END_IF;

// >>> BULK_SYNC_ANCHOR: FB_Heating_Safety_Gate <<<
