PROGRAM PRG_System_Test_Harness
VAR
    L_i : INT;
    L_j : INT;
    L_Used : REAL;
    L_HP_Used : REAL;
    L_HP_Manifold_Adjusted : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF INT;
    fbDecisionTest : FB_Heating_Decision_Context;
    fbDecisionHP : FB_Heating_Decision_Context;
    fbTestResult : FB_Test_Result_Handler;
    fbTrace : FB_Trace_Logger;
END_VAR

IF NOT GVL_TEST.G_Test_Enable THEN
    RETURN;
END_IF;

GVL_TEST.G_Test_Total_Checks := 0;
GVL_TEST.G_Test_Failed_Checks := 0;
GVL_TEST.G_Test_Passed := TRUE;
GVL_TEST.G_Test_Last_Failure_Index := 0;
GVL_TEST.G_Test_Last_Failure_Code := 0;

// Reset transient failure flags for this scan
GVL_TEST.G_Diagnostics_Duplicate_Event_Found := FALSE;
GVL_TEST.G_Diagnostics_Count_Out_Of_Range := FALSE;
GVL_TEST.G_Heating_Allocation_Budget_Exceeded := FALSE;
GVL_TEST.G_Heating_Allocation_Enabled_Not_Allowed := FALSE;
GVL_TEST.G_Safety_Latched_Without_Intent := FALSE;
GVL_TEST.G_HP_Adjusted_Priority_Lower_Bound_Violation := FALSE;
GVL_TEST.G_HP_Adjusted_Allocation_Budget_Exceeded := FALSE;
GVL_TEST.G_HP_Adjusted_Allocation_Enabled_Not_Allowed := FALSE;
GVL_TEST.G_HP_Guest_Preheat_Config_Out_Of_Range := FALSE;

// =========================
// TEST 1: Diagnostics count bounds
// =========================
GVL_TEST.G_Test_Total_Checks := GVL_TEST.G_Test_Total_Checks + 1;
IF (GVL_STATUS.G_Diagnostics_Count < 0) OR (GVL_STATUS.G_Diagnostics_Count > 50) THEN
    GVL_TEST.G_Diagnostics_Count_Out_Of_Range := TRUE;
    GVL_TEST.G_Test_Failed_Checks := GVL_TEST.G_Test_Failed_Checks + 1;
    GVL_TEST.G_Test_Passed := FALSE;
    GVL_TEST.G_Test_Last_Failure_Index := 1;
    GVL_TEST.G_Test_Last_Failure_Code := 1001;
END_IF;

// =========================
// TEST 2: Diagnostics duplicates
// =========================
GVL_TEST.G_Test_Total_Checks := GVL_TEST.G_Test_Total_CheckS + 1;
FOR L_i := 1 TO GVL_STATUS.G_Diagnostics_Count DO
    FOR L_j := L_i + 1 TO GVL_STATUS.G_Diagnostics_Count DO
        IF (GVL_STATUS.G_Diagnostics_Events[L_i].Code = GVL_STATUS.G_Diagnostics_Events[L_j].Code) AND
           (GVL_STATUS.G_Diagnostics_Events[L_i].Source = GVL_STATUS.G_Diagnostics_Events[L_j].Source) THEN
            GVL_TEST.G_Diagnostics_Duplicate_Event_Found := TRUE;
            GVL_TEST.G_Test_Failed_Checks := GVL_TEST.G_Test_Failed_Checks + 1;
            GVL_TEST.G_Test_Passed := FALSE;
            GVL_TEST.G_Test_Last_Failure_Index := 2;
            GVL_TEST.G_Test_Last_Failure_Code := 1002;
        END_IF;
    END_FOR;
END_FOR;

