// ==============================================================================
// System diagnostics helper
//
// Internal helper for PRG_System.
// Owns diagnostic flag export into GVL_STATUS.G_Diagnostics.
// ==============================================================================
FUNCTION_BLOCK FB_System_Diagnostics

GVL_STATUS.G_Diagnostics.Sensor_Fault :=
    GVL_STATE.G_Heating_Sensor_Fault OR
    GVL_STATE.G_DHW_Sensor_Fault OR
    GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault_Active OR
    GVL_STATUS.G_Diagnostics.Manifold_Current_Fault_Active OR
    GVL_STATUS.G_Diagnostics.Manifold_Return_Temp_Fault_Active;

GVL_STATUS.G_Diagnostics.IO_Offline :=
    GVL_STATE.G_Heating_IO_Fault OR
    GVL_STATE.G_DHW_IO_Fault OR
    GVL_STATE.G_Ventilation_IO_Fault OR
    GVL_STATE.G_Lighting_IO_Fault;

GVL_STATUS.G_Diagnostics.Subsystem_Degraded :=
    GVL_STATE.G_Heating_Subsystem_Degraded OR
    GVL_STATE.G_DHW_Subsystem_Degraded OR
    GVL_STATE.G_Ventilation_Subsystem_Degraded OR
    GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault_Active OR
    GVL_STATUS.G_Diagnostics.Manifold_Current_Fault_Active OR
    GVL_STATUS.G_Diagnostics.Manifold_Return_Temp_Fault_Active;

// >>> BULK_SYNC_ANCHOR: FB_System_Diagnostics <<<
END_FUNCTION_BLOCK
