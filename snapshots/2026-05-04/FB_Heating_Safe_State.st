FUNCTION_BLOCK FB_Heating_Safe_State
VAR_INPUT
    VI_Block_Normal_Heating : BOOL;
    VI_IO_Failsafe_Active : BOOL;
    VI_Gas_Safety_Active : BOOL;
    VI_Freeze_Active : BOOL;
    VI_Freeze_Target_Supply : REAL;
    VI_Manifold_Temps_Supply : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_Boiler_Error_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VI_Boiler_OT_Online : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
END_VAR
VAR_OUTPUT
    VO_Applied : BOOL;
    VO_Zone_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
    VO_Manifold_Pumps : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VO_Manifold_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VO_Boiler_OT_Enable : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VO_Boiler_OT_Setpoint : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL;
    VO_Boiler_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF ST_Boiler_Status;
    VO_Backup_Circulation_Pump : BOOL;
    VO_Electric_Heater_Enable : BOOL;
    VO_Freeze_Risk_Status : BOOL;
END_VAR
VAR
    L_i : INT;
    L_Min_Supply_Temp : REAL;
END_VAR

VO_Applied := VI_Block_Normal_Heating;
VO_Backup_Circulation_Pump := FALSE;
VO_Electric_Heater_Enable := FALSE;
VO_Freeze_Risk_Status := FALSE;

IF NOT VI_Block_Normal_Heating THEN
    RETURN;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    VO_Zone_Valves[L_i] := FALSE;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF VI_IO_Failsafe_Active AND VI_Freeze_Active THEN
        VO_Manifold_Pumps[L_i] := TRUE;
        VO_Manifold_Valves[L_i] := 35.0;
    ELSE
        VO_Manifold_Pumps[L_i] := FALSE;
        VO_Manifold_Valves[L_i] := 0.0;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    VO_Boiler_OT_Enable[L_i] := FALSE;
    VO_Boiler_OT_Setpoint[L_i] := 0.0;
    VO_Boiler_Status[L_i].Warning := FALSE;
    VO_Boiler_Status[L_i].Error := TRUE;
END_FOR;

IF VI_Gas_Safety_Active AND VI_Freeze_Active THEN
    VO_Backup_Circulation_Pump := TRUE;
    L_Min_Supply_Temp := 1000.0;
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        IF VI_Manifold_Temps_Supply[L_i] < L_Min_Supply_Temp THEN
            L_Min_Supply_Temp := VI_Manifold_Temps_Supply[L_i];
        END_IF;
    END_FOR;
    IF L_Min_Supply_Temp > 900.0 THEN
        L_Min_Supply_Temp := 0.0;
    END_IF;

    IF L_Min_Supply_Temp < (VI_Freeze_Target_Supply - 1.0) THEN
        VO_Electric_Heater_Enable := TRUE;
    ELSIF L_Min_Supply_Temp > (VI_Freeze_Target_Supply + 1.0) THEN
        VO_Electric_Heater_Enable := FALSE;
    END_IF;
    VO_Freeze_Risk_Status := TRUE;
END_IF;

IF VI_IO_Failsafe_Active AND VI_Freeze_Active THEN
    IF VI_Boiler_OT_Online[1] AND NOT VI_Boiler_Error_Status[1] THEN
        VO_Boiler_OT_Enable[1] := TRUE;
        VO_Boiler_OT_Setpoint[1] := VI_Freeze_Target_Supply;
    END_IF;
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Safe_State <<<
