FUNCTION_BLOCK FB_Heating_Maintenance_Gating
VAR
    L_i : INT;
END_VAR

// Extracted candidate from PRG_Heating S4.
// Not connected yet.
// Donor logic remains in PRG_Heating until all extracted candidates are prepared.

IF NOT GVL_CONFIG.G_Backup_Circulation_Pump_In_Service THEN
    GVL_STATE.G_Backup_Circulation_Pump := FALSE;
END_IF;
IF NOT GVL_CONFIG.G_Electric_Heater_In_Service THEN
    GVL_STATE.G_Electric_Heater_Enable := FALSE;
END_IF;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF NOT GVL_CONFIG.G_Manifold_Pump_In_Service[L_i] THEN
        GVL_STATE.G_Manifold_Pumps[L_i] := FALSE;
    END_IF;
END_FOR;
IF NOT GVL_CONFIG.G_DHW_Heating_Pump_In_Service THEN
    GVL_STATE.G_DHW_Heating_Pump := FALSE;
END_IF;
IF NOT GVL_CONFIG.G_DHW_Circ_Pump_In_Service THEN
    GVL_STATE.G_DHW_Circ_Pump := FALSE;
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Maintenance_Gating <<<
