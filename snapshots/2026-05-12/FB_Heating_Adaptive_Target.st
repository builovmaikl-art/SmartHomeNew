// ==============================================================================
// Adaptive target calculation for heating supply temperature
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Adaptive_Target
VAR_INPUT
    VI_Base_Target_Supply_Temp : REAL;
    VI_Global_Target_Temperature : REAL;
END_VAR

VAR_IN_OUT
    VI_Zone_Configs : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF ST_FloorHeating_Circuit_Config;
    VI_Floor_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF REAL;
    VI_Room_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF REAL;
END_VAR

VAR_OUTPUT
    VO_Target_Supply_Temp : REAL;
    VO_Adaptive_Correction : REAL;
    VO_Adaptive_Effective_Delta : REAL;
    VO_Adaptive_Max_Delta : REAL;
END_VAR

VAR
    L_Adaptive_Zone_i : INT;
    L_Zone_Index : INT;
    L_Adaptive_Delta : REAL;
    L_Adaptive_Weighted_Sum : REAL;
    L_Adaptive_Weight_Total : REAL;
    L_Adaptive_Weight : REAL;
END_VAR

VO_Target_Supply_Temp := VI_Base_Target_Supply_Temp;
VO_Adaptive_Max_Delta := 0.0;
L_Adaptive_Weighted_Sum := 0.0;
L_Adaptive_Weight_Total := 0.0;
VO_Adaptive_Effective_Delta := 0.0;
VO_Adaptive_Correction := 0.0;

IF VI_Global_Target_Temperature > 0.0 THEN
    VO_Target_Supply_Temp := VI_Global_Target_Temperature;
END_IF;

FOR L_Adaptive_Zone_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    L_Zone_Index := VI_Zone_Configs[L_Adaptive_Zone_i].zone;

    IF (L_Zone_Index >= 1) AND (L_Zone_Index <= GVL_CONSTANTS.C_MAX_ZONES) THEN
        CASE VI_Zone_Configs[L_Adaptive_Zone_i].control_type OF
            0:
                L_Adaptive_Delta :=
                    VI_Zone_Configs[L_Adaptive_Zone_i].design_temp -
                    VI_Floor_Temps[L_Adaptive_Zone_i];
                L_Adaptive_Weight := 0.6;
            1, 2:
                L_Adaptive_Delta :=
                    VI_Zone_Configs[L_Adaptive_Zone_i].design_temp -
                    VI_Room_Temps[L_Zone_Index];
                L_Adaptive_Weight := 1.0;
            ELSE
                L_Adaptive_Delta :=
                    VI_Zone_Configs[L_Adaptive_Zone_i].design_temp -
                    VI_Room_Temps[L_Zone_Index];
                L_Adaptive_Weight := 0.8;
        END_CASE;

        IF L_Zone_Index <= 4 THEN
            L_Adaptive_Weight := L_Adaptive_Weight * 1.2;
        ELSIF L_Zone_Index >= 9 THEN
            L_Adaptive_Weight := L_Adaptive_Weight * 0.7;
        END_IF;

        IF L_Adaptive_Weight > 2.0 THEN
            L_Adaptive_Weight := 2.0;
        ELSIF L_Adaptive_Weight < 0.2 THEN
            L_Adaptive_Weight := 0.2;
        END_IF;

        IF L_Adaptive_Delta > VO_Adaptive_Max_Delta THEN
            VO_Adaptive_Max_Delta := L_Adaptive_Delta;
        END_IF;

        L_Adaptive_Weighted_Sum := L_Adaptive_Weighted_Sum + (L_Adaptive_Delta * L_Adaptive_Weight);
        L_Adaptive_Weight_Total := L_Adaptive_Weight_Total + L_Adaptive_Weight;
    END_IF;
END_FOR;

IF L_Adaptive_Weight_Total > 0.0 THEN
    VO_Adaptive_Effective_Delta := L_Adaptive_Weighted_Sum / L_Adaptive_Weight_Total;
END_IF;

IF VO_Adaptive_Effective_Delta > 1.5 THEN
    VO_Adaptive_Correction := 2.0;
ELSIF VO_Adaptive_Effective_Delta > 0.7 THEN
    VO_Adaptive_Correction := 1.0;
ELSIF VO_Adaptive_Effective_Delta < -1.5 THEN
    VO_Adaptive_Correction := -2.0;
ELSIF VO_Adaptive_Effective_Delta < -0.7 THEN
    VO_Adaptive_Correction := -1.0;
ELSE
    VO_Adaptive_Correction := 0.0;
END_IF;

IF VO_Adaptive_Max_Delta > 2.5 AND VO_Adaptive_Correction < 2.0 THEN
    VO_Adaptive_Correction := 2.0;
END_IF;

VO_Target_Supply_Temp := VO_Target_Supply_Temp + VO_Adaptive_Correction;

IF VO_Target_Supply_Temp < 20.0 THEN
    VO_Target_Supply_Temp := 20.0;
ELSIF VO_Target_Supply_Temp > 45.0 THEN
    VO_Target_Supply_Temp := 45.0;
END_IF;

// >>> BULK_SYNC_ANCHOR: FB_Heating_Adaptive_Target <<<
END_FUNCTION_BLOCK
