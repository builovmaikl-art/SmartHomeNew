FUNCTION_BLOCK FB_Heating_Schedule_Preheat
VAR_INPUT
    VI_Time_Of_Day_MS : UDINT;
    VI_Enable : BOOL;
END_VAR

VAR
    L_i : INT;
    L_Time_To_Comfort_MS : UDINT;
    L_Adjustment : REAL;
END_VAR

IF NOT VI_Enable THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
        GVL_HEATING_POLICY.G_Zone_Schedule_Preheat_Active[L_i] := FALSE;
    END_FOR;
    RETURN;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    IF GVL_HEATING_POLICY.G_Zone_Schedule_Enabled[L_i] THEN
        IF GVL_HEATING_POLICY.G_Zone_Comfort_Time_MS[L_i] >= VI_Time_Of_Day_MS THEN
            L_Time_To_Comfort_MS := GVL_HEATING_POLICY.G_Zone_Comfort_Time_MS[L_i] - VI_Time_Of_Day_MS;
        ELSE
            L_Time_To_Comfort_MS := (86400000 - VI_Time_Of_Day_MS) + GVL_HEATING_POLICY.G_Zone_Comfort_Time_MS[L_i];
        END_IF;

        GVL_HEATING_POLICY.G_Zone_Schedule_Preheat_Active[L_i] :=
            (GVL_HEATING_POLICY.G_Zone_Time_To_Heat_MS[L_i] >= L_Time_To_Comfort_MS)
            AND (GVL_HEATING_POLICY.G_Zone_Time_To_Heat_MS[L_i] > 0);
    ELSE
        GVL_HEATING_POLICY.G_Zone_Schedule_Preheat_Active[L_i] := FALSE;
    END_IF;

    L_Adjustment := GVL_HEATING_POLICY.G_Zone_Target_Adjustment[L_i];
    IF GVL_HEATING_POLICY.G_Zone_Schedule_Preheat_Active[L_i] THEN
        L_Adjustment := L_Adjustment + 0.5;
    END_IF;

    IF L_Adjustment > 1.0 THEN
        L_Adjustment := 1.0;
    ELSIF L_Adjustment < -1.0 THEN
        L_Adjustment := -1.0;
    END_IF;

    GVL_HEATING_POLICY.G_Zone_Target_Adjustment[L_i] := L_Adjustment;
END_FOR;

END_FUNCTION_BLOCK
