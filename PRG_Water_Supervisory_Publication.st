PROGRAM PRG_Water_Supervisory_Publication
VAR
    fbWaterLeakProjection : FB_Water_Leak_Runtime_Projection;

    L_i : INT;
    L_State : ST_Water_Leak_Runtime_State;

    L_Any_Leak : BOOL;
    L_Any_Warning : BOOL;
    L_Any_Degraded_Mapping : BOOL;
    L_Selective_Isolation_Available : BOOL;
    L_Global_Fallback_Required : BOOL;
END_VAR

// ==============================================================================
// Water/Flood supervisory publication orchestration.
//
// Observe/publish-only.
// Does NOT mutate valve authority, runtime arbitration or safety shutdown.
// ==============================================================================

// Canonical Water semantic projection.
fbWaterLeakProjection(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

L_Any_Leak := FALSE;
L_Any_Warning := FALSE;
L_Any_Degraded_Mapping := FALSE;
L_Selective_Isolation_Available := FALSE;
L_Global_Fallback_Required := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO

    L_State := GVL_Water_Runtime_Projection.G_Leak_Runtime_State[L_i];

    // Compatibility explainability mirrors.
    GVL_Water_Leak_Explainability.G_Leak_Visible[L_i] :=
        L_State.Leak_Confirmed;

    GVL_Water_Leak_Explainability.G_Warning_Visible[L_i] :=
        L_State.Leak_Warning_Active;

    GVL_Water_Leak_Explainability.G_Mapping_Valid[L_i] :=
        L_State.Mapping_Valid;

    GVL_Water_Leak_Explainability.G_Selectively_Isolatable[L_i] :=
        L_State.Selective_Isolation_Possible;

    GVL_Water_Leak_Explainability.G_Global_Fallback_Required[L_i] :=
        L_State.Fallback_Global_Isolation_Required;

    GVL_Water_Leak_Explainability.G_Leak_Confidence[L_i] :=
        L_State.Leak_Confidence;

    GVL_Water_Leak_Explainability.G_Valve_Group_Id[L_i] :=
        L_State.Valve_Group_Id;

    GVL_Water_Leak_Explainability.G_Hydraulic_Zone_Id[L_i] :=
        L_State.Hydraulic_Zone_Id;

    GVL_Water_Leak_Explainability.G_Reason_Code[L_i] :=
        L_State.Reason_Code;

    GVL_Water_Leak_Explainability.G_Reason_Text[L_i] :=
        L_State.Reason_Text;

    GVL_Water_Leak_Explainability.G_Warning_Started_Event[L_i] :=
        L_State.Warning_Started_Event;

    GVL_Water_Leak_Explainability.G_Leak_Confirmed_Event[L_i] :=
        L_State.Leak_Confirmed_Event;

    GVL_Water_Leak_Explainability.G_Leak_Cleared_Event[L_i] :=
        L_State.Leak_Cleared_Event;

    // Supervisory aggregation.
    L_Any_Leak := L_Any_Leak OR L_State.Leak_Confirmed;
    L_Any_Warning := L_Any_Warning OR L_State.Leak_Warning_Active;

    L_Any_Degraded_Mapping :=
        L_Any_Degraded_Mapping OR L_State.Mapping_Missing;

    L_Selective_Isolation_Available :=
        L_Selective_Isolation_Available
        OR L_State.Selective_Isolation_Possible;

    L_Global_Fallback_Required :=
        L_Global_Fallback_Required
        OR L_State.Fallback_Global_Isolation_Required;

    IF L_State.Leak_Confirmed THEN
        GVL_Water_Runtime_Supervisory_Publication.G_Affected_Hydraulic_Zone :=
            L_State.Hydraulic_Zone_Id;

        GVL_Water_Runtime_Supervisory_Publication.G_Affected_Valve_Group :=
            L_State.Valve_Group_Id;
    END_IF;

END_FOR;

GVL_Water_Leak_Explainability.G_Explainability_Valid := TRUE;
GVL_Water_Leak_Explainability.G_Explainability_Status_Code := 0;
GVL_Water_Leak_Explainability.G_Explainability_Status_Text :=
    'Water leak explainability publication active';

// Canonical supervisory publication.
GVL_Water_Runtime_Supervisory_Publication.G_Supervisory_Valid := TRUE;
GVL_Water_Runtime_Supervisory_Publication.G_Last_Update_MS :=
    GVL_STATUS.G_System_Time_MS;

GVL_Water_Runtime_Supervisory_Publication.G_Any_Leak_Active :=
    L_Any_Leak;

GVL_Water_Runtime_Supervisory_Publication.G_Any_Warning_Active :=
    L_Any_Warning;

GVL_Water_Runtime_Supervisory_Publication.G_Any_Degraded_Mapping :=
    L_Any_Degraded_Mapping;

GVL_Water_Runtime_Supervisory_Publication.G_Selective_Isolation_Available :=
    L_Selective_Isolation_Available;

GVL_Water_Runtime_Supervisory_Publication.G_Global_Fallback_Active :=
    L_Global_Fallback_Required;

GVL_Water_Runtime_Supervisory_Publication.G_Active_Global_Close_Path :=
    GVL_COMMAND_SHADOW.G_Close_Valve_35
    OR GVL_COMMAND_SHADOW.G_Close_Valve_36;

GVL_Water_Runtime_Supervisory_Publication.G_Active_Safety_Latch :=
    GVL_INTENT_SAFETY.I_Water_Main_Close_Required;

IF L_Any_Leak THEN
    GVL_Water_Runtime_Supervisory_Publication.G_Status_Code := 1;
    GVL_Water_Runtime_Supervisory_Publication.G_Status_Text :=
        'Water leak active';
ELSIF L_Any_Warning THEN
    GVL_Water_Runtime_Supervisory_Publication.G_Status_Code := 2;
    GVL_Water_Runtime_Supervisory_Publication.G_Status_Text :=
        'Water leak warning active';
ELSE
    GVL_Water_Runtime_Supervisory_Publication.G_Status_Code := 0;
    GVL_Water_Runtime_Supervisory_Publication.G_Status_Text :=
        'Water runtime supervisory publication active';
END_IF;