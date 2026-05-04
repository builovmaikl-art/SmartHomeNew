FUNCTION_BLOCK FB_Rule_Engine
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_IsActivePLC : BOOL;
    VI_Security_Armed : BOOL;
    VI_Current_Time : TOD;
    VI_Day_Of_Week : INT;
END_VAR
VAR_IN_OUT
    VI_Rules : ARRAY[1..GVL_CONSTANTS.C_MAX_RULES] OF ST_User_Rule;
    VI_Indoor_Temps : ARRAY[1..16] OF REAL;
    VI_Floor_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF REAL;
    VI_Humidities : ARRAY[1..16] OF REAL;
    VI_CO2_Levels : ARRAY[1..16] OF REAL;
    VI_Motion_Sensors : ARRAY[1..16] OF BOOL;
    VI_Door_Sensors : ARRAY[1..GVL_CONSTANTS.C_MAX_DOOR_SENSORS] OF BOOL;
    VI_Window_Sensors : ARRAY[1..16] OF BOOL;
    VI_Water_Sensors : ARRAY[1..GVL_CONSTANTS.C_MAX_FLOOD_SENSORS] OF BOOL;
    VI_Smoke_Sensors : ARRAY[1..GVL_CONSTANTS.C_MAX_SMOKE_SENSORS] OF BOOL;
    VI_Methane_Sensors : ARRAY[1..GVL_CONSTANTS.C_MAX_METHANE_SENSORS] OF REAL;
    VI_CO_Sensors : ARRAY[1..GVL_CONSTANTS.C_MAX_CO_SENSORS] OF REAL;
END_VAR
VAR_OUTPUT
    VO_Preheat_Request : BOOL;
    VO_Actions : ARRAY[1..GVL_CONSTANTS.C_MAX_RULES] OF ST_Rule_Action;
END_VAR
VAR
    L_i : INT;
    L_Condition_Met : BOOL;
    L_Current_Value : REAL;
    L_Triggers : ARRAY[1..GVL_CONSTANTS.C_MAX_RULES] OF R_TRIG;
    L_Trigger_Count : ARRAY[1..GVL_CONSTANTS.C_MAX_RULES] OF UINT;
    L_Last_Reset_Time : UDINT;
    L_Elapsed_Time : UDINT;
END_VAR

IF NOT VI_IsActivePLC THEN RETURN; END_IF;

VO_Preheat_Request := FALSE;

L_Elapsed_Time := SEL(VI_System_Time_MS >= L_Last_Reset_Time, VI_System_Time_MS - L_Last_Reset_Time, (4294967295 - L_Last_Reset_Time) + VI_System_Time_MS + 1);

