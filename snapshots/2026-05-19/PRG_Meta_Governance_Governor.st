PROGRAM PRG_Meta_Governance_Governor
VAR
    L_Now_MS : UDINT;
    L_Meta_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Meta_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_META_GOVERNANCE_FABRIC.Meta_Governance_Valid := FALSE;
GVL_META_GOVERNANCE_FABRIC.Meta_Governance_Granted := FALSE;
GVL_META_GOVERNANCE_FABRIC.Meta_Governance_Quarantine_Active := TRUE;

GVL_META_GOVERNANCE_FABRIC.Governance_Graph_Acyclic := FALSE;
GVL_META_GOVERNANCE_FABRIC.Authority_Rooting_Valid := FALSE;
GVL_META_GOVERNANCE_FABRIC.Independent_Validation_Preserved := FALSE;
GVL_META_GOVERNANCE_FABRIC.Meta_Consistency_Coherent := FALSE;
GVL_META_GOVERNANCE_FABRIC.Recursive_Trust_Boundaries_Stable := FALSE;

// Epistemic integrity required.
IF NOT GVL_EPISTEMIC_INTEGRITY_FABRIC.Epistemic_Integrity_Granted THEN
    L_Meta_Valid := FALSE;
    L_Error_Code := 45000;
    L_Error_Text := 'Epistemic integrity authority not granted';
END_IF;

// Meta-governance recursion detectors.
IF GVL_META_GOVERNANCE_FABRIC.Recursive_Authority_Dependency_Detected THEN
    L_Meta_Valid := FALSE;
    L_Error_Code := 45001;
    L_Error_Text := 'Recursive authority dependency detected';
END_IF;

IF GVL_META_GOVERNANCE_FABRIC.Circular_Validation_Chain_Detected THEN
    L_Meta_Valid := FALSE;
    L_Error_Code := 45002;
    L_Error_Text := 'Circular validation chain detected';
END_IF;

IF GVL_META_GOVERNANCE_FABRIC.SelfJustifying_Governance_State_Detected THEN
    L_Meta_Valid := FALSE;
    L_Error_Code := 45003;
    L_Error_Text := 'Self-justifying governance state detected';
END_IF;

IF GVL_META_GOVERNANCE_FABRIC.Epistemic_Recursion_Leakage_Detected THEN
    L_Meta_Valid := FALSE;
    L_Error_Code := 45004;
    L_Error_Text := 'Epistemic recursion leakage detected';
END_IF;

IF GVL_META_GOVERNANCE_FABRIC.Authority_Bootstrap_Paradox_Detected THEN
    L_Meta_Valid := FALSE;
    L_Error_Code := 45005;
    L_Error_Text := 'Authority bootstrap paradox detected';
END_IF;

IF GVL_META_GOVERNANCE_FABRIC.Meta_Consistency_Erosion_Detected THEN
    L_Meta_Valid := FALSE;
    L_Error_Code := 45006;
    L_Error_Text := 'Meta-consistency erosion detected';
END_IF;

// Meta-governance consistency validation.
IF L_Meta_Valid
AND NOT GVL_META_GOVERNANCE_FABRIC.Validator_Independence_Valid THEN
    L_Meta_Valid := FALSE;
    L_Error_Code := 45010;
    L_Error_Text := 'Validator independence invalid';
END_IF;

IF L_Meta_Valid
AND NOT GVL_META_GOVERNANCE_FABRIC.CrossLayer_Causality_Grounded THEN
    L_Meta_Valid := FALSE;
    L_Error_Code := 45011;
    L_Error_Text := 'Cross-layer causality grounding invalid';
END_IF;

IF L_Meta_Valid
AND NOT GVL_META_GOVERNANCE_FABRIC.Bootstrap_Validation_Absent THEN
    L_Meta_Valid := FALSE;
    L_Error_Code := 45012;
    L_Error_Text := 'Bootstrap validation absence invalid';
END_IF;

IF L_Meta_Valid
AND NOT GVL_META_GOVERNANCE_FABRIC.SelfReference_Elimination_Valid THEN
    L_Meta_Valid := FALSE;
    L_Error_Code := 45013;
    L_Error_Text := 'Self-reference elimination invalid';
END_IF;

IF L_Meta_Valid THEN
    GVL_META_GOVERNANCE_FABRIC.Meta_Governance_Valid := TRUE;
    GVL_META_GOVERNANCE_FABRIC.Meta_Governance_Granted := TRUE;
    GVL_META_GOVERNANCE_FABRIC.Meta_Governance_Quarantine_Active := FALSE;

    GVL_META_GOVERNANCE_FABRIC.Governance_Graph_Acyclic := TRUE;
    GVL_META_GOVERNANCE_FABRIC.Authority_Rooting_Valid := TRUE;
    GVL_META_GOVERNANCE_FABRIC.Independent_Validation_Preserved := TRUE;
    GVL_META_GOVERNANCE_FABRIC.Meta_Consistency_Coherent := TRUE;
    GVL_META_GOVERNANCE_FABRIC.Recursive_Trust_Boundaries_Stable := TRUE;

    GVL_META_GOVERNANCE_FABRIC.Meta_Governance_Epoch :=
        GVL_EPISTEMIC_INTEGRITY_FABRIC.Epistemic_Integrity_Epoch;

    GVL_META_GOVERNANCE_FABRIC.Meta_Governance_Epoch_Coherent := TRUE;

    GVL_META_GOVERNANCE_FABRIC.Meta_Governance_Last_Update_MS :=
        L_Now_MS;

    GVL_META_GOVERNANCE_FABRIC.Meta_Governance_Lease_Expired := FALSE;

    GVL_META_GOVERNANCE_FABRIC.Meta_Governance_Last_Error_Code := 0;
    GVL_META_GOVERNANCE_FABRIC.Meta_Governance_Last_Error_Text := '';
ELSE
    GVL_META_GOVERNANCE_FABRIC.Meta_Governance_Valid := FALSE;
    GVL_META_GOVERNANCE_FABRIC.Meta_Governance_Granted := FALSE;
    GVL_META_GOVERNANCE_FABRIC.Meta_Governance_Quarantine_Active := TRUE;

    GVL_META_GOVERNANCE_FABRIC.Meta_Governance_Lease_Expired := TRUE;

    GVL_META_GOVERNANCE_FABRIC.Meta_Governance_Last_Error_Code :=
        L_Error_Code;

    GVL_META_GOVERNANCE_FABRIC.Meta_Governance_Last_Error_Text :=
        L_Error_Text;

    GVL_META_GOVERNANCE_FABRIC.Meta_Governance_Invalidation_Count :=
        GVL_META_GOVERNANCE_FABRIC.Meta_Governance_Invalidation_Count + 1;
END_IF;

END_PROGRAM