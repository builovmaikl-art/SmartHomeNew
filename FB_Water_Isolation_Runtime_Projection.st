FUNCTION_BLOCK FB_Water_Isolation_Runtime_Projection
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;
    L_Leak_State : ST_Water_Leak_Runtime_State;
    L_Isolation_State : ST_Water_Isolation_Runtime_State;

    L_Any_Isolation : BOOL;
    L_Any_Selective : BOOL;
    L_Global_Fallback : BOOL;
END_VAR

// ==============================================================================
// Water/Flood isolation semantic projection.
//
// Observe/publish-only.
//
// Converts canonical leak semantics into:
// - selective isolation visibility;
// - fallback-to-global semantics;
// - isolation explainability.
//
// Does NOT:
// - own outputs;
// - directly close valves;
// - override safety runtime.
// ==============================================================================

IF NOT VI_Enable THEN
    GVL_Water_Isolation_Runtime.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

L_Any_Isolation := FALSE;
L_Any_Selective := FALSE;
L_Global_Fallback := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO

    L_Leak_State :=
        GVL_Water_Runtime_Projection.G_Leak_Runtime_State[L_i];

    L_Isolation_State := (Projection_Valid := FALSE);

    L_Isolation_State.Projection_Valid := TRUE;
    L_Isolation_State.Projection_System_Time_MS := VI_System_Time_MS;

    // Topology propagation.
    L_Isolation_State.Hydraulic_Zone_Id :=
        L_Leak_State.Hydraulic_Zone_Id;

    L_Isolation_State.Isolation_Group_Id :=
        L_Leak_State.Isolation_Group_Id;

    L_Isolation_State.Valve_Group_Id :=
        L_Leak_State.Valve_Group_Id;

    // Runtime compatibility visibility.
    L_Isolation_State.Active_Global_Close_Path :=
        L_Leak_State.Active_Global_Close_Path;

    L_Isolation_State.Active_Safety_Latch :=
        L_Leak_State.Active_Safety_Leak_Latched;

    // Mapping visibility.
    L_Isolation_State.Mapping_Valid :=
        L_Leak_State.Mapping_Valid;

    L_Isolation_State.Fallback_To_Global_Required :=
        L_Leak_State.Fallback_Global_Isolation_Required;

    // Isolation semantics.
    IF L_Leak_State.Leak_Confirmed THEN

        L_Isolation_State.Isolation_Requested := TRUE;

        IF L_Leak_State.Selective_Isolation_Possible THEN
            L_Isolation_State.Selective_Isolation_Requested := TRUE;
            L_Isolation_State.Global_Isolation_Requested := FALSE;

            L_Isolation_State.Reason_Code := 1;
            L_Isolation_State.Reason_Text :=
                'Selective isolation topology available';

        ELSE
            L_Isolation_State.Selective_Isolation_Requested := FALSE;
            L_Isolation_State.Global_Isolation_Requested := TRUE;

            L_Isolation_State.Reason_Code := 2;
            L_Isolation_State.Reason_Text :=
                'Topology incomplete, fallback to global isolation required';
        END_IF;

    ELSE
        L_Isolation_State.Isolation_Requested := FALSE;
        L_Isolation_State.Selective_Isolation_Requested := FALSE;
        L_Isolation_State.Global_Isolation_Requested := FALSE;

        L_Isolation_State.Reason_Code := 0;
        L_Isolation_State.Reason_Text :=
            'No isolation required';
    END_IF;

    // Lifecycle edges.
    L_Isolation_State.Isolation_Requested_Event :=
        L_Leak_State.Isolation_Requested_Event;

    L_Isolation_State.Fallback_To_Global_Event :=
        L_Isolation_State.Global_Isolation_Requested;

    // Governance identity.
    L_Isolation_State.Supervisory_Observation_Only := TRUE;

    // Publish canonical isolation semantics.
    GVL_Water_Isolation_Runtime.G_Isolation_Runtime_State[L_i] :=
        L_Isolation_State;

    // Aggregation.
    L_Any_Isolation :=
        L_Any_Isolation
        OR L_Isolation_State.Isolation_Requested;

    L_Any_Selective :=
        L_Any_Selective
        OR L_Isolation_State.Selective_Isolation_Requested;

    L_Global_Fallback :=
        L_Global_Fallback
        OR L_Isolation_State.Global_Isolation_Requested;

END_FOR;

GVL_Water_Isolation_Runtime.G_Any_Isolation_Requested :=
    L_Any_Isolation;

GVL_Water_Isolation_Runtime.G_Any_Selective_Isolation :=
    L_Any_Selective;

GVL_Water_Isolation_Runtime.G_Global_Fallback_Required :=
    L_Global_Fallback;

GVL_Water_Isolation_Runtime.G_Runtime_Valid := TRUE;
GVL_Water_Isolation_Runtime.G_Last_Update_MS := VI_System_Time_MS;

IF L_Global_Fallback THEN
    GVL_Water_Isolation_Runtime.G_Status_Code := 2;
    GVL_Water_Isolation_Runtime.G_Status_Text :=
        'Global isolation fallback required';
ELSIF L_Any_Selective THEN
    GVL_Water_Isolation_Runtime.G_Status_Code := 1;
    GVL_Water_Isolation_Runtime.G_Status_Text :=
        'Selective isolation topology available';
ELSE
    GVL_Water_Isolation_Runtime.G_Status_Code := 0;
    GVL_Water_Isolation_Runtime.G_Status_Text :=
        'Water isolation semantic projection active';
END_IF;