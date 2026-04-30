FUNCTION_BLOCK FB_Heating_Diagnostics
VAR_INPUT
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    fbDiagEventManager : FB_Diagnostics_Event_Manager;
    L_i : INT;
END_VAR

// Extracted candidate from PRG_Heating S3.
// Not connected yet.
// Donor logic remains in PRG_Heating until all extracted candidates are prepared.

GVL_STATUS.G_Diagnostics.Backup_Pump_Out_Of_Service := NOT GVL_CONFIG.G_Backup_Circulation_Pump_In_Service;
GVL_STATUS.G_Diagnostics.Electric_Heater_Out_Of_Service := NOT GVL_CONFIG.G_Electric_Heater_In_Service;

fbDiagEventManager(
    VI_Code := GVL_CONFIG.ERR_BACKUP_PUMP_OUT_OF_SERVICE,
    VI_Severity := 2,
    VI_Active := NOT GVL_CONFIG.G_Backup_Circulation_Pump_In_Service,
    VI_Timestamp := VI_System_Time_MS,
    VI_Source := 400,
    VIO_Events := GVL_STATUS.G_Diagnostics_Events,
    VIO_Count := GVL_STATUS.G_Diagnostics_Count
);

fbDiagEventManager(
    VI_Code := GVL_CONFIG.ERR_ELECTRIC_HEATER_OUT_OF_SERVICE,
    VI_Severity := 2,
    VI_Active := NOT GVL_CONFIG.G_Electric_Heater_In_Service,
    VI_Timestamp := VI_System_Time_MS,
    VI_Source := 401,
    VIO_Events := GVL_STATUS.G_Diagnostics_Events,
    VIO_Count := GVL_STATUS.G_Diagnostics_Count
);

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    GVL_STATUS.G_Diagnostics.Manifold_Pump_Out_Of_Service[L_i] := NOT GVL_CONFIG.G_Manifold_Pump_In_Service[L_i];

    fbDiagEventManager(
        VI_Code := GVL_CONFIG.ERR_MANIFOLD_PUMP_OUT_OF_SERVICE,
        VI_Severity := 2,
        VI_Active := NOT GVL_CONFIG.G_Manifold_Pump_In_Service[L_i],
        VI_Timestamp := VI_System_Time_MS,
        VI_Source := 410 + L_i,
        VIO_Events := GVL_STATUS.G_Diagnostics_Events,
        VIO_Count := GVL_STATUS.G_Diagnostics_Count
    );
END_FOR;

GVL_STATUS.G_Diagnostics.DHW_Heating_Pump_Out_Of_Service := NOT GVL_CONFIG.G_DHW_Heating_Pump_In_Service;
GVL_STATUS.G_Diagnostics.DHW_Circ_Pump_Out_Of_Service := NOT GVL_CONFIG.G_DHW_Circ_Pump_In_Service;

fbDiagEventManager(
    VI_Code := GVL_CONFIG.ERR_DHW_HEATING_PUMP_OUT_OF_SERVICE,
    VI_Severity := 2,
    VI_Active := NOT GVL_CONFIG.G_DHW_Heating_Pump_In_Service,
    VI_Timestamp := VI_System_Time_MS,
    VI_Source := 420,
    VIO_Events := GVL_STATUS.G_Diagnostics_Events,
    VIO_Count := GVL_STATUS.G_Diagnostics_Count
);

fbDiagEventManager(
    VI_Code := GVL_CONFIG.ERR_DHW_CIRC_PUMP_OUT_OF_SERVICE,
    VI_Severity := 2,
    VI_Active := NOT GVL_CONFIG.G_DHW_Circ_Pump_In_Service,
    VI_Timestamp := VI_System_Time_MS,
    VI_Source := 421,
    VIO_Events := GVL_STATUS.G_Diagnostics_Events,
    VIO_Count := GVL_STATUS.G_Diagnostics_Count
);

fbDiagEventManager(
    VI_Code := GVL_CONFIG.ERR_FREEZE_HARDWARE_FAILED,
    VI_Severity := 4,
    VI_Active := GVL_STATE.G_Freeze_Hardware_Failed,
    VI_Timestamp := VI_System_Time_MS,
    VI_Source := 430,
    VIO_Events := GVL_STATUS.G_Diagnostics_Events,
    VIO_Count := GVL_STATUS.G_Diagnostics_Count
);

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Diagnostics <<<
