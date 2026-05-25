PROGRAM PRG_Governance_Liveness_Integrity_Governor
VAR
    L_Now_MS : UDINT;
    L_Integrity_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Integrity_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Liveness_Integrity_Valid := FALSE;
GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Liveness_Integrity_Granted := FALSE;
GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Liveness_Integrity_Quarantine_Active := TRUE;

GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Execution_Liveness_Stable := FALSE;
GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Integrity_Governor_Scheduling_Canonical := FALSE;
GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.CrossGovernor_Execution_Continuity_Valid := FALSE;
GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Deterministic_Validation_Cycle_Integrity := FALSE;
GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Runtime_Liveness_Coherent := FALSE;

// Governance validator integrity required.
IF NOT GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Validator_Integrity_Granted THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 54000;
    L_Error_Text := 'Governance validator integrity not granted';
END_IF;

// Governance liveness degradation detectors.
IF GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Integrity_Governor_Starvation_Detected THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 54001;
    L_Error_Text := 'Integrity governor starvation detected';
END_IF;

IF GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Validation_Cycle_Skip_Detected THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 54002;
    L_Error_Text := 'Validation cycle skip detected';
END_IF;

IF GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.CrossGovernor_Execution_Jitter_Fork THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 54003;
    L_Error_Text := 'Cross-governor execution jitter fork detected';
END_IF;

IF GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Selective_Governance_Degradation_Detected THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 54004;
    L_Error_Text := 'Selective governance degradation detected';
END_IF;

IF GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Runtime_Governor_Execution_Stall_Detected THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 54005;
    L_Error_Text := 'Runtime governor execution stall detected';
END_IF;

IF GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Distributed_Liveness_Reality_Fork_Detected THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 54006;
    L_Error_Text := 'Distributed liveness reality fork detected';
END_IF;

// Governance liveness validation.
IF L_Integrity_Valid
AND NOT GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Validation_Cycle_Timing_Monotonic THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 54010;
    L_Error_Text := 'Validation cycle timing invalid';
END_IF;

IF L_Integrity_Valid
AND NOT GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Distributed_Governor_Execution_Aligned THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 54011;
    L_Error_Text := 'Distributed governor execution alignment invalid';
END_IF;

IF L_Integrity_Valid
AND NOT GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Runtime_Integrity_Causality_Grounded THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 54012;
    L_Error_Text := 'Runtime integrity causality invalid';
END_IF;

IF L_Integrity_Valid
AND NOT GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Execution_Budget_Stable THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 54013;
    L_Error_Text := 'Governance execution budget invalid';
END_IF;

IF L_Integrity_Valid THEN
    GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Liveness_Integrity_Valid := TRUE;
    GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Liveness_Integrity_Granted := TRUE;
    GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Liveness_Integrity_Quarantine_Active := FALSE;

    GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Execution_Liveness_Stable := TRUE;
    GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Integrity_Governor_Scheduling_Canonical := TRUE;
    GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.CrossGovernor_Execution_Continuity_Valid := TRUE;
    GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Deterministic_Validation_Cycle_Integrity := TRUE;
    GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Runtime_Liveness_Coherent := TRUE;

    GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Liveness_Integrity_Epoch :=
        GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Validator_Integrity_Epoch;

    GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Liveness_Integrity_Epoch_Coherent := TRUE;

    GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Liveness_Integrity_Last_Update_MS :=
        L_Now_MS;

    GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Liveness_Integrity_Lease_Expired := FALSE;

    GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Liveness_Integrity_Last_Error_Code := 0;
    GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Liveness_Integrity_Last_Error_Text := '';
ELSE
    GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Liveness_Integrity_Valid := FALSE;
    GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Liveness_Integrity_Granted := FALSE;
    GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Liveness_Integrity_Quarantine_Active := TRUE;

    GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Liveness_Integrity_Lease_Expired := TRUE;

    GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Liveness_Integrity_Last_Error_Code :=
        L_Error_Code;

    GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Liveness_Integrity_Last_Error_Text :=
        L_Error_Text;

    GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Liveness_Integrity_Invalidation_Count :=
        GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Liveness_Integrity_Invalidation_Count + 1;
END_IF;

END_PROGRAM