// ==============================================================================
// Heating boiler control helper
//
// Internal refactoring helper for FB_Heating_System_Manager.
// Not connected yet.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Boiler_Control
VAR_INPUT
    VI_System_Time_MS : UDINT;
END_VAR

VAR_IN_OUT
    VI_Boiler_Modulation : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL;
END_VAR

VAR_OUTPUT
    VO_Boiler_OT_Enable : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VO_Boiler_OT_Setpoint : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL;
END_VAR

// Placeholder logic
// >>> BULK_SYNC_ANCHOR: FB_Heating_Boiler_Control <<<
