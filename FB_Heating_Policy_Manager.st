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
    L_Room_Error : REAL;
    L_Supply_Error : REAL;
    L_DeltaT : REAL;
    L_Quality : REAL;
    L_Last_Quality : REAL;
    L_Improving : BOOL;
    L_Stable : BOOL;
    L_Self_Level : INT;
END_VAR

// --- feedback metrics ---
L_Room_Error := VI_Target_Temp - VI_Room_Temp_Avg;
L_Supply_Error := VI_Target_Temp - VI_Supply_Temp;
L_DeltaT := VI_Supply_Temp - VI_Return_Temp;

L_Quality := 0.0;
IF L_Room_Error > 1.0 THEN L_Quality := L_Quality + 2.0; END_IF;
IF L_Supply_Error > 1.0 THEN L_Quality := L_Quality + 1.0; END_IF;
IF L_DeltaT < 3.0 THEN L_Quality := L_Quality + 1.0; END_IF;

// --- feedback evaluation ---
L_Improving := L_Quality < L_Last_Quality;
L_Stable := L_Quality = 0.0;

// --- self tuning with feedback ---
IF NOT L_Stable THEN
    IF NOT L_Improving AND L_Quality >= 3.0 THEN
        L_Self_Level := L_Self_Level + 1;
    ELSIF L_Improving THEN
        L_Self_Level := L_Self_Level - 1;
    END_IF;
ELSE
    L_Self_Level := 0;
END_IF;

IF L_Self_Level > 2 THEN L_Self_Level := 2; END_IF;
IF L_Self_Level < 0 THEN L_Self_Level := 0; END_IF;

// --- apply effect ---
VO_Target_Adjustment := REAL(L_Self_Level) + 3.0;
VO_Priority_Multiplier := 1.0 - (0.2 * REAL(L_Self_Level));

// --- outputs ---
VO_Self_Tune_Level := L_Self_Level;
VO_Self_Tune_Active := (L_Self_Level > 0);
VO_Feedback_Stable := L_Stable;
VO_Feedback_Improving := L_Improving;
VO_Feedback_Quality := L_Quality;

L_Last_Quality := L_Quality;

END_FUNCTION_BLOCK
