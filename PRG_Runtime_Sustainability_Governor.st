PROGRAM PRG_Runtime_Sustainability_Governor
VAR
    L_Now_MS : UDINT;
    L_Runtime_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Runtime_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_RUNTIME_SUSTAINABILITY_FABRIC.Runtime_Sustainability_Valid := FALSE;
GVL_RUNTIME_SUSTAINABILITY_FABRIC.Runtime_Sustainability_Granted := FALSE;
GVL_RUNTIME_SUSTAINABILITY_FABRIC.Runtime_Sustainability_Quarantine_Active := TRUE;

GVL_RUNTIME_SUSTAINABILITY_FABRIC.Deterministic_Cycle_Budget_Stable := FALSE;
GVL_RUNTIME_SUSTAINABILITY_FABRIC.Runtime_Queue_Load_Stable := FALSE;
GVL_RUNTIME_SUSTAINABILITY_FABRIC.Memory_Fragmentation_Stable := FALSE;
GVL_RUNTIME_SUSTAINABILITY_FABRIC.Watchdog_Jitter_Stable := FALSE;
GVL_RUNTIME_SUSTAINABILITY_FABRIC.HA_Synchronization_Load_Stable := FALSE;

// Energy causality authority required.
IF NOT GVL_ENERGY_CAUSALITY_FABRIC.Energy_Causality_Granted THEN
    L_Runtime_Valid := FALSE;
    L_Error_Code := 38000;
    L_Error_Text := 'Energy causality authority not granted';
END_IF;

// Resource-collapse detectors.
IF GVL_RUNTIME_SUSTAINABILITY_FABRIC.Memory_Fragmentation_Drift_Detected THEN
    L_Runtime_Valid := FALSE;
    L_Error_Code := 38001;
    L_Error_Text := 'Memory fragmentation drift detected';
END_IF;

IF GVL_RUNTIME_SUSTAINABILITY_FABRIC.Queue_Saturation_Detected THEN
    L_Runtime_Valid := FALSE;
    L_Error_Code := 38002;
    L_Error_Text := 'Runtime queue saturation detected';
END_IF;

IF GVL_RUNTIME_SUSTAINABILITY_FABRIC.Historical_Persistence_Amplification_Detected THEN
    L_Runtime_Valid := FALSE;
    L_Error_Code := 38003;
    L_Error_Text := 'Historical persistence amplification detected';
END_IF;

IF GVL_RUNTIME_SUSTAINABILITY_FABRIC.Watchdog_Jitter_Escalation_Detected THEN
    L_Runtime_Valid := FALSE;
    L_Error_Code := 38004;
    L_Error_Text := 'Watchdog jitter escalation detected';
END_IF;

IF GVL_RUNTIME_SUSTAINABILITY_FABRIC.HASynchronization_Overload_Detected THEN
    L_Runtime_Valid := FALSE;
    L_Error_Code := 38005;
    L_Error_Text := 'HA synchronization overload detected';
END_IF;

IF GVL_RUNTIME_SUSTAINABILITY_FABRIC.Deterministic_Cycle_Erosion_Detected THEN
    L_Runtime_Valid := FALSE;
    L_Error_Code := 38006;
    L_Error_Text := 'Deterministic cycle erosion detected';
END_IF;

// Long-term runtime sustainability validation.
IF L_Runtime_Valid
AND NOT GVL_RUNTIME_SUSTAINABILITY_FABRIC.Historical_Persistence_Load_Stable THEN
    L_Runtime_Valid := FALSE;
    L_Error_Code := 38010;
    L_Error_Text := 'Historical persistence load unstable';
END_IF;

IF L_Runtime_Valid
AND NOT GVL_RUNTIME_SUSTAINABILITY_FABRIC.Snapshot_Publication_Stable THEN
    L_Runtime_Valid := FALSE;
    L_Error_Code := 38011;
    L_Error_Text := 'Snapshot publication unstable';
END_IF;

IF L_Runtime_Valid
AND NOT GVL_RUNTIME_SUSTAINABILITY_FABRIC.Distributed_Runtime_Load_Coherent THEN
    L_Runtime_Valid := FALSE;
    L_Error_Code := 38012;
    L_Error_Text := 'Distributed runtime load coherence invalid';
END_IF;

IF L_Runtime_Valid
AND NOT GVL_RUNTIME_SUSTAINABILITY_FABRIC.Runtime_Evolution_Sustainable THEN
    L_Runtime_Valid := FALSE;
    L_Error_Code := 38013;
    L_Error_Text := 'Runtime evolution sustainability invalid';
END_IF;

IF L_Runtime_Valid THEN
    GVL_RUNTIME_SUSTAINABILITY_FABRIC.Runtime_Sustainability_Valid := TRUE;
    GVL_RUNTIME_SUSTAINABILITY_FABRIC.Runtime_Sustainability_Granted := TRUE;
    GVL_RUNTIME_SUSTAINABILITY_FABRIC.Runtime_Sustainability_Quarantine_Active := FALSE;

    GVL_RUNTIME_SUSTAINABILITY_FABRIC.Deterministic_Cycle_Budget_Stable := TRUE;
    GVL_RUNTIME_SUSTAINABILITY_FABRIC.Runtime_Queue_Load_Stable := TRUE;
    GVL_RUNTIME_SUSTAINABILITY_FABRIC.Memory_Fragmentation_Stable := TRUE;
    GVL_RUNTIME_SUSTAINABILITY_FABRIC.Watchdog_Jitter_Stable := TRUE;
    GVL_RUNTIME_SUSTAINABILITY_FABRIC.HA_Synchronization_Load_Stable := TRUE;

    GVL_RUNTIME_SUSTAINABILITY_FABRIC.Runtime_Sustainability_Epoch :=
        GVL_ENERGY_CAUSALITY_FABRIC.Energy_Causality_Epoch;

    GVL_RUNTIME_SUSTAINABILITY_FABRIC.Runtime_Sustainability_Epoch_Coherent := TRUE;

    GVL_RUNTIME_SUSTAINABILITY_FABRIC.Runtime_Sustainability_Last_Update_MS :=
        L_Now_MS;

    GVL_RUNTIME_SUSTAINABILITY_FABRIC.Runtime_Sustainability_Lease_Expired := FALSE;

    GVL_RUNTIME_SUSTAINABILITY_FABRIC.Runtime_Sustainability_Last_Error_Code := 0;
    GVL_RUNTIME_SUSTAINABILITY_FABRIC.Runtime_Sustainability_Last_Error_Text := '';
ELSE
    GVL_RUNTIME_SUSTAINABILITY_FABRIC.Runtime_Sustainability_Valid := FALSE;
    GVL_RUNTIME_SUSTAINABILITY_FABRIC.Runtime_Sustainability_Granted := FALSE;
    GVL_RUNTIME_SUSTAINABILITY_FABRIC.Runtime_Sustainability_Quarantine_Active := TRUE;

    GVL_RUNTIME_SUSTAINABILITY_FABRIC.Runtime_Sustainability_Lease_Expired := TRUE;

    GVL_RUNTIME_SUSTAINABILITY_FABRIC.Runtime_Sustainability_Last_Error_Code :=
        L_Error_Code;

    GVL_RUNTIME_SUSTAINABILITY_FABRIC.Runtime_Sustainability_Last_Error_Text :=
        L_Error_Text;

    GVL_RUNTIME_SUSTAINABILITY_FABRIC.Runtime_Sustainability_Invalidation_Count :=
        GVL_RUNTIME_SUSTAINABILITY_FABRIC.Runtime_Sustainability_Invalidation_Count + 1;
END_IF;

END_PROGRAM