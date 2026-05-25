PROGRAM PRG_Operator_Semantic_Alignment_Governor
VAR
    L_Now_MS : UDINT;
    L_Operator_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Operator_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Semantic_Alignment_Valid := FALSE;
GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Semantic_Alignment_Granted := FALSE;
GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Semantic_Alignment_Quarantine_Active := TRUE;

GVL_OPERATOR_SEMANTIC_ALIGNMENT.HMI_Semantic_State_Coherent := FALSE;
GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Recovery_Intent_Aligned := FALSE;
GVL_OPERATOR_SEMANTIC_ALIGNMENT.Alarm_Semantic_Priority_Coherent := FALSE;
GVL_OPERATOR_SEMANTIC_ALIGNMENT.Runtime_Explanation_Coherent := FALSE;
GVL_OPERATOR_SEMANTIC_ALIGNMENT.Authority_State_Human_Visible := FALSE;

// Semantic preservation required.
IF NOT GVL_SEMANTIC_PRESERVATION_FABRIC.Semantic_Preservation_Granted THEN
    L_Operator_Valid := FALSE;
    L_Error_Code := 40000;
    L_Error_Text := 'Semantic preservation authority not granted';
END_IF;

// Human-machine semantic split-brain detectors.
IF GVL_OPERATOR_SEMANTIC_ALIGNMENT.HMI_Semantic_Lag_Detected THEN
    L_Operator_Valid := FALSE;
    L_Error_Code := 40001;
    L_Error_Text := 'HMI semantic lag detected';
END_IF;

IF GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Interpretation_Skew_Detected THEN
    L_Operator_Valid := FALSE;
    L_Error_Code := 40002;
    L_Error_Text := 'Operator interpretation skew detected';
END_IF;

IF GVL_OPERATOR_SEMANTIC_ALIGNMENT.Alarm_Cognition_Mismatch_Detected THEN
    L_Operator_Valid := FALSE;
    L_Error_Code := 40003;
    L_Error_Text := 'Alarm cognition mismatch detected';
END_IF;

IF GVL_OPERATOR_SEMANTIC_ALIGNMENT.Hidden_Authority_State_Detected THEN
    L_Operator_Valid := FALSE;
    L_Error_Code := 40004;
    L_Error_Text := 'Hidden authority state detected';
END_IF;

IF GVL_OPERATOR_SEMANTIC_ALIGNMENT.Semantic_Explanation_Divergence_Detected THEN
    L_Operator_Valid := FALSE;
    L_Error_Code := 40005;
    L_Error_Text := 'Semantic explanation divergence detected';
END_IF;

IF GVL_OPERATOR_SEMANTIC_ALIGNMENT.Human_Recovery_Misunderstanding_Detected THEN
    L_Operator_Valid := FALSE;
    L_Error_Code := 40006;
    L_Error_Text := 'Human recovery misunderstanding detected';
END_IF;

// Operator cognition coherence validation.
IF L_Operator_Valid
AND NOT GVL_OPERATOR_SEMANTIC_ALIGNMENT.Human_Interpretation_Coherent THEN
    L_Operator_Valid := FALSE;
    L_Error_Code := 40010;
    L_Error_Text := 'Human interpretation coherence invalid';
END_IF;

IF L_Operator_Valid
AND NOT GVL_OPERATOR_SEMANTIC_ALIGNMENT.Adaptive_Runtime_Visibility_Valid THEN
    L_Operator_Valid := FALSE;
    L_Error_Code := 40011;
    L_Error_Text := 'Adaptive runtime visibility invalid';
END_IF;

IF L_Operator_Valid
AND NOT GVL_OPERATOR_SEMANTIC_ALIGNMENT.Semantic_Explanation_Fresh THEN
    L_Operator_Valid := FALSE;
    L_Error_Code := 40012;
    L_Error_Text := 'Semantic explanation freshness invalid';
END_IF;

IF L_Operator_Valid
AND NOT GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Action_Context_Aligned THEN
    L_Operator_Valid := FALSE;
    L_Error_Code := 40013;
    L_Error_Text := 'Operator action context alignment invalid';
END_IF;

IF L_Operator_Valid THEN
    GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Semantic_Alignment_Valid := TRUE;
    GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Semantic_Alignment_Granted := TRUE;
    GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Semantic_Alignment_Quarantine_Active := FALSE;

    GVL_OPERATOR_SEMANTIC_ALIGNMENT.HMI_Semantic_State_Coherent := TRUE;
    GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Recovery_Intent_Aligned := TRUE;
    GVL_OPERATOR_SEMANTIC_ALIGNMENT.Alarm_Semantic_Priority_Coherent := TRUE;
    GVL_OPERATOR_SEMANTIC_ALIGNMENT.Runtime_Explanation_Coherent := TRUE;
    GVL_OPERATOR_SEMANTIC_ALIGNMENT.Authority_State_Human_Visible := TRUE;

    GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Alignment_Epoch :=
        GVL_SEMANTIC_PRESERVATION_FABRIC.Semantic_Preservation_Epoch;

    GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Alignment_Epoch_Coherent := TRUE;

    GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Alignment_Last_Update_MS :=
        L_Now_MS;

    GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Alignment_Lease_Expired := FALSE;

    GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Alignment_Last_Error_Code := 0;
    GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Alignment_Last_Error_Text := '';
ELSE
    GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Semantic_Alignment_Valid := FALSE;
    GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Semantic_Alignment_Granted := FALSE;
    GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Semantic_Alignment_Quarantine_Active := TRUE;

    GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Alignment_Lease_Expired := TRUE;

    GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Alignment_Last_Error_Code :=
        L_Error_Code;

    GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Alignment_Last_Error_Text :=
        L_Error_Text;

    GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Alignment_Invalidation_Count :=
        GVL_OPERATOR_SEMANTIC_ALIGNMENT.Operator_Alignment_Invalidation_Count + 1;
END_IF;

END_PROGRAM