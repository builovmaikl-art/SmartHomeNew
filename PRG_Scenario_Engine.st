PROGRAM PRG_Scenario_Engine
VAR
    L_Hour : INT;
    L_BestScore : INT;
    L_Selected : E_System_Reason_Code;
    L_MaxHum : REAL;
    L_i : INT;
END_VAR

// Time
L_Hour := TO_INT(GVL_TIME_SERVICE.G_Time_Of_Day_MS / 3600000);

// Reset intent
GVL_INTENT_BEHAVIOR.I_Request_Night_Mode := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Away_Mode := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Comfort_Mode := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Energy_Save_Mode := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Preheat := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Ventilation_Boost := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Access_Secure_Mode := FALSE;

// Reset scores
GVL_INTENT_BEHAVIOR.I_Score_Comfort := 10;
GVL_INTENT_BEHAVIOR.I_Score_Night := 0;
GVL_INTENT_BEHAVIOR.I_Score_Energy_Save := 0;
GVL_INTENT_BEHAVIOR.I_Score_Preheat := 0;
GVL_INTENT_BEHAVIOR.I_Score_Vent_Boost := 0;
GVL_INTENT_BEHAVIOR.I_Score_Access_Secure := 0;

// Night scenario
IF (L_Hour >= 22) OR (L_Hour < 6) THEN
    GVL_INTENT_BEHAVIOR.I_Score_Night := 40;
END_IF;

// Preheat (based on system state request)
IF GVL_STATE.G_Preheat_Request THEN
    GVL_INTENT_BEHAVIOR.I_Score_Preheat := 50;
END_IF;

// Ventilation boost (humidity-driven)
L_MaxHum := 0.0;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    IF GVL_STATE.G_Room_Hum[L_i] > L_MaxHum THEN
        L_MaxHum := GVL_STATE.G_Room_Hum[L_i];
    END_IF;
END_FOR;

IF L_MaxHum > 65.0 THEN
    GVL_INTENT_BEHAVIOR.I_Score_Vent_Boost := 45;
END_IF;

// Access secure (night-based)
IF (L_Hour >= 23) OR (L_Hour < 5) THEN
    GVL_INTENT_BEHAVIOR.I_Score_Access_Secure := 30;
END_IF;

// Select best scenario
L_BestScore := 0;
L_Selected := REASON_NONE;

IF GVL_INTENT_BEHAVIOR.I_Score_Preheat > L_BestScore THEN
    L_BestScore := GVL_INTENT_BEHAVIOR.I_Score_Preheat;
    L_Selected := REASON_SCENARIO_COMFORT;
END_IF;

IF GVL_INTENT_BEHAVIOR.I_Score_Vent_Boost > L_BestScore THEN
    L_BestScore := GVL_INTENT_BEHAVIOR.I_Score_Vent_Boost;
    L_Selected := REASON_SCENARIO_VENT_BOOST;
END_IF;

IF GVL_INTENT_BEHAVIOR.I_Score_Night > L_BestScore THEN
    L_BestScore := GVL_INTENT_BEHAVIOR.I_Score_Night;
    L_Selected := REASON_SCENARIO_NIGHT;
END_IF;

IF GVL_INTENT_BEHAVIOR.I_Score_Access_Secure > L_BestScore THEN
    L_BestScore := GVL_INTENT_BEHAVIOR.I_Score_Access_Secure;
    L_Selected := REASON_SCENARIO_ACCESS_SECURE;
END_IF;

IF GVL_INTENT_BEHAVIOR.I_Score_Comfort > L_BestScore THEN
    L_BestScore := GVL_INTENT_BEHAVIOR.I_Score_Comfort;
    L_Selected := REASON_SCENARIO_COMFORT;
END_IF;

// Apply selected scenario
GVL_INTENT_BEHAVIOR.I_Behavior_Priority := L_BestScore;
GVL_INTENT_BEHAVIOR.I_Selected_Scenario_Code := L_Selected;

CASE L_Selected OF
    REASON_SCENARIO_NIGHT:
        GVL_INTENT_BEHAVIOR.I_Request_Night_Mode := TRUE;
        GVL_INTENT_BEHAVIOR.I_Request_Comfort_Mode := TRUE;
        GVL_INTENT_BEHAVIOR.I_Selected_Scenario_Text := 'Night scenario active';

    REASON_SCENARIO_COMFORT:
        GVL_INTENT_BEHAVIOR.I_Request_Comfort_Mode := TRUE;
        GVL_INTENT_BEHAVIOR.I_Selected_Scenario_Text := 'Comfort scenario active';

    REASON_SCENARIO_VENT_BOOST:
        GVL_INTENT_BEHAVIOR.I_Request_Ventilation_Boost := TRUE;
        GVL_INTENT_BEHAVIOR.I_Selected_Scenario_Text := 'Ventilation boost scenario active';

    REASON_SCENARIO_ACCESS_SECURE:
        GVL_INTENT_BEHAVIOR.I_Request_Access_Secure_Mode := TRUE;
        GVL_INTENT_BEHAVIOR.I_Selected_Scenario_Text := 'Access secure scenario active';

ELSE
    GVL_INTENT_BEHAVIOR.I_Request_Comfort_Mode := TRUE;
    GVL_INTENT_BEHAVIOR.I_Selected_Scenario_Text := 'Fallback comfort scenario';
END_CASE;

GVL_INTENT_BEHAVIOR.I_Reason_Code := L_Selected;
GVL_INTENT_BEHAVIOR.I_Reason_Text := GVL_INTENT_BEHAVIOR.I_Selected_Scenario_Text;
GVL_INTENT_BEHAVIOR.I_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;

// >>> BULK_SYNC_ANCHOR: PRG_Scenario_Engine <<<
