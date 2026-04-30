FUNCTION_BLOCK FB_Heating_Freeze_Hardware

// Extracted candidate from PRG_Heating S5.
// Not connected yet.
// Donor logic remains in PRG_Heating until all extracted candidates are prepared.

GVL_STATE.G_Freeze_Hardware_Degraded := GVL_STATUS.G_Diagnostics.Backup_Pump_Fault OR GVL_STATUS.G_Diagnostics.Electric_Heater_Fault;
GVL_STATE.G_Freeze_Hardware_Failed := GVL_STATUS.G_Diagnostics.Backup_Pump_Fault AND GVL_STATUS.G_Diagnostics.Electric_Heater_Fault;

IF GVL_STATE.G_Freeze_Hardware_Failed THEN
    GVL_STATE.G_Backup_Circulation_Pump := FALSE;
    GVL_STATE.G_Electric_Heater_Enable := FALSE;
    GVL_STATE.G_Safety_Freeze_Risk := TRUE;
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Freeze_Hardware <<<
