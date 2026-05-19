PROGRAM PRG_Sensor_Consensus_Governor
VAR
    L_Now_MS : UDINT;
    L_Consensus_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
    L_Consensus_Age_MS : UDINT;
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Consensus_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_SENSOR_CONSENSUS.Sensor_Consensus_Valid := FALSE;
GVL_SENSOR_CONSENSUS.Sensor_Consensus_Quarantine_Active := TRUE;
GVL_SENSOR_CONSENSUS.Sensor_Consensus_Lease_Expired := TRUE;
GVL_SENSOR_CONSENSUS.Sensor_Consensus_Freshness_Valid := FALSE;

GVL_SENSOR_CONSENSUS.Physics_Invariants_Satisfied := FALSE;
GVL_SENSOR_CONSENSUS.Cross_Sensor_Correlation_Valid := FALSE;
GVL_SENSOR_CONSENSUS.Telemetry_Plausibility_Valid := FALSE;

IF GVL_SENSOR_CONSENSUS.Sensor_Replay_Suspected THEN
    L_Consensus_Valid := FALSE;
    L_Error_Code := 22000;
    L_Error_Text := 'Sensor replay suspected';
END_IF;

IF L_Consensus_Valid
AND GVL_SENSOR_CONSENSUS.Sensor_Partition_Detected THEN
    L_Consensus_Valid := FALSE;
    L_Error_Code := 22001;
    L_Error_Text := 'Sensor partition detected';
END_IF;

IF L_Consensus_Valid
AND GVL_SENSOR_CONSENSUS.Sensor_Hallucination_Suspected THEN
    L_Consensus_Valid := FALSE;
    L_Error_Code := 22002;
    L_Error_Text := 'Sensor hallucination suspected';
END_IF;

IF L_Consensus_Valid
AND GVL_SENSOR_CONSENSUS.Cross_Sensor_Divergence_Detected THEN
    L_Consensus_Valid := FALSE;
    L_Error_Code := 22003;
    L_Error_Text := 'Cross sensor divergence detected';
END_IF;

IF L_Consensus_Valid
AND GVL_SENSOR_CONSENSUS.Sensor_Drift_Detected THEN
    L_Consensus_Valid := FALSE;
    L_Error_Code := 22004;
    L_Error_Text := 'Sensor drift detected';
END_IF;

IF L_Consensus_Valid
AND GVL_SENSOR_CONSENSUS.Sensor_Oscillation_Detected THEN
    L_Consensus_Valid := FALSE;
    L_Error_Code := 22005;
    L_Error_Text := 'Sensor oscillation detected';
END_IF;

IF L_Consensus_Valid
AND GVL_SENSOR_CONSENSUS.Sensor_Stuck_State_Detected THEN
    L_Consensus_Valid := FALSE;
    L_Error_Code := 22006;
    L_Error_Text := 'Sensor stuck state detected';
END_IF;

// Physics invariants.
IF L_Consensus_Valid
AND NOT GVL_SENSOR_CONSENSUS.Flow_Response_Valid THEN
    L_Consensus_Valid := FALSE;
    L_Error_Code := 22010;
    L_Error_Text := 'Flow response invalid';
END_IF;

IF L_Consensus_Valid
AND NOT GVL_SENSOR_CONSENSUS.Pressure_Response_Valid THEN
    L_Consensus_Valid := FALSE;
    L_Error_Code := 22011;
    L_Error_Text := 'Pressure response invalid';
END_IF;

IF L_Consensus_Valid
AND NOT GVL_SENSOR_CONSENSUS.Airflow_Response_Valid THEN
    L_Consensus_Valid := FALSE;
    L_Error_Code := 22012;
    L_Error_Text := 'Airflow response invalid';
END_IF;

IF L_Consensus_Valid
AND NOT GVL_SENSOR_CONSENSUS.Current_Signature_Valid THEN
    L_Consensus_Valid := FALSE;
    L_Error_Code := 22013;
    L_Error_Text := 'Current signature invalid';
END_IF;

// Consensus freshness.
L_Consensus_Age_MS :=
    L_Now_MS - GVL_SENSOR_CONSENSUS.Last_Consensus_Update_MS;

IF L_Consensus_Valid
AND (L_Consensus_Age_MS > 5000) THEN
    L_Consensus_Valid := FALSE;
    L_Error_Code := 22020;
    L_Error_Text := 'Sensor consensus stale';
END_IF;

IF L_Consensus_Valid THEN
    GVL_SENSOR_CONSENSUS.Sensor_Consensus_Valid := TRUE;
    GVL_SENSOR_CONSENSUS.Sensor_Consensus_Quarantine_Active := FALSE;
    GVL_SENSOR_CONSENSUS.Sensor_Consensus_Lease_Expired := FALSE;
    GVL_SENSOR_CONSENSUS.Sensor_Consensus_Freshness_Valid := TRUE;

    GVL_SENSOR_CONSENSUS.Physics_Invariants_Satisfied := TRUE;
    GVL_SENSOR_CONSENSUS.Cross_Sensor_Correlation_Valid := TRUE;
    GVL_SENSOR_CONSENSUS.Telemetry_Plausibility_Valid := TRUE;

    GVL_SENSOR_CONSENSUS.Sensor_Consensus_Epoch :=
        GVL_SENSOR_CONSENSUS.Sensor_Consensus_Epoch + 1;

    GVL_SENSOR_CONSENSUS.Last_Consensus_Update_MS := L_Now_MS;

    GVL_SENSOR_CONSENSUS.Sensor_Consensus_Last_Error_Code := 0;
    GVL_SENSOR_CONSENSUS.Sensor_Consensus_Last_Error_Text := '';
ELSE
    GVL_SENSOR_CONSENSUS.Sensor_Consensus_Valid := FALSE;
    GVL_SENSOR_CONSENSUS.Sensor_Consensus_Quarantine_Active := TRUE;
    GVL_SENSOR_CONSENSUS.Sensor_Consensus_Lease_Expired := TRUE;
    GVL_SENSOR_CONSENSUS.Sensor_Consensus_Freshness_Valid := FALSE;

    GVL_SENSOR_CONSENSUS.Sensor_Consensus_Last_Error_Code := L_Error_Code;
    GVL_SENSOR_CONSENSUS.Sensor_Consensus_Last_Error_Text := L_Error_Text;

    GVL_SENSOR_CONSENSUS.Sensor_Consensus_Invalidation_Count :=
        GVL_SENSOR_CONSENSUS.Sensor_Consensus_Invalidation_Count + 1;
END_IF;

END_PROGRAM