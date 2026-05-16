PROGRAM PRG_Physical_Snapshot_Governor
VAR
    L_Now_MS : UDINT;
    L_Snapshot_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Snapshot_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Valid := FALSE;
GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Frozen := FALSE;
GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Publication_Allowed := FALSE;
GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Isolation_Valid := FALSE;
GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Copy_Valid := FALSE;
GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Freshness_Valid := FALSE;
GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Consensus_Coherent := FALSE;
GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Causality_Coherent := FALSE;

// Runtime/output epoch coherence.
GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Runtime_Epoch :=
    GVL_RUNTIME_EPOCH.Runtime_Epoch;

GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Output_Epoch :=
    GVL_OUTPUT_EPOCH.Output_Publication_Epoch;

IF NOT GVL_RUNTIME_EPOCH.Runtime_Runtime_Barrier_OK THEN
    L_Snapshot_Valid := FALSE;
    L_Error_Code := 23000;
    L_Error_Text := 'Physical snapshot runtime barrier invalid';
END_IF;

IF L_Snapshot_Valid
AND NOT GVL_OUTPUT_EPOCH.Output_Publication_Valid THEN
    L_Snapshot_Valid := FALSE;
    L_Error_Code := 23001;
    L_Error_Text := 'Physical snapshot output publication invalid';
END_IF;

IF L_Snapshot_Valid
AND GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Mutation_Detected THEN
    L_Snapshot_Valid := FALSE;
    L_Error_Code := 23002;
    L_Error_Text := 'Physical snapshot mutation detected';
END_IF;

IF L_Snapshot_Valid
AND GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Replay_Suspected THEN
    L_Snapshot_Valid := FALSE;
    L_Error_Code := 23003;
    L_Error_Text := 'Physical snapshot replay suspected';
END_IF;

IF L_Snapshot_Valid
AND GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Lease_Expired THEN
    L_Snapshot_Valid := FALSE;
    L_Error_Code := 23004;
    L_Error_Text := 'Physical snapshot lease expired';
END_IF;

IF L_Snapshot_Valid THEN
    GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Valid := TRUE;
    GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Frozen := TRUE;
    GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Publication_Allowed := TRUE;
    GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Isolation_Valid := TRUE;
    GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Copy_Valid := TRUE;
    GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Freshness_Valid := TRUE;

    GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Consensus_Coherent := TRUE;
    GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Causality_Coherent := TRUE;

    GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Epoch :=
        GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Epoch + 1;

    GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Last_Update_MS := L_Now_MS;

    GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Last_Error_Code := 0;
    GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Last_Error_Text := '';
ELSE
    GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Valid := FALSE;
    GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Frozen := FALSE;
    GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Publication_Allowed := FALSE;

    GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Last_Error_Code := L_Error_Code;
    GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Last_Error_Text := L_Error_Text;

    GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Invalidation_Count :=
        GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Invalidation_Count + 1;
END_IF;

END_PROGRAM