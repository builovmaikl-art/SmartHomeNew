FUNCTION_BLOCK FB_Heating_Schedule_Preheat
VAR_INPUT
    VI_Time_Of_Day_MS : UDINT;
    VI_Day_Of_Week : INT; // 1=Mon ... 7=Sun
    VI_Enable : BOOL;
END_VAR

VAR
    L_i : INT;
    L_e : INT;
    L_Event : ST_Heating_Schedule_Event;
    L_Time_To_Comfort_MS : UDINT;
    L_Adjustment : REAL;
    L_Max_Boost : REAL;
    L_Active : BOOL;
END_VAR

IF NOT VI_Enable THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
        GVL_HEATING_POLICY.G_Zone_Schedule_Preheat_Active[L_i] := FALSE;
    END_FOR;
    RETURN;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    L_Active := FALSE;
    L_Max_Boost := 0.0;

    FOR L_e := 1 TO 3 DO
        L_Event := GVL_HEATING_POLICY_CONFIG.G_Zone_Schedule[L_i, L_e];

        IF L_Event.Enabled THEN
            IF (L_Event.Weekday_Mask AND SHL(1, VI_Day_Of_Week - 1)) <> 0 THEN

                IF L_Event.Comfort_Time_MS >= VI_Time_Of_Day_MS THEN
                    L_Time_To_Comfort_MS := L_Event.Comfort_Time_MS - VI_Time_Of_Day_MS;
                ELSE
                    L_Time_To_Comfort_MS := (86400000 - VI_Time_Of_Day_MS) + L_Event.Comfort_Time_MS;
                END_IF;

                IF (GVL_HEATING_POLICY.G_Zone_Time_To_Heat_MS[L_i] >= L_Time_To_Comfort_MS)
                   AND (GVL_HEATING_POLICY.G_Zone_Time_To_Heat_MS[L_i] > 0) THEN

                    IF L_Event.Preheat_Boost > L_Max_Boost THEN
                        L_Max_Boost := L_Event.Preheat_Boost;
                    END_IF;

                    L_Active := TRUE;
                END_IF;
            END_IF;
        END_IF;
    END_FOR;

    L_Adjustment := GVL_HEATING_POLICY.G_Zone_Target_Adjustment[L_i];

    // Smart blend: schedule does not stack on top of policy; it enforces at least the selected boost.
    IF L_Active AND (L_Adjustment < L_Max_Boost) THEN
        L_Adjustment := L_Max_Boost;
    END_IF;

    IF L_Adjustment > 1.0 THEN
        L_Adjustment := 1.0;
    ELSIF L_Adjustment < -1.0 THEN
        L_Adjustment := -1.0;
    END_IF;

    GVL_HEATING_POLICY.G_Zone_Target_Adjustment[L_i] := L_Adjustment;
    GVL_HEATING_POLICY.G_Zone_Schedule_Preheat_Active[L_i] := L_Active;
END_FOR;

END_FUNCTION_BLOCK
