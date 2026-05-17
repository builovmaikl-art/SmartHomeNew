PROGRAM PRG_Actuator_Semantic_Verification_Governor
VAR
    L_Now_MS : UDINT;
    L_Actuator_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Actuator_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_ACTUATOR_SEMANTIC_VERIFICATION.Actuator_Semantic_Verification_Valid := FALSE;
GVL_ACTUATOR_SEMANTIC_VERIFICATION.Actuator_Semantic_Verification_Granted := FALSE;
GVL_ACTUATOR_SEMANTIC_VERIFICATION.Actuator_Semantic_Verification_Quarantine_Active := TRUE;

GVL_ACTUATOR_SEMANTIC_VERIFICATION.Valve_Semantic_Realization_Valid := FALSE;
GVL_ACTUATOR_SEMANTIC_VERIFICATION.Relay_Semantic_Realization_Valid := FALSE;
GVL_ACTUATOR_SEMANTIC_VERIFICATION.Pump_Semantic_Realization_Valid := FALSE;
GVL_ACTUATOR_SEMANTIC_VERIFICATION.Fan_Semantic_Realization_Valid := FALSE;
GVL_ACTUATOR_SEMANTIC_VERIFICATION.Hydraulic_Response_Valid := FALSE;

// Control temporal coherence required.
IF NOT GVL_CONTROL_TIMING_FABRIC.Control_Temporal_Coherence_Granted THEN
    L_Actuator_Valid := FALSE;
    L_Error_Code := 36000;
    L_Error_Text := 'Control temporal coherence not granted';
END_IF;

// Semantic realization failure detectors.
IF GVL_ACTUATOR_SEMANTIC_VERIFICATION.False_Positive_Actuation_Detected THEN
    L_Actuator_Valid := FALSE;
    L_Error_Code := 36001;
    L_Error_Text := 'False-positive actuation detected';
END_IF;

IF GVL_ACTUATOR_SEMANTIC_VERIFICATION.Mechanical_NonRealization_Detected THEN
    L_Actuator_Valid := FALSE;
    L_Error_Code := 36002;
    L_Error_Text := 'Mechanical non-realization detected';
END_IF;

IF GVL_ACTUATOR_SEMANTIC_VERIFICATION.Welded_Relay_Semantics_Detected THEN
    L_Actuator_Valid := FALSE;
    L_Error_Code := 36003;
    L_Error_Text := 'Welded relay semantics detected';
END_IF;

IF GVL_ACTUATOR_SEMANTIC_VERIFICATION.Hydraulic_NoEffect_Execution_Detected THEN
    L_Actuator_Valid := FALSE;
    L_Error_Code := 36004;
    L_Error_Text := 'Hydraulic no-effect execution detected';
END_IF;

IF GVL_ACTUATOR_SEMANTIC_VERIFICATION.Airflow_Realization_Mismatch_Detected THEN
    L_Actuator_Valid := FALSE;
    L_Error_Code := 36005;
    L_Error_Text := 'Airflow realization mismatch detected';
END_IF;

IF GVL_ACTUATOR_SEMANTIC_VERIFICATION.Physical_Convergence_Divergence_Detected THEN
    L_Actuator_Valid := FALSE;
    L_Error_Code := 36006;
    L_Error_Text := 'Physical convergence divergence detected';
END_IF;

// Physical semantic convergence validation.
IF L_Actuator_Valid
AND NOT GVL_ACTUATOR_SEMANTIC_VERIFICATION.Physical_Effect_Converged THEN
    L_Actuator_Valid := FALSE;
    L_Error_Code := 36010;
    L_Error_Text := 'Physical effect convergence invalid';
END_IF;

IF L_Actuator_Valid
AND NOT GVL_ACTUATOR_SEMANTIC_VERIFICATION.Actuation_Response_Temporal_Valid THEN
    L_Actuator_Valid := FALSE;
    L_Error_Code := 36011;
    L_Error_Text := 'Actuation response timing invalid';
