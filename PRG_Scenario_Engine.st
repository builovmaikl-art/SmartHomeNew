PROGRAM PRG_Scenario_Engine
VAR
    L_IsNight : BOOL;
    L_IsAway : BOOL;
END_VAR

// Simple context (placeholder logic)
L_IsNight := (GVL_TIME_SERVICE.G_Hour >= 22) OR (GVL_TIME_SERVICE.G_Hour < 6);
L_IsAway := NOT GVL_PRESENCE.G_Presence_Detected;

// Reset
GVL_INTENT_BEHAVIOR.I_Request_Night_Mode := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Away_Mode := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Comfort_Mode := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Energy_Save_Mode := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Preheat := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Ventilation_Boost := FALSE;

// Scenario logic
IF L_IsNight THEN
    GVL_INTENT_BEHAVIOR.I_Request_Night_Mode := TRUE;
END_IF;

IF L_IsAway THEN
    GVL_INTENT_BEHAVIOR.I_Request_Away_Mode := TRUE;
END_IF;

// Basic priority
IF GVL_INTENT_BEHAVIOR.I_Request_Away_Mode THEN
    GVL_INTENT_BEHAVIOR.I_Request_Energy_Save_Mode := TRUE;
ELSIF GVL_INTENT_BEHAVIOR.I_Request_Night_Mode THEN
    GVL_INTENT_BEHAVIOR.I_Request_Comfort_Mode := TRUE;
ELSE
    GVL_INTENT_BEHAVIOR.I_Request_Comfort_Mode := TRUE;
END_IF;

GVL_INTENT_BEHAVIOR.I_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;

// >>> BULK_SYNC_ANCHOR: PRG_Scenario_Engine <<<
