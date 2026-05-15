FUNCTION_BLOCK FB_Water_Valve_Runtime_Governance
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;

    L_Authority : ST_Water_Isolation_Authority_State;
    L_Valve : ST_Water_Valve_Runtime_State;

    L_Any_Degraded : BOOL;
    L_Any_Confirmation_Unknown : BOOL;
    L_Any_Unsafe_Reopen : BOOL;
END_VAR

// ==============================================================================
// Water/Flood valve governance and confirmation runtime.
//
// Observe-first governance layer.
//
// Responsibilities:
// - publish valve runtime semantics;
// - publish authority visibility;
// - publish confirmation/degraded state;
// - provide future recovery hooks.
//
// This layer intentionally does NOT directly own physical outputs.
// ==============================================================================

IF NOT VI_Enable THEN
    GVL_Water_Valve_Runtime.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

L_Any_Degraded := FALSE;
L_Any_Confirmation_Unknown := FALSE;
L_Any_Unsafe_Reopen := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO

    L_Authority :=
        GVL_Water_Isolation_Authority.G_Authority_State[L_i];

    L_Valve := (Runtime_Valid := FALSE);

    L_Valve.Runtime_Valid := TRUE;
    L_Valve.Runtime_System_Time_MS := VI_System_Time_MS;

    // Identity.
    L_Valve.Valve_Id := L_Authority.Valve_Group_Id;
    L_Valve.Valve_Group_Id := L_Authority.Valve_Group_Id;

    // Authority visibility.
    L_Valve.Close_Requested :=
        L_Authority.Selective_Authority_Allowed
        OR L_Authority.Global_Fallback_Required;

    L_Valve.Global_Fallback_Request :=
        L_Authority.Global_Fallback_Required;

    L_Valve.Selective_Authority_Allowed :=
        L_Authority.Selective_Authority_Allowed;

    // Runtime visibility.
    // Current runtime still owns actual outputs.
    L_Valve.Physical_Output_Active :=
        GVL_COMMAND_SHADOW.G_Close_Valve_35
        OR GVL_COMMAND_SHADOW.G_Close_Valve_36;

    L_Valve.Output_Command_Projected :=
        L_Valve.Close_Requested;

    // Confirmation semantics.
    // Conservative until explicit valve feedback wiring is reconstructed.
    L_Valve.Confirmation_Available := FALSE;

    IF L_Valve.Physical_Output_Active THEN
        L_Valve.Confirmed_Closed := TRUE;
        L_Valve.Confirmation_Unknown := FALSE;
    ELSE
        L_Valve.Confirmation_Unknown := TRUE;
    END_IF;

    // Diagnostics.
    // Future physical diagnostics hooks.
    L_Valve.Diagnostics_Available := FALSE;
    L_Valve.Valve_Healthy := TRUE;

    // Conservative degraded semantics.
    IF NOT L_Valve.Confirmation_Available THEN
        L_Valve.Valve_Degraded := TRUE;

        L_Valve.Status_Code := 1;
        L_Valve.Status_Text :=
            'Valve confirmation unavailable';
    END_IF;

    // Unsafe reopen prevention.
    IF L_Valve.Valve_Degraded THEN
        L_Valve.Unsafe_Reopen_Denied := TRUE;
        L_Valve.Recovery_Allowed := FALSE;

        L_Valve.Status_Code := 2;
        L_Valve.Status_Text :=
            'Recovery denied: valve state degraded';
    END_IF;

    // Lifecycle.
    L_Valve.Close_Command_Event :=
        L_Valve.Close_Requested;

    L_Valve.Open_Command_Event :=
        L_Valve.Open_Requested;

    L_Valve.Confirmation_Lost_Event :=
        NOT L_Valve.Confirmation_Available;

    L_Valve.Valve_Degraded_Event :=
        L_Valve.Valve_Degraded;

    // Publish.
    GVL_Water_Valve_Runtime.G_Valve_Runtime_State[L_i] :=
        L_Valve;

    // Aggregation.
    L_Any_Degraded :=
        L_Any_Degraded
        OR L_Valve.Valve_Degraded;

    L_Any_Confirmation_Unknown :=
        L_Any_Confirmation_Unknown
        OR L_Valve.Confirmation_Unknown;

    L_Any_Unsafe_Reopen :=
        L_Any_Unsafe_Reopen
        OR L_Valve.Unsafe_Reopen_Denied;

END_FOR;

GVL_Water_Valve_Runtime.G_Any_Valve_Degraded :=
    L_Any_Degraded;

GVL_Water_Valve_Runtime.G_Any_Confirmation_Unknown :=
    L_Any_Confirmation_Unknown;

GVL_Water_Valve_Runtime.G_Any_Unsafe_Reopen_Denied :=
    L_Any_Unsafe_Reopen;

GVL_Water_Valve_Runtime.G_Runtime_Valid := TRUE;
GVL_Water_Valve_Runtime.G_Last_Update_MS := VI_System_Time_MS;

IF L_Any_Degraded THEN
    GVL_Water_Valve_Runtime.G_Status_Code := 2;
    GVL_Water_Valve_Runtime.G_Status_Text :=
        'Valve governance degraded';
ELSIF L_Any_Confirmation_Unknown THEN
    GVL_Water_Valve_Runtime.G_Status_Code := 1;
    GVL_Water_Valve_Runtime.G_Status_Text :=
        'Valve confirmation unknown';
ELSE
    GVL_Water_Valve_Runtime.G_Status_Code := 0;
    GVL_Water_Valve_Runtime.G_Status_Text :=
        'Valve governance runtime active';
END_IF;