// ==============================================================================
// Heating root-cause diagnostics observer
// Public diagnostics/explainability layer.
// Does NOT own control/runtime decisions.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_RootCause_Diagnostics
VAR_INPUT
    VI_Enable : BOOL;
END_VAR
VAR
    fbRootCause : FB_Diagnostics_RootCause;
    fbDemandMap : FB_Heating_Demand_Map;
    L_Demand_Map : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_STATE.G_Heating_RootCause := E_Heating_RootCause.RC_NONE;
    GVL_STATE.G_Heating_RootConfidence := 0.0;
    GVL_STATE.G_Heating_Confidence := 0.0;
    GVL_STATE.G_Heating_Error_Score := 1.0;
    GVL_STATE.G_Heating_Confidence_Reason_Code := -1;
    GVL_STATE.G_Heating_Confidence_Reason_Text := 'Heating diagnostics disabled';
    RETURN;
END_IF;

// ======================================================
// DEMAND MAP
// ======================================================
fbDemandMap(
    VI_Zone_Valves := GVL_STATE.G_Zone_Valves,
    VI_Zone_Configs := GVL_CONFIG.G_HMI_FloorHeating_Configs,
    VO_Manifold_Demand_Map => L_Demand_Map
);

// ======================================================
// INTERNAL INFERENCE ENGINE
// ======================================================
fbRootCause(
    VI_Emergency_Stop := GVL_STATE.G_Safety_Emergency_Stop,
    VI_Gas_Safety := GVL_STATE.G_Safety_Gas_Latched,
    VI_IO_Failsafe := GVL_STATE.G_Heating_IO_Fault,

    VI_Cascade_Available := GVL_STATE.G_Heating_Cascade_Available,
    VI_Cascade_Degraded := GVL_STATE.G_Heating_Cascade_Degraded,
    VI_Cascade_Partial_Capacity := GVL_STATE.G_Heating_Cascade_Partial_Capacity,
    VI_Cascade_No_Flame := GVL_STATE.G_Heating_Cascade_No_Flame,
    VI_Cascade_Transport_Degraded := GVL_STATE.G_Heating_Cascade_Transport_Degraded,
    VI_Cascade_Ignition_Timeout := GVL_STATE.G_Heating_Cascade_Ignition_Timeout,
    VI_Cascade_Active_Boilers := GVL_STATE.G_Heating_Cascade_Active_Boilers,
    VI_Cascade_Available_Boilers := GVL_STATE.G_Heating_Cascade_Available_Boilers,

    VI_Boiler_OT_Online := GVL_STATE.G_Boiler_OT_Online,
    VI_Boiler_Error := GVL_STATE.G_Boiler_Error,
    VI_Boiler_Flame := GVL_STATE.G_Boiler_Flame,
    VI_Boiler_OT_Command_Timeout := GVL_STATE.G_Boiler_OT_Command_Timeout,
    VI_Boiler_OT_Heartbeat_Timeout := GVL_STATE.G_Boiler_OT_Heartbeat_Timeout,
    VI_Boiler_OT_Adapter_Error := GVL_STATE.G_Boiler_OT_Adapter_Error,

    VI_Manifold_Pumps := GVL_STATE.G_Manifold_Pumps,
    VI_Manifold_Valves := GVL_STATE.G_Manifold_Valves,

    VI_Sensor_Error := GVL_STATE.G_Heating_Sensor_Fault,
    VI_Supply_Temps := GVL_STATE.G_Manifold_T_Supply,
    VI_Target_Supply := GVL_STATE.G_Target_Temperature,
    VI_Demand_Map := L_Demand_Map
);

// ======================================================
// PUBLIC DIAGNOSTICS STATE
// ======================================================
GVL_STATE.G_Heating_RootCause := fbRootCause.VO_RootCause;
GVL_STATE.G_Heating_RootConfidence := fbRootCause.VO_Confidence;
GVL_STATE.G_Heating_Confidence := fbRootCause.VO_Confidence;
GVL_STATE.G_Heating_Error_Score := fbRootCause.VO_Error_Score;
GVL_STATE.G_Heating_Confidence_Reason_Code := fbRootCause.VO_Reason_Code;
GVL_STATE.G_Heating_Confidence_Reason_Text := fbRootCause.VO_Reason_Text;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_RootCause_Diagnostics <<<
