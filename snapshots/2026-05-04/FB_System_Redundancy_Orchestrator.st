// ==============================================================================
// System redundancy orchestrator helper
//
// Internal helper for PRG_System.
// Owns PLC role calculation, heartbeat output projection, and synced-state apply.
// ==============================================================================
FUNCTION_BLOCK FB_System_Redundancy_Orchestrator
VAR_IN_OUT
    VIO_Local_State : ST_System_State_Snapshot;
    VIO_Remote_State : ST_System_State_Snapshot;
END_VAR

VAR
    fbRedundancy : FB_Redundancy_Manager;
END_VAR

// Build local state snapshot for replication.
VIO_Local_State.System_Time_MS := GVL_STATUS.G_System_Time_MS;
VIO_Local_State.Current_Scenario := GVL_STATUS.G_Current_Scenario;
VIO_Local_State.Security_Armed := GVL_ALARM.G_Security_Armed;
VIO_Local_State.Active_Alarms := GVL_ALARM.G_Active_Alarm_Count;
VIO_Local_State.Zone_Valves := GVL_STATE.G_Zone_Valves;
VIO_Local_State.Manifold_Pumps := GVL_STATE.G_Manifold_Pumps;
VIO_Local_State.Lighting_States := GVL_STATE.G_Lighting_Levels;
VIO_Local_State.Blinds_Positions := GVL_STATE.G_Blinds_Positions;
VIO_Local_State.Socket_States := GVL_STATE.G_Socket_States;
VIO_Local_State.Gas_Valve_Closed := GVL_COMMAND.G_Gas_Valve_Close;
VIO_Local_State.Water_Valves_Closed := GVL_COMMAND.G_Close_Valve_36;
VIO_Local_State.Version := VIO_Local_State.Version + 1;

fbRedundancy(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Local_PLC_ID := GVL_STATUS.G_PLC_ID,
    VI_Remote_Pulse := GVL_IO.DI_Partner_Pulse,
    VI_Remote_Is_Active := GVL_IO.DI_Partner_Active,
    VI_Gateway_Ping_OK := GVL_GATEWAY.G_Gateway_Ping_OK,
    VI_Local_State := VIO_Local_State,
    VI_Remote_State := VIO_Remote_State
);

GVL_STATUS.G_Is_Active_PLC := (fbRedundancy.VO_Local_Role = E_PLC_ROLE.ROLE_ACTIVE);
GVL_IO.DO_Heartbeat_Pulse := fbRedundancy.VO_Local_Pulse;
GVL_IO.DO_Active_Status := GVL_STATUS.G_Is_Active_PLC;

IF fbRedundancy.VO_State_Updated THEN
    GVL_STATUS.G_Current_Scenario := fbRedundancy.VO_Synced_State.Current_Scenario;
    GVL_ALARM.G_Security_Armed := fbRedundancy.VO_Synced_State.Security_Armed;
    GVL_STATE.G_Zone_Valves := fbRedundancy.VO_Synced_State.Zone_Valves;
    GVL_STATE.G_Manifold_Pumps := fbRedundancy.VO_Synced_State.Manifold_Pumps;
    GVL_STATE.G_Lighting_Levels := fbRedundancy.VO_Synced_State.Lighting_States;
    GVL_STATE.G_Blinds_Positions := fbRedundancy.VO_Synced_State.Blinds_Positions;
    GVL_STATE.G_Socket_States := fbRedundancy.VO_Synced_State.Socket_States;
    GVL_COMMAND.G_Gas_Valve_Close := fbRedundancy.VO_Synced_State.Gas_Valve_Closed;
    GVL_COMMAND.G_Close_Valve_36 := fbRedundancy.VO_Synced_State.Water_Valves_Closed;
    VIO_Local_State.Version := fbRedundancy.VO_Synced_State.Version;
END_IF;

// >>> BULK_SYNC_ANCHOR: FB_System_Redundancy_Orchestrator <<<
