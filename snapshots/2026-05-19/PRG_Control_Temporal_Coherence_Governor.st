PROGRAM PRG_Control_Temporal_Coherence_Governor
VAR
    L_Now_MS : UDINT;
    L_Control_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Control_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_CONTROL_TIMING_FABRIC.Control_Temporal_Coherence_Valid := FALSE;
GVL_CONTROL_TIMING_FABRIC.Control_Temporal_Coherence_Granted := FALSE;
GVL_CONTROL_TIMING_FABRIC.Control_Temporal_Coherence_Quarantine_Active := TRUE;

GVL_CONTROL_TIMING_FABRIC.Loop_Sampling_Coherent := FALSE;
GVL_CONTROL_TIMING_FABRIC.Feedback_Freshness_Valid := FALSE;
GVL_CONTROL_TIMING_FABRIC.PID_Phase_Alignment_Valid := FALSE;
GVL_CONTROL_TIMING_FABRIC.Cross_Loop_Temporal_Stable := FALSE;
GVL_CONTROL_TIMING_FABRIC.Multi_Rate_Causality_Coherent := FALSE;

// Global authority synchronization required.
IF NOT GVL_GLOBAL_AUTHORITY_SYNC.Global_Authority_Sync_Granted THEN
    L_Control_Valid := FALSE;
    L_Error_Code := 35000;
    L_Error_Text := 'Global authority synchronization not granted';
END_IF;

// Temporal aliasing detectors.
IF GVL_CONTROL_TIMING_FABRIC.PID_Phase_Skew_Detected THEN
    L_Control_Valid := FALSE;
    L_Error_Code := 35001;
    L_Error_Text := 'PID phase skew detected';
END_IF;

IF GVL_CONTROL_TIMING_FABRIC.Sampling_Window_Divergence_Detected THEN
    L_Control_Valid := FALSE;
    L_Error_Code := 35002;
    L_Error_Text := 'Sampling window divergence detected';
END_IF;

IF GVL_CONTROL_TIMING_FABRIC.Feedback_Freshness_Aliasing_Detected THEN
    L_Control_Valid := FALSE;
    L_Error_Code := 35003;
    L_Error_Text := 'Feedback freshness aliasing detected';
END_IF;

IF GVL_CONTROL_TIMING_FABRIC.Cross_Loop_Stabilization_Lag_Detected THEN
    L_Control_Valid := FALSE;
    L_Error_Code := 35004;
    L_Error_Text := 'Cross-loop stabilization lag detected';
END_IF;

IF GVL_CONTROL_TIMING_FABRIC.Multi_Rate_Oscillation_Risk_Detected THEN
    L_Control_Valid := FALSE;
    L_Error_Code := 35005;
    L_Error_Text := 'Multi-rate oscillation risk detected';
END_IF;

IF GVL_CONTROL_TIMING_FABRIC.Distributed_Control_Ringing_Detected THEN
    L_Control_Valid := FALSE;
    L_Error_Code := 35006;
    L_Error_Text := 'Distributed control ringing detected';
END_IF;

// Deterministic control timing validation.
IF L_Control_Valid
AND NOT GVL_CONTROL_TIMING_FABRIC.Control_Snapshot_Epoch_Coherent THEN
    L_Control_Valid := FALSE;
    L_Error_Code := 35010;
    L_Error_Text := 'Control snapshot epoch coherence invalid';
END_IF;

IF L_Control_Valid
AND NOT GVL_CONTROL_TIMING_FABRIC.Feedback_Window_Stable THEN
    L_Control_Valid := FALSE;
    L_Error_Code := 35011;
    L_Error_Text := 'Feedback window unstable';
END_IF;

IF L_Control_Valid
AND NOT GVL_CONTROL_TIMING_FABRIC.Loop_Execution_Phase_Stable THEN
    L_Control_Valid := FALSE;
    L_Error_Code := 35012;
    L_Error_Text := 'Loop execution phase unstable';
END_IF;

IF L_Control_Valid
AND NOT GVL_CONTROL_TIMING_FABRIC.Temporal_Observation_Aligned THEN
    L_Control_Valid := FALSE;
    L_Error_Code := 35013;
    L_Error_Text := 'Temporal observation alignment invalid';
END_IF;

IF L_Control_Valid THEN
    GVL_CONTROL_TIMING_FABRIC.Control_Temporal_Coherence_Valid := TRUE;
    GVL_CONTROL_TIMING_FABRIC.Control_Temporal_Coherence_Granted := TRUE;
    GVL_CONTROL_TIMING_FABRIC.Control_Temporal_Coherence_Quarantine_Active := FALSE;

    GVL_CONTROL_TIMING_FABRIC.Loop_Sampling_Coherent := TRUE;
    GVL_CONTROL_TIMING_FABRIC.Feedback_Freshness_Valid := TRUE;
    GVL_CONTROL_TIMING_FABRIC.PID_Phase_Alignment_Valid := TRUE;
    GVL_CONTROL_TIMING_FABRIC.Cross_Loop_Temporal_Stable := TRUE;
    GVL_CONTROL_TIMING_FABRIC.Multi_Rate_Causality_Coherent := TRUE;

    GVL_CONTROL_TIMING_FABRIC.Control_Timing_Epoch :=
        GVL_GLOBAL_AUTHORITY_SYNC.Global_Authority_Epoch;

    GVL_CONTROL_TIMING_FABRIC.Control_Timing_Epoch_Coherent := TRUE;

    GVL_CONTROL_TIMING_FABRIC.Control_Timing_Last_Update_MS := L_Now_MS;
    GVL_CONTROL_TIMING_FABRIC.Control_Timing_Lease_Expired := FALSE;

    GVL_CONTROL_TIMING_FABRIC.Control_Timing_Last_Error_Code := 0;
    GVL_CONTROL_TIMING_FABRIC.Control_Timing_Last_Error_Text := '';
ELSE
    GVL_CONTROL_TIMING_FABRIC.Control_Temporal_Coherence_Valid := FALSE;
    GVL_CONTROL_TIMING_FABRIC.Control_Temporal_Coherence_Granted := FALSE;
    GVL_CONTROL_TIMING_FABRIC.Control_Temporal_Coherence_Quarantine_Active := TRUE;

    GVL_CONTROL_TIMING_FABRIC.Control_Timing_Lease_Expired := TRUE;

    GVL_CONTROL_TIMING_FABRIC.Control_Timing_Last_Error_Code :=
        L_Error_Code;

    GVL_CONTROL_TIMING_FABRIC.Control_Timing_Last_Error_Text :=
        L_Error_Text;

    GVL_CONTROL_TIMING_FABRIC.Control_Timing_Invalidation_Count :=
        GVL_CONTROL_TIMING_FABRIC.Control_Timing_Invalidation_Count + 1;
END_IF;

END_PROGRAM