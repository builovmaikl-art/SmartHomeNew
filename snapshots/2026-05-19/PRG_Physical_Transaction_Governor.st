PROGRAM PRG_Physical_Transaction_Governor
VAR
    L_Now_MS : UDINT;
    L_Transaction_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Transaction_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_PHYSICAL_TRANSACTION.Physical_Transaction_Valid := FALSE;
GVL_PHYSICAL_TRANSACTION.Physical_Transaction_Granted := FALSE;
GVL_PHYSICAL_TRANSACTION.Physical_Transaction_Quarantine_Active := TRUE;

GVL_PHYSICAL_TRANSACTION.All_Actuators_Converged := FALSE;
GVL_PHYSICAL_TRANSACTION.Cross_Actuator_Epoch_Coherent := FALSE;
GVL_PHYSICAL_TRANSACTION.Distributed_Actuation_Coherent := FALSE;
GVL_PHYSICAL_TRANSACTION.Stable_Plant_State_Confirmed := FALSE;

// Bind transaction epochs.
GVL_PHYSICAL_TRANSACTION.Physical_Transaction_Command_Epoch :=
    GVL_ACTUATION_AUTHORITY.Actuation_Command_Epoch;

GVL_PHYSICAL_TRANSACTION.Physical_Transaction_ACK_Epoch :=
    GVL_ACTUATION_AUTHORITY.Field_ACK_Epoch;

IF GVL_PHYSICAL_TRANSACTION.Physical_Transaction_Command_Epoch <>
   GVL_PHYSICAL_TRANSACTION.Physical_Transaction_ACK_Epoch THEN

    GVL_PHYSICAL_TRANSACTION.Cross_Actuator_Convergence_Skew := TRUE;

    L_Transaction_Valid := FALSE;
    L_Error_Code := 27000;
    L_Error_Text := 'Physical transaction epoch skew detected';
END_IF;

// Ordering race detection.
IF L_Transaction_Valid
AND GVL_PHYSICAL_TRANSACTION.Pump_Valve_Ordering_Race_Detected THEN
    L_Transaction_Valid := FALSE;
    L_Error_Code := 27001;
    L_Error_Text := 'Pump/valve ordering race detected';
END_IF;

// Brownout / rollback protection.
IF L_Transaction_Valid
AND GVL_PHYSICAL_TRANSACTION.Distributed_Actuator_Rollback_Detected THEN
    L_Transaction_Valid := FALSE;
    L_Error_Code := 27002;
    L_Error_Text := 'Distributed actuator rollback detected';
END_IF;

IF L_Transaction_Valid
AND GVL_PHYSICAL_TRANSACTION.Brownout_Partial_Switching_Detected THEN
    L_Transaction_Valid := FALSE;
    L_Error_Code := 27003;
    L_Error_Text := 'Brownout partial switching detected';
END_IF;

IF L_Transaction_Valid
AND GVL_PHYSICAL_TRANSACTION.Transaction_Timeout_Detected THEN
    L_Transaction_Valid := FALSE;
    L_Error_Code := 27004;
    L_Error_Text := 'Physical transaction timeout detected';
END_IF;

IF L_Transaction_Valid
AND GVL_PHYSICAL_TRANSACTION.Partial_Plant_Transition_Detected THEN
    L_Transaction_Valid := FALSE;
    L_Error_Code := 27005;
    L_Error_Text := 'Partial plant transition detected';
END_IF;

// All actuator transitions required.
IF L_Transaction_Valid
AND NOT GVL_PHYSICAL_TRANSACTION.Valve_Transition_Confirmed THEN
    L_Transaction_Valid := FALSE;
    L_Error_Code := 27010;
    L_Error_Text := 'Valve transition confirmation missing';
END_IF;

IF L_Transaction_Valid
AND NOT GVL_PHYSICAL_TRANSACTION.Pump_Transition_Confirmed THEN
    L_Transaction_Valid := FALSE;
    L_Error_Code := 27011;
    L_Error_Text := 'Pump transition confirmation missing';
END_IF;

