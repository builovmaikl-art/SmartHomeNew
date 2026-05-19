PROGRAM PRG_Global_Authority_Sync_Governor
VAR
    L_Now_MS : UDINT;
    L_Global_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Global_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_GLOBAL_AUTHORITY_SYNC.Global_Authority_Sync_Valid := FALSE;
GVL_GLOBAL_AUTHORITY_SYNC.Global_Authority_Sync_Granted := FALSE;
GVL_GLOBAL_AUTHORITY_SYNC.Global_Authority_Sync_Quarantine_Active := TRUE;

GVL_GLOBAL_AUTHORITY_SYNC.Heating_Authority_Coherent := FALSE;
GVL_GLOBAL_AUTHORITY_SYNC.Ventilation_Authority_Coherent := FALSE;
GVL_GLOBAL_AUTHORITY_SYNC.Water_Authority_Coherent := FALSE;
GVL_GLOBAL_AUTHORITY_SYNC.Access_Authority_Coherent := FALSE;
GVL_GLOBAL_AUTHORITY_SYNC.Lighting_Authority_Coherent := FALSE;

// Historical truth authority required.
IF NOT GVL_HISTORICAL_TRUTH.Historical_Truth_Granted THEN
    L_Global_Valid := FALSE;
    L_Error_Code := 34000;
    L_Error_Text := 'Historical truth authority not granted';
END_IF;

// Cross-domain split-brain detectors.
IF GVL_GLOBAL_AUTHORITY_SYNC.Authority_Epoch_Fragmentation_Detected THEN
    L_Global_Valid := FALSE;
    L_Error_Code := 34001;
    L_Error_Text := 'Authority epoch fragmentation detected';
END_IF;

IF GVL_GLOBAL_AUTHORITY_SYNC.Partial_Recovery_SplitBrain_Detected THEN
    L_Global_Valid := FALSE;
    L_Error_Code := 34002;
    L_Error_Text := 'Partial recovery split-brain detected';
END_IF;

IF GVL_GLOBAL_AUTHORITY_SYNC.Cross_Domain_Replay_Skew_Detected THEN
    L_Global_Valid := FALSE;
    L_Error_Code := 34003;
    L_Error_Text := 'Cross-domain replay skew detected';
END_IF;

IF GVL_GLOBAL_AUTHORITY_SYNC.Distributed_Authority_Divergence_Detected THEN
    L_Global_Valid := FALSE;
    L_Error_Code := 34004;
    L_Error_Text := 'Distributed authority divergence detected';
END_IF;

IF GVL_GLOBAL_AUTHORITY_SYNC.Global_Causality_Desynchronization_Detected THEN
    L_Global_Valid := FALSE;
    L_Error_Code := 34005;
    L_Error_Text := 'Global causality desynchronization detected';
END_IF;

IF GVL_GLOBAL_AUTHORITY_SYNC.Multi_Domain_Chronology_Drift_Detected THEN
    L_Global_Valid := FALSE;
    L_Error_Code := 34006;
    L_Error_Text := 'Multi-domain chronology drift detected';
END_IF;

// Cross-domain synchronization validation.
IF L_Global_Valid
AND NOT GVL_GLOBAL_AUTHORITY_SYNC.Cross_Domain_Epoch_Coherent THEN
    L_Global_Valid := FALSE;
    L_Error_Code := 34010;
    L_Error_Text := 'Cross-domain epoch coherence invalid';
END_IF;

IF L_Global_Valid
AND NOT GVL_GLOBAL_AUTHORITY_SYNC.Distributed_Authority_Generation_Coherent THEN
    L_Global_Valid := FALSE;
    L_Error_Code := 34011;
    L_Error_Text := 'Distributed authority generation coherence invalid';
END_IF;

IF L_Global_Valid
AND NOT GVL_GLOBAL_AUTHORITY_SYNC.Global_Causality_Timeline_Stable THEN
    L_Global_Valid := FALSE;
    L_Error_Code := 34012;
    L_Error_Text := 'Global causality timeline unstable';
END_IF;

IF L_Global_Valid
AND NOT GVL_GLOBAL_AUTHORITY_SYNC.Multi_Domain_Recovery_Coherent THEN
    L_Global_Valid := FALSE;
    L_Error_Code := 34013;
    L_Error_Text := 'Multi-domain recovery coherence invalid';
END_IF;

IF L_Global_Valid THEN
    GVL_GLOBAL_AUTHORITY_SYNC.Global_Authority_Sync_Valid := TRUE;
    GVL_GLOBAL_AUTHORITY_SYNC.Global_Authority_Sync_Granted := TRUE;
    GVL_GLOBAL_AUTHORITY_SYNC.Global_Authority_Sync_Quarantine_Active := FALSE;

    GVL_GLOBAL_AUTHORITY_SYNC.Heating_Authority_Coherent := TRUE;
    GVL_GLOBAL_AUTHORITY_SYNC.Ventilation_Authority_Coherent := TRUE;
    GVL_GLOBAL_AUTHORITY_SYNC.Water_Authority_Coherent := TRUE;
    GVL_GLOBAL_AUTHORITY_SYNC.Access_Authority_Coherent := TRUE;
    GVL_GLOBAL_AUTHORITY_SYNC.Lighting_Authority_Coherent := TRUE;

    GVL_GLOBAL_AUTHORITY_SYNC.Global_Authority_Epoch :=
        GVL_HISTORICAL_TRUTH.Historical_Truth_Epoch;

    GVL_GLOBAL_AUTHORITY_SYNC.Global_Authority_Epoch_Coherent := TRUE;

    GVL_GLOBAL_AUTHORITY_SYNC.Global_Authority_Last_Update_MS := L_Now_MS;
    GVL_GLOBAL_AUTHORITY_SYNC.Global_Authority_Lease_Expired := FALSE;

    GVL_GLOBAL_AUTHORITY_SYNC.Global_Authority_Last_Error_Code := 0;
    GVL_GLOBAL_AUTHORITY_SYNC.Global_Authority_Last_Error_Text := '';
ELSE
    GVL_GLOBAL_AUTHORITY_SYNC.Global_Authority_Sync_Valid := FALSE;
    GVL_GLOBAL_AUTHORITY_SYNC.Global_Authority_Sync_Granted := FALSE;
    GVL_GLOBAL_AUTHORITY_SYNC.Global_Authority_Sync_Quarantine_Active := TRUE;

    GVL_GLOBAL_AUTHORITY_SYNC.Global_Authority_Lease_Expired := TRUE;

    GVL_GLOBAL_AUTHORITY_SYNC.Global_Authority_Last_Error_Code :=
        L_Error_Code;

    GVL_GLOBAL_AUTHORITY_SYNC.Global_Authority_Last_Error_Text :=
        L_Error_Text;

    GVL_GLOBAL_AUTHORITY_SYNC.Global_Authority_Invalidation_Count :=
        GVL_GLOBAL_AUTHORITY_SYNC.Global_Authority_Invalidation_Count + 1;
END_IF;

END_PROGRAM