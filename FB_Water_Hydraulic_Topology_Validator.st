FUNCTION_BLOCK FB_Water_Hydraulic_Topology_Validator
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;

    L_Node : ST_Water_Hydraulic_Topology_Node;
    L_Group : ST_Water_Hydraulic_Isolation_Group;
    L_Validation : ST_Water_Topology_Validation_State;

    L_Any_Invalid : BOOL;
    L_Any_Ambiguous : BOOL;
    L_Any_Fallback : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Water_Topology_Validation.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO

    L_Node := (Runtime_Valid := TRUE);

    L_Node.Sensor_Id := TO_UINT(L_i);
    L_Node.Hydraulic_Zone_Id :=
        GVL_Water_Runtime_Projection.G_Leak_Runtime_State[L_i].Hydraulic_Zone_Id;

    L_Node.Valve_Group_Id :=
        GVL_Water_Runtime_Projection.G_Leak_Runtime_State[L_i].Valve_Group_Id;

    L_Node.Isolation_Group_Id :=
        L_Node.Valve_Group_Id;

    L_Node.Hydraulic_Segment_Id :=
        L_Node.Hydraulic_Zone_Id;

    L_Node.Fallback_Domain_Id := 1;

    // Validation.
    L_Node.Mapping_Valid :=
        L_Node.Valve_Group_Id <> 0;

    IF NOT L_Node.Mapping_Valid THEN
        L_Node.Global_Fallback_Required := TRUE;
        L_Node.Status_Code := 1;
        L_Node.Status_Text := 'Missing valve group';
    ELSE
        L_Node.Selective_Isolation_Allowed := TRUE;
        L_Node.Status_Code := 0;
        L_Node.Status_Text := 'Topology valid';
    END_IF;

    // Shared valve-group detection.
    IF L_Node.Valve_Group_Id = 3 THEN
        L_Node.Shared_Valve_Group := TRUE;
    END_IF;

    // Isolation group publication.
    L_Group := (Runtime_Valid := TRUE);

    L_Group.Isolation_Group_Id :=
        L_Node.Isolation_Group_Id;

    L_Group.Valve_Group_Id :=
        L_Node.Valve_Group_Id;

    L_Group.Fallback_Domain_Id :=
        L_Node.Fallback_Domain_Id;

    L_Group.Shared_Sensor_Count :=
        SEL(L_Node.Shared_Valve_Group, 1, 2);

    L_Group.Isolation_Valid :=
        L_Node.Mapping_Valid;

    L_Group.Isolation_Ambiguous :=
        L_Node.Mapping_Ambiguous;

    L_Group.Selective_Isolation_Allowed :=
        L_Node.Selective_Isolation_Allowed;

    L_Group.Global_Fallback_Required :=
        L_Node.Global_Fallback_Required;

    // Validation publication.
    L_Validation := (Runtime_Valid := TRUE);

    L_Validation.Runtime_System_Time_MS :=
        VI_System_Time_MS;

    L_Validation.Sensor_Id :=
        L_Node.Sensor_Id;

    L_Validation.Topology_Valid :=
        L_Node.Mapping_Valid;

    L_Validation.Topology_Ambiguous :=
        L_Node.Mapping_Ambiguous;

    L_Validation.Isolation_Path_Valid :=
        L_Group.Isolation_Valid;

    L_Validation.Shared_Valve_Group :=
        L_Node.Shared_Valve_Group;

    L_Validation.Missing_Valve_Group :=
        NOT L_Node.Mapping_Valid;

    L_Validation.Selective_Isolation_Allowed :=
        L_Node.Selective_Isolation_Allowed;

    L_Validation.Global_Fallback_Required :=
        L_Node.Global_Fallback_Required;

    IF L_Validation.Global_Fallback_Required THEN
        L_Validation.Status_Code := 1;
        L_Validation.Status_Text :=
            'Global fallback required';
    ELSE
        L_Validation.Status_Code := 0;
        L_Validation.Status_Text :=
            'Topology validation healthy';
    END_IF;

    GVL_Water_Hydraulic_Topology.G_Topology_Node[L_i] :=
        L_Node;

    GVL_Water_Hydraulic_Topology.G_Isolation_Group[L_i] :=
        L_Group;

    GVL_Water_Topology_Validation.G_Validation_State[L_i] :=
        L_Validation;

    L_Any_Invalid :=
        L_Any_Invalid
        OR NOT L_Validation.Topology_Valid;

    L_Any_Ambiguous :=
        L_Any_Ambiguous
        OR L_Validation.Topology_Ambiguous;

    L_Any_Fallback :=
        L_Any_Fallback
        OR L_Validation.Global_Fallback_Required;

END_FOR;

GVL_Water_Hydraulic_Topology.G_Any_Ambiguous :=
    L_Any_Ambiguous;

GVL_Water_Hydraulic_Topology.G_Any_Global_Fallback_Required :=
    L_Any_Fallback;

GVL_Water_Hydraulic_Topology.G_Runtime_Valid := TRUE;
GVL_Water_Hydraulic_Topology.G_Last_Update_MS := VI_System_Time_MS;

GVL_Water_Topology_Validation.G_Any_Invalid :=
    L_Any_Invalid;

GVL_Water_Topology_Validation.G_Any_Ambiguous :=
    L_Any_Ambiguous;

GVL_Water_Topology_Validation.G_Any_Global_Fallback_Required :=
    L_Any_Fallback;

GVL_Water_Topology_Validation.G_Runtime_Valid := TRUE;
GVL_Water_Topology_Validation.G_Last_Update_MS := VI_System_Time_MS;

END_FUNCTION_BLOCK