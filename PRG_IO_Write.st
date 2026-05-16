PROGRAM PRG_IO_Write
VAR
    L_i : INT;
    L_Heating_Forced_Off : BOOL;
    L_Vent_Forced_Off : BOOL;
    L_Water_Forced_Off : BOOL;
    L_Access_Forced_Off : BOOL;
    L_Access_Safety_Override : BOOL;
    L_Global_Hard_Stop : BOOL;
    L_Gas_Safety_Stop : BOOL;
    L_Freeze_Active : BOOL;
    L_Gas_Fire_Siren_Enable : BOOL;
    L_PreOutput_Block_IO : BOOL;
    L_Output_Freshness_Block : BOOL;
    L_Output_Publication_Block : BOOL;
    L_Distributed_Publication_Block : BOOL;
    L_Snapshot_Block : BOOL;
    L_Distributed_Execution_Block : BOOL;
    L_Gas_Siren_Authority : BOOL;
    L_Fire_Siren_Authority : BOOL;
    fbTrace : FB_Trace_Write;
END_VAR

L_PreOutput_Block_IO := GVL_COMMAND_VERIFY.PreOutput_Block_IO;
L_Output_Freshness_Block := GVL_OUTPUT_EPOCH.Output_Forced_Safe_Decay;

L_Output_Publication_Block :=
    (NOT GVL_OUTPUT_EPOCH.Output_Publication_Valid)
    OR (NOT GVL_OUTPUT_EPOCH.Output_Runtime_Epoch_Valid)
    OR GVL_OUTPUT_EPOCH.Output_Lease_Expired;

// Final distributed publication continuity authority.
L_Distributed_Publication_Block :=
    (NOT GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Valid)
    OR GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Quarantine_Active
    OR GVL_DISTRIBUTED_COMMIT.Commit_Lease_Expired
    OR (NOT GVL_DISTRIBUTED_SNAPSHOT.Distributed_Publication_Reconciled)
    OR (NOT GVL_DISTRIBUTED_SNAPSHOT.Distributed_Publication_Freeze_Valid)
    OR (NOT GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Consistent);

L_Snapshot_Block :=
    (NOT GVL_RUNTIME_SNAPSHOT.Snapshot_Frozen)
    OR (NOT GVL_RUNTIME_SNAPSHOT.Snapshot_Publication_Allowed)
    OR (NOT GVL_RUNTIME_SNAPSHOT.Snapshot_Copy_Valid)
    OR (NOT GVL_RUNTIME_SNAPSHOT.Snapshot_Isolation_Valid)
    OR GVL_RUNTIME_SNAPSHOT.Snapshot_Mutation_Detected;

L_Distributed_Execution_Block :=
    NOT GVL_Distributed_Execution_Gates.G_Can_Execute
    OR NOT GVL_Distributed_Execution_Gates.G_Can_Own_Projection;

L_Global_Hard_Stop :=
    GVL_COMMAND_SHADOW.G_Heating_Emergency_Stop
    OR L_PreOutput_Block_IO
    OR L_Output_Freshness_Block
    OR L_Output_Publication_Block
    OR L_Distributed_Publication_Block
    OR L_Snapshot_Block
    OR L_Distributed_Execution_Block;

L_Gas_Safety_Stop := GVL_COMMAND_SHADOW.G_Heating_Gas_Safety_Stop OR GVL_COMMAND_SHADOW.G_Boiler_Stop;
L_Freeze_Active := GVL_STATE.G_Safety_Freeze_Risk;
L_Gas_Fire_Siren_Enable := GVL_ALARM.G_Gas_Fire_Siren OR GVL_ALARM.G_Global_Siren OR GVL_ALARM.G_Global_Critical;

L_Gas_Siren_Authority := GVL_HEALTH_BRIDGE.G_Gas_Detected OR GVL_HEALTH_BRIDGE.G_CO_Alarm_Level OR GVL_STATE.G_Safety_Gas_Latched;
L_Fire_Siren_Authority := GVL_HEALTH_BRIDGE.G_Smoke_Detected OR GVL_STATE.G_Safety_Smoke_Latched;

IF NOT GVL_STATUS.G_Is_Active_PLC OR L_Global_Hard_Stop THEN

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
        GVL_IO.DO_Zone_Valves[L_i] := FALSE;
    END_FOR;

    GVL_IO.DO_Gas_Valve_Close := TRUE;

    IF L_Distributed_Publication_Block THEN
        fbTrace(
            iLayer := TRACE_IO,
            iSource := SRC_IO,
            iReason := REASON_SAFETY_BLOCK,
            iValueBool := TRUE,
            iValueReal := UDINT_TO_REAL(GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Last_Error_Code),
            iText := 'IO blocked by distributed publication continuity authority');
    END_IF;

    IF L_Output_Publication_Block THEN
        fbTrace(
            iLayer := TRACE_IO,
            iSource := SRC_IO,
            iReason := REASON_SAFETY_BLOCK,
            iValueBool := TRUE,
            iValueReal := UDINT_TO_REAL(GVL_OUTPUT_EPOCH.Output_Last_Error_Code),
            iText := 'IO blocked by finalized output publication authority');
    END_IF;

    RETURN;
END_IF;

fbTrace(
    iLayer := TRACE_IO,
    iSource := SRC_IO,
    iReason := REASON_DOMAIN_PROJECTION,
    iValueBool := TRUE,
    iValueReal := 0.0,
    iText := 'IO write projection executed');
END_PROGRAM