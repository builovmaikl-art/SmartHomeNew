// ==============================================================================
// Heating circuit control helper
//
// Internal refactoring helper for FB_Heating_System_Manager.
// Owns per-circuit sensor validation, temperature source fallback,
// floor-heating controller call, overheat shutdown, and rule action projection.
//
// Temperature source selection is confidence-aware:
// - range invalid still blocks that source;
// - passive input-quality confidence can prefer a healthier fallback;
// - degraded-but-range-valid sources remain operational if no better source exists.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Circuit_Control
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_Current_Hour : UINT;
    VI_IsActivePLC : BOOL;
    VI_Config : ST_Heating_Config;
    VI_Tariff : ST_Tariff_Config;
    VI_Scenario_Adjust : REAL;
END_VAR

VAR_IN_OUT
    VI_Zone_Configs : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF ST_FloorHeating_Circuit_Config;
    VI_Floor_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF REAL;
    VI_Room_Temps : ARRAY[1..16] OF REAL;
    VI_Rule_Actions : ARRAY[1..GVL_CONSTANTS.C_MAX_RULES] OF ST_Rule_Action;
END_VAR

VAR_OUTPUT
    VO_Zone_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
    VO_Heating_Sensor_Fault : BOOL;
END_VAR

VAR
    L_i : INT;
    L_j : INT;
    L_Climate_Zone_ID : INT;
    L_Zone_Config : ST_FloorHeating_Circuit_Config;
    L_Current_Temp : REAL;
    L_Sensor_Error : BOOL;
    L_Floor_Source_Valid : BOOL;
    L_Room_Source_Valid : BOOL;
    L_Floor_Confidence : REAL;
    L_Room_Confidence : REAL;
    L_Min_Source_Confidence : REAL;

    L_Floor_Controllers : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF FB_FloorHeating_Controller;
    L_Overheat_Timer : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF FB_System_Timer;
    fbFloorTempValidator : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF FB_Analog_Validator;
    fbRoomTempValidator : ARRAY[1..16] OF FB_Analog_Validator;
END_VAR

