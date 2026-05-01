PROGRAM PRG_Scenario_Engine
VAR
    L_Hour : INT;
    L_Hum : REAL;
    L_ZoneWeight : REAL;
    L_ZoneConfidence : REAL;
    L_ZoneScore : REAL;
    L_BestVentScore : REAL;
    L_BestVentZone : INT;
    L_i : INT;
    fbTrace : FB_Trace_Write;
END_VAR

L_Hour := TO_INT(GVL_TIME_SERVICE.G_Time_Of_Day_MS / 3600000);

GVL_INTENT_BEHAVIOR.I_Request_Night_Mode := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Comfort_Mode := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Ventilation_Boost := FALSE;
GVL_INTENT_BEHAVIOR.I_Request_Access_Secure_Mode := FALSE;

GVL_INTENT_BEHAVIOR.I_Score_Comfort := REAL_TO_INT(10.0 * GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_Comfort);
GVL_INTENT_BEHAVIOR.I_Score_Night := 0;
GVL_INTENT_BEHAVIOR.I_Score_Preheat := 0;
GVL_INTENT_BEHAVIOR.I_Score_Vent_Boost := 0;
GVL_INTENT_BEHAVIOR.I_Score_Access_Secure := 0;

IF (L_Hour >= 22) OR (L_Hour < 6) THEN
    GVL_INTENT_BEHAVIOR.I_Score_Night := REAL_TO_INT(40.0 * GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_Night);
END_IF;

IF GVL_INPUT.I_Preheat_Request THEN
    GVL_INTENT_BEHAVIOR.I_Score_Preheat := REAL_TO_INT(50.0 * GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_Preheat);
END_IF;

L_BestVentScore := 0.0;
L_BestVentZone := 0;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    L_Hum := GVL_INPUT.I_Room_Humidity[L_i];

    IF GVL_BEHAVIOR_ADAPT.G_VentBoost_Zone_Adapt[L_i].Zone_Weight = 0.0 THEN
        L_ZoneWeight := GVL_BEHAVIOR_ADAPT.G_Adapt_Default_Zone_Weight;
    ELSE
        L_ZoneWeight := GVL_BEHAVIOR_ADAPT.G_VentBoost_Zone_Adapt[L_i].Zone_Weight;
    END_IF;

    L_ZoneConfidence := GVL_BEHAVIOR_ADAPT.G_VentBoost_Zone_Adapt[L_i].Confidence;
    IF L_ZoneConfidence <= 0.0 THEN
        L_ZoneConfidence := 0.5;
    END_IF;

    IF L_Hum > 65.0 THEN
        L_ZoneScore := 45.0 * GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_VentBoost * L_ZoneWeight * L_ZoneConfidence;

        IF L_ZoneScore > L_BestVentScore THEN
            L_BestVentScore := L_ZoneScore;
            L_BestVentZone := L_i;
        END_IF;
    END_IF;
END_FOR;

GVL_INTENT_BEHAVIOR.I_Score_Vent_Boost := REAL_TO_INT(L_BestVentScore);

IF (L_Hour >= 23) OR (L_Hour < 5) THEN
    GVL_INTENT_BEHAVIOR.I_Score_Access_Secure := REAL_TO_INT(30.0 * GVL_BEHAVIOR_ADAPT.G_Behavior_Weights.W_AccessSecure);
END_IF;

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

GVL_INTENT_BEHAVIOR.I_Request_Comfort_Mode := TRUE;

GVL_INTENT_BEHAVIOR.I_Selected_Scenario_Text := 'Updated via INPUT';
GVL_INTENT_BEHAVIOR.I_Reason_Text := GVL_INTENT_BEHAVIOR.I_Selected_Scenario_Text;
GVL_INTENT_BEHAVIOR.I_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;

fbTrace(iLayer:=TRACE_SCENARIO,iSource:=SRC_SCENARIO,iReason:=REASON_SCENARIO_VENT_BOOST,iValueBool:=GVL_INTENT_BEHAVIOR.I_Request_Ventilation_Boost,iValueReal:=TO_REAL(GVL_INTENT_BEHAVIOR.I_Score_Vent_Boost),iText:=GVL_INTENT_BEHAVIOR.I_Selected_Scenario_Text);
