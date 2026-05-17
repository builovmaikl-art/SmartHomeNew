PROGRAM PRG_Semantic_Federation_Governor
VAR
    L_Now_MS : UDINT;
    L_Federation_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Federation_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_SEMANTIC_FEDERATION_FABRIC.Semantic_Federation_Valid := FALSE;
GVL_SEMANTIC_FEDERATION_FABRIC.Semantic_Federation_Granted := FALSE;
GVL_SEMANTIC_FEDERATION_FABRIC.Semantic_Federation_Quarantine_Active := TRUE;

GVL_SEMANTIC_FEDERATION_FABRIC.External_SCADA_Semantics_Coherent := FALSE;
GVL_SEMANTIC_FEDERATION_FABRIC.Cloud_Authority_Projection_Aligned := FALSE;
GVL_SEMANTIC_FEDERATION_FABRIC.MQTT_Semantic_State_Fresh := FALSE;
GVL_SEMANTIC_FEDERATION_FABRIC.ThirdParty_Integration_Trust_Valid := FALSE;
GVL_SEMANTIC_FEDERATION_FABRIC.Federated_Observability_Coherent := FALSE;

// Operator semantic alignment required.
IF NOT GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Semantic_Alignment_Granted THEN
    L_Federation_Valid := FALSE;
    L_Error_Code := 41000;
    L_Error_Text := 'Operator semantic alignment not granted';
END_IF;

// Ecosystem semantic split-brain detectors.
IF GVL_SEMANTIC_FEDERATION_FABRIC.External_Semantic_Lag_Detected THEN
    L_Federation_Valid := FALSE;
    L_Error_Code := 41001;
    L_Error_Text := 'External semantic lag detected';
END_IF;

IF GVL_SEMANTIC_FEDERATION_FABRIC.SCADA_Projection_Skew_Detected THEN
    L_Federation_Valid := FALSE;
    L_Error_Code := 41002;
    L_Error_Text := 'SCADA projection skew detected';
END_IF;

IF GVL_SEMANTIC_FEDERATION_FABRIC.Cloud_Authority_Desynchronization_Detected THEN
    L_Federation_Valid := FALSE;
    L_Error_Code := 41003;
    L_Error_Text := 'Cloud authority desynchronization detected';
END_IF;

IF GVL_SEMANTIC_FEDERATION_FABRIC.ThirdParty_Semantic_Drift_Detected THEN
    L_Federation_Valid := FALSE;
    L_Error_Code := 41004;
    L_Error_Text := 'Third-party semantic drift detected';
END_IF;

IF GVL_SEMANTIC_FEDERATION_FABRIC.Integration_Trust_Divergence_Detected THEN
    L_Federation_Valid := FALSE;
    L_Error_Code := 41005;
    L_Error_Text := 'Integration trust divergence detected';
END_IF;

IF GVL_SEMANTIC_FEDERATION_FABRIC.Federated_Authority_Inconsistency_Detected THEN
    L_Federation_Valid := FALSE;
    L_Error_Code := 41006;
    L_Error_Text := 'Federated authority inconsistency detected';
END_IF;

// External semantic federation validation.
IF L_Federation_Valid
AND NOT GVL_SEMANTIC_FEDERATION_FABRIC.Exported_Authority_State_Coherent THEN
    L_Federation_Valid := FALSE;
    L_Error_Code := 41010;
    L_Error_Text := 'Exported authority state coherence invalid';
END_IF;

IF L_Federation_Valid
AND NOT GVL_SEMANTIC_FEDERATION_FABRIC.Federation_Projection_Temporal_Stable THEN
    L_Federation_Valid := FALSE;
    L_Error_Code := 41011;
    L_Error_Text := 'Federation projection temporal stability invalid';
END_IF;

IF L_Federation_Valid
AND NOT GVL_SEMANTIC_FEDERATION_FABRIC.External_Runtime_Interpretation_Aligned THEN
    L_Federation_Valid := FALSE;
    L_Error_Code := 41012;
    L_Error_Text := 'External runtime interpretation alignment invalid';
END_IF;

IF L_Federation_Valid
AND NOT GVL_SEMANTIC_FEDERATION_FABRIC.Federated_Trust_Boundary_Stable THEN
    L_Federation_Valid := FALSE;
    L_Error_Code := 41013;
    L_Error_Text := 'Federated trust boundary unstable';
END_IF;

IF L_Federation_Valid THEN
    GVL_SEMANTIC_FEDERATION_FABRIC.Semantic_Federation_Valid := TRUE;
    GVL_SEMANTIC_FEDERATION_FABRIC.Semantic_Federation_Granted := TRUE;
    GVL_SEMANTIC_FEDERATION_FABRIC.Semantic_Federation_Quarantine_Active := FALSE;

    GVL_SEMANTIC_FEDERATION_FABRIC.External_SCADA_Semantics_Coherent := TRUE;
    GVL_SEMANTIC_FEDERATION_FABRIC.Cloud_Authority_Projection_Aligned := TRUE;
    GVL_SEMANTIC_FEDERATION_FABRIC.MQTT_Semantic_State_Fresh := TRUE;
    GVL_SEMANTIC_FEDERATION_FABRIC.ThirdParty_Integration_Trust_Valid := TRUE;
    GVL_SEMANTIC_FEDERATION_FABRIC.Federated_Observability_Coherent := TRUE;

    GVL_SEMANTIC_FEDERATION_FABRIC.Semantic_Federation_Epoch :=
        GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Alignment_Epoch;

    GVL_SEMANTIC_FEDERATION_FABRIC.Semantic_Federation_Epoch_Coherent := TRUE;

    GVL_SEMANTIC_FEDERATION_FABRIC.Semantic_Federation_Last_Update_MS :=
        L_Now_MS;

    GVL_SEMANTIC_FEDERATION_FABRIC.Semantic_Federation_Lease_Expired := FALSE;

    GVL_SEMANTIC_FEDERATION_FABRIC.Semantic_Federation_Last_Error_Code := 0;
    GVL_SEMANTIC_FEDERATION_FABRIC.Semantic_Federation_Last_Error_Text := '';
ELSE
    GVL_SEMANTIC_FEDERATION_FABRIC.Semantic_Federation_Valid := FALSE;
    GVL_SEMANTIC_FEDERATION_FABRIC.Semantic_Federation_Granted := FALSE;
    GVL_SEMANTIC_FEDERATION_FABRIC.Semantic_Federation_Quarantine_Active := TRUE;

    GVL_SEMANTIC_FEDERATION_FABRIC.Semantic_Federation_Lease_Expired := TRUE;

    GVL_SEMANTIC_FEDERATION_FABRIC.Semantic_Federation_Last_Error_Code :=
        L_Error_Code;

    GVL_SEMANTIC_FEDERATION_FABRIC.Semantic_Federation_Last_Error_Text :=
        L_Error_Text;

    GVL_SEMANTIC_FEDERATION_FABRIC.Semantic_Federation_Invalidation_Count :=
        GVL_SEMANTIC_FEDERATION_FABRIC.Semantic_Federation_Invalidation_Count + 1;
END_IF;

END_PROGRAM