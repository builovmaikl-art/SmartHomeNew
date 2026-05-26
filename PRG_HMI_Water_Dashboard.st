PROGRAM PRG_HMI_Water_Dashboard
VAR
    L_i : INT;
    L_Movement_Timeout_MS : UDINT;
END_VAR

L_Movement_Timeout_MS := GVL_CONSTANTS.C_MS_IN_SECOND * 10;

GVL_HMI_WATER_TOPOLOGY.G_Active_Config_Version := GVL_Water_Topology_Config.G_Active_Config_Version;
GVL_HMI_WATER_TOPOLOGY.G_Config_Loaded := GVL_Water_Topology_Config.G_Config_Loaded;
GVL_HMI_WATER_TOPOLOGY.G_Runtime_Valid := GVL_Water_Topology_Config.G_Runtime_Valid;
GVL_HMI_WATER_TOPOLOGY.G_Runtime_Remap_Ready := GVL_Water_Topology_Config.G_Runtime_Remap_Ready;
GVL_HMI_WATER_TOPOLOGY.G_Any_Invalid_Config := GVL_Water_Topology_Config.G_Any_Invalid_Config;
GVL_HMI_WATER_TOPOLOGY.G_Any_Multi_Valve_Required := GVL_Water_Topology_Config.G_Any_Multi_Valve_Required;
GVL_HMI_WATER_TOPOLOGY.G_Status_Code := GVL_Water_Topology_Config.G_Status_Code;
GVL_HMI_WATER_TOPOLOGY.G_Status_Text := GVL_Water_Topology_Config.G_Status_Text;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO
    GVL_HMI_WATER_TOPOLOGY.G_Sensor_Config_Valid[L_i] := GVL_Water_Topology_Config.G_Config_Record[L_i].Config_Valid;
    GVL_HMI_WATER_TOPOLOGY.G_Sensor_Id[L_i] := GVL_Water_Topology_Config.G_Config_Record[L_i].Sensor_Id;
    GVL_HMI_WATER_TOPOLOGY.G_Logical_Zone_Id[L_i] := GVL_Water_Topology_Config.G_Config_Record[L_i].Logical_Zone_Id;
    GVL_HMI_WATER_TOPOLOGY.G_Hydraulic_Segment_Id[L_i] := GVL_Water_Topology_Config.G_Config_Record[L_i].Hydraulic_Segment_Id;
    GVL_HMI_WATER_TOPOLOGY.G_Isolation_Group_Id[L_i] := GVL_Water_Topology_Config.G_Config_Record[L_i].Isolation_Group_Id;
    GVL_HMI_WATER_TOPOLOGY.G_Primary_Valve_Group_Id[L_i] := GVL_Water_Topology_Config.G_Config_Record[L_i].Primary_Valve_Group_Id;
    GVL_HMI_WATER_TOPOLOGY.G_Secondary_Valve_Group_Id[L_i] := GVL_Water_Topology_Config.G_Config_Record[L_i].Secondary_Valve_Group_Id;
    GVL_HMI_WATER_TOPOLOGY.G_Fallback_Domain_Id[L_i] := GVL_Water_Topology_Config.G_Config_Record[L_i].Fallback_Domain_Id;
    GVL_HMI_WATER_TOPOLOGY.G_Recovery_Domain_Id[L_i] := GVL_Water_Topology_Config.G_Config_Record[L_i].Recovery_Domain_Id;
    GVL_HMI_WATER_TOPOLOGY.G_Shared_Trunk[L_i] := GVL_Water_Topology_Config.G_Config_Record[L_i].Shared_Trunk;
    GVL_HMI_WATER_TOPOLOGY.G_Cross_Zone_Dependency[L_i] := GVL_Water_Topology_Config.G_Config_Record[L_i].Cross_Zone_Dependency;
    GVL_HMI_WATER_TOPOLOGY.G_Multi_Valve_Required[L_i] := GVL_Water_Topology_Config.G_Config_Record[L_i].Multi_Valve_Required;
    GVL_HMI_WATER_TOPOLOGY.G_Record_Status_Text[L_i] := GVL_Water_Topology_Config.G_Config_Record[L_i].Status_Text;

    CASE GVL_Water_Topology_Config.G_Config_Record[L_i].Primary_Valve_Group_Id OF
        1:
            GVL_HMI_WATER_TOPOLOGY.G_Topology_Text[L_i] := 'Riser 1: local valves 1/2';
        2:
            GVL_HMI_WATER_TOPOLOGY.G_Topology_Text[L_i] := 'Riser 2: local valves 3/4';
        3:
            GVL_HMI_WATER_TOPOLOGY.G_Topology_Text[L_i] := 'Riser 3: local valves 5/6';
        4:
            GVL_HMI_WATER_TOPOLOGY.G_Topology_Text[L_i] := 'Common inlet: valves 35/36';
    ELSE
            GVL_HMI_WATER_TOPOLOGY.G_Topology_Text[L_i] := 'Invalid or fallback topology';
    END_CASE;
