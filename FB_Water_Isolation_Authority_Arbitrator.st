FUNCTION_BLOCK FB_Water_Isolation_Authority_Arbitrator
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;

    L_Runtime : ST_Water_Isolation_Runtime_State;
    L_Authority : ST_Water_Isolation_Authority_State;

    L_Any_Selective : BOOL;
    L_Any_Global : BOOL;
    L_Any_Denied : BOOL;
END_VAR

// ==============================================================================
// Deterministic Water/Flood authority arbitration.
//
// IMPORTANT:
// - does NOT directly write outputs;
// - does NOT bypass runtime safety shutdown;
// - preserves conservative global fallback.
//
// This layer decides whether localized authority is deterministic and allowed.
// ==============================================================================

IF NOT VI_Enable THEN
    GVL_Water_Isolation_Authority.G_Authority_Valid := FALSE;
    RETURN;
END_IF;

L_Any_Selective := FALSE;
L_Any_Global := FALSE;
L_Any_Denied := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO

    L_Runtime :=
        GVL_Water_Isolation_Runtime.G_Isolation_Runtime_State[L_i];

    L_Authority := (Decision_Valid := FALSE);

    L_Authority.Decision_Valid := TRUE;
    L_Authority.Decision_System_Time_MS := VI_System_Time_MS;

    // Runtime compatibility visibility.
    L_Authority.Active_Global_Close_Path :=
        L_Runtime.Active_Global_Close_Path;

    L_Authority.Active_Safety_Latch :=
        L_Runtime.Active_Safety_Latch;

    // Requested semantics.
    L_Authority.Isolation_Requested :=
        L_Runtime.Isolation_Requested;

    L_Authority.Selective_Candidate :=
        L_Runtime.Selective_Isolation_Requested;

    L_Authority.Global_Fallback_Candidate :=
        L_Runtime.Global_Isolation_Requested;

    // Topology propagation.
    L_Authority.Hydraulic_Zone_Id :=
        L_Runtime.Hydraulic_Zone_Id;

    L_Authority.Isolation_Group_Id :=
        L_Runtime.Isolation_Group_Id;

    L_Authority.Valve_Group_Id :=
        L_Runtime.Valve_Group_Id;

    // Validation.
    L_Authority.Mapping_Valid :=
        L_Runtime.Mapping_Valid;

    L_Authority.Deterministic_Target_Valid :=
        (L_Runtime.Valve_Group_Id <> 0);

    // Current safety model.
    // Conservative until richer safety governance is reconstructed.
    L_Authority.Safety_Context_Allows_Selective :=
        NOT GVL_INTENT_SAFETY.I_Water_Main_Close_Required;

    // Future hooks.
    L_Authority.Valve_Diagnostics_Available := FALSE;
    L_Authority.Valve_Confirmation_Required := TRUE;

    // Deterministic authority arbitration.
    IF NOT L_Authority.Isolation_Requested THEN

        L_Authority.Decision_Code := 0;
        L_Authority.Decision_Text :=
            'No isolation authority required';

    ELSIF NOT L_Authority.Mapping_Valid THEN

        L_Authority.Global_Fallback_Required := TRUE;
        L_Authority.Authority_Denied := TRUE;

        L_Authority.Decision_Code := 1;
        L_Authority.Decision_Text :=
            'Selective authority denied: mapping invalid';

    ELSIF NOT L_Authority.Deterministic_Target_Valid THEN

        L_Authority.Global_Fallback_Required := TRUE;
        L_Authority.Authority_Denied := TRUE;

        L_Authority.Decision_Code := 2;
        L_Authority.Decision_Text :=
            'Selective authority denied: target not deterministic';

    ELSIF NOT L_Authority.Safety_Context_Allows_Selective THEN

        L_Authority.Global_Fallback_Required := TRUE;
        L_Authority.Authority_Denied := TRUE;

        L_Authority.Decision_Code := 3;
        L_Authority.Decision_Text :=
            'Selective authority denied: safety context requires global fallback';

    ELSE

        L_Authority.Selective_Authority_Allowed := TRUE;

        L_Authority.Decision_Code := 10;
        L_Authority.Decision_Text :=
            'Selective isolation authority allowed';

    END_IF;

    // Lifecycle visibility.
    L_Authority.Authority_Selected_Event :=
        L_Authority.Selective_Authority_Allowed;

    L_Authority.Authority_Denied_Event :=
        L_Authority.Authority_Denied;

    L_Authority.Fallback_Selected_Event :=
        L_Authority.Global_Fallback_Required;

    // Publish.
    GVL_Water_Isolation_Authority.G_Authority_State[L_i] :=
        L_Authority;

    // Aggregation.
    L_Any_Selective :=
        L_Any_Selective
        OR L_Authority.Selective_Authority_Allowed;

    L_Any_Global :=
        L_Any_Global
        OR L_Authority.Global_Fallback_Required;

    L_Any_Denied :=
        L_Any_Denied
        OR L_Authority.Authority_Denied;

END_FOR;

GVL_Water_Isolation_Authority.G_Any_Selective_Authority_Allowed :=
    L_Any_Selective;

GVL_Water_Isolation_Authority.G_Any_Global_Fallback_Required :=
    L_Any_Global;

GVL_Water_Isolation_Authority.G_Any_Authority_Denied :=
    L_Any_Denied;

GVL_Water_Isolation_Authority.G_Authority_Valid := TRUE;
GVL_Water_Isolation_Authority.G_Last_Update_MS := VI_System_Time_MS;

IF L_Any_Global THEN
    GVL_Water_Isolation_Authority.G_Status_Code := 2;
    GVL_Water_Isolation_Authority.G_Status_Text :=
        'Conservative global fallback authority active';
ELSIF L_Any_Selective THEN
    GVL_Water_Isolation_Authority.G_Status_Code := 1;
    GVL_Water_Isolation_Authority.G_Status_Text :=
        'Deterministic selective authority available';
ELSE
    GVL_Water_Isolation_Authority.G_Status_Code := 0;
    GVL_Water_Isolation_Authority.G_Status_Text :=
        'No authority decisions active';
END_IF;