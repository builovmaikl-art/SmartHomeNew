PROGRAM PRG_DryRun_TestRig
VAR
    fbDryRunHarness : FB_DryRun_Simulation_Harness;
    fbDryRunAssert  : FB_DryRun_Assertion_Map;

    L_DryRun_Enable : BOOL := FALSE;
    L_System_Time_MS : UDINT;

    L_Status_Line : STRING(120);
    L_Expected_Line : STRING(220);
END_VAR

// Local dry-run progression only.
// Not connected to production command/state paths yet.

fbDryRunHarness(
    VI_Enable := L_DryRun_Enable,
    VI_System_Time_MS := L_System_Time_MS,
    VO_Status_Msg => L_Status_Line
);

fbDryRunAssert(
    VI_Test_Step := fbDryRunHarness.VO_Test_Step,
    VO_Expected_Result => L_Expected_Line
);

// >>> BULK_SYNC_ANCHOR: PRG_DryRun_TestRig <<<
