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
//
// Per-circuit fallback/source-selection reasoning is published to
// GVL_Heating_Circuit_Explainability. This publication is observation-only
// and does not own valves, pumps, demand or runtime authority.
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
    L_Primary_Source_Code : UINT;
    L_Selected_Source_Code : UINT;
    L_Primary_Confidence : REAL;
    L_Fallback_Confidence : REAL;
    L_Selected_Confidence : REAL;
    L_Fallback_Active : BOOL;
    L_Source_Degraded : BOOL;
    L_Reason_Code : UINT;
    L_Reason_Text : STRING(128);
    L_Selected_Source_Text : STRING(64);

    L_Prev_Selected_Source_Code : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF UINT;
    L_Prev_Fallback_Active : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
    L_Prev_Source_Loss : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
    L_Source_Loss_Active : BOOL;

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
    L_Selected_Source_Code := 0;
    L_Selected_Source_Text := 'none';
    L_Selected_Confidence := REAL#0.0;
    L_Fallback_Active := FALSE;
    L_Source_Degraded := FALSE;
    L_Reason_Code := 0;
    L_Reason_Text := 'OK';

    IF VI_Zone_Configs[L_i].control_type = 1 OR VI_Zone_Configs[L_i].control_type = 2 THEN
        L_Primary_Source_Code := 1; // room
        L_Primary_Confidence := L_Room_Confidence;
        L_Fallback_Confidence := L_Floor_Confidence;

        // Primary: room air temperature. If room quality is degraded and floor
        // source is healthier, prefer floor fallback without declaring hard fault.
        IF L_Room_Source_Valid AND
           ((L_Room_Confidence >= L_Min_Source_Confidence) OR NOT L_Floor_Source_Valid OR (L_Room_Confidence >= L_Floor_Confidence)) THEN
            L_Current_Temp := fbRoomTempValidator[L_Climate_Zone_ID].VO_Value;
            L_Selected_Source_Code := 1;
            L_Selected_Source_Text := 'room';
            L_Selected_Confidence := L_Room_Confidence;
        ELSIF L_Floor_Source_Valid THEN
            L_Current_Temp := fbFloorTempValidator[L_i].VO_Value;
            L_Selected_Source_Code := 2;
            L_Selected_Source_Text := 'floor';
            L_Selected_Confidence := L_Floor_Confidence;
            L_Fallback_Active := TRUE;
        ELSIF L_Room_Source_Valid THEN
            L_Current_Temp := fbRoomTempValidator[L_Climate_Zone_ID].VO_Value;
            L_Selected_Source_Code := 1;
            L_Selected_Source_Text := 'room';
            L_Selected_Confidence := L_Room_Confidence;
            L_Source_Degraded := TRUE;
            L_Reason_Code := 2;
            L_Reason_Text := 'Room source degraded but retained; floor source unavailable';
        ELSE
            L_Sensor_Error := TRUE;
        END_IF;
    ELSE
        L_Primary_Source_Code := 2; // floor
        L_Primary_Confidence := L_Floor_Confidence;
        L_Fallback_Confidence := L_Room_Confidence;

        // Primary: floor temperature. If floor quality is degraded and room
        // source is healthier, prefer room fallback without declaring hard fault.
        IF L_Floor_Source_Valid AND
           ((L_Floor_Confidence >= L_Min_Source_Confidence) OR NOT L_Room_Source_Valid OR (L_Floor_Confidence >= L_Room_Confidence)) THEN
            L_Current_Temp := fbFloorTempValidator[L_i].VO_Value;
            L_Selected_Source_Code := 2;
            L_Selected_Source_Text := 'floor';
            L_Selected_Confidence := L_Floor_Confidence;
        ELSIF L_Room_Source_Valid THEN
            L_Current_Temp := fbRoomTempValidator[L_Climate_Zone_ID].VO_Value;
            L_Selected_Source_Code := 1;
            L_Selected_Source_Text := 'room';
            L_Selected_Confidence := L_Room_Confidence;
            L_Fallback_Active := TRUE;
        ELSIF L_Floor_Source_Valid THEN
            L_Current_Temp := fbFloorTempValidator[L_i].VO_Value;
            L_Selected_Source_Code := 2;
            L_Selected_Source_Text := 'floor';
            L_Selected_Confidence := L_Floor_Confidence;
            L_Source_Degraded := TRUE;
            L_Reason_Code := 2;
            L_Reason_Text := 'Floor source degraded but retained; room source unavailable';
        ELSE
            L_Sensor_Error := TRUE;
        END_IF;
    END_IF;

    IF L_Fallback_Active THEN
        L_Source_Degraded := TRUE;
        L_Reason_Code := 1;
        IF L_Primary_Source_Code = 1 THEN
            L_Reason_Text := 'Room source degraded or unavailable; floor fallback selected';
        ELSE
            L_Reason_Text := 'Floor source degraded or unavailable; room fallback selected';
        END_IF;
    END_IF;

    IF L_Sensor_Error THEN
        L_Source_Degraded := TRUE;
        L_Reason_Code := 3;
        L_Reason_Text := 'No valid temperature source available';
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

    L_Source_Loss_Active := L_Sensor_Error;

    GVL_Heating_Circuit_Explainability.G_Source_Switched_Event[L_i] :=
        (L_Prev_Selected_Source_Code[L_i] <> 0) AND
        (L_Selected_Source_Code <> 0) AND
        (L_Selected_Source_Code <> L_Prev_Selected_Source_Code[L_i]);

    GVL_Heating_Circuit_Explainability.G_Fallback_Activated_Event[L_i] :=
        L_Fallback_Active AND NOT L_Prev_Fallback_Active[L_i];

    GVL_Heating_Circuit_Explainability.G_Fallback_Recovered_Event[L_i] :=
        (NOT L_Fallback_Active) AND L_Prev_Fallback_Active[L_i] AND NOT L_Source_Loss_Active;

    GVL_Heating_Circuit_Explainability.G_Source_Loss_Event[L_i] :=
        L_Source_Loss_Active AND NOT L_Prev_Source_Loss[L_i];

    GVL_Heating_Circuit_Explainability.G_Last_Event_Code[L_i] := 0;
    GVL_Heating_Circuit_Explainability.G_Last_Event_Text[L_i] := '';

    IF GVL_Heating_Circuit_Explainability.G_Source_Loss_Event[L_i] THEN
        GVL_Heating_Circuit_Explainability.G_Last_Event_MS[L_i] := VI_System_Time_MS;
        GVL_Heating_Circuit_Explainability.G_Last_Event_Code[L_i] := 4;
        GVL_Heating_Circuit_Explainability.G_Last_Event_Text[L_i] := 'Temperature source loss';
    ELSIF GVL_Heating_Circuit_Explainability.G_Fallback_Activated_Event[L_i] THEN
        GVL_Heating_Circuit_Explainability.G_Last_Event_MS[L_i] := VI_System_Time_MS;
        GVL_Heating_Circuit_Explainability.G_Last_Event_Code[L_i] := 2;
        GVL_Heating_Circuit_Explainability.G_Last_Event_Text[L_i] := L_Reason_Text;
    ELSIF GVL_Heating_Circuit_Explainability.G_Fallback_Recovered_Event[L_i] THEN
        GVL_Heating_Circuit_Explainability.G_Last_Event_MS[L_i] := VI_System_Time_MS;
        GVL_Heating_Circuit_Explainability.G_Last_Event_Code[L_i] := 3;
        GVL_Heating_Circuit_Explainability.G_Last_Event_Text[L_i] := 'Fallback recovered; primary source selected';
    ELSIF GVL_Heating_Circuit_Explainability.G_Source_Switched_Event[L_i] THEN
        GVL_Heating_Circuit_Explainability.G_Last_Event_MS[L_i] := VI_System_Time_MS;
        GVL_Heating_Circuit_Explainability.G_Last_Event_Code[L_i] := 1;
        GVL_Heating_Circuit_Explainability.G_Last_Event_Text[L_i] := 'Temperature source switched';
    END_IF;

    GVL_Heating_Circuit_Explainability.G_Source_Selection_Visible[L_i] := TRUE;
    GVL_Heating_Circuit_Explainability.G_Selected_Source_Code[L_i] := L_Selected_Source_Code;
    GVL_Heating_Circuit_Explainability.G_Selected_Source_Text[L_i] := L_Selected_Source_Text;
    GVL_Heating_Circuit_Explainability.G_Fallback_Active[L_i] := L_Fallback_Active;
    GVL_Heating_Circuit_Explainability.G_Source_Degraded[L_i] := L_Source_Degraded;
    GVL_Heating_Circuit_Explainability.G_Selected_Source_Confidence[L_i] := L_Selected_Confidence;
    GVL_Heating_Circuit_Explainability.G_Primary_Source_Confidence[L_i] := L_Primary_Confidence;
    GVL_Heating_Circuit_Explainability.G_Fallback_Source_Confidence[L_i] := L_Fallback_Confidence;
    GVL_Heating_Circuit_Explainability.G_Reason_Code[L_i] := L_Reason_Code;
    GVL_Heating_Circuit_Explainability.G_Reason_Text[L_i] := L_Reason_Text;

    L_Prev_Selected_Source_Code[L_i] := L_Selected_Source_Code;
    L_Prev_Fallback_Active[L_i] := L_Fallback_Active;
    L_Prev_Source_Loss[L_i] := L_Source_Loss_Active;

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
