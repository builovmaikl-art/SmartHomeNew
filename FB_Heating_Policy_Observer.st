FUNCTION_BLOCK FB_Heating_Policy_Observer

VAR_INPUT
    VI_Zone_Occupied : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF BOOL;
    VI_Zone_Last_Motion_TS : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF UDINT;
    VI_System_Time_MS : UDINT;
    VI_Zone_Permanent_Use : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF BOOL;
    VI_Zone_Guest_Preheat : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF BOOL;
END_VAR

VAR_OUTPUT
    VO_Zone_Empty_Duration_MS : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF UDINT;
    VO_Zone_Policy_Class : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF INT;
    VO_Zone_Target_Adjustment : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF REAL;
    VO_Zone_Priority_Bias : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF REAL;
END_VAR

VAR
    L_i : INT;
    L_Long_Threshold : UDINT := 86400000; // 24h
END_VAR

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO

    // compute empty duration
    IF VI_Zone_Occupied[L_i] THEN
        VO_Zone_Empty_Duration_MS[L_i] := 0;
    ELSE
        VO_Zone_Empty_Duration_MS[L_i] := VI_System_Time_MS - VI_Zone_Last_Motion_TS[L_i];
    END_IF;

    // policy classification
    IF VI_Zone_Guest_Preheat[L_i] THEN
        VO_Zone_Policy_Class[L_i] := 3; // guest

    ELSIF VI_Zone_Occupied[L_i] THEN
        VO_Zone_Policy_Class[L_i] := 0; // comfort

    ELSIF VI_Zone_Permanent_Use[L_i] THEN
        VO_Zone_Policy_Class[L_i] := 4; // permanent mild eco

    ELSIF VO_Zone_Empty_Duration_MS[L_i] >= L_Long_Threshold THEN
        VO_Zone_Policy_Class[L_i] := 2; // deep eco

    ELSE
        VO_Zone_Policy_Class[L_i] := 1; // mild eco
    END_IF;

    // observe-only target adjustment (no effect yet)
    CASE VO_Zone_Policy_Class[L_i] OF
        0: // comfort
            VO_Zone_Target_Adjustment[L_i] := 0.0;
            VO_Zone_Priority_Bias[L_i] := 1.0;

        1: // mild eco
            VO_Zone_Target_Adjustment[L_i] := -1.0;
            VO_Zone_Priority_Bias[L_i] := 0.8;

        2: // deep eco
            VO_Zone_Target_Adjustment[L_i] := -3.0;
            VO_Zone_Priority_Bias[L_i] := 0.5;

        3: // guest preheat
            VO_Zone_Target_Adjustment[L_i] := 0.0;
            VO_Zone_Priority_Bias[L_i] := 1.5;

        4: // permanent-use mild eco
            VO_Zone_Target_Adjustment[L_i] := -0.5;
            VO_Zone_Priority_Bias[L_i] := 0.9;

    END_CASE;

END_FOR;
