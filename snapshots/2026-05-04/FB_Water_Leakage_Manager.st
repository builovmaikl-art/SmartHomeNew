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
    VO_Status_Msg     : STRING(200);
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
        END_IF;
    END_IF;
END_FOR;

// Manual latch instead of RS
IF GVL_INTENT_USER.I_Reset_Errors THEN
    VO_Leak_Detected := FALSE;
ELSIF L_Any_Leak THEN
    VO_Leak_Detected := TRUE;
END_IF;

VO_Leak_Warning_Level := L_Any_Warning;

IF VO_Leak_Detected THEN
    VO_Status_Msg := 'АВАРИЯ: ПРОТЕЧКА ВОДЫ.';
ELSIF L_Any_Warning THEN
    VO_Status_Msg := 'ПРЕДУПРЕЖДЕНИЕ: ОБНАРУЖЕНА ВОДА.';
ELSE
    VO_Status_Msg := 'Система контроля протечек в норме';
END_IF;
// >>> BULK_SYNC_ANCHOR: FB_Water_Leakage_Manager <<<
END_FUNCTION_BLOCK
