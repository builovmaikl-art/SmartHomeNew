// ==============================================================================
// Heating runtime state publication phase
// Owns publication of finalized runtime outputs into global state/status layers.
// Does NOT calculate heating logic and does NOT mutate outputs.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_State_Publication_Phase
VAR_INPUT
    VI_Enable : BOOL;
    VI_Zone_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
    VI_Manifold_Pumps : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Manifold_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_Boiler_OT_Enable : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VI_Boiler_OT_Setpoint : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL;
    VI_Backup_Circulation_Pump : BOOL;
    VI_Electric_Heater_Enable : BOOL;
    VI_Freeze_Risk_Status : BOOL;
    VI_Manifold_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF ST_Manifold_Status;
    VI_Boiler_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF ST_Boiler_Status;
    VI_DHW_Heating_Pump : BOOL;
    VI_DHW_Circ_Pump : BOOL;
    VI_DHW_Status : ST_DHW_Status;
END_VAR
VAR_OUTPUT
    VO_Executed : BOOL;
    VO_Valid : BOOL;
END_VAR
VAR
    L_i : INT;
END_VAR

VO_Executed := FALSE;
VO_Valid := FALSE;

IF NOT VI_Enable THEN
    RETURN;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    GVL_STATE.G_Zone_Valves[L_i] := VI_Zone_Valves[L_i];
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    GVL_STATE.G_Manifold_Pumps[L_i] := VI_Manifold_Pumps[L_i];
    GVL_STATE.G_Manifold_Valves[L_i] := VI_Manifold_Valves[L_i];
    GVL_STATUS.G_Manifold_Status[L_i] := VI_Manifold_Status[L_i];
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    GVL_STATE.G_Boiler_OT_Enable[L_i] := VI_Boiler_OT_Enable[L_i];
    GVL_STATE.G_Boiler_OT_Setpoint[L_i] := VI_Boiler_OT_Setpoint[L_i];
    GVL_STATUS.G_Boiler_Status[L_i] := VI_Boiler_Status[L_i];
END_FOR;

GVL_STATE.G_Backup_Circulation_Pump := VI_Backup_Circulation_Pump;
GVL_STATE.G_Electric_Heater_Enable := VI_Electric_Heater_Enable;
GVL_STATE.G_Safety_Freeze_Risk := VI_Freeze_Risk_Status;
GVL_STATE.G_DHW_Heating_Pump := VI_DHW_Heating_Pump;
GVL_STATE.G_DHW_Circ_Pump := VI_DHW_Circ_Pump;
GVL_STATUS.G_DHW_Status := VI_DHW_Status;

VO_Executed := TRUE;
VO_Valid := TRUE;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_State_Publication_Phase <<<
