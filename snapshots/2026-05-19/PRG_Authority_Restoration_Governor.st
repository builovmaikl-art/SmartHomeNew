PROGRAM PRG_Authority_Restoration_Governor
VAR
    L_Now_MS : UDINT;
    L_Restoration_Valid : BOOL := TRUE;
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Restoration_Valid := TRUE;

// Fail-safe defaults.
GVL_AUTHORITY_RESTORATION.Authority_Restoration_Active := FALSE;
GVL_AUTHORITY_RESTORATION.Authority_Restoration_Allowed := FALSE;
GVL_AUTHORITY_RESTORATION.Authority_Restoration_Completed := FALSE;

GVL_AUTHORITY_RESTORATION.Snapshot_Restoration_Valid := FALSE;
GVL_AUTHORITY_RESTORATION.Consensus_Restoration_Valid := FALSE;
GVL_AUTHORITY_RESTORATION.Causality_Restoration_Valid := FALSE;
GVL_AUTHORITY_RESTORATION.Epoch_Restoration_Valid := FALSE;
GVL_AUTHORITY_RESTORATION.Lineage_Restoration_Valid := FALSE;

GVL_AUTHORITY_RESTORATION.Revocation_Clearance_Valid := FALSE;
GVL_AUTHORITY_RESTORATION.Stabilization_Window_Elapsed := FALSE;
GVL_AUTHORITY_RESTORATION.Reauthorization_Order_Valid := FALSE;

// Restoration impossible while revocation active.
IF GVL_AUTHORITY_REVOCATION.Authority_Revocation_Active THEN
    L_Restoration_Valid := FALSE;
END_IF;

// Snapshot must recover first.
IF L_Restoration_Valid
AND NOT GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Valid THEN
    L_Restoration_Valid := FALSE;
END_IF;

IF L_Restoration_Valid THEN
    GVL_AUTHORITY_RESTORATION.Snapshot_Restoration_Valid := TRUE;
END_IF;

// Consensus recovery.
IF L_Restoration_Valid
AND NOT GVL_SENSOR_CONSENSUS.Sensor_Consensus_Valid THEN
    L_Restoration_Valid := FALSE;
END_IF;

IF L_Restoration_Valid THEN
    GVL_AUTHORITY_RESTORATION.Consensus_Restoration_Valid := TRUE;
END_IF;

// Telemetry causality recovery.
IF L_Restoration_Valid
AND NOT GVL_TELEMETRY.Command_Telemetry_Causality_Valid THEN
    L_Restoration_Valid := FALSE;
END_IF;

IF L_Restoration_Valid THEN
    GVL_AUTHORITY_RESTORATION.Causality_Restoration_Valid := TRUE;
END_IF;

// Epoch coherence recovery.
IF L_Restoration_Valid
AND NOT GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Authority_Epoch_Valid THEN
    L_Restoration_Valid := FALSE;
END_IF;

IF L_Restoration_Valid THEN
    GVL_AUTHORITY_RESTORATION.Epoch_Restoration_Valid := TRUE;
END_IF;

// Lineage continuity recovery.
IF L_Restoration_Valid
AND NOT GVL_AUTHORITY_LINEAGE.Authority_Lineage_Valid THEN
    L_Restoration_Valid := FALSE;
END_IF;

IF L_Restoration_Valid THEN
    GVL_AUTHORITY_RESTORATION.Lineage_Restoration_Valid := TRUE;
END_IF;

// Revocation must be fully cleared.
IF L_Restoration_Valid
AND GVL_AUTHORITY_REVOCATION.Quarantine_Fabric_Active THEN
    L_Restoration_Valid := FALSE;
END_IF;

IF L_Restoration_Valid THEN
    GVL_AUTHORITY_RESTORATION.Revocation_Clearance_Valid := TRUE;
END_IF;

// Stabilization window after recovery.
IF L_Restoration_Valid
AND ((L_Now_MS - GVL_AUTHORITY_REVOCATION.Revocation_Last_Update_MS) < 5000) THEN
    L_Restoration_Valid := FALSE;
END_IF;

IF L_Restoration_Valid THEN
    GVL_AUTHORITY_RESTORATION.Stabilization_Window_Elapsed := TRUE;
END_IF;

IF L_Restoration_Valid THEN
    GVL_AUTHORITY_RESTORATION.Authority_Restoration_Active := TRUE;
    GVL_AUTHORITY_RESTORATION.Authority_Restoration_Allowed := TRUE;
    GVL_AUTHORITY_RESTORATION.Authority_Restoration_Completed := TRUE;

    GVL_AUTHORITY_RESTORATION.Reauthorization_Order_Valid := TRUE;

    GVL_AUTHORITY_RESTORATION.Restoration_Epoch :=
        GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Authority_Epoch;

    GVL_AUTHORITY_RESTORATION.Restoration_Last_Update_MS := L_Now_MS;
END_IF;

END_PROGRAM