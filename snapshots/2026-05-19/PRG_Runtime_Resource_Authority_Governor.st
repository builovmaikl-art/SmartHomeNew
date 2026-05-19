PROGRAM PRG_Runtime_Resource_Authority_Governor
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
GVL_RUNTIME_RESOURCE_AUTHORITY.Runtime_Resource_Authority_Valid := FALSE;
GVL_RUNTIME_RESOURCE_AUTHORITY.Runtime_Resource_Authority_Granted := FALSE;
GVL_RUNTIME_RESOURCE_AUTHORITY.Runtime_Resource_Quarantine_Active := TRUE;

GVL_RUNTIME_RESOURCE_AUTHORITY.Deterministic_Cycle_Time_Valid := FALSE;
GVL_RUNTIME_RESOURCE_AUTHORITY.Task_Jitter_Within_Bounds := FALSE;
GVL_RUNTIME_RESOURCE_AUTHORITY.Watchdog_Margin_Stable := FALSE;
GVL_RUNTIME_RESOURCE_AUTHORITY.Runtime_Latency_Stable := FALSE;
GVL_RUNTIME_RESOURCE_AUTHORITY.Queue_Backlog_Stable := FALSE;

// Environmental authority required.
IF NOT GVL_ENVIRONMENTAL_AUTHORITY.Environmental_Authority_Granted THEN
    L_Runtime_Valid := FALSE;
    L_Error_Code := 30000;
    L_Error_Text := 'Environmental authority not granted';
END_IF;

// Resource exhaustion detectors.
IF GVL_RUNTIME_RESOURCE_AUTHORITY.Hidden_Jitter_Amplification_Detected THEN
    L_Runtime_Valid := FALSE;
    L_Error_Code := 30001;
    L_Error_Text := 'Hidden jitter amplification detected';
END_IF;

IF GVL_RUNTIME_RESOURCE_AUTHORITY.Queue_Induced_Authority_Lag_Detected THEN
    L_Runtime_Valid := FALSE;
    L_Error_Code := 30002;
    L_Error_Text := 'Queue-induced authority lag detected';
END_IF;

IF GVL_RUNTIME_RESOURCE_AUTHORITY.Watchdog_Near_Death_Oscillation_Detected THEN
    L_Runtime_Valid := FALSE;
    L_Error_Code := 30003;
    L_Error_Text := 'Watchdog near-death oscillation detected';
END_IF;

IF GVL_RUNTIME_RESOURCE_AUTHORITY.Runtime_Starvation_Race_Detected THEN
    L_Runtime_Valid := FALSE;
    L_Error_Code := 30004;
    L_Error_Text := 'Runtime starvation race detected';
END_IF;

IF GVL_RUNTIME_RESOURCE_AUTHORITY.Cycle_Collapse_SplitBrain_Detected THEN
    L_Runtime_Valid := FALSE;
    L_Error_Code := 30005;
    L_Error_Text := 'Cycle collapse split-brain detected';
END_IF;

IF GVL_RUNTIME_RESOURCE_AUTHORITY.Heap_Fragmentation_Critical THEN
    L_Runtime_Valid := FALSE;
    L_Error_Code := 30006;
    L_Error_Text := 'Critical heap fragmentation detected';
END_IF;

IF GVL_RUNTIME_RESOURCE_AUTHORITY.Fieldbus_Backlog_Saturation_Detected THEN
    L_Runtime_Valid := FALSE;
    L_Error_Code := 30007;
    L_Error_Text := 'Fieldbus backlog saturation detected';
END_IF;

// Deterministic execution envelope validation.
IF L_Runtime_Valid
AND (GVL_RUNTIME_RESOURCE_AUTHORITY.Current_Task_Jitter_US >
     GVL_RUNTIME_RESOURCE_AUTHORITY.Max_Allowed_Task_Jitter_US) THEN

    L_Runtime_Valid := FALSE;
    L_Error_Code := 30010;
    L_Error_Text := 'Task jitter exceeds deterministic envelope';
END_IF;

