PROGRAM PRG_Scenario_Engine
VAR
    L_Hour : INT;
    L_Hum : REAL;
    L_ZoneWeight : REAL;
    L_AdaptConfidence : REAL;
    L_InputConfidence : REAL;
    L_ZoneConfidence : REAL;
    L_ZoneScore : REAL;
    L_BestVentScore : REAL;
    L_BestVentZone : INT;
    L_i : INT;
    fbTrace : FB_Trace_Write;
END_VAR

L_Hour := TO_INT(GVL_TIME_SERVICE.G_Time_Of_Day_MS / 3600000);

// Reset
GVL_INTENT_BEHAVIOR.I_Request_Night_Mode := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Comfort_Mode := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Ventilation_Boost := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Access_Secure_Mode := FALSE;

GVL_INTENT_BEHAVIOR.I_Score_Comfort := REAL_TO_INT(10.0 * GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_Comfort);
GVL_INTENT_BEHAVIOR.I_Score_Night := 0;
GVL_INTENT_BEHAVIOR.I_Score_Preheat := 0;
GVL_INTENT_BEHAVIOR.I_Score_Vent_Boost := 0;
GVL_INTENT_BEHAVIOR.I_Score_Access_Secure := 0;

// Night
IF (L_Hour >= 22) OR (L_Hour < 6) THEN
    GVL_INTENT_BEHAVIOR.I_Score_Night := REAL_TO_INT(40.0 * GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_Night);
END_IF;

// Preheat
IF GVL_INPUT.IN_Preheat_Request THEN
    GVL_INTENT_BEHAVIOR.I_Score_Preheat := REAL_TO_INT(50.0 * GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_Preheat);
END_IF;

// Vent boost (zone-aware + sensor-confidence-aware)
L_BestVentScore := 0.0;
L_BestVentZone := 0;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    L_Hum := GVL_INPUT.IN_Room_Hum[L_i];

    IF GVL_BEHAVIOR_ADAPT.G_VentBoost_Zone_Adapt[L_i].Zone_Weight = 0.0 THEN
        L_ZoneWeight := GVL_BEHAVIOR_ADAPT.G_Adapt_Default_Zone_Weight;
    ELSE
        L_ZoneWeight := GVL_BEHAVIOR_ADAPT.G_VentBoost_Zone_Adapt[L_i].Zone_Weight;
    END_IF;

    L_AdaptConfidence := GVL_BEHAVIOR_ADAPT.G_VentBoost_Zone_Adapt[L_i].Confidence;
    IF L_AdaptConfidence <= 0.0 THEN
        L_AdaptConfidence := 0.5;
    END_IF;

    L_InputConfidence := GVL_INPUT.IN_Zone_Confidence[L_i];
    IF L_InputConfidence <= 0.0 THEN
        L_InputConfidence := 0.5;
    END_IF;

    L_ZoneConfidence := L_AdaptConfidence * L_InputConfidence;

    IF L_Hum > 65.0 THEN
        L_ZoneScore := 45.0 * GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_VentBoost * L_ZoneWeight * L_ZoneConfidence;

        IF L_ZoneScore > L_BestVentScore THEN
            L_BestVentScore := L_ZoneScore;
            L_BestVentZone := L_i;
        END_IF;
    END_IF;
END_FOR;

GVL_INTENT_BEHAVIOR.I_Score_Vent_Boost := REAL_TO_INT(L_BestVentScore);
GVL_INTENT_BEHAVIOR.I_Best_VentBoost_Zone := L_BestVentZone;

// Access secure
IF (L_Hour >= 23) OR (L_Hour < 5) THEN
    GVL_INTENT_BEHAVIOR.I_Score_Access_Secure := REAL_TO_INT(30.0 * GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_AccessSecure);
END_IF;

// Activate flags
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

// Multi-objective weights
GVL_INTENT_BEHAVIOR.I_Weight_Night := TO_REAL(GVL_INTENT_BEHAVIOR.I_Score_Night) / 100.0;
GVL_INTENT_BEHAVIOR.I_Weight_Comfort := TO_REAL(GVL_INTENT_BEHAVIOR.I_Score_Comfort) / 100.0;
GVL_INTENT_BEHAVIOR.I_Weight_Vent_Boost := TO_REAL(GVL_INTENT_BEHAVIOR.I_Score_Vent_Boost) / 100.0;
GVL_INTENT_BEHAVIOR.I_Weight_Access_Secure := TO_REAL(GVL_INTENT_BEHAVIOR.I_Score_Access_Secure) / 100.0;

// Scenario text (NO STUB)
IF GVL_INTENT_BEHAVIOR.I_Request_Night_Mode THEN
    GVL_INTENT_BEHAVIOR.I_Selected_Scenario_Text := 'Night mode';
ELSIF GVL_INTENT_BEHAVIOR.I_Request_Ventilation_Boost THEN
    GVL_INTENT_BEHAVIOR.I_Selected_Scenario_Text := 'Vent Boost';
ELSIF GVL_INTENT_BEHAVIOR.I_Request_Comfort_Mode THEN
    GVL_INTENT_BEHAVIOR.I_Selected_Scenario_Text := 'Comfort';
ELSIF GVL_INTENT_BEHAVIOR.I_Request_Access_Secure_Mode THEN
    GVL_INTENT_BEHAVIOR.I_Selected_Scenario_Text := 'Access Secure';
ELSE
    GVL_INTENT_BEHAVIOR.I_Selected_Scenario_Text := 'Idle';
END_IF;

GVL_INTENT_BEHAVIOR.I_Reason_Text := GVL_INTENT_BEHAVIOR.I_Selected_Scenario_Text;
GVL_INTENT_BEHAVIOR.I_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;

fbTrace(iLayer:=TRACE_SCENARIO,iSource:=SRC_SCENARIO,iReason:=REASON_SCENARIO_VENT_BOOST,iValueBool:=GVL_INTENT_BEHAVIOR.I_Request_Ventilation_Boost,iValueReal:=TO_REAL(GVL_INTENT_BEHAVIOR.I_Score_Vent_Boost),iText:=GVL_INTENT_BEHAVIOR.I_Selected_Scenario_Text);
