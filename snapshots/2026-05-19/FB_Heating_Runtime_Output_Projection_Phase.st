// ==============================================================================
// Heating runtime output projection phase
// Final phase wrapper around physical output projection.
// Does NOT calculate heating logic and does NOT publish state/status.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Output_Projection_Phase
VAR_INPUT
    VI_Enable : BOOL;
    VI_Zone_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
    VI_Manifold_Pumps : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Manifold_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_DHW_Heating_Pump : BOOL;
    VI_DHW_Circ_Pump : BOOL;
    VI_Backup_Circulation_Pump : BOOL;
    VI_Electric_Heater_Enable : BOOL;
END_VAR
VAR_OUTPUT
    VO_Executed : BOOL;
    VO_Valid : BOOL;
END_VAR
VAR
    fbOutputProjection : FB_Heating_Output_Projection;
END_VAR

VO_Executed := FALSE;
VO_Valid := FALSE;

IF NOT VI_Enable THEN
    RETURN;
END_IF;

fbOutputProjection(
    VI_Zone_Valves := VI_Zone_Valves,
    VI_Manifold_Pumps := VI_Manifold_Pumps,
    VI_Manifold_Valves := VI_Manifold_Valves,
    VI_DHW_Heating_Pump := VI_DHW_Heating_Pump,
    VI_DHW_Circ_Pump := VI_DHW_Circ_Pump,
    VI_Backup_Circulation_Pump := VI_Backup_Circulation_Pump,
    VI_Electric_Heater_Enable := VI_Electric_Heater_Enable
);

VO_Executed := TRUE;
VO_Valid := TRUE;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Output_Projection_Phase <<<
