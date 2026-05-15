FUNCTION_BLOCK FB_Water_Topology_Config_Runtime
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;
    L_Config : ST_Water_Topology_Config_Record;

    L_Any_Invalid : BOOL;
    L_Any_Multi_Valve : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Water_Topology_Config.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO

    L_Config := (Config_Valid := TRUE);

    L_Config.Config_Version := 1;
    L_Config.Sensor_Id := TO_UINT(L_i);

    // Runtime remap-ready topology source.
    // Future source:
    //   persistent config / file / HMI / remote sync.

    L_Config.Logical_Zone_Id := TO_UINT(L_i);
    L_Config.Hydraulic_Segment_Id := TO_UINT(L_i);
    L_Config.Isolation_Group_Id := TO_UINT(L_i);
    L_Config.Primary_Valve_Group_Id := TO_UINT(L_i);
    L_Config.Fallback_Domain_Id := 1;
    L_Config.Recovery_Domain_Id := 1;

    // Shared trunk example topology.
    IF (L_i MOD 4) = 0 THEN
        L_Config.Shared_Trunk := TRUE;
        L_Config.Cross_Zone_Dependency := TRUE;
        L_Config.Multi_Valve_Required := TRUE;
        L_Config.Secondary_Valve_Group_Id := TO_UINT(L_i + 100);
    END_IF;

    IF L_Config.Primary_Valve_Group_Id = 0 THEN
        L_Config.Config_Valid := FALSE;
        L_Config.Status_Code := 1;
        L_Config.Status_Text := 'Invalid topology config';
    ELSE
        L_Config.Status_Code := 0;
        L_Config.Status_Text := 'Topology config loaded';
    END_IF;

    GVL_Water_Topology_Config.G_Config_Record[L_i] := L_Config;

    L_Any_Invalid :=
        L_Any_Invalid
        OR NOT L_Config.Config_Valid;

    L_Any_Multi_Valve :=
        L_Any_Multi_Valve
        OR L_Config.Multi_Valve_Required;

END_FOR;

GVL_Water_Topology_Config.G_Active_Config_Version := 1;
GVL_Water_Topology_Config.G_Config_Loaded := TRUE;
GVL_Water_Topology_Config.G_Runtime_Remap_Ready := TRUE;

GVL_Water_Topology_Config.G_Any_Invalid_Config :=
    L_Any_Invalid;

GVL_Water_Topology_Config.G_Any_Multi_Valve_Required :=
    L_Any_Multi_Valve;

GVL_Water_Topology_Config.G_Runtime_Valid := TRUE;
GVL_Water_Topology_Config.G_Last_Update_MS := VI_System_Time_MS;

IF L_Any_Invalid THEN
    GVL_Water_Topology_Config.G_Status_Code := 2;
    GVL_Water_Topology_Config.G_Status_Text :=
        'Topology config invalid';
ELSIF L_Any_Multi_Valve THEN
    GVL_Water_Topology_Config.G_Status_Code := 1;
    GVL_Water_Topology_Config.G_Status_Text :=
        'Multi-valve topology active';
ELSE
    GVL_Water_Topology_Config.G_Status_Code := 0;
    GVL_Water_Topology_Config.G_Status_Text :=
        'Topology config runtime healthy';
END_IF;

END_FUNCTION_BLOCK