PROGRAM PRG_Authority_Revocation_Governor
VAR
    L_Now_MS : UDINT;
    L_Revocation_Required : BOOL := FALSE;
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;

// Fail-safe defaults.
GVL_AUTHORITY_REVOCATION.Authority_Revocation_Active := FALSE;
GVL_AUTHORITY_REVOCATION.Authority_Revocation_Propagated := FALSE;
GVL_AUTHORITY_REVOCATION.Authority_Fail_Closed_Valid := FALSE;
GVL_AUTHORITY_REVOCATION.Revocation_Order_Valid := FALSE;

// Detect upstream authority invalidation.
GVL_AUTHORITY_REVOCATION.Snapshot_Authority_Revoked :=
    NOT GVL_PHYSICAL_SNAPSHOT.Physical_Snapshot_Valid;

GVL_AUTHORITY_REVOCATION.Sensor_Consensus_Authority_Revoked :=
    NOT GVL_SENSOR_CONSENSUS.Sensor_Consensus_Valid;

GVL_AUTHORITY_REVOCATION.Telemetry_Causality_Authority_Revoked :=
    NOT GVL_TELEMETRY.Command_Telemetry_Causality_Valid;

GVL_AUTHORITY_REVOCATION.Physical_Authority_Epoch_Revoked :=
    NOT GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Authority_Epoch_Valid;

GVL_AUTHORITY_REVOCATION.Authority_Lineage_Revoked :=
    NOT GVL_AUTHORITY_LINEAGE.Authority_Lineage_Valid;

L_Revocation_Required :=
    GVL_AUTHORITY_REVOCATION.Snapshot_Authority_Revoked
    OR GVL_AUTHORITY_REVOCATION.Sensor_Consensus_Authority_Revoked
    OR GVL_AUTHORITY_REVOCATION.Telemetry_Causality_Authority_Revoked
    OR GVL_AUTHORITY_REVOCATION.Physical_Authority_Epoch_Revoked
    OR GVL_AUTHORITY_REVOCATION.Authority_Lineage_Revoked;

IF L_Revocation_Required THEN
    GVL_AUTHORITY_REVOCATION.Authority_Revocation_Active := TRUE;
    GVL_AUTHORITY_REVOCATION.Quarantine_Fabric_Active := TRUE;

    GVL_AUTHORITY_REVOCATION.PreOutput_Authority_Revoked := TRUE;
    GVL_AUTHORITY_REVOCATION.Physical_IO_Release_Denied := TRUE;

    GVL_AUTHORITY_REVOCATION.Authority_Revocation_Propagated := TRUE;
    GVL_AUTHORITY_REVOCATION.Authority_Fail_Closed_Valid := TRUE;
    GVL_AUTHORITY_REVOCATION.Revocation_Order_Valid := TRUE;

    GVL_AUTHORITY_REVOCATION.Revocation_Epoch :=
        GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Authority_Epoch;

    GVL_AUTHORITY_REVOCATION.Revocation_Last_Update_MS := L_Now_MS;
ELSE
    GVL_AUTHORITY_REVOCATION.Authority_Revocation_Active := FALSE;
    GVL_AUTHORITY_REVOCATION.Quarantine_Fabric_Active := FALSE;

    GVL_AUTHORITY_REVOCATION.PreOutput_Authority_Revoked := FALSE;
    GVL_AUTHORITY_REVOCATION.Physical_IO_Release_Denied := FALSE;

    GVL_AUTHORITY_REVOCATION.Authority_Revocation_Propagated := FALSE;
    GVL_AUTHORITY_REVOCATION.Authority_Fail_Closed_Valid := TRUE;
    GVL_AUTHORITY_REVOCATION.Revocation_Order_Valid := TRUE;
END_IF;

END_PROGRAM