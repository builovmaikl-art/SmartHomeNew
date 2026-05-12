FUNCTION_BLOCK FB_Simulation_Manager
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_IsActivePLC    : BOOL;
    VI_Scenario       : E_SCENARIO_TYPE;
    VI_Config         : ST_Scenario_Config;
END_VAR
VAR_OUTPUT
    VO_Sim_Lights     : ARRAY[1..32] OF BOOL;
    VO_Sim_Active     : BOOL;
    VO_Sim_Water_Leak : ARRAY[1..GVL_CONSTANTS.C_MAX_FLOOD_SENSORS] OF BOOL;
    VO_Sim_Gas_Leak   : ARRAY[1..GVL_CONSTANTS.C_MAX_METHANE_SENSORS] OF REAL;
END_VAR
VAR
    L_Last_Toggle     : UDINT;
    L_i               : INT;
    L_Slot            : UDINT;
END_VAR

IF (NOT VI_IsActivePLC) THEN
    VO_Sim_Active := FALSE;
    FOR L_i := 1 TO 32 DO
        VO_Sim_Lights[L_i] := FALSE;
    END_FOR;
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO
        VO_Sim_Water_Leak[L_i] := FALSE;
    END_FOR;
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_METHANE_SENSORS DO
        VO_Sim_Gas_Leak[L_i] := REAL#0.0;
    END_FOR;
    RETURN;
END_IF;

IF (VI_Scenario = E_SCENARIO_TYPE.SCENARIO_AWAY) AND VI_Config.Presence_Simulation_Enabled THEN
    VO_Sim_Active := TRUE;

    IF (VI_System_Time_MS - L_Last_Toggle) >= (GVL_CONSTANTS.C_MS_IN_MINUTE * 30) THEN
        L_Last_Toggle := VI_System_Time_MS;
        L_Slot := (VI_System_Time_MS / GVL_CONSTANTS.C_MS_IN_MINUTE) MOD 32;

        FOR L_i := 1 TO 32 DO
            VO_Sim_Lights[L_i] := ((TO_UDINT(L_i) + L_Slot) MOD 5) = 0;
        END_FOR;
    END_IF;
ELSE
    VO_Sim_Active := FALSE;
    FOR L_i := 1 TO 32 DO
        VO_Sim_Lights[L_i] := FALSE;
    END_FOR;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO
    VO_Sim_Water_Leak[L_i] := FALSE;
END_FOR;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_METHANE_SENSORS DO
    VO_Sim_Gas_Leak[L_i] := REAL#0.0;
END_FOR;

// >>> BULK_SYNC_ANCHOR: FB_Simulation_Manager <<<
END_FUNCTION_BLOCK
