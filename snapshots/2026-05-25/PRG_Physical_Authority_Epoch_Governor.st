PROGRAM PRG_Physical_Authority_Epoch_Governor
VAR
    L_Now_MS : UDINT;
    L_Epoch_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
    L_Global_Epoch : UDINT;
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Epoch_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Authority_Epoch_Valid := FALSE;
GVL_PHYSICAL_AUTHORITY_EPOCH.Snapshot_Epoch_Coherent := FALSE;
GVL_PHYSICAL_AUTHORITY_EPOCH.Consensus_Epoch_Coherent := FALSE;
GVL_PHYSICAL_AUTHORITY_EPOCH.Causality_Epoch_Coherent := FALSE;
GVL_PHYSICAL_AUTHORITY_EPOCH.PreOutput_Epoch_Coherent := FALSE;

L_Global_Epoch := GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Epoch;

// Snapshot epoch is the authoritative physical world epoch.
IF GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Epoch = 0 THEN
    L_Epoch_Valid := FALSE;
    L_Error_Code := 24000;
    L_Error_Text := 'Physical snapshot epoch invalid';
END_IF;

// Consensus must validate the same immutable world.
IF L_Epoch_Valid
AND (GVL_SENSOR_CONSENSUS.Sensor_Consensus_Epoch <> L_Global_Epoch) THEN
    GVL_PHYSICAL_AUTHORITY_EPOCH.Cross_Cycle_Epoch_Skew_Detected := TRUE;

    L_Epoch_Valid := FALSE;
    L_Error_Code := 24001;
    L_Error_Text := 'Sensor consensus epoch skew detected';
END_IF;

// Telemetry causality must validate the same immutable world.
IF L_Epoch_Valid
AND (GVL_TELEMETRY.Telemetry_Epoch <> L_Global_Epoch) THEN
    GVL_PHYSICAL_AUTHORITY_EPOCH.Cross_Cycle_Epoch_Skew_Detected := TRUE;

    L_Epoch_Valid := FALSE;
    L_Error_Code := 24002;
    L_Error_Text := 'Telemetry epoch skew detected';
END_IF;

// Output publication epoch must remain coherent.
IF L_Epoch_Valid
AND (GVL_OUTPUT_EPOCH.Output_Publication_Epoch <> L_Global_Epoch) THEN
    GVL_PHYSICAL_AUTHORITY_EPOCH.Partial_Epoch_Advancement_Detected := TRUE;

    L_Epoch_Valid := FALSE;
    L_Error_Code := 24003;
    L_Error_Text := 'Output publication epoch skew detected';
END_IF;

IF L_Epoch_Valid
AND GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Epoch_Replay_Suspected THEN
    L_Epoch_Valid := FALSE;
    L_Error_Code := 24004;
    L_Error_Text := 'Physical authority epoch replay suspected';
END_IF;

IF L_Epoch_Valid
AND GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Epoch_Drift_Detected THEN
    L_Epoch_Valid := FALSE;
    L_Error_Code := 24005;
    L_Error_Text := 'Physical authority epoch drift detected';
END_IF;

IF L_Epoch_Valid THEN
    GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Authority_Epoch := L_Global_Epoch;
    GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Authority_Epoch_Valid := TRUE;

    GVL_PHYSICAL_AUTHORITY_EPOCH.Snapshot_Epoch_Coherent := TRUE;
    GVL_PHYSICAL_AUTHORITY_EPOCH.Consensus_Epoch_Coherent := TRUE;
    GVL_PHYSICAL_AUTHORITY_EPOCH.Causality_Epoch_Coherent := TRUE;
    GVL_PHYSICAL_AUTHORITY_EPOCH.PreOutput_Epoch_Coherent := TRUE;

    GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Authority_Lease_Expired := FALSE;
    GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Authority_Quarantine_Active := FALSE;

    GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Authority_Last_Update_MS := L_Now_MS;

    GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Authority_Last_Error_Code := 0;
    GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Authority_Last_Error_Text := '';
ELSE
    GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Authority_Epoch_Valid := FALSE;

    GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Authority_Lease_Expired := TRUE;
    GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Authority_Quarantine_Active := TRUE;

    GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Authority_Last_Error_Code := L_Error_Code;
    GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Authority_Last_Error_Text := L_Error_Text;

    GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Authority_Invalidation_Count :=
        GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Authority_Invalidation_Count + 1;
END_IF;

END_PROGRAM