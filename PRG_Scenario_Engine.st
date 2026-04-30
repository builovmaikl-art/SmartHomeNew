PROGRAM PRG_Scenario_Engine
VAR
    L_Hour : INT;
    L_MaxHum : REAL;
    L_i : INT;
END_VAR

// Time
L_Hour := TO_INT(GVL_TIME_SERVICE.G_Time_Of_Day_MS / 3600000);

// Reset intent
GVL_INTENT_BEHAVIOR.I_Request_Night_Mode := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Comfort_Mode := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Ventilation_Boost := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Access_Secure_Mode := FALSE;

// Reset scores
GVL_INTENT_BEHAVIOR.I_Score_Comfort := 10;
GVL_INTENT_BEHAVIOR.I_Score_Night := 0;
GVL_INTENT_BEHAVIOR.I_Score_Preheat := 0;
GVL_INTENT_BEHAVIOR.I_Score_Vent_Boost := 0;
GVL_INTENT_BEHAVIOR.I_Score_Access_Secure := 0;

// --- Scenario scoring ---
IF (L_Hour >= 22) OR (L_Hour < 6) THEN
    GVL_INTENT_BEHAVIOR.I_Score_Night := 40;
END_IF;

IF GVL_STATE.G_Preheat_Request THEN
    GVL_INTENT_BEHAVIOR.I_Score_Preheat := 50;
END_IF;

L_MaxHum := 0.0;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    IF GVL_STATE.G_Room_Hum[L_i] > L_MaxHum THEN
        L_MaxHum := GVL_STATE.G_Room_Hum[L_i];
    END_IF;
END_FOR;

IF L_MaxHum > 65.0 THEN
    GVL_INTENT_BEHAVIOR.I_Score_Vent_Boost := 45;
END_IF;

IF (L_Hour >= 23) OR (L_Hour < 5) THEN
    GVL_INTENT_BEHAVIOR.I_Score_Access_Secure := 30;
END_IF;

// --- Multi-scenario activation ---
IF GVL_INTENT_BEHAVIOR.I_Score_Night >= 30 THEN
    GVL_INTENT_BEHAVIOR.I_Request_Night_Mode := TRUE;
END_IF;

IF GVL_INTENT_BEHAVIOR.I_Score_Preheat >= 40 THEN
    GVL_INTENT_BEHAVIOR.I_Request_Comfort_Mode := TRUE;
END_IF;

IF GVL_INTENT_BEHAVIOR.I_Score_Vent_Boost >= 40 THEN
    GVL_INTENT_BEHAVIOR.I_Request_Ventilation_Boost := TRUE;
END_IF;

IF GVL_INTENT_BEHAVIOR.I_Score_Access_Secure >= 25 THEN
    GVL_INTENT_BEHAVIOR.I_Request_Access_Secure_Mode := TRUE;
END_IF;

// Always baseline comfort
GVL_INTENT_BEHAVIOR.I_Request_Comfort_Mode := TRUE;

// --- Trace ---
GVL_INTENT_BEHAVIOR.I_Selected_Scenario_Text := CONCAT('Active: ',
    CONCAT(
        SEL(GVL_INTENT_BEHAVIOR.I_Request_Night_Mode, 'Night ', ''),
        CONCAT(
            SEL(GVL_INTENT_BEHAVIOR.I_Request_Ventilation_Boost, 'VentBoost ', ''),
            SEL(GVL_INTENT_BEHAVIOR.I_Request_Access_Secure_Mode, 'AccessSecure ', '')
        )
    )
);

GVL_INTENT_BEHAVIOR.I_Reason_Text := GVL_INTENT_BEHAVIOR.I_Selected_Scenario_Text;
GVL_INTENT_BEHAVIOR.I_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;

// >>> BULK_SYNC_ANCHOR: PRG_Scenario_Engine <<<
