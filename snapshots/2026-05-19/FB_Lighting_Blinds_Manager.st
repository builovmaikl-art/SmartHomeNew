FUNCTION_BLOCK FB_Lighting_Blinds_Manager
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_IsActivePLC : BOOL;
    VI_Current_Scenario : E_SCENARIO_TYPE;
    VI_Away_Level : BYTE;
    VI_Simulation_Active : BOOL;
    VI_Is_Night : BOOL;
    VI_System_Mode : E_System_Operating_Mode;
END_VAR
VAR_IN_OUT
    VI_Manual_Light_Override : ARRAY[1..GVL_CONSTANTS.C_MAX_LIGHT_ZONES] OF BYTE;
    VI_Manual_Blinds_Override : ARRAY[1..GVL_CONSTANTS.C_MAX_BLINDS] OF BYTE;
    VI_Simulation_Lights : ARRAY[1..GVL_CONSTANTS.C_MAX_LIGHT_ZONES] OF BOOL;
    VI_Physical_Switches : ARRAY[1..GVL_CONSTANTS.C_MAX_LIGHT_ZONES] OF BOOL;
    VI_Motion_Sensors : ARRAY[1..GVL_CONSTANTS.C_MAX_LIGHT_ZONES] OF BOOL;
    VI_Rule_Actions : ARRAY[1..GVL_CONSTANTS.C_MAX_RULES] OF ST_Rule_Action;
    VI_IO_Modules_Online : ARRAY[1..GVL_CONSTANTS.C_MAX_MODULES] OF BOOL;
    VI_Wet_Zone_Map : ARRAY[1..GVL_CONSTANTS.C_MAX_LIGHT_ZONES] OF BOOL;
    VI_Scenario_Configs : ARRAY[1..GVL_CONSTANTS.C_MAX_SCENARIOS] OF ST_Scenario_Config;
END_VAR
VAR_OUTPUT
    VO_Lighting_Levels : ARRAY[1..GVL_CONSTANTS.C_MAX_LIGHT_ZONES] OF BYTE;
    VO_Blinds_Positions : ARRAY[1..GVL_CONSTANTS.C_MAX_BLINDS] OF BYTE;
    VO_Wet_Zone_Light_Active : ARRAY[1..GVL_CONSTANTS.C_MAX_WET_ZONES] OF BOOL;
END_VAR
VAR
    L_i : INT;
    L_j : INT;
    L_Base_Light : BYTE;
    L_Base_Blinds : BYTE;
    L_Target_Base_Light : BYTE;
    L_Target_Base_Blinds : BYTE;
    L_Prev_Scenario : E_SCENARIO_TYPE;
    L_Transition_Light : FB_Scenario_Transition_Controller;
    L_Transition_Blinds : FB_Scenario_Transition_Controller;
    L_Light_States : ARRAY[1..GVL_CONSTANTS.C_MAX_LIGHT_ZONES] OF BOOL;
    L_Prev_Switches : ARRAY[1..GVL_CONSTANTS.C_MAX_LIGHT_ZONES] OF BOOL;
    L_Prev_Motion_Q : ARRAY[1..GVL_CONSTANTS.C_MAX_LIGHT_ZONES] OF BOOL;
    L_Manual_Override : ARRAY[1..GVL_CONSTANTS.C_MAX_LIGHT_ZONES] OF BOOL;
    L_Motion_Timers : ARRAY[1..GVL_CONSTANTS.C_MAX_LIGHT_ZONES] OF FB_System_Timer_TOF;
    L_Rule_Light_Active : BOOL;
    L_Rule_Light_Val : BYTE;
    L_Rule_Blinds_Active : BOOL;
    L_Rule_Blinds_Val : BYTE;
    L_Wet_Zone_Idx : INT;
    L_Effective_Scenario : E_SCENARIO_TYPE;
    L_Effective_Simulation_Active : BOOL;
END_VAR

IF NOT VI_IsActivePLC THEN RETURN; END_IF;

GVL_STATE.G_Lighting_IO_Fault := FALSE;
GVL_STATE.G_Lighting_Subsystem_Degraded := FALSE;

