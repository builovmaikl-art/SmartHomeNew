// ==============================================================================
// Heating circuit control helper
//
// Internal refactoring helper for FB_Heating_System_Manager.
// Not connected yet.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Circuit_Control
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_Current_Hour : UINT;
END_VAR

VAR_IN_OUT
    VI_Zone_Configs : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF ST_FloorHeating_Circuit_Config;
    VI_Floor_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF REAL;
    VI_Room_Temps : ARRAY[1..16] OF REAL;
END_VAR

VAR_OUTPUT
    VO_Zone_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
END_VAR

// Placeholder logic – actual logic remains in manager until connection step
// >>> BULK_SYNC_ANCHOR: FB_Heating_Circuit_Control <<<
