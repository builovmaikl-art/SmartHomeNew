FUNCTION_BLOCK FB_Heating_Policy_Manager
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_System_Mode : E_System_Operating_Mode;
    VI_RootCause : E_Heating_RootCause;
    VI_RootConfidence : REAL;
    VI_Min_Hold_MS : UDINT;
    VI_Emergency_Stop : BOOL;
    VI_Gas_Safety : BOOL;
    VI_Room_Temp_Avg : REAL;
    VI_Floor_Temp_Avg : REAL;
    VI_Supply_Temp : REAL;
    VI_Return_Temp : REAL;
    VI_Target_Temp : REAL;
    VI_Room_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF REAL;
    VI_Floor_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF REAL;
END_VAR

VAR_OUTPUT
    VO_Policy_Mode : E_Heating_Policy_Mode;
    VO_Block_Heating : BOOL;
    VO_Target_Adjustment : REAL;
    VO_Priority_Multiplier : REAL;
    VO_Self_Tune_Active : BOOL;
    VO_Self_Tune_Level : INT;
    VO_Feedback_Stable : BOOL;
    VO_Feedback_Improving : BOOL;
    VO_Feedback_Quality : REAL;
END_VAR

VAR
    L_Raw_Mode : E_Heating_Policy_Mode;
    L_Raw_Block : BOOL;
    L_Raw_Target_Adjustment : REAL;
    L_Raw_Priority_Multiplier : REAL;
    L_Held_Mode : E_Heating_Policy_Mode;
    L_Held_Block : BOOL;
    L_Held_Target_Adjustment : REAL;
    L_Held_Priority_Multiplier : REAL;
    L_Last_Accept_MS : UDINT;
    L_Initialized : BOOL;
    L_Effective_Hold_MS : UDINT;
    L_Force_Immediate : BOOL;
    L_Same_Cause_Since : UDINT;
    L_Last_Cause : E_Heating_RootCause;
    L_Self_Level : INT;
    L_Room_Error : REAL;
    L_Supply_Error : REAL;
    L_DeltaT : REAL;
    L_Quality : REAL;
    L_Last_Quality : REAL;
    L_Improving : BOOL;
    L_Stable : BOOL;
    L_Last_Room_Avg : REAL;
    L_Trend : REAL;
    L_Predictive_Adjustment : REAL;
    L_i : INT;
    L_Zone_Error : REAL;
    L_Zone_Quality : REAL;
END_VAR

// --- predictive trend ---
L_Trend := VI_Room_Temp_Avg - L_Last_Room_Avg;
L_Last_Room_Avg := VI_Room_Temp_Avg;

L_Predictive_Adjustment := 0.0;

IF (L_Trend < -0.05) AND (VI_Room_Temp_Avg < VI_Target_Temp + 0.5) THEN
    L_Predictive_Adjustment := 1.0;
ELSIF (L_Trend > 0.05) THEN
    L_Predictive_Adjustment := -0.5;
END_IF;

// clamp predictive
IF L_Predictive_Adjustment > 1.0 THEN L_Predictive_Adjustment := 1.0; END_IF;
IF L_Predictive_Adjustment < -1.0 THEN L_Predictive_Adjustment := -1.0; END_IF;

L_Raw_Mode := E_Heating_Policy_Mode.HPM_NORMAL;
L_Raw_Block := FALSE;
L_Raw_Target_Adjustment := L_Predictive_Adjustment;
L_Raw_Priority_Multiplier := 1.0;
L_Force_Immediate := FALSE;

// --- feedback metrics ---
L_Room_Error := VI_Target_Temp - VI_Room_Temp_Avg;
L_Supply_Error := VI_Target_Temp - VI_Supply_Temp;
L_DeltaT := VI_Supply_Temp - VI_Return_Temp;

L_Quality := 0.0;
IF L_Room_Error > 1.0 THEN L_Quality := L_Quality + 2.0; END_IF;
IF L_Supply_Error > 1.0 THEN L_Quality := L_Quality + 1.0; END_IF;
IF L_DeltaT < 3.0 THEN L_Quality := L_Quality + 1.0; END_IF;

L_Improving := L_Quality < L_Last_Quality;
L_Stable := L_Quality = 0.0;

// --- zone-level feedback ---
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    L_Zone_Error := VI_Target_Temp - VI_Room_Temps[L_i];
    L_Zone_Quality := 0.0;

    IF L_Zone_Error > 1.0 THEN
        L_Zone_Quality := L_Zone_Quality + 2.0;
    END_IF;

    IF VI_Floor_Temps[L_i] < (VI_Target_Temp - 2.0) THEN
        L_Zone_Quality := L_Zone_Quality + 1.0;
    END_IF;

    GVL_HEATING_POLICY.G_Zone_Improving[L_i] := (L_Zone_Quality < GVL_HEATING_POLICY.G_Zone_Quality[L_i]);
    GVL_HEATING_POLICY.G_Zone_Stable[L_i] := (L_Zone_Quality = 0.0);

    IF GVL_HEATING_POLICY.G_Zone_Stable[L_i] THEN
        GVL_HEATING_POLICY.G_Zone_Self_Level[L_i] := 0;
    ELSIF GVL_HEATING_POLICY.G_Zone_Improving[L_i] THEN
        GVL_HEATING_POLICY.G_Zone_Self_Level[L_i] := GVL_HEATING_POLICY.G_Zone_Self_Level[L_i] - 1;
    ELSIF L_Zone_Quality >= 3.0 THEN
        GVL_HEATING_POLICY.G_Zone_Self_Level[L_i] := GVL_HEATING_POLICY.G_Zone_Self_Level[L_i] + 1;
    END_IF;

    IF GVL_HEATING_POLICY.G_Zone_Self_Level[L_i] > 2 THEN
        GVL_HEATING_POLICY.G_Zone_Self_Level[L_i] := 2;
    END_IF;

    IF GVL_HEATING_POLICY.G_Zone_Self_Level[L_i] < 0 THEN
        GVL_HEATING_POLICY.G_Zone_Self_Level[L_i] := 0;
    END_IF;

    GVL_HEATING_POLICY.G_Zone_Quality[L_i] := L_Zone_Quality;
END_FOR;

VO_Target_Adjustment := L_Held_Target_Adjustment;
VO_Feedback_Stable := L_Stable;
VO_Feedback_Improving := L_Improving;
VO_Feedback_Quality := L_Quality;

L_Last_Quality := L_Quality;

END_FUNCTION_BLOCK
