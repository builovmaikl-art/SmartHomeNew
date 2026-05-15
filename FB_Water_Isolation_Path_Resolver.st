FUNCTION_BLOCK FB_Water_Isolation_Path_Resolver
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;

    L_Edge : ST_Water_Hydraulic_Topology_Edge;
    L_Path : ST_Water_Isolation_Path_Runtime_State;
    L_Validation : ST_Water_Topology_Validation_State;

    L_Any_Shared_Trunk : BOOL;
    L_Any_Conflict : BOOL;
    L_Any_Fallback : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Water_Hydraulic_Graph.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO

    L_Validation :=
        GVL_Water_Topology_Validation.G_Validation_State[L_i];

    // Graph edge publication.
    L_Edge := (Runtime_Valid := TRUE);

    L_Edge.Edge_Id := TO_UINT(L_i);

    L_Edge.Upstream_Segment_Id :=
        GVL_Water_Hydraulic_Topology.G_Topology_Node[L_i].Hydraulic_Segment_Id;

    L_Edge.Downstream_Segment_Id :=
        GVL_Water_Hydraulic_Topology.G_Topology_Node[L_i].Hydraulic_Zone_Id;

    L_Edge.Isolation_Group_Id :=
        GVL_Water_Hydraulic_Topology.G_Topology_Node[L_i].Isolation_Group_Id;

    L_Edge.Valve_Group_Id :=
        GVL_Water_Hydraulic_Topology.G_Topology_Node[L_i].Valve_Group_Id;

    // Shared trunk semantics.
    IF L_Edge.Valve_Group_Id = 3 THEN
        L_Edge.Shared_Trunk := TRUE;
        L_Edge.Cross_Zone_Dependency := TRUE;
    END_IF;

    L_Edge.Dependency_Valid :=
        L_Validation.Topology_Valid;

    L_Edge.Dependency_Ambiguous :=
        L_Validation.Topology_Ambiguous;

    L_Edge.Selective_Isolation_Allowed :=
        L_Validation.Selective_Isolation_Allowed;

    L_Edge.Global_Fallback_Required :=
        L_Validation.Global_Fallback_Required;

    // Isolation path runtime.
    L_Path := (Runtime_Valid := TRUE);

    L_Path.Runtime_System_Time_MS :=
        VI_System_Time_MS;

    L_Path.Sensor_Id := TO_UINT(L_i);

    L_Path.Isolation_Path_Valid :=
        L_Edge.Dependency_Valid;

    L_Path.Isolation_Path_Ambiguous :=
        L_Edge.Dependency_Ambiguous;

    L_Path.Active_Isolation_Group_Id :=
        L_Edge.Isolation_Group_Id;

    L_Path.Active_Valve_Group_Id :=
        L_Edge.Valve_Group_Id;

    L_Path.Shared_Trunk_Impact :=
        L_Edge.Shared_Trunk;

    L_Path.Cross_Zone_Impact :=
        L_Edge.Cross_Zone_Dependency;

    L_Path.Selective_Isolation_Allowed :=
        L_Edge.Selective_Isolation_Allowed;

    L_Path.Global_Fallback_Required :=
        L_Edge.Global_Fallback_Required;

    // Multi-valve/shared-trunk path.
    IF L_Path.Shared_Trunk_Impact THEN
        L_Path.Multi_Valve_Path := TRUE;
    END_IF;

    // Conflict detection.
    IF L_Path.Isolation_Path_Ambiguous THEN
        L_Path.Conflict_Detected := TRUE;
    END_IF;

    // Conservative escalation.
    IF L_Path.Conflict_Detected THEN
        L_Path.Global_Fallback_Required := TRUE;
        L_Path.Selective_Isolation_Allowed := FALSE;

        L_Path.Status_Code := 2;
        L_Path.Status_Text :=
            'Isolation path conflict detected';

    ELSIF L_Path.Shared_Trunk_Impact THEN
        L_Path.Status_Code := 1;
        L_Path.Status_Text :=
            'Shared trunk isolation path active';

    ELSE
        L_Path.Status_Code := 0;
        L_Path.Status_Text :=
            'Isolation path resolved';
    END_IF;

    GVL_Water_Hydraulic_Graph.G_Topology_Edge[L_i] :=
        L_Edge;

    GVL_Water_Hydraulic_Graph.G_Isolation_Path[L_i] :=
        L_Path;

    L_Any_Shared_Trunk :=
        L_Any_Shared_Trunk
        OR L_Path.Shared_Trunk_Impact;

    L_Any_Conflict :=
        L_Any_Conflict
        OR L_Path.Conflict_Detected;

    L_Any_Fallback :=
        L_Any_Fallback
        OR L_Path.Global_Fallback_Required;

END_FOR;

GVL_Water_Hydraulic_Graph.G_Any_Shared_Trunk :=
    L_Any_Shared_Trunk;

GVL_Water_Hydraulic_Graph.G_Any_Conflict :=
    L_Any_Conflict;

GVL_Water_Hydraulic_Graph.G_Any_Global_Fallback_Required :=
    L_Any_Fallback;

GVL_Water_Hydraulic_Graph.G_Runtime_Valid := TRUE;
GVL_Water_Hydraulic_Graph.G_Last_Update_MS := VI_System_Time_MS;

IF L_Any_Conflict THEN
    GVL_Water_Hydraulic_Graph.G_Status_Code := 2;
    GVL_Water_Hydraulic_Graph.G_Status_Text :=
        'Hydraulic graph conflicts detected';
ELSIF L_Any_Shared_Trunk THEN
    GVL_Water_Hydraulic_Graph.G_Status_Code := 1;
    GVL_Water_Hydraulic_Graph.G_Status_Text :=
        'Shared trunk governance active';
ELSE
    GVL_Water_Hydraulic_Graph.G_Status_Code := 0;
    GVL_Water_Hydraulic_Graph.G_Status_Text :=
        'Hydraulic graph runtime healthy';
END_IF;

END_FUNCTION_BLOCK