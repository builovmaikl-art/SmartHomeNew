FUNCTION_BLOCK FB_Water_Leak_Runtime_Projection
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;
    L_Runtime_State : ST_Water_Leak_Runtime_State;
    L_Global_Leak : BOOL;
    L_Global_Warning : BOOL;
END_VAR

// ==============================================================================
// Water/Flood canonical runtime semantic projection.
//
// Observe/publish-only layer.
//
// Reads active runtime leak state and projects:
// - logical leak semantics;
// - mapping visibility;
// - isolation semantics;
// - degraded-state visibility;
// - explainability;
// - lifecycle edges.
//
// Does NOT:
// - own valve authority;
// - modify runtime outputs;
// - override safety;
// - mutate arbitration.
// ==============================================================================

IF NOT VI_Enable THEN
    GVL_Water_Runtime_Projection.G_Projection_Valid := FALSE;
    RETURN;
END_IF;

L_Global_Leak := FALSE;
L_Global_Warning := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO

    // Reset local projection state.
    L_Runtime_State := (Projection_Valid := FALSE);

    // Projection lifecycle.
    L_Runtime_State.Projection_Valid := TRUE;
    L_Runtime_State.Projection_System_Time_MS := VI_System_Time_MS;

    // Physical source semantics.
    L_Runtime_State.Physical_Sensor_Index := TO_UINT(L_i);
    L_Runtime_State.Physical_Input_Valid := TRUE;

    // Current active runtime leak semantics.
    L_Runtime_State.Leak_Warning_Active := GVL_STATE.G_Flood_Warning[L_i];
    L_Runtime_State.Leak_Confirmed := GVL_STATE.G_Flood_Alarm[L_i];
    L_Runtime_State.Active_Safety_Leak_Latched := GVL_INTENT_SAFETY.I_Water_Main_Close_Required;
    L_Runtime_State.Active_Global_Close_Path := GVL_COMMAND_SHADOW.G_Close_Valve_35
        OR GVL_COMMAND_SHADOW.G_Close_Valve_36;

    // Runtime-configurable topology reserve visibility.
    // NOTE:
    // Existing reserve topology currently only exposes sensor -> valve mapping.
    // Richer hydraulic domain semantics will be reconstructed incrementally.
    L_Runtime_State.Mapping_Valid :=
        (GVL_CONFIG.G_Flood_Global_Config.sensor_to_valve_map[L_i] <> 0);

    L_Runtime_State.Mapping_Missing := NOT L_Runtime_State.Mapping_Valid;

    IF L_Runtime_State.Mapping_Valid THEN
        L_Runtime_State.Valve_Group_Id :=
            TO_UINT(GVL_CONFIG.G_Flood_Global_Config.sensor_to_valve_map[L_i]);

        L_Runtime_State.Selective_Isolation_Possible := TRUE;
        L_Runtime_State.Fallback_Global_Isolation_Required := FALSE;
    ELSE
        L_Runtime_State.Selective_Isolation_Possible := FALSE;
        L_Runtime_State.Fallback_Global_Isolation_Required := TRUE;
    END_IF;

    // Future hydraulic semantics placeholders.
    L_Runtime_State.Logical_Sensor_Valid := TRUE;
    L_Runtime_State.Hydraulic_Zone_Id := TO_UINT(L_i);
    L_Runtime_State.Hydraulic_Segment_Id := TO_UINT(L_i);
    L_Runtime_State.Isolation_Group_Id := L_Runtime_State.Valve_Group_Id;

    // Initial confidence semantics.
    // Conservative until richer signal-quality reconstruction exists.
    IF L_Runtime_State.Leak_Confirmed THEN
        L_Runtime_State.Leak_Confidence := 1.0;
    ELSIF L_Runtime_State.Leak_Warning_Active THEN
        L_Runtime_State.Leak_Confidence := 0.5;
    ELSE
        L_Runtime_State.Leak_Confidence := 0.0;
    END_IF;

    L_Runtime_State.Sensor_Quality_Valid := TRUE;

    // Explainability.
    IF L_Runtime_State.Leak_Confirmed THEN
        IF L_Runtime_State.Mapping_Valid THEN
            L_Runtime_State.Reason_Code := 1;
            L_Runtime_State.Reason_Text := 'Leak confirmed, selective isolation topology available';
        ELSE
            L_Runtime_State.Reason_Code := 2;
            L_Runtime_State.Reason_Text := 'Leak confirmed, topology missing, global isolation fallback required';
        END_IF;

    ELSIF L_Runtime_State.Leak_Warning_Active THEN
        L_Runtime_State.Reason_Code := 3;
        L_Runtime_State.Reason_Text := 'Leak warning active';

    ELSE
        L_Runtime_State.Reason_Code := 0;
        L_Runtime_State.Reason_Text := 'No leak activity';
    END_IF;

    // Lifecycle edges.
    L_Runtime_State.Warning_Started_Event :=
        GVL_STATE.G_Flood_Warning_Rise[L_i];

    L_Runtime_State.Leak_Confirmed_Event :=
        GVL_STATE.G_Flood_Alarm_Rise[L_i];

    L_Runtime_State.Leak_Cleared_Event :=
        GVL_STATE.G_Flood_Alarm_Fall[L_i];

    L_Runtime_State.Isolation_Requested_Event :=
        L_Runtime_State.Leak_Confirmed;

    L_Runtime_State.Mapping_Invalid_Event :=
        L_Runtime_State.Mapping_Missing;

    // Projection identity.
    L_Runtime_State.Supervisory_Observation_Only := TRUE;

    // Publish canonical runtime projection.
    GVL_Water_Runtime_Projection.G_Leak_Runtime_State[L_i] := L_Runtime_State;

    // Aggregate compatibility visibility.
    L_Global_Leak := L_Global_Leak OR L_Runtime_State.Leak_Confirmed;
    L_Global_Warning := L_Global_Warning OR L_Runtime_State.Leak_Warning_Active;

END_FOR;

GVL_Water_Runtime_Projection.G_Global_Leak_Active := L_Global_Leak;
GVL_Water_Runtime_Projection.G_Global_Warning_Active := L_Global_Warning;

GVL_Water_Runtime_Projection.G_Projection_Valid := TRUE;
GVL_Water_Runtime_Projection.G_Last_Projection_MS := VI_System_Time_MS;

GVL_Water_Runtime_Projection.G_Runtime_Projection_Status_Code := 0;
GVL_Water_Runtime_Projection.G_Runtime_Projection_Status_Text :=
    'Water runtime semantic projection active';