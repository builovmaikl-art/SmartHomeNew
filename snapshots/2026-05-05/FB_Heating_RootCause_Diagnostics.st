FUNCTION_BLOCK FB_Heating_RootCause_Diagnostics
VAR_INPUT
    VI_Zone_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
END_VAR
VAR
    fbRootCause : FB_Diagnostics_RootCause;
    fbRootDemandMap : FB_Heating_Demand_Map;
    L_Root_Demand_Map : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
END_VAR

// Extracted candidate from PRG_Heating S7.
// Not connected yet.
// Donor logic remains in PRG_Heating until all extracted candidates are prepared.

fbRootDemandMap(
    VI_Zone_Valves := VI_Zone_Valves,
    VI_Zone_Configs := GVL_CONFIG.G_HMI_FloorHeating_Configs,
    VO_Manifold_Demand_Map => L_Root_Demand_Map
);

fbRootCause(
    VI_Emergency_Stop := GVL_STATE.G_Safety_Emergency_Stop,
    VI_Gas_Safety := GVL_STATE.G_Safety_Gas_Latched,
    VI_IO_Failsafe := GVL_STATE.G_Heating_IO_Fault,
    VI_Boiler_OT_Online := GVL_STATE.G_Boiler_OT_Online,
    VI_Boiler_Error := GVL_STATE.G_Boiler_Error,
    VI_Boiler_Flame := GVL_STATE.G_Boiler_Flame,
    VI_Manifold_Pumps := GVL_STATE.G_Manifold_Pumps,
    VI_Manifold_Valves := GVL_STATE.G_Manifold_Valves,
    VI_Sensor_Error := GVL_STATE.G_Heating_Sensor_Fault,
    VI_Supply_Temps := GVL_STATE.G_Manifold_T_Supply,
    VI_Target_Supply := GVL_CONFIG.G_Heating_Config.Target_Floor_Temp,
    VI_Demand_Map := L_Root_Demand_Map
);

GVL_STATE.G_Heating_RootCause := fbRootCause.VO_RootCause;
GVL_STATE.G_Heating_RootConfidence := fbRootCause.VO_Confidence;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_RootCause_Diagnostics <<<
