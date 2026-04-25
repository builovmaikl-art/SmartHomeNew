PROGRAM PRG_System_Test_Harness
VAR
    L_i : INT;
    L_j : INT;
    L_Used : REAL;
    fbDecisionTest : FB_Heating_Decision_Context;
END_VAR

IF NOT GVL_TEST.G_Test_Enable THEN
    RETURN;
END_IF;

GVL_TEST.G_Test_Total_Checks := 0;
GVL_TEST.G_Test_Failed_Checks := 0;
GVL_TEST.G_Test_Passed := TRUE;

// =========================
// TEST 1: Diagnostics count bounds
// =========================
GVL_TEST.G_Test_Total_Checks := GVL_TEST.G_Test_Total_CheckS + 1;
IF (GVL_STATUS.G_Diagnostics_Count < 0) OR (GVL_STATUS.G_Diagnostics_Count > 50) THEN
    GVL_TEST.G_Diagnostics_Count_Out_Of_Range := TRUE;
    GVL_TEST.G_Test_Failed_Checks := GVL_TEST.G_Test_Failed_Checks + 1;
    GVL_TEST.G_Test_Passed := FALSE;
END_IF;

// =========================
// TEST 2: Diagnostics duplicates (Code+Source)
// =========================
FOR L_i := 1 TO GVL_STATUS.G_Diagnostics_Count DO
    FOR L_j := L_i + 1 TO GVL_STATUS.G_Diagnostics_Count DO
        IF (GVL_STATUS.G_Diagnostics_Events[L_i].Code = GVL_STATUS.G_Diagnostics_Events[L_j].Code) AND
           (GVL_STATUS.G_Diagnostics_Events[L_i].Source = GVL_STATUS.G_Diagnostics_Events[L_j].Source) THEN
            GVL_TEST.G_Diagnostics_Duplicate_Event_Found := TRUE;
            GVL_TEST.G_Test_Failed_Checks := GVL_TEST.G_Test_Failed_Checks + 1;
            GVL_TEST.G_Test_Passed := FALSE;
        END_IF;
    END_FOR;
END_FOR;

GVL_TEST.G_Test_Total_Checks := GVL_TEST.G_Test_Total_Checks + 1;

// =========================
// TEST 3: Heating decision consistency
// =========================
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
        GVL_TEST.G_Test_Failed_Checks := GVL_TEST.G_Test_Failed_CheckS + 1;
        GVL_TEST.G_Test_Passed := FALSE;
    END_IF;

    IF fbDecisionTest.VO_Manifold_Enabled[L_i] THEN
        L_Used := L_Used + GVL_CONFIG.G_Manifold_Thermal_Weight[L_i];
    END_IF;
END_FOR;

IF L_Used > (GVL_CONFIG.G_Max_Thermal_Budget + 0.001) THEN
    GVL_TEST.G_Heating_Allocation_Budget_Exceeded := TRUE;
    GVL_TEST.G_Test_Failed_CheckS := GVL_TEST.G_Test_Failed_CheckS + 1;
    GVL_TEST.G_Test_Passed := FALSE;
END_IF;

GVL_TEST.G_Test_Total_Checks := GVL_TEST.G_Test_Total_CheckS + 1;

// =========================
// TEST 4: Safety latch consistency
// =========================
IF GVL_STATE.G_Safety_Gas_Latched AND (NOT GVL_INTENT_SAFETY.I_Gas_Alarm_Active) THEN
    GVL_TEST.G_Safety_Latched_Without_Intent := TRUE;
    GVL_TEST.G_Test_Failed_CheckS := GVL_TEST.G_Test_Failed_CheckS + 1;
    GVL_TEST.G_Test_Passed := FALSE;
END_IF;

GVL_TEST.G_Test_Total_CheckS := GVL_TEST.G_Test_Total_CheckS + 1;

// =========================
// FINAL STATUS
// =========================
IF GVL_TEST.G_Test_Passed THEN
    GVL_TEST.G_Test_Status_Msg := 'ALL TESTS PASSED';
ELSE
    GVL_TEST.G_Test_Status_Msg := 'TEST FAILURES DETECTED';
END_IF;
