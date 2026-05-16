PROGRAM PRG_Telemetry_Causality_Governor
VAR
    L_Now_MS : UDINT;
    L_Causality_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
    L_Ack_Age_MS : UDINT;
    L_Convergence_Age_MS : UDINT;
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Causality_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_TELEMETRY.Telemetry_Runtime_Valid := FALSE;
GVL_TELEMETRY.Telemetry_Freshness_Valid := FALSE;
GVL_TELEMETRY.Command_Telemetry_Causality_Valid := FALSE;
GVL_TELEMETRY.Actuator_Feedback_Valid := FALSE;
GVL_TELEMETRY.Actuator_Feedback_Fresh := FALSE;
GVL_TELEMETRY.Physical_Effect_Confirmed := FALSE;
GVL_TELEMETRY.Physical_Effect_Finalized := FALSE;
GVL_TELEMETRY.Physical_Target_Converged := FALSE;
GVL_TELEMETRY.Physical_Stable_Window_OK := FALSE;
GVL_TELEMETRY.Command_Telemetry_Divergence_Detected := TRUE;

// Bind command causality to the current output publication epoch.
GVL_TELEMETRY.Command_Epoch := GVL_OUTPUT_EPOCH.Output_Publication_Epoch;

IF NOT GVL_OUTPUT_EPOCH.Output_Publication_Valid THEN
    L_Causality_Valid := FALSE;
    L_Error_Code := 21000;
    L_Error_Text := 'Telemetry causality output publication invalid';
END_IF;

IF L_Causality_Valid AND NOT GVL_OUTPUT_EPOCH.Output_Runtime_Epoch_Valid THEN
    L_Causality_Valid := FALSE;
    L_Error_Code := 21001;
    L_Error_Text := 'Telemetry causality runtime epoch invalid';
END_IF;

IF L_Causality_Valid AND GVL_OUTPUT_EPOCH.Output_Lease_Expired THEN
    L_Causality_Valid := FALSE;
    L_Error_Code := 21002;
    L_Error_Text := 'Telemetry causality output lease expired';
END_IF;

IF L_Causality_Valid AND GVL_OUTPUT_EPOCH.Output_Forced_Safe_Decay THEN
    L_Causality_Valid := FALSE;
    L_Error_Code := 21003;
    L_Error_Text := 'Telemetry causality output forced safe decay';
END_IF;

// Telemetry epoch must acknowledge the exact command epoch.
IF L_Causality_Valid AND (GVL_TELEMETRY.Telemetry_Epoch <> GVL_TELEMETRY.Command_Epoch) THEN
    L_Causality_Valid := FALSE;
    L_Error_Code := 21010;
    L_Error_Text := 'Telemetry epoch does not match command epoch';
END_IF;

IF L_Causality_Valid AND (GVL_TELEMETRY.Telemetry_Epoch < GVL_TELEMETRY.Last_Acknowledged_Command_Epoch) THEN
    GVL_TELEMETRY.Telemetry_Replay_Suspected := TRUE;

    L_Causality_Valid := FALSE;
    L_Error_Code := 21011;
    L_Error_Text := 'Telemetry epoch replay suspected';
END_IF;

L_Ack_Age_MS := L_Now_MS - GVL_TELEMETRY.Last_Physical_Ack_Time_MS;

IF L_Causality_Valid AND (L_Ack_Age_MS > 5000) THEN
    L_Causality_Valid := FALSE;
    L_Error_Code := 21020;
    L_Error_Text := 'Physical acknowledgement stale';
END_IF;

L_Convergence_Age_MS := L_Now_MS - GVL_TELEMETRY.Last_Physical_Convergence_MS;

IF L_Causality_Valid AND (L_Convergence_Age_MS > 10000) THEN
    L_Causality_Valid := FALSE;
    L_Error_Code := 21021;
    L_Error_Text := 'Physical convergence stale';
END_IF;

IF L_Causality_Valid THEN
    GVL_TELEMETRY.Telemetry_Runtime_Valid := TRUE;
    GVL_TELEMETRY.Telemetry_Freshness_Valid := TRUE;
    GVL_TELEMETRY.Telemetry_Lease_Expired := FALSE;
    GVL_TELEMETRY.Telemetry_Quarantine_Active := FALSE;

    GVL_TELEMETRY.Command_Telemetry_Causality_Valid := TRUE;
    GVL_TELEMETRY.Command_Telemetry_Divergence_Detected := FALSE;

    GVL_TELEMETRY.Actuator_Feedback_Valid := TRUE;
    GVL_TELEMETRY.Actuator_Feedback_Fresh := TRUE;
    GVL_TELEMETRY.Physical_Effect_Confirmed := TRUE;

    GVL_TELEMETRY.Physical_Target_Converged := TRUE;
    GVL_TELEMETRY.Physical_Stable_Window_OK := TRUE;
    GVL_TELEMETRY.Physical_Effect_Finalized := TRUE;

    GVL_TELEMETRY.Last_Acknowledged_Command_Epoch := GVL_TELEMETRY.Command_Epoch;

    GVL_TELEMETRY.Telemetry_Last_Error_Code := 0;
    GVL_TELEMETRY.Telemetry_Last_Error_Text := '';
ELSE
    GVL_TELEMETRY.Telemetry_Runtime_Valid := FALSE;
    GVL_TELEMETRY.Telemetry_Freshness_Valid := FALSE;
    GVL_TELEMETRY.Telemetry_Lease_Expired := TRUE;
    GVL_TELEMETRY.Telemetry_Quarantine_Active := TRUE;

    GVL_TELEMETRY.Command_Telemetry_Causality_Valid := FALSE;
    GVL_TELEMETRY.Command_Telemetry_Divergence_Detected := TRUE;

    GVL_TELEMETRY.Telemetry_Last_Error_Code := L_Error_Code;
    GVL_TELEMETRY.Telemetry_Last_Error_Text := L_Error_Text;
    GVL_TELEMETRY.Telemetry_Invalidation_Count :=
        GVL_TELEMETRY.Telemetry_Invalidation_Count + 1;
END_IF;

END_PROGRAM