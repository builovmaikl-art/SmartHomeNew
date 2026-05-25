// ==============================================================================
// System redundancy orchestrator helper
//
// Cold-spare architecture helper. The active runtime is local-only; a second PLC
// is not allowed to hot-apply replicated state or arbitrate the same physical
// outputs. This block only builds the local snapshot for diagnostics/future
// backup use and publishes local service status.
// ==============================================================================
FUNCTION_BLOCK FB_System_Redundancy_Orchestrator
VAR_IN_OUT
    VIO_Local_State : ST_System_State_Snapshot;
    VIO_Remote_State : ST_System_State_Snapshot;
END_VAR

// Build local state snapshot for diagnostics / future backup export.
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

// Local-only role projection. No remote-state apply is permitted here.
GVL_STATUS.G_Is_Active_PLC := TRUE;
GVL_STATUS.G_Other_PLC_Is_Active := FALSE;
GVL_IO.DO_Active_Status := TRUE;

// Keep the remote snapshot untouched; it is intentionally not applied to any
// status/alarm/state/command GVL in cold-spare mode.

// >>> BULK_SYNC_ANCHOR: FB_System_Redundancy_Orchestrator <<<
END_FUNCTION_BLOCK