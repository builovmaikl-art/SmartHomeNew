PROGRAM PRG_Scenario_Engine
VAR
    L_IsNight : BOOL;
    L_Hour : INT;
END_VAR

// Derive hour from time service (ms of day)
L_Hour := GVL_TIME_SERVICE.G_Time_Of_Day_MS / 3600000;

// Simple context (safe, existing signals only)
L_IsNight := (L_Hour >= 22) OR (L_Hour < 6);

// Reset
GVL_INTENT_BEHAVIOR.I_Request_Night_Mode := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Away_Mode := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Comfort_Mode := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Energy_Save_Mode := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Preheat := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Ventilation_Boost := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Access_Secure_Mode := FALSE;
GVL_INTENT_BEHAVIOR.I_Behavior_Priority := 0;
GVL_INTENT_BEHAVIOR.I_Reason_Code := REASON_NONE;
GVL_INTENT_BEHAVIOR.I_Reason_Text := 'No behavior scenario active';

// Scenario logic (safe baseline)
IF L_IsNight THEN
    GVL_INTENT_BEHAVIOR.I_Request_Night_Mode := TRUE;
    GVL_INTENT_BEHAVIOR.I_Request_Comfort_Mode := TRUE;
    GVL_INTENT_BEHAVIOR.I_Behavior_Priority := 10;
    GVL_INTENT_BEHAVIOR.I_Reason_Code := REASON_SCENARIO_NIGHT;
    GVL_INTENT_BEHAVIOR.I_Reason_Text := 'Night mode active (time-based)';
ELSE
    GVL_INTENT_BEHAVIOR.I_Request_Comfort_Mode := TRUE;
    GVL_INTENT_BEHAVIOR.I_Behavior_Priority := 5;
    GVL_INTENT_BEHAVIOR.I_Reason_Text := 'Default comfort mode';
END_IF;

// Example: ventilation boost placeholder (future humidity integration)
// IF humidity high → set I_Request_Ventilation_Boost

GVL_INTENT_BEHAVIOR.I_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;

// >>> BULK_SYNC_ANCHOR: PRG_Scenario_Engine <<<
