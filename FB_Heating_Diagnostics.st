FUNCTION_BLOCK FB_Heating_Diagnostics
VAR_INPUT
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    fbDiagEventManager : FB_Diagnostics_Event_Manager;
    L_i : INT;
    L_Any_Heating_Device_Failed : BOOL;
    L_Critical_Fault : BOOL;
    L_Device_Text : STRING(200);
    L_Critical_Text : STRING(200);
END_VAR

// ======================================================
// DEVICE AVAILABILITY
// ======================================================
GVL_STATUS.G_Diagnostics.Backup_Pump_Out_Of_Service := NOT GVL_CONFIG.G_Backup_Circulation_Pump_In_Service;
GVL_STATUS.G_Diagnostics.Electric_Heater_Out_Of_Service := NOT GVL_CONFIG.G_Electric_Heater_In_Service;

L_Any_Heating_Device_Failed := FALSE;
L_Device_Text := '';
L_Critical_Text := '';

IF NOT GVL_CONFIG.G_Backup_Circulation_Pump_In_Service THEN
    L_Any_Heating_Device_Failed := TRUE;
    L_Device_Text := 'backup pump out of service';
END_IF;

IF NOT GVL_CONFIG.G_Electric_Heater_In_Service THEN
    L_Any_Heating_Device_Failed := TRUE;
    IF L_Device_Text = '' THEN
        L_Device_Text := 'electric heater out of service';
    ELSE
        L_Device_Text := CONCAT(L_Device_Text, '; electric heater out of service');
    END_IF;
END_IF;

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

// ======================================================
// MANIFOLDS
// ======================================================
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    GVL_STATUS.G_Diagnostics.Manifold_Pump_Out_Of_Service[L_i] := NOT GVL_CONFIG.G_Manifold_Pump_In_Service[L_i];

    IF NOT GVL_CONFIG.G_Manifold_Pump_In_Service[L_i] THEN
        L_Any_Heating_Device_Failed := TRUE;
        IF L_Device_Text = '' THEN
            L_Device_Text := CONCAT('manifold pump OOS #', INT_TO_STRING(L_i));
        END_IF;
    END_IF;

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

// ======================================================
// DHW
// ======================================================
GVL_STATUS.G_Diagnostics.DHW_Heating_Pump_Out_Of_Service := NOT GVL_CONFIG.G_DHW_Heating_Pump_In_Service;
GVL_STATUS.G_Diagnostics.DHW_Circ_Pump_Out_Of_Service := NOT GVL_CONFIG.G_DHW_Circ_Pump_In_Service;

IF NOT GVL_CONFIG.G_DHW_Heating_Pump_In_Service THEN
    L_Any_Heating_Device_Failed := TRUE;
    IF L_Device_Text = '' THEN
        L_Device_Text := 'DHW heating pump out of service';
    ELSE
        L_Device_Text := CONCAT(L_Device_Text, '; DHW heating pump out of service');
    END_IF;
END_IF;

IF NOT GVL_CONFIG.G_DHW_Circ_Pump_In_Service THEN
    L_Any_Heating_Device_Failed := TRUE;
    IF L_Device_Text = '' THEN
        L_Device_Text := 'DHW circ pump out of service';
    ELSE
        L_Device_Text := CONCAT(L_Device_Text, '; DHW circ pump out of service');
    END_IF;
END_IF;

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

// ======================================================
// CRITICAL FAULTS
// ======================================================
L_Critical_Fault := GVL_STATE.G_Freeze_Hardware_Failed;

IF L_Critical_Fault THEN
    L_Critical_Text := 'Freeze hardware critical fault';
END_IF;

fbDiagEventManager(
    VI_Code := GVL_CONFIG.ERR_FREEZE_HARDWARE_FAILED,
    VI_Severity := 4,
    VI_Active := GVL_STATE.G_Freeze_Hardware_Failed,
    VI_Timestamp := VI_System_Time_MS,
    VI_Source := 430,
    VIO_Events := GVL_STATUS.G_Diagnostics_Events,
    VIO_Count := GVL_STATUS.G_Diagnostics_Count
);

// ======================================================
// ROOT CAUSE EXPORT VIA STATE (SAFE AGGREGATION PATH)
// ======================================================
GVL_STATE.G_Heating_Subsystem_Degraded := GVL_STATE.G_Heating_Subsystem_Degraded OR L_Any_Heating_Device_Failed;
GVL_STATE.G_Freeze_Hardware_Degraded := GVL_STATE.G_Freeze_Hardware_Degraded OR L_Any_Heating_Device_Failed;

GVL_STATUS.G_Diagnostics.Freeze_Hardware_Event_Pending :=
    GVL_STATUS.G_Diagnostics.Freeze_Hardware_Event_Pending OR L_Critical_Fault OR L_Any_Heating_Device_Failed;

// Priority text: critical first, then degraded details. Do not overwrite critical with warning.
IF L_Critical_Fault AND L_Any_Heating_Device_Failed THEN
    GVL_STATUS.G_Diagnostics.Freeze_Hardware_Event_Text := CONCAT(L_Critical_Text, '; ');
    GVL_STATUS.G_Diagnostics.Freeze_Hardware_Event_Text := CONCAT(GVL_STATUS.G_Diagnostics.Freeze_Hardware_Event_Text, L_Device_Text);
ELSIF L_Critical_Fault THEN
    GVL_STATUS.G_Diagnostics.Freeze_Hardware_Event_Text := L_Critical_Text;
ELSIF L_Any_Heating_Device_Failed THEN
    GVL_STATUS.G_Diagnostics.Freeze_Hardware_Event_Text := L_Device_Text;
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Diagnostics <<<