IF L_Runtime_Valid
AND (GVL_RUNTIME_RESOURCE_AUTHORITY.Current_Runtime_Latency_US >
     GVL_RUNTIME_RESOURCE_AUTHORITY.Max_Allowed_Runtime_Latency_US) THEN

    L_Runtime_Valid := FALSE;
    L_Error_Code := 30011;
    L_Error_Text := 'Runtime latency exceeds deterministic envelope';
END_IF;

IF L_Runtime_Valid
AND (GVL_RUNTIME_RESOURCE_AUTHORITY.Current_Fieldbus_Queue_Depth >
     GVL_RUNTIME_RESOURCE_AUTHORITY.Max_Allowed_Fieldbus_Queue_Depth) THEN

    L_Runtime_Valid := FALSE;
    L_Error_Code := 30012;
    L_Error_Text := 'Fieldbus queue depth exceeds deterministic envelope';
END_IF;

IF L_Runtime_Valid
AND (GVL_RUNTIME_RESOURCE_AUTHORITY.Current_Watchdog_Margin_MS <
     GVL_RUNTIME_RESOURCE_AUTHORITY.Minimum_Watchdog_Margin_MS) THEN

    L_Runtime_Valid := FALSE;
    L_Error_Code := 30013;
    L_Error_Text := 'Watchdog margin below deterministic envelope';
END_IF;

IF L_Runtime_Valid THEN
    GVL_RUNTIME_RESOURCE_AUTHORITY.Runtime_Resource_Authority_Valid := TRUE;
    GVL_RUNTIME_RESOURCE_AUTHORITY.Runtime_Resource_Authority_Granted := TRUE;
    GVL_RUNTIME_RESOURCE_AUTHORITY.Runtime_Resource_Quarantine_Active := FALSE;

    GVL_RUNTIME_RESOURCE_AUTHORITY.Deterministic_Cycle_Time_Valid := TRUE;
    GVL_RUNTIME_RESOURCE_AUTHORITY.Task_Jitter_Within_Bounds := TRUE;
    GVL_RUNTIME_RESOURCE_AUTHORITY.Watchdog_Margin_Stable := TRUE;
    GVL_RUNTIME_RESOURCE_AUTHORITY.Runtime_Latency_Stable := TRUE;
    GVL_RUNTIME_RESOURCE_AUTHORITY.Queue_Backlog_Stable := TRUE;

    GVL_RUNTIME_RESOURCE_AUTHORITY.Runtime_Resource_Authority_Epoch :=
        GVL_ENVIRONMENTAL_AUTHORITY.Environmental_Authority_Epoch;

    GVL_RUNTIME_RESOURCE_AUTHORITY.Runtime_Resource_Authority_Epoch_Coherent := TRUE;

    GVL_RUNTIME_RESOURCE_AUTHORITY.Runtime_Resource_Last_Update_MS :=
        L_Now_MS;

    GVL_RUNTIME_RESOURCE_AUTHORITY.Runtime_Resource_Lease_Expired := FALSE;

    GVL_RUNTIME_RESOURCE_AUTHORITY.Runtime_Resource_Last_Error_Code := 0;
    GVL_RUNTIME_RESOURCE_AUTHORITY.Runtime_Resource_Last_Error_Text := '';
ELSE
    GVL_RUNTIME_RESOURCE_AUTHORITY.Runtime_Resource_Authority_Valid := FALSE;
    GVL_RUNTIME_RESOURCE_AUTHORITY.Runtime_Resource_Authority_Granted := FALSE;
    GVL_RUNTIME_RESOURCE_AUTHORITY.Runtime_Resource_Quarantine_Active := TRUE;

    GVL_RUNTIME_RESOURCE_AUTHORITY.Runtime_Resource_Lease_Expired := TRUE;

    GVL_RUNTIME_RESOURCE_AUTHORITY.Runtime_Resource_Last_Error_Code :=
        L_Error_Code;

    GVL_RUNTIME_RESOURCE_AUTHORITY.Runtime_Resource_Last_Error_Text :=
        L_Error_Text;

    GVL_RUNTIME_RESOURCE_AUTHORITY.Runtime_Resource_Invalidation_Count :=
        GVL_RUNTIME_RESOURCE_AUTHORITY.Runtime_Resource_Invalidation_Count + 1;
END_IF;

END_PROGRAM