// =========================
// TEST 3: Base heating decision consistency
// =========================
GVL_TEST.G_Test_Total_Checks := GVL_TEST.G_Test_Total_Checks + 1;
fbDecisionTest(
    VI_Manifold_Pump_In_Service := GVL_CONFIG.G_Manifold_Pump_In_Service,
    VI_Manifold_Pressure_Fault := GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault,
    VI_Manifold_Current_Fault := GVL_STATUS.G_Diagnostics.Manifold_Current_Fault,
    VI_Manifold_Thermal_Weight := GVL_CONFIG.G_Manifold_Thermal_Weight,
    VI_Manifold_Priority := GVL_CONFIG.G_Manifold_Priority,
    VI_Max_Thermal_Budget := GVL_CONFIG.G_Max_Thermal_Budget
);

L_Used := 0.0;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF fbDecisionTest.VO_Manifold_Enabled[L_i] AND (NOT fbDecisionTest.VO_Manifold_Allowed[L_i]) THEN
        GVL_TEST.G_Heating_Allocation_Enabled_Not_Allowed := TRUE;
        GVL_TEST.G_Test_Failed_Checks := GVL_TEST.G_Test_Failed_Checks + 1;
        GVL_TEST.G_Test_Passed := FALSE;
        GVL_TEST.G_Test_Last_Failure_Index := 3;
        GVL_TEST.G_Test_Last_Failure_Code := 1003;
    END_IF;

    IF fbDecisionTest.VO_Manifold_Enabled[L_i] THEN
        L_Used := L_Used + GVL_CONFIG.G_Manifold_Thermal_Weight[L_i];
    END_IF;
END_FOR;

IF L_Used > (GVL_CONFIG.G_Max_Thermal_Budget + 0.001) THEN
    GVL_TEST.G_Heating_Allocation_Budget_Exceeded := TRUE;
    GVL_TEST.G_Test_Failed_Checks := GVL_TEST.G_Test_Failed_Checks + 1;
    GVL_TEST.G_Test_Passed := FALSE;
    GVL_TEST.G_Test_Last_Failure_Index := 3;
    GVL_TEST.G_Test_Last_Failure_Code := 1004;
END_IF;

// =========================
// TEST 4: Safety latch consistency
// =========================
GVL_TEST.G_Test_Total_Checks := GVL_TEST.G_Test_Total_Checks + 1;
IF GVL_STATE.G_Safety_Gas_Latched AND (NOT GVL_INTENT_SAFETY.I_Gas_Alarm_Active) THEN
    GVL_TEST.G_Safety_Latched_Without_Intent := TRUE;
    GVL_TEST.G_Test_Failed_CHECKS := GVL_TEST.G_Test_Failed_Checks + 1;
    GVL_TEST.G_Test_Passed := FALSE;
    GVL_TEST.G_Test_Last_Failure_Index := 4;
    GVL_TEST.G_Test_Last_Failure_Code := 1005;
END_IF;

// =========================
// TEST 5: HP policy adjusted priority
// =========================
GVL_TEST.G_Test_Total_Checks := GVL_TEST.G_Test_Total_Checks + 1;

// config sanity
IF (GVL_HEATING_POLICY_CONFIG.G_Guest_Preheat_Priority_Boost < 0) OR (GVL_HEATING_POLICY_CONFIG.G_Guest_Preheat_Priority_Boost > 10) THEN
    GVL_TEST.G_HP_Guest_Preheat_Config_Out_Of_Range := TRUE;
    GVL_TEST.G_Test_Failed_Checks := GVL_TEST.G_Test_Failed_Checks + 1;
    GVL_TEST.G_Test_Passed := FALSE;
    GVL_TEST.G_Test_Last_Failure_Index := 5;
    GVL_TEST.G_Test_Last_Failure_Code := 1007;
END_IF;

