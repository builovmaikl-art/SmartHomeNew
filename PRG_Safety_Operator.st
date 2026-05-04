PROGRAM PRG_Safety_Operator
VAR
    fbSafetyWorkflow : FB_Safety_Workflow_Manager;
END_VAR

// Operator / test / recover workflow ownership.

fbSafetyWorkflow(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_Water_Selective_Recover := GVL_INTENT_USER.I_Water_Selective_Recover,
    VI_Gas_Selective_Recover := GVL_INTENT_USER.I_Gas_Selective_Recover,
    VI_Water_Valve_Test_Open := GVL_INTENT_USER.I_Water_Valve_Test_Open,
    VI_Water_Valve_Test_Close := GVL_INTENT_USER.I_Water_Valve_Test_Close,
    VI_Water_Valve_Test_Confirm := GVL_INTENT_USER.I_Water_Valve_Test_Confirm,
    VI_Gas_Valve_Test_Open := GVL_INTENT_USER.I_Gas_Valve_Test_Open,
    VI_Gas_Valve_Test_Close := GVL_INTENT_USER.I_Gas_Valve_Test_Close,
    VI_Gas_Valve_Test_Confirm := GVL_INTENT_USER.I_Gas_Valve_Test_Confirm
);

// propagate test timeout safety actions
IF fbSafetyWorkflow.VO_Water_Test_Timeout_Close_Required THEN
    GVL_INTENT_SAFETY.I_Test_Timeout_Water_Close := TRUE;
END_IF;

IF fbSafetyWorkflow.VO_Gas_Test_Timeout_Close_Required THEN
    GVL_INTENT_SAFETY.I_Test_Timeout_Gas_Close := TRUE;
END_IF;

// move recovery manual confirm here
IF GVL_INTENT_USER.I_Reset_Errors THEN
    GVL_SAFETY_RECOVERY.G_Recovery_Manual_Confirm := TRUE;
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_Safety_Operator <<<
END_PROGRAM