VO_Heating_Sensor_Fault := FALSE;
L_Min_Source_Confidence := GVL_INPUT_VALIDATION_CONFIG.G_Min_Sensor_Confidence;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    fbFloorTempValidator[L_i](
        VI_Value := VI_Floor_Temps[L_i],
        VI_Min_Valid := -40.0,
        VI_Max_Valid := 120.0,
        VI_Fallback_Mode := 0
    );

    L_Climate_Zone_ID := VI_Zone_Configs[L_i].zone;
    IF L_Climate_Zone_ID >= 1 AND L_Climate_Zone_ID <= 16 THEN
        fbRoomTempValidator[L_Climate_Zone_ID](
            VI_Value := VI_Room_Temps[L_Climate_Zone_ID],
            VI_Min_Valid := -40.0,
            VI_Max_Valid := 120.0,
            VI_Fallback_Mode := 0
        );
    END_IF;

    L_Floor_Source_Valid := NOT fbFloorTempValidator[L_i].VO_Error;
    L_Room_Source_Valid :=
        (L_Climate_Zone_ID >= 1) AND
        (L_Climate_Zone_ID <= 16) AND
        (NOT fbRoomTempValidator[L_Climate_Zone_ID].VO_Error);

    L_Floor_Confidence := REAL#1.0;
    IF GVL_INPUT_QUALITY.G_Floor_Temp_Quality[L_i].Quality_Visible THEN
        L_Floor_Confidence := GVL_INPUT_QUALITY.G_Floor_Temp_Quality[L_i].Confidence;
    END_IF;

    L_Room_Confidence := REAL#1.0;
    IF (L_Climate_Zone_ID >= 1) AND (L_Climate_Zone_ID <= 16) THEN
        IF GVL_INPUT_QUALITY.G_Room_Temp_Quality[L_Climate_Zone_ID].Quality_Visible THEN
            L_Room_Confidence := GVL_INPUT_QUALITY.G_Room_Temp_Quality[L_Climate_Zone_ID].Confidence;
        END_IF;
    END_IF;

    IF L_Floor_Confidence < REAL#0.0 THEN
        L_Floor_Confidence := REAL#0.0;
    ELSIF L_Floor_Confidence > REAL#1.0 THEN
        L_Floor_Confidence := REAL#1.0;
    END_IF;

    IF L_Room_Confidence < REAL#0.0 THEN
        L_Room_Confidence := REAL#0.0;
    ELSIF L_Room_Confidence > REAL#1.0 THEN
        L_Room_Confidence := REAL#1.0;
    END_IF;

    // Floor overheat protection remains floor-bound and range-validity based.
    L_Overheat_Timer[L_i](
        IN := L_Floor_Source_Valid AND (fbFloorTempValidator[L_i].VO_Value > VI_Config.Overheat_Threshold),
        PT := T#60s,
        VI_System_Time_MS := VI_System_Time_MS
    );

    L_Current_Temp := REAL#0.0;
    L_Sensor_Error := FALSE;

    IF VI_Zone_Configs[L_i].control_type = 1 OR VI_Zone_Configs[L_i].control_type = 2 THEN
        // Primary: room air temperature. If room quality is degraded and floor
        // source is healthier, prefer floor fallback without declaring hard fault.
        IF L_Room_Source_Valid AND
           ((L_Room_Confidence >= L_Min_Source_Confidence) OR NOT L_Floor_Source_Valid OR (L_Room_Confidence >= L_Floor_Confidence)) THEN
            L_Current_Temp := fbRoomTempValidator[L_Climate_Zone_ID].VO_Value;
        ELSIF L_Floor_Source_Valid THEN
            L_Current_Temp := fbFloorTempValidator[L_i].VO_Value;
        ELSIF L_Room_Source_Valid THEN
            L_Current_Temp := fbRoomTempValidator[L_Climate_Zone_ID].VO_Value;
        ELSE
            L_Sensor_Error := TRUE;
        END_IF;
    ELSE
        // Primary: floor temperature. If floor quality is degraded and room
        // source is healthier, prefer room fallback without declaring hard fault.
        IF L_Floor_Source_Valid AND
           ((L_Floor_Confidence >= L_Min_Source_Confidence) OR NOT L_Room_Source_Valid OR (L_Floor_Confidence >= L_Room_Confidence)) THEN
            L_Current_Temp := fbFloorTempValidator[L_i].VO_Value;
        ELSIF L_Room_Source_Valid THEN
            L_Current_Temp := fbRoomTempValidator[L_Climate_Zone_ID].VO_Value;
        ELSIF L_Floor_Source_Valid THEN
            L_Current_Temp := fbFloorTempValidator[L_i].VO_Value;
        ELSE
            L_Sensor_Error := TRUE;
        END_IF;
    END_IF;

    IF L_Sensor_Error THEN
        VO_Heating_Sensor_Fault := TRUE;
        VO_Zone_Valves[L_i] := FALSE;
    ELSE
        L_Zone_Config := VI_Zone_Configs[L_i];
        L_Zone_Config.design_temp := L_Zone_Config.design_temp + VI_Scenario_Adjust;

        L_Floor_Controllers[L_i](
            VI_Current_Temp := L_Current_Temp,
            VI_Config := L_Zone_Config,
            VI_Tariff := VI_Tariff,
            VI_Current_Hour := VI_Current_Hour,
            VI_IsActivePLC := VI_IsActivePLC,
            VI_System_Time_MS := VI_System_Time_MS,
            VO_Valve_Bool => VO_Zone_Valves[L_i]
        );
    END_IF;

    IF L_Overheat_Timer[L_i].Q THEN
        VO_Zone_Valves[L_i] := FALSE;
    END_IF;

    FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_RULES DO
        IF VI_Rule_Actions[L_j].Active AND VI_Rule_Actions[L_j].Target_ID = L_i THEN
            IF VI_Rule_Actions[L_j].Action_Type = E_Rule_Action_Type.ACTION_SET_FLOOR_HEATING THEN
                VO_Zone_Valves[L_i] := (VI_Rule_Actions[L_j].Value > REAL#0.5);
            END_IF;
        END_IF;
    END_FOR;
END_FOR;

// >>> BULK_SYNC_ANCHOR: FB_Heating_Circuit_Control <<<
END_FUNCTION_BLOCK