L_Effective_Scenario := VI_Current_Scenario;
L_Effective_Simulation_Active := VI_Simulation_Active;

CASE VI_System_Mode OF
    E_System_Operating_Mode.MODE_SAFE_STOP:
        FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
            VO_Lighting_Levels[L_j] := 0;
        END_FOR;
        FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_BLINDS DO
            VO_Blinds_Positions[L_j] := 100;
        END_FOR;
        FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_WET_ZONES DO
            VO_Wet_Zone_Light_Active[L_j] := FALSE;
        END_FOR;
        RETURN;
    E_System_Operating_Mode.MODE_FREEZE_PROTECTION:
        L_Effective_Scenario := E_SCENARIO_TYPE.SCENARIO_NONE;
        L_Effective_Simulation_Active := FALSE;
    E_System_Operating_Mode.MODE_DEGRADED:
        L_Effective_Simulation_Active := FALSE;
END_CASE;

L_Wet_Zone_Idx := 1;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_WET_ZONES DO
    VO_Wet_Zone_Light_Active[L_i] := FALSE;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MODULES DO
    IF NOT VI_IO_Modules_Online[L_i] THEN
        GVL_STATE.G_Lighting_IO_Fault := TRUE;
        GVL_STATE.G_Lighting_Subsystem_Degraded := TRUE;
        FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
            VO_Lighting_Levels[L_j] := 0;
        END_FOR;
        FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_BLINDS DO
            VO_Blinds_Positions[L_j] := 100;
        END_FOR;
        RETURN;
    END_IF;
END_FOR;

IF L_Effective_Scenario >= 1 AND L_Effective_Scenario <= GVL_CONSTANTS.C_MAX_SCENARIOS THEN
    L_Target_Base_Light := VI_Scenario_Configs[L_Effective_Scenario].lighting_level_base;
    L_Target_Base_Blinds := VI_Scenario_Configs[L_Effective_Scenario].blinds_position_percent;
ELSE
    L_Target_Base_Light := 100;
    L_Target_Base_Blinds := 100;
END_IF;

IF VI_Is_Night AND L_Effective_Scenario <> E_SCENARIO_TYPE.SCENARIO_AWAY AND L_Effective_Scenario <> E_SCENARIO_TYPE.SCENARIO_SLEEP THEN
    L_Target_Base_Blinds := 0;
END_IF;

IF L_Effective_Scenario <> L_Prev_Scenario THEN
    L_Transition_Light(VI_System_Time := VI_System_Time_MS, VI_Start_Time := VI_System_Time_MS, VI_Duration := 5000, VI_Start_Value := TO_REAL(L_Base_Light), VI_End_Value := TO_REAL(L_Target_Base_Light));
    L_Transition_Blinds(VI_System_Time := VI_System_Time_MS, VI_Start_Time := VI_System_Time_MS, VI_Duration := 10000, VI_Start_Value := TO_REAL(L_Base_Blinds), VI_End_Value := TO_REAL(L_Target_Base_Blinds));
    L_Prev_Scenario := L_Effective_Scenario;
ELSE
    L_Transition_Light(VI_System_Time := VI_System_Time_MS, VI_Start_Time := L_Transition_Light.VI_Start_Time, VI_Duration := L_Transition_Light.VI_Duration, VI_Start_Value := L_Transition_Light.VI_Start_Value, VI_End_Value := TO_REAL(L_Target_Base_Light));
    L_Transition_Blinds(VI_System_Time := VI_System_Time_MS, VI_Start_Time := L_Transition_Blinds.VI_Start_Time, VI_Duration := L_Transition_Blinds.VI_Duration, VI_Start_Value := L_Transition_Blinds.VI_Start_Value, VI_End_Value := TO_REAL(L_Target_Base_Blinds));
END_IF;

