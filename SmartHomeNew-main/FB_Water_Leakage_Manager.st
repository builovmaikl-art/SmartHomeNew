FUNCTION_BLOCK FB_Water_Leakage_Manager
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_IsActivePLC    : BOOL;
    VI_Config         : ST_Flood_Global_Config;
END_VAR

VAR_IN_OUT
    VI_Sensors : ARRAY[1..GVL_CONSTANTS.C_MAX_FLOOD_SENSORS] OF BOOL;
END_VAR

VAR_OUTPUT
    VO_Close_Valve_35 : BOOL;
    VO_Close_Valve_36 : BOOL;
    VO_Status_Msg     : STRING(200);

    // Health signals
    VO_Leak_Detected      : BOOL;
    VO_Leak_Warning_Level : BOOL;
END_VAR

VAR
    L_i             : INT;
    L_Sensor_Timers : ARRAY[1..GVL_CONSTANTS.C_MAX_FLOOD_SENSORS] OF FB_System_Timer;
    L_Any_Leak      : BOOL;
    L_Any_Warning   : BOOL;
END_VAR

IF NOT VI_IsActivePLC THEN RETURN; END_IF;

L_Any_Leak := FALSE;
L_Any_Warning := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO
    L_Sensor_Timers[L_i](
        IN := VI_Sensors[L_i],
        PT := TO_TIME(VI_Config.min_duration_ms + VI_Config.warning_duration_ms),
        VI_System_Time_MS := VI_System_Time_MS
    );

    IF L_Sensor_Timers[L_i].ET >= TO_TIME(VI_Config.min_duration_ms) THEN
        L_Any_Warning := TRUE;

        IF L_Sensor_Timers[L_i].Q THEN
            L_Any_Leak := TRUE;

            IF VI_Config.sensor_to_valve_map[L_i] = 1 THEN
                VO_Close_Valve_35 := FALSE; // ownership moved to PRG_Safety
            ELSIF VI_Config.sensor_to_valve_map[L_i] = 2 THEN
                VO_Close_Valve_36 := FALSE; // ownership moved to PRG_Safety
            END_IF;
        END_IF;
    END_IF;
END_FOR;

// Health signals
VO_Leak_Detected := L_Any_Leak;
VO_Leak_Warning_Level := L_Any_Warning;

// Status
IF L_Any_Leak THEN
    VO_Status_Msg := 'АВАРИЯ: ПРОТЕЧКА ВОДЫ. КЛАПАНЫ ЗАКРЫТЫ.';
ELSIF L_Any_Warning THEN
    VO_Status_Msg := 'ПРЕДУПРЕЖДЕНИЕ: ОБНАРУЖЕНА ВОДА.';
ELSE
    VO_Status_Msg := 'Система контроля протечек в норме';
    VO_Close_Valve_35 := FALSE;
    VO_Close_Valve_36 := FALSE;
END_IF;
// >>> BULK_SYNC_ANCHOR: FB_Water_Leakage_Manager <<<