// calculate adjusted priorities
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    L_HP_Manifold_Adjusted[L_i] := GVL_CONFIG.G_Manifold_Priority[L_i];
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    L_j := TO_INT(GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].manifold_id);

    IF (L_j >= 1) AND (L_j <= GVL_CONSTANTS.C_MAX_MANIFOLDS) THEN

        L_HP_Manifold_Adjusted[L_j] := L_HP_Manifold_Adjusted[L_j] + TO_INT(GVL_HEATING_POLICY.G_Zone_Priority_Bias[L_i]);

        IF GVL_HEATING_POLICY_CONFIG.G_Guest_Preheat_Enabled AND GVL_HEATING_POLICY.G_Zone_Guest_Preheat_Request[L_i] THEN
            L_HP_Manifold_Adjusted[L_j] := L_HP_Manifold_Adjusted[L_j] + GVL_HEATING_POLICY_CONFIG.G_Guest_Preheat_Priority_Boost;
        END_IF;

        IF L_HP_Manifold_Adjusted[L_j] < 1 THEN
            GVL_TEST.G_HP_Adjusted_Priority_Lower_Bound_Violation := TRUE;
            GVL_TEST.G_Test_Failed_Checks := GVL_TEST.G_Test_Failed_Checks + 1;
            GVL_TEST.G_Test_Passed := FALSE;
            GVL_TEST.G_Test_Last_Failure_Index := 5;
            GVL_TEST.G_Test_Last_Failure_Code := 1006;
        END_IF;

    END_IF;
END_FOR;

// expose for debug
FOR L_i := 1 TO 10 DO
    GVL_TEST.G_HP_Manifold_Adjusted_Priority[L_i] := L_HP_Manifold_Adjusted[L_i];
END_FOR;

// validate decision with adjusted priorities
fbDecisionHP(
    VI_Manifold_Pump_In_Service := GVL_CONFIG.G_Manifold_Pump_In_Service,
    VI_Manifold_Pressure_Fault := GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault,
    VI_Manifold_Current_Fault := GVL_STATUS.G_Diagnostics.Manifold_Current_Fault,
    VI_Manifold_Thermal_Weight := GVL_CONFIG.G_Manifold_Thermal_Weight,
    VI_Manifold_Priority := L_HP_Manifold_Adjusted,
    VI_Max_Thermal_Budget := GVL_CONFIG.G_Max_Thermal_Budget
);

L_HP_Used := 0.0;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF fbDecisionHP.VO_Manifold_Enabled[L_i] AND (NOT fbDecisionHP.VO_Manifold_Allowed[L_i]) THEN
        GVL_TEST.G_HP_Adjusted_Allocation_Enabled_Not_Allowed := TRUE;
        GVL_TEST.G_Test_Failed_Checks := GVL_TEST.G_Test_Failed_Checks + 1;
        GVL_TEST.G_Test_Passed := FALSE;
        GVL_TEST.G_Test_Last_Failure_Index := 5;
        GVL_TEST.G_Test_Last_Failure_Code := 1008;
    END_IF;

    IF fbDecisionHP.VO_Manifold_Enabled[L_i] THEN
        L_HP_Used := L_HP_Used + GVL_CONFIG.G_Manifold_Thermal_Weight[L_i];
    END_IF;
END_FOR;

IF L_HP_Used > (GVL_CONFIG.G_Max_Thermal_Budget + 0.001) THEN
    GVL_TEST.G_HP_Adjusted_Allocation_Budget_Exceeded := TRUE;
    GVL_TEST.G_Test_Failed_Checks := GVL_TEST.G_Test_Failed_Checks + 1;
    GVL_TEST.G_Test_Passed := FALSE;
    GVL_TEST.G_Test_Last_Failure_Index := 5;
    GVL_TEST.G_Test_Last_Failure_Code := 1009;
END_IF;

// =========================
// FINAL STATUS
// =========================
IF GVL_TEST.G_Test_Passed THEN
    GVL_TEST.G_Test_Status_Msg := 'ALL TESTS PASSED';
ELSE
    GVL_TEST.G_Test_Status_Msg := 'TEST FAILURES DETECTED';
END_IF;

fbTestResult(
    VI_Test_Passed := GVL_TEST.G_Test_Passed
);

IF NOT GVL_TEST.G_Test_Passed THEN
    fbTrace(
        VI_Event_Code := UDINT_TO_INT(GVL_TEST.G_Test_Last_Failure_Code),
        VI_System_Time := GVL_STATUS.G_System_Time_MS
    );
END_IF;