L_Base_Light := TO_BYTE(L_Transition_Light.VO_Current_Value);
L_Base_Blinds := TO_BYTE(L_Transition_Blinds.VO_Current_Value);

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
    L_Rule_Light_Active := FALSE;
    L_Rule_Light_Val := 0;
    FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_RULES DO
        IF VI_Rule_Actions[L_j].Active AND VI_Rule_Actions[L_j].Target_ID = L_i THEN
            IF VI_Rule_Actions[L_j].Action_Type = E_Rule_Action_Type.ACTION_SET_LIGHTING_BASE THEN
                L_Rule_Light_Active := TRUE;
                L_Rule_Light_Val := REAL_TO_BYTE(VI_Rule_Actions[L_j].Value);
                L_Light_States[L_i] := (L_Rule_Light_Val > 0);
            ELSIF VI_Rule_Actions[L_j].Action_Type = E_Rule_Action_Type.ACTION_TOGGLE_LIGHTING AND VI_Rule_Actions[L_j].Triggered THEN
                L_Light_States[L_i] := NOT L_Light_States[L_i];
            END_IF;
        END_IF;
    END_FOR;

    IF VI_Physical_Switches[L_i] AND NOT L_Prev_Switches[L_i] THEN
        L_Light_States[L_i] := NOT L_Light_States[L_i];
        L_Manual_Override[L_i] := TRUE;
    END_IF;
    L_Prev_Switches[L_i] := VI_Physical_Switches[L_i];

    L_Motion_Timers[L_i](IN := VI_Motion_Sensors[L_i], PT := T#5m, VI_System_Time_MS := VI_System_Time_MS);

    IF L_Prev_Motion_Q[L_i] AND NOT L_Motion_Timers[L_i].Q THEN
        L_Manual_Override[L_i] := FALSE;
    END_IF;
    L_Prev_Motion_Q[L_i] := L_Motion_Timers[L_i].Q;

    IF L_Motion_Timers[L_i].Q THEN
        IF NOT L_Manual_Override[L_i] THEN
            L_Light_States[L_i] := TRUE;
        END_IF;
    ELSE
        IF NOT L_Manual_Override[L_i] THEN
            L_Light_States[L_i] := FALSE;
        END_IF;
    END_IF;

    IF L_Effective_Scenario = E_SCENARIO_TYPE.SCENARIO_AWAY AND L_Effective_Simulation_Active THEN
        L_Light_States[L_i] := VI_Simulation_Lights[L_i];
    END_IF;

    IF VI_Manual_Light_Override[L_i] > 0 THEN
        VO_Lighting_Levels[L_i] := VI_Manual_Light_Override[L_i];
    ELSIF L_Rule_Light_Active THEN
        VO_Lighting_Levels[L_i] := L_Rule_Light_Val;
    ELSE
        VO_Lighting_Levels[L_i] := SEL(L_Light_States[L_i], 0, L_Base_Light);
    END_IF;

    IF VI_Wet_Zone_Map[L_i] AND L_Wet_Zone_Idx <= GVL_CONSTANTS.C_MAX_WET_ZONES THEN
        VO_Wet_Zone_Light_Active[L_Wet_Zone_Idx] := (VO_Lighting_Levels[L_i] > 10);
        L_Wet_Zone_Idx := L_Wet_Zone_Idx + 1;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BLINDS DO
    L_Rule_Blinds_Active := FALSE;
    L_Rule_Blinds_Val := 0;
    FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_RULES DO
        IF VI_Rule_Actions[L_j].Active AND VI_Rule_Actions[L_j].Target_ID = L_i THEN
            IF VI_Rule_Actions[L_j].Action_Type = E_Rule_Action_Type.ACTION_SET_BLINDS THEN
                L_Rule_Blinds_Active := TRUE;
                L_Rule_Blinds_Val := REAL_TO_BYTE(VI_Rule_Actions[L_j].Value);
            END_IF;
        END_IF;
    END_FOR;

    IF VI_Manual_Blinds_Override[L_i] > 0 THEN
        VO_Blinds_Positions[L_i] := VI_Manual_Blinds_Override[L_i];
    ELSIF L_Rule_Blinds_Active THEN
        VO_Blinds_Positions[L_i] := L_Rule_Blinds_Val;
    ELSE
        VO_Blinds_Positions[L_i] := L_Base_Blinds;
    END_IF;
END_FOR;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Lighting_Blinds_Manager <<<