IF L_Transaction_Valid
AND NOT GVL_PHYSICAL_TRANSACTION.Damper_Transition_Confirmed THEN
    L_Transaction_Valid := FALSE;
    L_Error_Code := 27012;
    L_Error_Text := 'Damper transition confirmation missing';
END_IF;

IF L_Transaction_Valid
AND NOT GVL_PHYSICAL_TRANSACTION.Relay_Bank_Transition_Confirmed THEN
    L_Transaction_Valid := FALSE;
    L_Error_Code := 27013;
    L_Error_Text := 'Relay bank transition confirmation missing';
END_IF;

// Stable plant convergence required.
IF L_Transaction_Valid
AND NOT GVL_PHYSICAL_TRANSACTION.Flow_Stabilization_Confirmed THEN
    L_Transaction_Valid := FALSE;
    L_Error_Code := 27020;
    L_Error_Text := 'Flow stabilization missing';
END_IF;

IF L_Transaction_Valid
AND NOT GVL_PHYSICAL_TRANSACTION.Pressure_Stabilization_Confirmed THEN
    L_Transaction_Valid := FALSE;
    L_Error_Code := 27021;
    L_Error_Text := 'Pressure stabilization missing';
END_IF;

IF L_Transaction_Valid
AND NOT GVL_PHYSICAL_TRANSACTION.Thermal_Response_Confirmed THEN
    L_Transaction_Valid := FALSE;
    L_Error_Code := 27022;
    L_Error_Text := 'Thermal response confirmation missing';
END_IF;

IF L_Transaction_Valid
AND NOT GVL_PHYSICAL_TRANSACTION.Electrical_Load_Stabilized THEN
    L_Transaction_Valid := FALSE;
    L_Error_Code := 27023;
    L_Error_Text := 'Electrical load stabilization missing';
END_IF;

IF L_Transaction_Valid THEN
    GVL_PHYSICAL_TRANSACTION.Physical_Transaction_Valid := TRUE;
    GVL_PHYSICAL_TRANSACTION.Physical_Transaction_Granted := TRUE;
    GVL_PHYSICAL_TRANSACTION.Physical_Transaction_Quarantine_Active := FALSE;

    GVL_PHYSICAL_TRANSACTION.All_Actuators_Converged := TRUE;
    GVL_PHYSICAL_TRANSACTION.Cross_Actuator_Epoch_Coherent := TRUE;
    GVL_PHYSICAL_TRANSACTION.Distributed_Actuation_Coherent := TRUE;
    GVL_PHYSICAL_TRANSACTION.Stable_Plant_State_Confirmed := TRUE;

    GVL_PHYSICAL_TRANSACTION.Physical_Transaction_Epoch :=
        GVL_PHYSICAL_TRANSACTION.Physical_Transaction_Command_Epoch;

    GVL_PHYSICAL_TRANSACTION.Physical_Transaction_Last_Update_MS :=
        L_Now_MS;

    GVL_PHYSICAL_TRANSACTION.Physical_Transaction_Lease_Expired := FALSE;

    GVL_PHYSICAL_TRANSACTION.Physical_Transaction_Last_Error_Code := 0;
    GVL_PHYSICAL_TRANSACTION.Physical_Transaction_Last_Error_Text := '';
ELSE
    GVL_PHYSICAL_TRANSACTION.Physical_Transaction_Valid := FALSE;
    GVL_PHYSICAL_TRANSACTION.Physical_Transaction_Granted := FALSE;
    GVL_PHYSICAL_TRANSACTION.Physical_Transaction_Quarantine_Active := TRUE;

    GVL_PHYSICAL_TRANSACTION.Physical_Transaction_Lease_Expired := TRUE;

    GVL_PHYSICAL_TRANSACTION.Physical_Transaction_Last_Error_Code :=
        L_Error_Code;

    GVL_PHYSICAL_TRANSACTION.Physical_Transaction_Last_Error_Text :=
        L_Error_Text;

    GVL_PHYSICAL_TRANSACTION.Physical_Transaction_Invalidation_Count :=
        GVL_PHYSICAL_TRANSACTION.Physical_Transaction_Invalidation_Count + 1;
END_IF;

END_PROGRAM