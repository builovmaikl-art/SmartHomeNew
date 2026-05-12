// ==============================================================================
// Heating runtime service gating phase
// Applies service/out-of-service and freeze hardware gating to computed outputs.
// Does NOT calculate heating demand and does NOT publish final state.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Service_Gating_Phase
VAR_INPUT
    VI_Enable : BOOL;
END_VAR
VAR_IN_OUT
    VIO_Manifold_Pumps : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VIO_Backup_Circulation_Pump : BOOL;
    VIO_Electric_Heater_Enable : BOOL;
    VIO_DHW_Heating_Pump : BOOL;
    VIO_DHW_Circ_Pump : BOOL;
    VIO_DHW_Status : ST_DHW_Status;
    VIO_Freeze_Risk_Status : BOOL;
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

GVL_STATUS.G_Diagnostics.Backup_Pump_Out_Of_Service := NOT GVL_CONFIG.G_Backup_Circulation_Pump_In_Service;
GVL_STATUS.G_Diagnostics.Electric_Heater_Out_Of_Service := NOT GVL_CONFIG.G_Electric_Heater_In_Service;

IF NOT GVL_CONFIG.G_Backup_Circulation_Pump_In_Service THEN
    VIO_Backup_Circulation_Pump := FALSE;
END_IF;

IF NOT GVL_CONFIG.G_Electric_Heater_In_Service THEN
    VIO_Electric_Heater_Enable := FALSE;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    GVL_STATUS.G_Diagnostics.Manifold_Pump_Out_Of_Service[L_i] := NOT GVL_CONFIG.G_Manifold_Pump_In_Service[L_i];
    IF NOT GVL_CONFIG.G_Manifold_Pump_In_Service[L_i] THEN
        VIO_Manifold_Pumps[L_i] := FALSE;
    END_IF;
END_FOR;

GVL_STATUS.G_Diagnostics.DHW_Heating_Pump_Out_Of_Service := NOT GVL_CONFIG.G_DHW_Heating_Pump_In_Service;
IF NOT GVL_CONFIG.G_DHW_Heating_Pump_In_Service THEN
    VIO_DHW_Heating_Pump := FALSE;
    VIO_DHW_Status.Heating_Pump_On := FALSE;
END_IF;

GVL_STATUS.G_Diagnostics.DHW_Circ_Pump_Out_Of_Service := NOT GVL_CONFIG.G_DHW_Circ_Pump_In_Service;
IF NOT GVL_CONFIG.G_DHW_Circ_Pump_In_Service THEN
    VIO_DHW_Circ_Pump := FALSE;
    VIO_DHW_Status.Circ_Pump_On := FALSE;
END_IF;

GVL_STATE.G_Freeze_Hardware_Degraded := GVL_STATUS.G_Diagnostics.Backup_Pump_Fault OR GVL_STATUS.G_Diagnostics.Electric_Heater_Fault;
GVL_STATE.G_Freeze_Hardware_Failed := GVL_STATUS.G_Diagnostics.Backup_Pump_Fault AND GVL_STATUS.G_Diagnostics.Electric_Heater_Fault;

IF GVL_STATE.G_Freeze_Hardware_Failed THEN
    VIO_Backup_Circulation_Pump := FALSE;
    VIO_Electric_Heater_Enable := FALSE;
    VIO_Freeze_Risk_Status := TRUE;
END_IF;

VO_Executed := TRUE;
VO_Valid := TRUE;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Service_Gating_Phase <<<