END_IF;

IF L_Actuator_Valid
AND NOT GVL_ACTUATOR_SEMANTIC_VERIFICATION.Sensor_Confirmed_Execution_Valid THEN
    L_Actuator_Valid := FALSE;
    L_Error_Code := 36012;
    L_Error_Text := 'Sensor-confirmed execution invalid';
END_IF;

IF L_Actuator_Valid
AND NOT GVL_ACTUATOR_SEMANTIC_VERIFICATION.Semantic_Outcome_Aligned THEN
    L_Actuator_Valid := FALSE;
    L_Error_Code := 36013;
    L_Error_Text := 'Semantic outcome alignment invalid';
END_IF;

IF L_Actuator_Valid THEN
    GVL_ACTUATOR_SEMANTIC_VERIFICATION.Actuator_Semantic_Verification_Valid := TRUE;
    GVL_ACTUATOR_SEMANTIC_VERIFICATION.Actuator_Semantic_Verification_Granted := TRUE;
    GVL_ACTUATOR_SEMANTIC_VERIFICATION.Actuator_Semantic_Verification_Quarantine_Active := FALSE;

    GVL_ACTUATOR_SEMANTIC_VERIFICATION.Valve_Semantic_Realization_Valid := TRUE;
    GVL_ACTUATOR_SEMANTIC_VERIFICATION.Relay_Semantic_Realization_Valid := TRUE;
    GVL_ACTUATOR_SEMANTIC_VERIFICATION.Pump_Semantic_Realization_Valid := TRUE;
    GVL_ACTUATOR_SEMANTIC_VERIFICATION.Fan_Semantic_Realization_Valid := TRUE;
    GVL_ACTUATOR_SEMANTIC_VERIFICATION.Hydraulic_Response_Valid := TRUE;

    GVL_ACTUATOR_SEMANTIC_VERIFICATION.Actuator_Verification_Epoch :=
        GVL_CONTROL_TIMING_FABRIC.Control_Timing_Epoch;

    GVL_ACTUATOR_SEMANTIC_VERIFICATION.Actuator_Verification_Epoch_Coherent := TRUE;

    GVL_ACTUATOR_SEMANTIC_VERIFICATION.Actuator_Verification_Last_Update_MS :=
        L_Now_MS;

    GVL_ACTUATOR_SEMANTIC_VERIFICATION.Actuator_Verification_Lease_Expired := FALSE;

    GVL_ACTUATOR_SEMANTIC_VERIFICATION.Actuator_Verification_Last_Error_Code := 0;
    GVL_ACTUATOR_SEMANTIC_VERIFICATION.Actuator_Verification_Last_Error_Text := '';
ELSE
    GVL_ACTUATOR_SEMANTIC_VERIFICATION.Actuator_Semantic_Verification_Valid := FALSE;
    GVL_ACTUATOR_SEMANTIC_VERIFICATION.Actuator_Semantic_Verification_Granted := FALSE;
    GVL_ACTUATOR_SEMANTIC_VERIFICATION.Actuator_Semantic_Verification_Quarantine_Active := TRUE;

    GVL_ACTUATOR_SEMANTIC_VERIFICATION.Actuator_Verification_Lease_Expired := TRUE;

    GVL_ACTUATOR_SEMANTIC_VERIFICATION.Actuator_Verification_Last_Error_Code :=
        L_Error_Code;

    GVL_ACTUATOR_SEMANTIC_VERIFICATION.Actuator_Verification_Last_Error_Text :=
        L_Error_Text;

    GVL_ACTUATOR_SEMANTIC_VERIFICATION.Actuator_Verification_Invalidation_Count :=
        GVL_ACTUATOR_SEMANTIC_VERIFICATION.Actuator_Verification_Invalidation_Count + 1;
END_IF;

END_PROGRAM