END_FOR;

FOR L_i := 1 TO 4 DO
    GVL_HMI.G_HMI_Water_Emergency_Open_Active[L_i] := GVL_WATER_EMERGENCY_OPEN.G_Open_Active[L_i];
    GVL_HMI.G_HMI_Water_Emergency_Open_Remaining_MS[L_i] := GVL_WATER_EMERGENCY_OPEN.G_Open_Remaining_MS[L_i];
    GVL_HMI.G_HMI_Water_Emergency_Open_Count_Today[L_i] := GVL_WATER_EMERGENCY_OPEN.G_Open_Count_Today[L_i];
END_FOR;

GVL_HMI.G_HMI_Water_Emergency_Open_Any_Active := GVL_WATER_EMERGENCY_OPEN.G_Any_Open_Active;
GVL_HMI.G_HMI_Water_Emergency_Open_Last_Accepted := GVL_WATER_EMERGENCY_OPEN.G_Last_Request_Accepted;
GVL_HMI.G_HMI_Water_Emergency_Open_Last_Denied := GVL_WATER_EMERGENCY_OPEN.G_Last_Request_Denied;
GVL_HMI.G_HMI_Water_Emergency_Open_Last_Denial_Code := GVL_WATER_EMERGENCY_OPEN.G_Last_Denial_Code;
GVL_HMI.G_HMI_Water_Emergency_Open_Last_Event_Group := GVL_WATER_EMERGENCY_OPEN.G_Last_Event_Group;
GVL_HMI.G_HMI_Water_Emergency_Open_Last_Event_MS := GVL_WATER_EMERGENCY_OPEN.G_Last_Event_MS;
GVL_HMI.G_HMI_Water_Emergency_Open_Status_Text := GVL_WATER_EMERGENCY_OPEN.G_Status_Text;

IF GVL_WATER_EMERGENCY_OPEN.G_Last_Request_Denied THEN
    GVL_HMI.G_HMI_Water_Emergency_Open_Status_Level := 2;
ELSIF GVL_WATER_EMERGENCY_OPEN.G_Any_Open_Active THEN
    GVL_HMI.G_HMI_Water_Emergency_Open_Status_Level := 1;
ELSE
    GVL_HMI.G_HMI_Water_Emergency_Open_Status_Level := 0;
END_IF;

FOR L_i := 1 TO 6 DO
    GVL_HMI.G_HMI_Water_Valve_Command_Open[L_i] := GVL_WATER_OUTPUT.DO_Water_Local_Valve_Open[L_i];
    GVL_HMI.G_HMI_Water_Valve_Command_Close[L_i] := GVL_WATER_OUTPUT.DO_Water_Local_Valve_Close[L_i];
END_FOR;

GVL_HMI.G_HMI_Water_Valve_Command_Open[7] := GVL_WATER_OUTPUT.DO_Water_Valve_35_Open;
GVL_HMI.G_HMI_Water_Valve_Command_Close[7] := GVL_WATER_OUTPUT.DO_Water_Valve_35_Close;
GVL_HMI.G_HMI_Water_Valve_Command_Open[8] := GVL_WATER_OUTPUT.DO_Water_Valve_36_Open;
GVL_HMI.G_HMI_Water_Valve_Command_Close[8] := GVL_WATER_OUTPUT.DO_Water_Valve_36_Close;

