PROGRAM PRG_Observability_Truth_Governor
VAR
    L_Now_MS : UDINT;
    L_Observability_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Observability_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_OBSERVABILITY_TRUTH.Observability_Truth_Valid := FALSE;
GVL_OBSERVABILITY_TRUTH.Observability_Truth_Granted := FALSE;
GVL_OBSERVABILITY_TRUTH.Observability_Truth_Quarantine_Active := TRUE;

GVL_OBSERVABILITY_TRUTH.HMI_Authority_Coherent := FALSE;
GVL_OBSERVABILITY_TRUTH.Alarm_Authority_Coherent := FALSE;
GVL_OBSERVABILITY_TRUTH.Trend_Authority_Coherent := FALSE;
GVL_OBSERVABILITY_TRUTH.Diagnostics_Authority_Coherent := FALSE;
GVL_OBSERVABILITY_TRUTH.History_Authority_Coherent := FALSE;

// Semantic continuity authority required.
IF NOT GVL_SEMANTIC_CONTINUITY.Semantic_Continuity_Granted THEN
    L_Observability_Valid := FALSE;
    L_Error_Code := 32000;
    L_Error_Text := 'Semantic continuity authority not granted';
END_IF;

// Observability split-brain detectors.
IF GVL_OBSERVABILITY_TRUTH.Stale_HMI_Epoch_Detected THEN
    L_Observability_Valid := FALSE;
    L_Error_Code := 32001;
    L_Error_Text := 'Stale HMI epoch detected';
END_IF;

IF GVL_OBSERVABILITY_TRUTH.Alarm_Publication_Lag_Detected THEN
    L_Observability_Valid := FALSE;
    L_Error_Code := 32002;
    L_Error_Text := 'Alarm publication lag detected';
END_IF;

IF GVL_OBSERVABILITY_TRUTH.Trend_Causality_Skew_Detected THEN
    L_Observability_Valid := FALSE;
    L_Error_Code := 32003;
    L_Error_Text := 'Trend causality skew detected';
END_IF;

IF GVL_OBSERVABILITY_TRUTH.Diagnostic_Truth_Race_Detected THEN
    L_Observability_Valid := FALSE;
    L_Error_Code := 32004;
    L_Error_Text := 'Diagnostic truth race detected';
END_IF;

IF GVL_OBSERVABILITY_TRUTH.Operator_Visibility_Fragmentation_Detected THEN
    L_Observability_Valid := FALSE;
    L_Error_Code := 32005;
    L_Error_Text := 'Operator visibility fragmentation detected';
END_IF;

IF GVL_OBSERVABILITY_TRUTH.Authority_UI_Divergence_Detected THEN
    L_Observability_Valid := FALSE;
    L_Error_Code := 32006;
    L_Error_Text := 'Authority/UI divergence detected';
END_IF;

// Projection causality validation.
IF L_Observability_Valid
AND NOT GVL_OBSERVABILITY_TRUTH.HMI_Epoch_Coherent THEN
    L_Observability_Valid := FALSE;
    L_Error_Code := 32010;
    L_Error_Text := 'HMI epoch coherence invalid';
END_IF;

IF L_Observability_Valid
AND NOT GVL_OBSERVABILITY_TRUTH.Alarm_Publication_Coherent THEN
    L_Observability_Valid := FALSE;
    L_Error_Code := 32011;
    L_Error_Text := 'Alarm publication coherence invalid';
END_IF;

IF L_Observability_Valid
AND NOT GVL_OBSERVABILITY_TRUTH.Trend_Causality_Coherent THEN
    L_Observability_Valid := FALSE;
    L_Error_Code := 32012;
    L_Error_Text := 'Trend causality coherence invalid';
END_IF;

IF L_Observability_Valid
AND NOT GVL_OBSERVABILITY_TRUTH.Diagnostics_Causality_Coherent THEN
    L_Observability_Valid := FALSE;
    L_Error_Code := 32013;
    L_Error_Text := 'Diagnostics causality coherence invalid';
END_IF;

IF L_Observability_Valid
AND NOT GVL_OBSERVABILITY_TRUTH.Operator_Visibility_Consistent THEN
    L_Observability_Valid := FALSE;
    L_Error_Code := 32014;
    L_Error_Text := 'Operator visibility consistency invalid';
END_IF;

IF L_Observability_Valid THEN
    GVL_OBSERVABILITY_TRUTH.Observability_Truth_Valid := TRUE;
    GVL_OBSERVABILITY_TRUTH.Observability_Truth_Granted := TRUE;
    GVL_OBSERVABILITY_TRUTH.Observability_Truth_Quarantine_Active := FALSE;

    GVL_OBSERVABILITY_TRUTH.HMI_Authority_Coherent := TRUE;
    GVL_OBSERVABILITY_TRUTH.Alarm_Authority_Coherent := TRUE;
    GVL_OBSERVABILITY_TRUTH.Trend_Authority_Coherent := TRUE;
    GVL_OBSERVABILITY_TRUTH.Diagnostics_Authority_Coherent := TRUE;
    GVL_OBSERVABILITY_TRUTH.History_Authority_Coherent := TRUE;

    GVL_OBSERVABILITY_TRUTH.Observability_Truth_Epoch :=
        GVL_SEMANTIC_CONTINUITY.Semantic_Continuity_Epoch;

    GVL_OBSERVABILITY_TRUTH.Observability_Truth_Epoch_Coherent := TRUE;

    GVL_OBSERVABILITY_TRUTH.Observability_Last_Update_MS := L_Now_MS;
    GVL_OBSERVABILITY_TRUTH.Observability_Lease_Expired := FALSE;

    GVL_OBSERVABILITY_TRUTH.Observability_Last_Error_Code := 0;
    GVL_OBSERVABILITY_TRUTH.Observability_Last_Error_Text := '';
ELSE
    GVL_OBSERVABILITY_TRUTH.Observability_Truth_Valid := FALSE;
    GVL_OBSERVABILITY_TRUTH.Observability_Truth_Granted := FALSE;
    GVL_OBSERVABILITY_TRUTH.Observability_Truth_Quarantine_Active := TRUE;

    GVL_OBSERVABILITY_TRUTH.Observability_Lease_Expired := TRUE;

    GVL_OBSERVABILITY_TRUTH.Observability_Last_Error_Code :=
        L_Error_Code;

    GVL_OBSERVABILITY_TRUTH.Observability_Last_Error_Text :=
        L_Error_Text;

    GVL_OBSERVABILITY_TRUTH.Observability_Invalidation_Count :=
        GVL_OBSERVABILITY_TRUTH.Observability_Invalidation_Count + 1;
END_IF;

END_PROGRAM