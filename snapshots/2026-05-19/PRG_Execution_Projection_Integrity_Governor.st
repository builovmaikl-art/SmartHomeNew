PROGRAM PRG_Execution_Projection_Integrity_Governor
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
GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Projection_Integrity_Valid := FALSE;
GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Projection_Integrity_Granted := FALSE;
GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Projection_Integrity_Quarantine_Active := TRUE;

GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Authority_Projection_Consistent := FALSE;
GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.CrossDomain_Actuation_Enforcement_Aligned := FALSE;
GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Physical_Execution_Governance_Canonical := FALSE;
GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Actuation_Surface_Consensus_Valid := FALSE;
GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Projection_Lineage_Coherent := FALSE;

// Governance observer consensus required.
IF NOT GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Governance_Observer_Consensus_Granted THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 51000;
    L_Error_Text := 'Governance observer consensus not granted';
END_IF;

// Execution projection split-brain detectors.
IF GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Projection_Divergence_Detected THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 51001;
    L_Error_Text := 'Execution projection divergence detected';
END_IF;

IF GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Actuation_Path_Authority_Bypass_Detected THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 51002;
    L_Error_Text := 'Actuation path authority bypass detected';
END_IF;

IF GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.CrossDomain_Enforcement_Fork_Detected THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 51003;
    L_Error_Text := 'Cross-domain enforcement fork detected';
END_IF;

IF GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Canonical_Governance_Execution_Lost THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 51004;
    L_Error_Text := 'Canonical governance execution lost';
END_IF;

IF GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Runtime_Execution_Lineage_Drift_Detected THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 51005;
    L_Error_Text := 'Runtime execution lineage drift detected';
END_IF;

IF GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Distributed_Actuation_Reality_Fork_Detected THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 51006;
    L_Error_Text := 'Distributed actuation reality fork detected';
END_IF;

// Execution enforcement validation.
IF L_Integrity_Valid
AND NOT GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Runtime_Actuation_Projection_Stable THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 51010;
    L_Error_Text := 'Runtime actuation projection invalid';
END_IF;

IF L_Integrity_Valid
AND NOT GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Distributed_Execution_Equivalence_Valid THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 51011;
    L_Error_Text := 'Distributed execution equivalence invalid';
END_IF;

IF L_Integrity_Valid
AND NOT GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Governance_Causality_Grounded THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 51012;
    L_Error_Text := 'Execution governance causality invalid';
END_IF;

IF L_Integrity_Valid
AND NOT GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Physical_Enforcement_Timeline_Monotonic THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 51013;
    L_Error_Text := 'Physical enforcement timeline monotonicity invalid';
END_IF;

IF L_Integrity_Valid THEN
    GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Projection_Integrity_Valid := TRUE;
    GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Projection_Integrity_Granted := TRUE;
    GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Projection_Integrity_Quarantine_Active := FALSE;

    GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Authority_Projection_Consistent := TRUE;
    GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.CrossDomain_Actuation_Enforcement_Aligned := TRUE;
    GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Physical_Execution_Governance_Canonical := TRUE;
    GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Actuation_Surface_Consensus_Valid := TRUE;
    GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Projection_Lineage_Coherent := TRUE;

    GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Projection_Integrity_Epoch :=
        GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Governance_Observer_Consensus_Epoch;

    GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Projection_Integrity_Epoch_Coherent := TRUE;

    GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Projection_Integrity_Last_Update_MS :=
        L_Now_MS;

    GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Projection_Integrity_Lease_Expired := FALSE;

    GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Projection_Integrity_Last_Error_Code := 0;
    GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Projection_Integrity_Last_Error_Text := '';
ELSE
    GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Projection_Integrity_Valid := FALSE;
    GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Projection_Integrity_Granted := FALSE;
    GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Projection_Integrity_Quarantine_Active := TRUE;

    GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Projection_Integrity_Lease_Expired := TRUE;

    GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Projection_Integrity_Last_Error_Code :=
        L_Error_Code;

    GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Projection_Integrity_Last_Error_Text :=
        L_Error_Text;

    GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Projection_Integrity_Invalidation_Count :=
        GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Projection_Integrity_Invalidation_Count + 1;
END_IF;

END_PROGRAM