FOR L_i := 1 TO 8 DO
    GVL_HMI.G_HMI_Water_Valve_Open_FB[L_i] := GVL_STATE.G_Water_Zone_Open_FB[L_i];
    GVL_HMI.G_HMI_Water_Valve_Close_FB[L_i] := GVL_STATE.G_Water_Zone_Close_FB[L_i];
    GVL_HMI.G_HMI_Water_Valve_Movement_Timeout_MS[L_i] := L_Movement_Timeout_MS;
    GVL_HMI.G_HMI_Water_Valve_Open_Fault[L_i] := GVL_STATUS.G_Diagnostics.Water_Zone_Open_Fault[L_i];
    GVL_HMI.G_HMI_Water_Valve_Close_Fault[L_i] := GVL_STATUS.G_Diagnostics.Water_Zone_Close_Fault[L_i];
    GVL_HMI.G_HMI_Water_Valve_Critical_Close_Fault[L_i] := GVL_STATUS.G_Diagnostics.Water_Zone_Critical_Close_Fault[L_i];
    GVL_HMI.G_HMI_Water_Valve_Open_Blocked[L_i] := GVL_STATUS.G_Diagnostics.Water_Zone_Open_Blocked[L_i];
END_FOR;

GVL_HMI.G_HMI_Water_Valve_Open_Block_Active := GVL_STATUS.G_Diagnostics.Water_Open_Block_Active;
GVL_HMI.G_HMI_Water_Valve_Open_Block_Text := GVL_STATUS.G_Diagnostics.Water_Open_Block_Text;
GVL_HMI.G_HMI_Water_Valve_Service_Last_Reset_Accepted := GVL_WATER_VALVE_SERVICE.G_Last_Reset_Accepted;
GVL_HMI.G_HMI_Water_Valve_Service_Last_Reset_Denied := GVL_WATER_VALVE_SERVICE.G_Last_Reset_Denied;
GVL_HMI.G_HMI_Water_Valve_Service_Last_Reset_Denial_Code := GVL_WATER_VALVE_SERVICE.G_Last_Reset_Denial_Code;
GVL_HMI.G_HMI_Water_Valve_Service_Last_Reset_Valve_Index := GVL_WATER_VALVE_SERVICE.G_Last_Reset_Valve_Index;
GVL_HMI.G_HMI_Water_Valve_Service_Last_Reset_MS := GVL_WATER_VALVE_SERVICE.G_Last_Reset_MS;
GVL_HMI.G_HMI_Water_Valve_Service_Status_Text := GVL_WATER_VALVE_SERVICE.G_Status_Text;

GVL_HMI.G_HMI_Water_Valve_Close_Fault_Active := GVL_STATUS.G_Diagnostics.Water_Close_Fault_Active;
GVL_HMI.G_HMI_Water_Valve_Main_Shutdown_Recommended := GVL_STATUS.G_Diagnostics.Water_Main_Shutdown_Recommended;
GVL_HMI.G_HMI_Water_Valve_Localization_Failed := GVL_STATUS.G_Diagnostics.Water_Localization_Failed;
GVL_HMI.G_HMI_Water_Valve_Close_Fault_Text := GVL_STATUS.G_Diagnostics.Water_Close_Fault_Text;
GVL_HMI.G_HMI_Water_Valve_Escalation_Text := GVL_STATUS.G_Diagnostics.Water_Escalation_Text;

IF GVL_STATUS.G_Diagnostics.Water_Close_Fault_Active THEN
    GVL_HMI.G_HMI_Water_Valve_Status_Level := 2;
ELSIF GVL_STATUS.G_Diagnostics.Water_Open_Block_Active OR
      GVL_STATUS.G_Diagnostics.Water_Main_Shutdown_Recommended OR
      GVL_STATUS.G_Diagnostics.Water_Localization_Failed THEN
    GVL_HMI.G_HMI_Water_Valve_Status_Level := 1;
ELSE
    GVL_HMI.G_HMI_Water_Valve_Status_Level := 0;
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_HMI_Water_Dashboard <<<
END_PROGRAM
