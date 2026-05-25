PROGRAM PRG_Temporal_Stability_Governor
VAR
    L_Now_MS : UDINT;
    L_Stability_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Stability_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_TEMPORAL_STABILITY.Temporal_Stability_Valid := FALSE;
GVL_TEMPORAL_STABILITY.Temporal_Stability_Granted := FALSE;
GVL_TEMPORAL_STABILITY.Temporal_Stability_Quarantine_Active := TRUE;

GVL_TEMPORAL_STABILITY.Post_Convergence_Stable := FALSE;
GVL_TEMPORAL_STABILITY.No_Oscillation_Detected := FALSE;
GVL_TEMPORAL_STABILITY.No_Relay_Chatter_Detected := FALSE;
GVL_TEMPORAL_STABILITY.Thermal_Slope_Stable := FALSE;
GVL_TEMPORAL_STABILITY.Pressure_Stable := FALSE;
GVL_TEMPORAL_STABILITY.Flow_Stable := FALSE;

// Temporal stability requires completed physical transaction.
IF NOT GVL_PHYSICAL_TRANSACTION.Physical_Transaction_Granted THEN
    L_Stability_Valid := FALSE;
    L_Error_Code := 28000;
    L_Error_Text := 'Physical transaction not granted';
END_IF;

// Start deterministic observation window.
IF L_Stability_Valid
AND NOT GVL_TEMPORAL_STABILITY.Stability_Observation_Window_Active THEN
    GVL_TEMPORAL_STABILITY.Stability_Observation_Window_Active := TRUE;
    GVL_TEMPORAL_STABILITY.Stability_Window_Start_MS := L_Now_MS;
END_IF;

IF GVL_TEMPORAL_STABILITY.Stability_Observation_Window_Active THEN
    GVL_TEMPORAL_STABILITY.Stability_Window_Elapsed_MS :=
        L_Now_MS - GVL_TEMPORAL_STABILITY.Stability_Window_Start_MS;
END_IF;

// Observation window must fully elapse.
IF L_Stability_Valid
AND (GVL_TEMPORAL_STABILITY.Stability_Window_Elapsed_MS <
     GVL_TEMPORAL_STABILITY.Stability_Window_Target_MS) THEN

    L_Stability_Valid := FALSE;
    L_Error_Code := 28001;
    L_Error_Text := 'Temporal observation window not elapsed';
END_IF;

// Delayed instability detection.
IF GVL_TEMPORAL_STABILITY.Post_Convergence_Oscillation_Detected THEN
    L_Stability_Valid := FALSE;
    L_Error_Code := 28002;
    L_Error_Text := 'Post-convergence oscillation detected';
END_IF;

IF GVL_TEMPORAL_STABILITY.Thermal_Inertia_Rebound_Detected THEN
    L_Stability_Valid := FALSE;
    L_Error_Code := 28003;
    L_Error_Text := 'Thermal inertia rebound detected';
END_IF;

IF GVL_TEMPORAL_STABILITY.Pressure_Rebound_Detected THEN
    L_Stability_Valid := FALSE;
    L_Error_Code := 28004;
    L_Error_Text := 'Pressure rebound detected';
END_IF;

IF GVL_TEMPORAL_STABILITY.Relay_Chatter_Detected THEN
    L_Stability_Valid := FALSE;
    L_Error_Code := 28005;
    L_Error_Text := 'Relay chatter detected';
END_IF;

IF GVL_TEMPORAL_STABILITY.Pump_Cavitation_Recovery_Detected THEN
    L_Stability_Valid := FALSE;
    L_Error_Code := 28006;
    L_Error_Text := 'Pump cavitation recovery detected';
END_IF;

IF GVL_TEMPORAL_STABILITY.Delayed_Actuator_Divergence_Detected THEN
    L_Stability_Valid := FALSE;
    L_Error_Code := 28007;
    L_Error_Text := 'Delayed actuator divergence detected';
END_IF;

// Stable physical conditions required.
IF L_Stability_Valid
AND NOT GVL_TEMPORAL_STABILITY.No_Oscillation_Detected THEN
    L_Stability_Valid := FALSE;
    L_Error_Code := 28010;
    L_Error_Text := 'Oscillation-free state not confirmed';
END_IF;

IF L_Stability_Valid
AND NOT GVL_TEMPORAL_STABILITY.No_Relay_Chatter_Detected THEN
    L_Stability_Valid := FALSE;
    L_Error_Code := 28011;
    L_Error_Text := 'Relay chatter-free state not confirmed';
END_IF;

IF L_Stability_Valid
AND NOT GVL_TEMPORAL_STABILITY.Thermal_Slope_Stable THEN
    L_Stability_Valid := FALSE;
    L_Error_Code := 28012;
    L_Error_Text := 'Thermal slope stability missing';
END_IF;

IF L_Stability_Valid
AND NOT GVL_TEMPORAL_STABILITY.Pressure_Stable THEN
    L_Stability_Valid := FALSE;
    L_Error_Code := 28013;
    L_Error_Text := 'Pressure stability missing';
END_IF;

IF L_Stability_Valid
AND NOT GVL_TEMPORAL_STABILITY.Flow_Stable THEN
    L_Stability_Valid := FALSE;
    L_Error_Code := 28014;
    L_Error_Text := 'Flow stability missing';
END_IF;

IF L_Stability_Valid THEN
    GVL_TEMPORAL_STABILITY.Temporal_Stability_Valid := TRUE;
    GVL_TEMPORAL_STABILITY.Temporal_Stability_Granted := TRUE;
    GVL_TEMPORAL_STABILITY.Temporal_Stability_Quarantine_Active := FALSE;

    GVL_TEMPORAL_STABILITY.Post_Convergence_Stable := TRUE;

    GVL_TEMPORAL_STABILITY.Temporal_Stability_Epoch :=
        GVL_PHYSICAL_TRANSACTION.Physical_Transaction_Epoch;

    GVL_TEMPORAL_STABILITY.Temporal_Stability_Epoch_Coherent := TRUE;

    GVL_TEMPORAL_STABILITY.Temporal_Stability_Last_Update_MS :=
        L_Now_MS;

    GVL_TEMPORAL_STABILITY.Temporal_Stability_Lease_Expired := FALSE;

    GVL_TEMPORAL_STABILITY.Temporal_Stability_Last_Error_Code := 0;
    GVL_TEMPORAL_STABILITY.Temporal_Stability_Last_Error_Text := '';
ELSE
    GVL_TEMPORAL_STABILITY.Temporal_Stability_Valid := FALSE;
    GVL_TEMPORAL_STABILITY.Temporal_Stability_Granted := FALSE;
    GVL_TEMPORAL_STABILITY.Temporal_Stability_Quarantine_Active := TRUE;

    GVL_TEMPORAL_STABILITY.Temporal_Stability_Lease_Expired := TRUE;

    GVL_TEMPORAL_STABILITY.Temporal_Stability_Last_Error_Code :=
        L_Error_Code;

    GVL_TEMPORAL_STABILITY.Temporal_Stability_Last_Error_Text :=
        L_Error_Text;

    GVL_TEMPORAL_STABILITY.Temporal_Stability_Invalidation_Count :=
        GVL_TEMPORAL_STABILITY.Temporal_Stability_Invalidation_Count + 1;
END_IF;

END_PROGRAM