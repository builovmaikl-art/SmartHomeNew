PROGRAM PRG_Historical_Truth_Governor
VAR
    L_Now_MS : UDINT;
    L_History_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_History_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_HISTORICAL_TRUTH.Historical_Truth_Valid := FALSE;
GVL_HISTORICAL_TRUTH.Historical_Truth_Granted := FALSE;
GVL_HISTORICAL_TRUTH.Historical_Truth_Quarantine_Active := TRUE;

GVL_HISTORICAL_TRUTH.Trend_History_Causally_Immutable := FALSE;
GVL_HISTORICAL_TRUTH.Alarm_Chronology_Immutable := FALSE;
GVL_HISTORICAL_TRUTH.Blackbox_Snapshot_Immutable := FALSE;
GVL_HISTORICAL_TRUTH.Diagnostics_History_Coherent := FALSE;
GVL_HISTORICAL_TRUTH.Failover_Chronology_Coherent := FALSE;

// Observability truth authority required.
IF NOT GVL_OBSERVABILITY_TRUTH.Observability_Truth_Granted THEN
    L_History_Valid := FALSE;
    L_Error_Code := 33000;
    L_Error_Text := 'Observability truth authority not granted';
END_IF;

// Historical corruption detectors.
IF GVL_HISTORICAL_TRUTH.History_Epoch_Skew_Detected THEN
    L_History_Valid := FALSE;
    L_Error_Code := 33001;
    L_Error_Text := 'Historical epoch skew detected';
END_IF;

IF GVL_HISTORICAL_TRUTH.Failover_Chronology_Corruption_Detected THEN
    L_History_Valid := FALSE;
    L_Error_Code := 33002;
    L_Error_Text := 'Failover chronology corruption detected';
END_IF;

IF GVL_HISTORICAL_TRUTH.Trend_Replay_Race_Detected THEN
    L_History_Valid := FALSE;
    L_Error_Code := 33003;
    L_Error_Text := 'Trend replay race detected';
END_IF;

IF GVL_HISTORICAL_TRUTH.Blackbox_Causality_Drift_Detected THEN
    L_History_Valid := FALSE;
    L_Error_Code := 33004;
    L_Error_Text := 'Blackbox causality drift detected';
END_IF;

IF GVL_HISTORICAL_TRUTH.Alarm_Order_Reconstruction_Error THEN
    L_History_Valid := FALSE;
    L_Error_Code := 33005;
    L_Error_Text := 'Alarm order reconstruction error detected';
END_IF;

IF GVL_HISTORICAL_TRUTH.Mixed_Authority_Persistence_Detected THEN
    L_History_Valid := FALSE;
    L_Error_Code := 33006;
    L_Error_Text := 'Mixed-authority persistence detected';
END_IF;

// Historical persistence integrity validation.
IF L_History_Valid
AND NOT GVL_HISTORICAL_TRUTH.Persisted_Epochs_Coherent THEN
    L_History_Valid := FALSE;
    L_Error_Code := 33010;
    L_Error_Text := 'Persisted epoch coherence invalid';
END_IF;

IF L_History_Valid
AND NOT GVL_HISTORICAL_TRUTH.Recovery_Replay_Coherent THEN
    L_History_Valid := FALSE;
    L_Error_Code := 33011;
    L_Error_Text := 'Recovery replay coherence invalid';
END_IF;

IF L_History_Valid
AND NOT GVL_HISTORICAL_TRUTH.Historical_Snapshot_Coherent THEN
    L_History_Valid := FALSE;
    L_Error_Code := 33012;
    L_Error_Text := 'Historical snapshot coherence invalid';
END_IF;

IF L_History_Valid
AND NOT GVL_HISTORICAL_TRUTH.Mixed_Authority_Persistence_Absent THEN
    L_History_Valid := FALSE;
    L_Error_Code := 33013;
    L_Error_Text := 'Mixed-authority persistence absence invalid';
END_IF;

IF L_History_Valid THEN
    GVL_HISTORICAL_TRUTH.Historical_Truth_Valid := TRUE;
    GVL_HISTORICAL_TRUTH.Historical_Truth_Granted := TRUE;
    GVL_HISTORICAL_TRUTH.Historical_Truth_Quarantine_Active := FALSE;

    GVL_HISTORICAL_TRUTH.Trend_History_Causally_Immutable := TRUE;
    GVL_HISTORICAL_TRUTH.Alarm_Chronology_Immutable := TRUE;
    GVL_HISTORICAL_TRUTH.Blackbox_Snapshot_Immutable := TRUE;
    GVL_HISTORICAL_TRUTH.Diagnostics_History_Coherent := TRUE;
    GVL_HISTORICAL_TRUTH.Failover_Chronology_Coherent := TRUE;

    GVL_HISTORICAL_TRUTH.Historical_Truth_Epoch :=
        GVL_OBSERVABILITY_TRUTH.Observability_Truth_Epoch;

    GVL_HISTORICAL_TRUTH.Historical_Truth_Epoch_Coherent := TRUE;

    GVL_HISTORICAL_TRUTH.Historical_Last_Update_MS := L_Now_MS;
    GVL_HISTORICAL_TRUTH.Historical_Lease_Expired := FALSE;

    GVL_HISTORICAL_TRUTH.Historical_Last_Error_Code := 0;
    GVL_HISTORICAL_TRUTH.Historical_Last_Error_Text := '';
ELSE
    GVL_HISTORICAL_TRUTH.Historical_Truth_Valid := FALSE;
    GVL_HISTORICAL_TRUTH.Historical_Truth_Granted := FALSE;
    GVL_HISTORICAL_TRUTH.Historical_Truth_Quarantine_Active := TRUE;

    GVL_HISTORICAL_TRUTH.Historical_Lease_Expired := TRUE;

    GVL_HISTORICAL_TRUTH.Historical_Last_Error_Code :=
        L_Error_Code;

    GVL_HISTORICAL_TRUTH.Historical_Last_Error_Text :=
        L_Error_Text;

    GVL_HISTORICAL_TRUTH.Historical_Invalidation_Count :=
        GVL_HISTORICAL_TRUTH.Historical_Invalidation_Count + 1;
END_IF;

END_PROGRAM