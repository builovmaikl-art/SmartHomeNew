PROGRAM PRG_Actuation_Authority_Governor
VAR
    L_Now_MS : UDINT;
    L_Actuation_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Actuation_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_ACTUATION_AUTHORITY.Actuation_Authority_Valid := FALSE;
GVL_ACTUATION_AUTHORITY.Actuation_Authority_Granted := FALSE;
GVL_ACTUATION_AUTHORITY.Actuation_Quarantine_Active := TRUE;

GVL_ACTUATION_AUTHORITY.Field_Device_ACK_Valid := FALSE;
GVL_ACTUATION_AUTHORITY.Actuator_Transition_Observed := FALSE;
GVL_ACTUATION_AUTHORITY.Physical_Convergence_Confirmed := FALSE;
GVL_ACTUATION_AUTHORITY.Stable_Physical_Convergence := FALSE;

// Actuation epoch binding.
GVL_ACTUATION_AUTHORITY.Actuation_Command_Epoch :=
    GVL_OUTPUT_EPOCH.Output_Publication_Epoch;

// Field ACK must match command epoch.
IF GVL_ACTUATION_AUTHORITY.Field_ACK_Epoch <>
   GVL_ACTUATION_AUTHORITY.Actuation_Command_Epoch THEN

    GVL_ACTUATION_AUTHORITY.Command_Actuation_Skew_Detected := TRUE;

    L_Actuation_Valid := FALSE;
    L_Error_Code := 26000;
    L_Error_Text := 'Command/actuation epoch skew detected';
END_IF;

// ACK replay detection.
IF L_Actuation_Valid
AND GVL_ACTUATION_AUTHORITY.ACK_Replay_Suspected THEN
    L_Actuation_Valid := FALSE;
    L_Error_Code := 26001;
    L_Error_Text := 'Field ACK replay suspected';
END_IF;

// Missing field acknowledgement.
IF L_Actuation_Valid
AND GVL_ACTUATION_AUTHORITY.Write_Without_Confirm_Detected THEN
    L_Actuation_Valid := FALSE;
    L_Error_Code := 26002;
    L_Error_Text := 'Write without field confirmation detected';
END_IF;

// Relay weld / actuator stall.
IF L_Actuation_Valid
AND GVL_ACTUATION_AUTHORITY.Relay_Weld_Suspected THEN
    L_Actuation_Valid := FALSE;
    L_Error_Code := 26003;
    L_Error_Text := 'Relay weld suspected';
END_IF;

IF L_Actuation_Valid
AND GVL_ACTUATION_AUTHORITY.Actuator_Stall_Detected THEN
    L_Actuation_Valid := FALSE;
    L_Error_Code := 26004;
    L_Error_Text := 'Actuator stall detected';
END_IF;

IF L_Actuation_Valid
AND GVL_ACTUATION_AUTHORITY.Partial_Actuation_Detected THEN
    L_Actuation_Valid := FALSE;
    L_Error_Code := 26005;
    L_Error_Text := 'Partial actuation detected';
END_IF;

// Physical execution validation.
IF L_Actuation_Valid
AND NOT GVL_ACTUATION_AUTHORITY.Current_Signature_Confirmed THEN
    L_Actuation_Valid := FALSE;
    L_Error_Code := 26010;
    L_Error_Text := 'Current signature confirmation missing';
END_IF;

IF L_Actuation_Valid
AND NOT GVL_ACTUATION_AUTHORITY.Flow_Response_Confirmed THEN
    L_Actuation_Valid := FALSE;
    L_Error_Code := 26011;
    L_Error_Text := 'Flow response confirmation missing';
END_IF;

IF L_Actuation_Valid
AND NOT GVL_ACTUATION_AUTHORITY.Pressure_Response_Confirmed THEN
    L_Actuation_Valid := FALSE;
    L_Error_Code := 26012;
    L_Error_Text := 'Pressure response confirmation missing';
END_IF;

IF L_Actuation_Valid
AND NOT GVL_ACTUATION_AUTHORITY.Motion_Response_Confirmed THEN
    L_Actuation_Valid := FALSE;
    L_Error_Code := 26013;
    L_Error_Text := 'Motion response confirmation missing';
END_IF;

IF L_Actuation_Valid THEN
    GVL_ACTUATION_AUTHORITY.Actuation_Authority_Valid := TRUE;
    GVL_ACTUATION_AUTHORITY.Actuation_Authority_Granted := TRUE;
    GVL_ACTUATION_AUTHORITY.Actuation_Quarantine_Active := FALSE;

    GVL_ACTUATION_AUTHORITY.Field_Device_ACK_Valid := TRUE;
    GVL_ACTUATION_AUTHORITY.Actuator_Transition_Observed := TRUE;
    GVL_ACTUATION_AUTHORITY.Physical_Convergence_Confirmed := TRUE;
    GVL_ACTUATION_AUTHORITY.Stable_Physical_Convergence := TRUE;

    GVL_ACTUATION_AUTHORITY.Actuation_Authority_Epoch :=
        GVL_ACTUATION_AUTHORITY.Actuation_Command_Epoch;

    GVL_ACTUATION_AUTHORITY.Actuation_Last_Update_MS := L_Now_MS;
    GVL_ACTUATION_AUTHORITY.Actuation_Lease_Expired := FALSE;

    GVL_ACTUATION_AUTHORITY.Actuation_Last_Error_Code := 0;
    GVL_ACTUATION_AUTHORITY.Actuation_Last_Error_Text := '';
ELSE
    GVL_ACTUATION_AUTHORITY.Actuation_Authority_Valid := FALSE;
    GVL_ACTUATION_AUTHORITY.Actuation_Authority_Granted := FALSE;
    GVL_ACTUATION_AUTHORITY.Actuation_Quarantine_Active := TRUE;

    GVL_ACTUATION_AUTHORITY.Actuation_Lease_Expired := TRUE;

    GVL_ACTUATION_AUTHORITY.Actuation_Last_Error_Code := L_Error_Code;
    GVL_ACTUATION_AUTHORITY.Actuation_Last_Error_Text := L_Error_Text;

    GVL_ACTUATION_AUTHORITY.Actuation_Invalidation_Count :=
        GVL_ACTUATION_AUTHORITY.Actuation_Invalidation_Count + 1;
END_IF;

END_PROGRAM