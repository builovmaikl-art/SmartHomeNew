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
    L_Default_Group : UINT;
END_VAR

IF NOT VI_Enable THEN
    GVL_Water_Topology_Config.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

L_Any_Invalid := FALSE;
L_Any_Multi_Valve := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO

    L_Config := GVL_Water_Topology_Config_Source.G_Source_Record[L_i];
    L_Default_Group := 0;

    // Default topology from current TZ:
    // sensors 1..2  -> riser 1 local valves 1/2;
    // sensors 3..4  -> riser 2 local valves 3/4;
    // sensors 5..9  -> riser 3 local valves 5/6;
    // sensors 10..12 -> common inlet valves 35/36.
    IF (L_i >= 1) AND (L_i <= 2) THEN
        L_Default_Group := 1;
    ELSIF (L_i >= 3) AND (L_i <= 4) THEN
        L_Default_Group := 2;
    ELSIF (L_i >= 5) AND (L_i <= 9) THEN
        L_Default_Group := 3;
    ELSIF (L_i >= 10) AND (L_i <= 12) THEN
        L_Default_Group := 4;
    END_IF;

    IF NOT L_Config.Config_Valid THEN
        L_Config.Config_Valid := L_Default_Group <> 0;
        L_Config.Config_Version := 1;
        L_Config.Sensor_Id := TO_UINT(L_i);
        L_Config.Logical_Zone_Id := TO_UINT(L_i);
        L_Config.Hydraulic_Segment_Id := L_Default_Group;
        L_Config.Isolation_Group_Id := L_Default_Group;
        L_Config.Primary_Valve_Group_Id := L_Default_Group;
        L_Config.Secondary_Valve_Group_Id := 0;
        L_Config.Fallback_Domain_Id := 4;
        L_Config.Recovery_Domain_Id := L_Default_Group;
        L_Config.Shared_Trunk := L_Default_Group = 4;
        L_Config.Cross_Zone_Dependency := L_Default_Group = 4;
        L_Config.Multi_Valve_Required := L_Default_Group <> 0;
        L_Config.Recovery_Requires_Manual_Ack := TRUE;
    END_IF;

    IF (NOT L_Config.Config_Valid)
       OR (L_Config.Primary_Valve_Group_Id < 1)
       OR (L_Config.Primary_Valve_Group_Id > 4) THEN
        L_Config.Config_Valid := FALSE;
        L_Config.Status_Code := 1;
        L_Config.Status_Text := 'Invalid water topology config';
    ELSE
        L_Config.Status_Code := 0;
        CASE L_Config.Primary_Valve_Group_Id OF
            1:
                L_Config.Status_Text := 'Topology loaded: riser 1 valves 1/2';
            2:
                L_Config.Status_Text := 'Topology loaded: riser 2 valves 3/4';
            3:
                L_Config.Status_Text := 'Topology loaded: riser 3 valves 5/6';
            4:
                L_Config.Status_Text := 'Topology loaded: common inlet 35/36';
        ELSE
                L_Config.Status_Text := 'Topology loaded';
        END_CASE;
    END_IF;

    GVL_Water_Topology_Config.G_Config_Record[L_i] := L_Config;

    L_Any_Invalid := L_Any_Invalid OR NOT L_Config.Config_Valid;
    L_Any_Multi_Valve := L_Any_Multi_Valve OR L_Config.Multi_Valve_Required;

END_FOR;

GVL_Water_Topology_Config.G_Active_Config_Version := GVL_Water_Topology_Config_Source.G_Source_Version;
GVL_Water_Topology_Config.G_Config_Loaded := TRUE;
GVL_Water_Topology_Config.G_Runtime_Remap_Ready := TRUE;
GVL_Water_Topology_Config.G_Any_Invalid_Config := L_Any_Invalid;
GVL_Water_Topology_Config.G_Any_Multi_Valve_Required := L_Any_Multi_Valve;
GVL_Water_Topology_Config.G_Runtime_Valid := NOT L_Any_Invalid;
GVL_Water_Topology_Config.G_Last_Update_MS := VI_System_Time_MS;

IF L_Any_Invalid THEN
    GVL_Water_Topology_Config.G_Status_Code := 2;
    GVL_Water_Topology_Config.G_Status_Text := 'Topology config invalid';
ELSIF L_Any_Multi_Valve THEN
    GVL_Water_Topology_Config.G_Status_Code := 1;
    GVL_Water_Topology_Config.G_Status_Text := 'Multi-valve topology active';
ELSE
    GVL_Water_Topology_Config.G_Status_Code := 0;
    GVL_Water_Topology_Config.G_Status_Text := 'Topology config runtime healthy';
END_IF;

END_FUNCTION_BLOCK