FUNCTION_BLOCK FB_Heating_Thermal_Allocation
VAR_INPUT
    VI_Zone_Configs : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF ST_FloorHeating_Circuit_Config;
    VI_Circuit_To_Zone : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF INT;
    VI_Manifold_Base_Priority : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF INT;
    VI_Zone_Priority_Bias : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF REAL;
    VI_Guest_Preheat_Enabled : BOOL;
    VI_Zone_Guest_Preheat_Request : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF BOOL;
    VI_Guest_Preheat_Priority_Boost : INT;
    VI_Zone_Target_Adjustment : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF REAL;
    VI_Zone_Self_Level : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF INT;
    VI_Policy_Priority_Multiplier : REAL;
    VI_Manifold_Pump_In_Service : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Manifold_Pressure_Fault : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Manifold_Current_Fault : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Manifold_Thermal_Weight : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_Max_Thermal_Budget : REAL;
END_VAR
VAR_OUTPUT
    VO_Manifold_Adjusted_Priority : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF INT;
    VO_Manifold_Allowed : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VO_Manifold_Enabled : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VO_Heating_Degraded : BOOL;
END_VAR
VAR
    fbDecision : FB_Heating_Decision_Context;
    L_i : INT;
    L_j : INT;
    L_Zone_ID : INT;
END_VAR

// Extracted candidate from PRG_Heating S1.5
// Not connected yet.

// Base copy
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    VO_Manifold_Adjusted_Priority[L_i] := VI_Manifold_Base_Priority[L_i];
END_FOR;

// Adjustment loop
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO

    L_j := TO_INT(VI_Zone_Configs[L_i].manifold_id);
    L_Zone_ID := VI_Circuit_To_Zone[L_i];

    IF (L_j >= 1) AND (L_j <= GVL_CONSTANTS.C_MAX_MANIFOLDS) AND
       (L_Zone_ID >= 1) AND (L_Zone_ID <= GVL_CONSTANTS.C_MAX_ZONES) THEN

        VO_Manifold_Adjusted_Priority[L_j] := VO_Manifold_Adjusted_Priority[L_j]
            + TO_INT(VI_Zone_Priority_Bias[L_Zone_ID]);

        IF VI_Guest_Preheat_Enabled AND VI_Zone_Guest_Preheat_Request[L_Zone_ID] THEN
            VO_Manifold_Adjusted_Priority[L_j] := VO_Manifold_Adjusted_Priority[L_j]
                + VI_Guest_Preheat_Priority_Boost;
        END_IF;

        IF VI_Zone_Target_Adjustment[L_Zone_ID] > 0.1 THEN
            VO_Manifold_Adjusted_Priority[L_j] := VO_Manifold_Adjusted_Priority[L_j] + 1;
        ELSIF VI_Zone_Target_Adjustment[L_Zone_ID] < -0.1 THEN
            VO_Manifold_Adjusted_Priority[L_j] := VO_Manifold_Adjusted_Priority[L_j] - 1;
        END_IF;

        VO_Manifold_Adjusted_Priority[L_j] := VO_Manifold_Adjusted_Priority[L_j]
            + VI_Zone_Self_Level[L_Zone_ID];

        VO_Manifold_Adjusted_Priority[L_j] := TO_INT(
            TO_REAL(VO_Manifold_Adjusted_Priority[L_j])
            * VI_Policy_Priority_Multiplier
        );

        IF VO_Manifold_Adjusted_Priority[L_j] < 1 THEN
            VO_Manifold_Adjusted_Priority[L_j] := 1;
        END_IF;

    END_IF;

END_FOR;

// Decision context call
fbDecision(
    VI_Manifold_Pump_In_Service := VI_Manifold_Pump_In_Service,
    VI_Manifold_Pressure_Fault := VI_Manifold_Pressure_Fault,
    VI_Manifold_Current_Fault := VI_Manifold_Current_Fault,
    VI_Manifold_Thermal_Weight := VI_Manifold_Thermal_Weight,
    VI_Manifold_Priority := VO_Manifold_Adjusted_Priority,
    VI_Max_Thermal_Budget := VI_Max_Thermal_Budget
);

VO_Manifold_Allowed := fbDecision.VO_Manifold_Allowed;
VO_Manifold_Enabled := fbDecision.VO_Manifold_Enabled;
VO_Heating_Degraded := fbDecision.VO_Heating_Degraded;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Thermal_Allocation <<<
