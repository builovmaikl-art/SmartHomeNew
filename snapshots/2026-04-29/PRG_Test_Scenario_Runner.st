PROGRAM PRG_Test_Scenario_Runner

IF NOT GVL_TEST.G_Test_Enable THEN
    RETURN;
END_IF;

IF NOT GVL_TEST_INJECTION.G_Scenario_Enable THEN
    RETURN;
END_IF;

// Reset request
IF GVL_TEST_INJECTION.G_Scenario_Reset_Request THEN
    GVL_TEST_INJECTION.G_Inject_Enable := FALSE;
    GVL_TEST_INJECTION.G_Inject_Gas_Level := 0.0;
    GVL_TEST_INJECTION.G_Inject_Force_Gas_Alarm_Reset := FALSE;
    GVL_TEST_INJECTION.G_Inject_Force_IO_Offline := FALSE;
    GVL_TEST_INJECTION.G_Scenario_Step := 0;
    GVL_TEST_INJECTION.G_Scenario_Done := FALSE;
    GVL_TEST_INJECTION.G_Scenario_Failed := FALSE;
    GVL_TEST_INJECTION.G_Scenario_Reset_Request := FALSE;
END_IF;

CASE GVL_TEST_INJECTION.G_Scenario_Current OF

// =========================
// SCENARIO 1: GAS + WATCHDOG
// =========================
1:
    CASE GVL_TEST_INJECTION.G_Scenario_Step OF
    0:
        GVL_TEST_INJECTION.G_Inject_Enable := TRUE;
        GVL_TEST_INJECTION.G_Inject_Gas_Level := 50.0;
        GVL_TEST_INJECTION.G_Scenario_Status_Msg := 'Gas injected';
        GVL_TEST_INJECTION.G_Scenario_Step := 1;

    1:
        GVL_TEST_INJECTION.G_Inject_Force_Gas_Alarm_Reset := TRUE;
        GVL_TEST_INJECTION.G_Scenario_Status_Msg := 'Forced alarm reset';
        GVL_TEST_INJECTION.G_Scenario_Step := 2;

    2:
        IF GVL_TEST.G_Ownership_Violation THEN
            GVL_TEST_INJECTION.G_Scenario_Done := TRUE;
            GVL_TEST_INJECTION.G_Scenario_Status_Msg := 'Watchdog OK';
        ELSE
            GVL_TEST_INJECTION.G_Scenario_Failed := TRUE;
        END_IF;
    END_CASE;

// =========================
// SCENARIO 2: IO OFFLINE
// =========================
2:
    CASE GVL_TEST_INJECTION.G_Scenario_Step OF
    0:
        GVL_TEST_INJECTION.G_Inject_Enable := TRUE;
        GVL_TEST_INJECTION.G_Inject_Force_IO_Offline := TRUE;
        GVL_TEST_INJECTION.G_Scenario_Status_Msg := 'IO offline injected';
        GVL_TEST_INJECTION.G_Scenario_Step := 1;

    1:
        IF NOT GVL_STATUS.G_IO_Modules_Online[1] THEN
            GVL_TEST_INJECTION.G_Scenario_Done := TRUE;
            GVL_TEST_INJECTION.G_Scenario_Status_Msg := 'IO fail-safe OK';
        ELSE
            GVL_TEST_INJECTION.G_Scenario_Failed := TRUE;
        END_IF;
    END_CASE;

END_CASE;

// Auto advance
IF GVL_TEST_INJECTION.G_Scenario_Done AND GVL_TEST_INJECTION.G_Scenario_Auto_Run THEN
    GVL_TEST_INJECTION.G_Scenario_Current := GVL_TEST_INJECTION.G_Scenario_Current + 1;
    GVL_TEST_INJECTION.G_Scenario_Reset_Request := TRUE;
END_IF;