IF L_Elapsed_Time >= GVL_CONSTANTS.C_MS_IN_MINUTE THEN
    L_Last_Reset_Time := VI_System_Time_MS;
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_RULES DO
        L_Trigger_Count[L_i] := 0;
    END_FOR;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_RULES DO

    VO_Actions[L_i].Active := FALSE;
    IF VI_Rules[L_i].Enabled THEN
        L_Condition_Met := FALSE;
        L_Current_Value := 0.0;
        
        IF VI_Rules[L_i].Condition_Target_ID > 0 THEN
            CASE VI_Rules[L_i].Condition_Type OF
                E_Rule_Condition_Type.COND_AIR_TEMP: IF VI_Rules[L_i].Condition_Target_ID <= 16 THEN L_Current_Value := VI_Indoor_Temps[VI_Rules[L_i].Condition_Target_ID]; END_IF;
                E_Rule_Condition_Type.COND_FLOOR_TEMP: IF VI_Rules[L_i].Condition_Target_ID <= GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS THEN L_Current_Value := VI_Floor_Temps[VI_Rules[L_i].Condition_Target_ID]; END_IF;
                E_Rule_Condition_Type.COND_HUMIDITY: IF VI_Rules[L_i].Condition_Target_ID <= 16 THEN L_Current_Value := VI_Humidities[VI_Rules[L_i].Condition_Target_ID]; END_IF;
                E_Rule_Condition_Type.COND_CO2: IF VI_Rules[L_i].Condition_Target_ID <= 16 THEN L_Current_Value := VI_CO2_Levels[VI_Rules[L_i].Condition_Target_ID]; END_IF;
                E_Rule_Condition_Type.COND_MOTION: IF VI_Rules[L_i].Condition_Target_ID <= 16 THEN L_Current_Value := SEL(VI_Motion_Sensors[VI_Rules[L_i].Condition_Target_ID], 0.0, 1.0); END_IF;
                E_Rule_Condition_Type.COND_DOOR_WINDOW: 
                    IF VI_Rules[L_i].Condition_Target_ID <= GVL_CONSTANTS.C_MAX_DOOR_SENSORS THEN
                        L_Current_Value := SEL(VI_Door_Sensors[VI_Rules[L_i].Condition_Target_ID] OR VI_Window_Sensors[VI_Rules[L_i].Condition_Target_ID], 0.0, 1.0);
                    ELSIF VI_Rules[L_i].Condition_Target_ID <= 16 THEN
                        L_Current_Value := SEL(VI_Window_Sensors[VI_Rules[L_i].Condition_Target_ID], 0.0, 1.0);
                    END_IF;
                E_Rule_Condition_Type.COND_FLOOD: IF VI_Rules[L_i].Condition_Target_ID <= GVL_CONSTANTS.C_MAX_FLOOD_SENSORS THEN L_Current_Value := SEL(VI_Water_Sensors[VI_Rules[L_i].Condition_Target_ID], 0.0, 1.0); END_IF;
                E_Rule_Condition_Type.COND_SMOKE: IF VI_Rules[L_i].Condition_Target_ID <= GVL_CONSTANTS.C_MAX_SMOKE_SENSORS THEN L_Current_Value := SEL(VI_Smoke_Sensors[VI_Rules[L_i].Condition_Target_ID], 0.0, 1.0); END_IF;
                E_Rule_Condition_Type.COND_METHANE: IF VI_Rules[L_i].Condition_Target_ID <= GVL_CONSTANTS.C_MAX_METHANE_SENSORS THEN L_Current_Value := VI_Methane_Sensors[VI_Rules[L_i].Condition_Target_ID]; END_IF;
                E_Rule_Condition_Type.COND_CO: IF VI_Rules[L_i].Condition_Target_ID <= GVL_CONSTANTS.C_MAX_CO_SENSORS THEN L_Current_Value := VI_CO_Sensors[VI_Rules[L_i].Condition_Target_ID]; END_IF;
                E_Rule_Condition_Type.COND_TIME_OF_DAY: L_Current_Value := TO_REAL(TOD_TO_UDINT(VI_Current_Time) / GVL_CONSTANTS.C_MS_IN_MINUTE);
                E_Rule_Condition_Type.COND_DAY_OF_WEEK: L_Current_Value := TO_REAL(VI_Day_Of_Week);
            END_CASE;
        ELSE
            IF VI_Rules[L_i].Condition_Type = E_Rule_Condition_Type.COND_TIME_OF_DAY THEN
                L_Current_Value := TO_REAL(TOD_TO_UDINT(VI_Current_Time) / GVL_CONSTANTS.C_MS_IN_MINUTE);
            ELSIF VI_Rules[L_i].Condition_Type = E_Rule_Condition_Type.COND_DAY_OF_WEEK THEN
                L_Current_Value := TO_REAL(VI_Day_Of_Week);
            END_IF;
        END_IF;
        
        CASE VI_Rules[L_i].Condition_Op OF
            E_Rule_Comparison.COMP_GT: L_Condition_Met := (L_Current_Value > VI_Rules[L_i].Condition_Value);
            E_Rule_Comparison.COMP_LT: L_Condition_Met := (L_Current_Value < VI_Rules[L_i].Condition_Value);
            E_Rule_Comparison.COMP_EQ: L_Condition_Met := (ABS(L_Current_Value - VI_Rules[L_i].Condition_Value) < 0.1);
            E_Rule_Comparison.COMP_GE: L_Condition_Met := (L_Current_Value >= VI_Rules[L_i].Condition_Value);
            E_Rule_Comparison.COMP_LE: L_Condition_Met := (L_Current_Value <= VI_Rules[L_i].Condition_Value);
            E_Rule_Comparison.COMP_IN_RANGE: L_Condition_Met := (L_Current_Value >= VI_Rules[L_i].Condition_Value) AND (L_Current_Value <= VI_Rules[L_i].Condition_Value_Max);
            E_Rule_Comparison.COMP_TRUE: L_Condition_Met := (L_Current_Value > 0.5);
            E_Rule_Comparison.COMP_FALSE: L_Condition_Met := (L_Current_Value < 0.5);
        END_CASE;
        
        L_Triggers[L_i](CLK := L_Condition_Met);
        
        IF L_Triggers[L_i].Q THEN
            L_Trigger_Count[L_i] := L_Trigger_Count[L_i] + 1;
            IF L_Trigger_Count[L_i] > 10 THEN
                VO_Actions[L_i].Active := FALSE;
                VO_Actions[L_i].Triggered := FALSE;
                CONTINUE;
            END_IF;
        END_IF;
        
        IF L_Condition_Met AND (L_Trigger_Count[L_i] <= 10) THEN
            VO_Actions[L_i].Active := TRUE;
            VO_Actions[L_i].Triggered := L_Triggers[L_i].Q;
            VO_Actions[L_i].Action_Type := VI_Rules[L_i].Action_Type;
            VO_Actions[L_i].Target_ID := VI_Rules[L_i].Action_Target_ID;
            VO_Actions[L_i].Value := VI_Rules[L_i].Action_Value;
        END_IF;
    END_IF;
END_FOR;

// >>> BULK_SYNC_ANCHOR: FB_Rule_Engine <<<
