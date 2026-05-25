PROGRAM PRG_Observability_Authority_Governor
VAR
    L_Now_MS : UDINT;
    L_Observability_Valid : BOOL := TRUE;
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Observability_Valid := TRUE;

// Fail-safe defaults.
GVL_OBSERVABILITY_AUTHORITY_FABRIC.Observability_Authority_Valid := FALSE;
GVL_OBSERVABILITY_AUTHORITY_FABRIC.Observability_Quarantine_Active := TRUE;
GVL_OBSERVABILITY_AUTHORITY_FABRIC.Observability_Publication_Allowed := FALSE;

GVL_OBSERVABILITY_AUTHORITY_FABRIC.HMI_Authority_Coherent := FALSE;
GVL_OBSERVABILITY_AUTHORITY_FABRIC.Diagnostics_Authority_Coherent := FALSE;
GVL_OBSERVABILITY_AUTHORITY_FABRIC.Blackbox_Authority_Coherent := FALSE;
GVL_OBSERVABILITY_AUTHORITY_FABRIC.Trend_Authority_Coherent := FALSE;
GVL_OBSERVABILITY_AUTHORITY_FABRIC.Alarm_Authority_Coherent := FALSE;

// Revocation blocks authoritative observability.
IF GVL_AUTHORITY_REVOCATION.Authority_Revocation_Active THEN
    L_Observability_Valid := FALSE;
END_IF;

// Restoration must be fully completed.
IF L_Observability_Valid
AND NOT GVL_AUTHORITY_RESTORATION.Authority_Restoration_Completed THEN
    L_Observability_Valid := FALSE;
END_IF;

// Physical authority epoch coherence required.
IF L_Observability_Valid
AND NOT GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Authority_Epoch_Valid THEN
    L_Observability_Valid := FALSE;
END_IF;

// Authority lineage continuity required.
IF L_Observability_Valid
AND NOT GVL_AUTHORITY_LINEAGE.Authority_Lineage_Valid THEN
    L_Observability_Valid := FALSE;
END_IF;

IF L_Observability_Valid THEN
    GVL_OBSERVABILITY_AUTHORITY_FABRIC.Observability_Authority_Valid := TRUE;
    GVL_OBSERVABILITY_AUTHORITY_FABRIC.Observability_Quarantine_Active := FALSE;
    GVL_OBSERVABILITY_AUTHORITY_FABRIC.Observability_Publication_Allowed := TRUE;

    GVL_OBSERVABILITY_AUTHORITY_FABRIC.HMI_Authority_Coherent := TRUE;
    GVL_OBSERVABILITY_AUTHORITY_FABRIC.Diagnostics_Authority_Coherent := TRUE;
    GVL_OBSERVABILITY_AUTHORITY_FABRIC.Blackbox_Authority_Coherent := TRUE;
    GVL_OBSERVABILITY_AUTHORITY_FABRIC.Trend_Authority_Coherent := TRUE;
    GVL_OBSERVABILITY_AUTHORITY_FABRIC.Alarm_Authority_Coherent := TRUE;

    GVL_OBSERVABILITY_AUTHORITY_FABRIC.Observability_Epoch :=
        GVL_PHYSICAL_AUTHORITY_EPOCH.Physical_Authority_Epoch;

    GVL_OBSERVABILITY_AUTHORITY_FABRIC.Observability_Epoch_Coherent := TRUE;

    GVL_OBSERVABILITY_AUTHORITY_FABRIC.Observability_Last_Update_MS :=
        L_Now_MS;

    GVL_OBSERVABILITY_AUTHORITY_FABRIC.Observability_Lease_Expired := FALSE;
ELSE
    GVL_OBSERVABILITY_AUTHORITY_FABRIC.Observability_Authority_Valid := FALSE;
    GVL_OBSERVABILITY_AUTHORITY_FABRIC.Observability_Quarantine_Active := TRUE;
    GVL_OBSERVABILITY_AUTHORITY_FABRIC.Observability_Publication_Allowed := FALSE;

    GVL_OBSERVABILITY_AUTHORITY_FABRIC.Observability_Lease_Expired := TRUE;

    GVL_OBSERVABILITY_AUTHORITY_FABRIC.Observability_Invalidation_Count :=
        GVL_OBSERVABILITY_AUTHORITY_FABRIC.Observability_Invalidation_Count + 1;
END_IF;

END_PROGRAM