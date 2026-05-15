FUNCTION_BLOCK FB_Water_Orchestration_Runtime
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;

    L_Path : ST_Water_Isolation_Path_Runtime_State;
    L_Traversal : ST_Water_Graph_Traversal_State;
    L_Orchestration : ST_Water_Orchestration_Runtime_State;

    L_Any_Conflict : BOOL;
    L_Any_Escalation : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Water_Orchestration.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO

    L_Path :=
        GVL_Water_Hydraulic_Graph.G_Isolation_Path[L_i];

    // Traversal runtime.
    L_Traversal := (Runtime_Valid := TRUE);

    L_Traversal.Runtime_System_Time_MS :=
        VI_System_Time_MS;

    L_Traversal.Sensor_Id := TO_UINT(L_i);

    L_Traversal.Start_Segment_Id :=
        L_Path.Active_Isolation_Group_Id;

    L_Traversal.Target_Valve_Group_Id :=
        L_Path.Active_Valve_Group_Id;

    L_Traversal.Shared_Trunk_Traversal :=
        L_Path.Shared_Trunk_Impact;

    L_Traversal.Upstream_Dependency_Detected :=
        L_Path.Shared_Trunk_Impact;

    L_Traversal.Downstream_Impact_Detected :=
        L_Path.Cross_Zone_Impact;

    L_Traversal.Traversal_Valid :=
        L_Path.Isolation_Path_Valid;

    L_Traversal.Traversal_Conflict :=
        L_Path.Conflict_Detected;

    L_Traversal.Traversal_Ambiguous :=
        L_Path.Isolation_Path_Ambiguous;

    IF L_Path.Multi_Valve_Path THEN
        L_Traversal.Dependency_Depth := 2;
    ELSE
        L_Traversal.Dependency_Depth := 1;
    END_IF;

    L_Traversal.Selective_Path_Allowed :=
        L_Path.Selective_Isolation_Allowed;

    L_Traversal.Global_Fallback_Required :=
        L_Path.Global_Fallback_Required;

    // Orchestration runtime.
    L_Orchestration := (Runtime_Valid := TRUE);

    L_Orchestration.Runtime_System_Time_MS :=
        VI_System_Time_MS;

    L_Orchestration.Isolation_Sequence_Active :=
        L_Traversal.Traversal_Valid;

    L_Orchestration.Shared_Trunk_Sequencing :=
        L_Traversal.Shared_Trunk_Traversal;

    L_Orchestration.Staged_Close_Required :=
        L_Path.Multi_Valve_Path;

    L_Orchestration.Recovery_Sequence_Active :=
        GVL_INTENT_SAFETY.I_Water_Selective_Recovery_Allowed;

    L_Orchestration.Staged_Open_Required :=
        L_Orchestration.Recovery_Sequence_Active
        AND L_Path.Multi_Valve_Path;

    L_Orchestration.Observation_Window_Active :=
        L_Orchestration.Recovery_Sequence_Active;

    // Conservative sequencing governance.
    IF L_Traversal.Traversal_Conflict
       OR L_Traversal.Traversal_Ambiguous THEN

        L_Orchestration.Rollback_Required := TRUE;
        L_Orchestration.Escalation_Required := TRUE;
        L_Orchestration.Sequencing_Valid := FALSE;

        L_Orchestration.Status_Code := 2;
        L_Orchestration.Status_Text :=
            'Orchestration conflict escalation active';

    ELSE

        L_Orchestration.Sequencing_Valid := TRUE;

        IF L_Orchestration.Shared_Trunk_Sequencing THEN
            L_Orchestration.Status_Code := 1;
            L_Orchestration.Status_Text :=
                'Shared trunk orchestration active';
        ELSE
            L_Orchestration.Status_Code := 0;
            L_Orchestration.Status_Text :=
                'Deterministic orchestration active';
        END_IF;

    END_IF;

    GVL_Water_Orchestration.G_Traversal_State[L_i] :=
        L_Traversal;

    GVL_Water_Orchestration.G_Orchestration_State[L_i] :=
        L_Orchestration;

    L_Any_Conflict :=
        L_Any_Conflict
        OR L_Traversal.Traversal_Conflict;

    L_Any_Escalation :=
        L_Any_Escalation
        OR L_Orchestration.Escalation_Required;

END_FOR;

GVL_Water_Orchestration.G_Topology_Version := 1;
GVL_Water_Orchestration.G_Config_Runtime_Ready := TRUE;

GVL_Water_Orchestration.G_Any_Traversal_Conflict :=
    L_Any_Conflict;

GVL_Water_Orchestration.G_Any_Escalation_Required :=
    L_Any_Escalation;

GVL_Water_Orchestration.G_Runtime_Valid := TRUE;
GVL_Water_Orchestration.G_Last_Update_MS := VI_System_Time_MS;

IF L_Any_Escalation THEN
    GVL_Water_Orchestration.G_Status_Code := 2;
    GVL_Water_Orchestration.G_Status_Text :=
        'Water orchestration escalation active';
ELSIF L_Any_Conflict THEN
    GVL_Water_Orchestration.G_Status_Code := 1;
    GVL_Water_Orchestration.G_Status_Text :=
        'Water orchestration conflict detected';
ELSE
    GVL_Water_Orchestration.G_Status_Code := 0;
    GVL_Water_Orchestration.G_Status_Text :=
        'Water orchestration runtime healthy';
END_IF;

END_FUNCTION_BLOCK