// ==============================================================================
// Heating diagnostics event projection
// Read-only diagnostics layer for service/OOS/freeze hardware events.
// Does NOT own heating control or output decisions.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Diagnostics
VAR_INPUT
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    fbDiagEventManager : FB_Diagnostics_Event_Manager;
    L_i : INT;
    L_Any_Heating_Device_OOS : BOOL;
    L_Critical_Fault : BOOL;
    L_Device_Text : STRING(200);
    L_Critical_Text : STRING(200);
    L_Event_Text : STRING(200);
    L_Add_Text : STRING(80);
END_VAR

// ======================================================
// DEFAULTS
// ======================================================
L_Any_Heating_Device_OOS := FALSE;
L_Critical_Fault := FALSE;
L_Device_Text := '';
L_Critical_Text := '';
L_Event_Text := '';
L_Add_Text := '';

// ======================================================
// SERVICE / OUT-OF-SERVICE FLAGS
// ======================================================
GVL_STATUS.G_Diagnostics.Backup_Pump_Out_Of_Service :=
    NOT GVL_CONFIG.G_Backup_Circulation_Pump_In_Service;

GVL_STATUS.G_Diagnostics.Electric_Heater_Out_Of_Service :=
    NOT GVL_CONFIG.G_Electric_Heater_In_Service;

IF GVL_STATUS.G_Diagnostics.Backup_Pump_Out_Of_Service THEN
    L_Any_Heating_Device_OOS := TRUE;
    L_Add_Text := 'backup pump out of service';
    L_Device_Text := L_Add_Text;
END_IF;

IF GVL_STATUS.G_Diagnostics.Electric_Heater_Out_Of_Service THEN
    L_Any_Heating_Device_OOS := TRUE;
    L_Add_Text := 'electric heater out of service';
    IF LEN(L_Device_Text) = 0 THEN
        L_Device_Text := L_Add_Text;
    ELSIF (LEN(L_Device_Text) + LEN(L_Add_Text) + 2) < 200 THEN
        L_Device_Text := CONCAT(L_Device_Text, CONCAT('; ', L_Add_Text));
    END_IF;
END_IF;

fbDiagEventManager(
    VI_Code := GVL_CONFIG.ERR_BACKUP_PUMP_OUT_OF_SERVICE,
    VI_Severity := 2,
    VI_Active := GVL_STATUS.G_Diagnostics.Backup_Pump_Out_Of_Service,
    VI_Timestamp := VI_System_Time_MS,
    VI_Source := 400,
    VIO_Events := GVL_STATUS.G_Diagnostics_Events,
    VIO_Count := GVL_STATUS.G_Diagnostics_Count
);

fbDiagEventManager(
    VI_Code := GVL_CONFIG.ERR_ELECTRIC_HEATER_OUT_OF_SERVICE,
    VI_Severity := 2,
    VI_Active := GVL_STATUS.G_Diagnostics.Electric_Heater_Out_Of_Service,
    VI_Timestamp := VI_System_Time_MS,
    VI_Source := 401,
    VIO_Events := GVL_STATUS.G_Diagnostics_Events,
    VIO_Count := GVL_STATUS.G_Diagnostics_Count
);

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO

    GVL_STATUS.G_Diagnostics.Manifold_Pump_Out_Of_Service[L_i] :=
        NOT GVL_CONFIG.G_Manifold_Pump_In_Service[L_i];

    IF GVL_STATUS.G_Diagnostics.Manifold_Pump_Out_Of_Service[L_i] THEN
        L_Any_Heating_Device_OOS := TRUE;
        L_Add_Text := CONCAT('manifold pump OOS #', INT_TO_STRING(L_i));

        IF LEN(L_Device_Text) = 0 THEN
            L_Device_Text := L_Add_Text;
        ELSIF (LEN(L_Device_Text) + LEN(L_Add_Text) + 2) < 200 THEN
            L_Device_Text := CONCAT(L_Device_Text, CONCAT('; ', L_Add_Text));
        END_IF;
    END_IF;

    fbDiagEventManager(
        VI_Code := GVL_CONFIG.ERR_MANIFOLD_PUMP_OUT_OF_SERVICE,
        VI_Severity := 2,
        VI_Active := GVL_STATUS.G_Diagnostics.Manifold_Pump_Out_Of_Service[L_i],
        VI_Timestamp := VI_System_Time_MS,
        VI_Source := 410 + L_i,
        VIO_Events := GVL_STATUS.G_Diagnostics_Events,
        VIO_Count := GVL_STATUS.G_Diagnostics_Count
    );

END_FOR;

GVL_STATUS.G_Diagnostics.DHW_Heating_Pump_Out_Of_Service :=
    NOT GVL_CONFIG.G_DHW_Heating_Pump_In_Service;

GVL_STATUS.G_Diagnostics.DHW_Circ_Pump_Out_Of_Service :=
    NOT GVL_CONFIG.G_DHW_Circ_Pump_In_Service;

IF GVL_STATUS.G_Diagnostics.DHW_Heating_Pump_Out_Of_Service THEN
    L_Any_Heating_Device_OOS := TRUE;
    L_Add_Text := 'DHW heating pump out of service';

    IF LEN(L_Device_Text) = 0 THEN
        L_Device_Text := L_Add_Text;
    ELSIF (LEN(L_Device_Text) + LEN(L_Add_Text) + 2) < 200 THEN
        L_Device_Text := CONCAT(L_Device_Text, CONCAT('; ', L_Add_Text));
    END_IF;
END_IF;

IF GVL_STATUS.G_Diagnostics.DHW_Circ_Pump_Out_Of_Service THEN
    L_Any_Heating_Device_OOS := TRUE;
    L_Add_Text := 'DHW circ pump out of service';

    IF LEN(L_Device_Text) = 0 THEN
        L_Device_Text := L_Add_Text;
    ELSIF (LEN(L_Device_Text) + LEN(L_Add_Text) + 2) < 200 THEN
        L_Device_Text := CONCAT(L_Device_Text, CONCAT('; ', L_Add_Text));
    END_IF;
END_IF;

fbDiagEventManager(
    VI_Code := GVL_CONFIG.ERR_DHW_HEATING_PUMP_OUT_OF_SERVICE,
    VI_Severity := 2,
    VI_Active := GVL_STATUS.G_Diagnostics.DHW_Heating_Pump_Out_Of_Service,
    VI_Timestamp := VI_System_Time_MS,
    VI_Source := 420,
    VIO_Events := GVL_STATUS.G_Diagnostics_Events,
    VIO_Count := GVL_STATUS.G_Diagnostics_Count
);

fbDiagEventManager(
    VI_Code := GVL_CONFIG.ERR_DHW_CIRC_PUMP_OUT_OF_SERVICE,
    VI_Severity := 2,
    VI_Active := GVL_STATUS.G_Diagnostics.DHW_Circ_Pump_Out_Of_Service,
    VI_Timestamp := VI_System_Time_MS,
    VI_Source := 421,
    VIO_Events := GVL_STATUS.G_Diagnostics_Events,
    VIO_Count := GVL_STATUS.G_Diagnostics_Count
);

// ======================================================
// FREEZE HARDWARE EVENT PROJECTION
// ======================================================
L_Critical_Fault := GVL_STATE.G_Freeze_Hardware_Failed;

IF L_Critical_Fault THEN
    L_Critical_Text := 'Freeze hardware critical fault';
END_IF;

fbDiagEventManager(
    VI_Code := GVL_CONFIG.ERR_FREEZE_HARDWARE_FAILED,
    VI_Severity := 4,
    VI_Active := L_Critical_Fault,
    VI_Timestamp := VI_System_Time_MS,
    VI_Source := 430,
    VIO_Events := GVL_STATUS.G_Diagnostics_Events,
    VIO_Count := GVL_STATUS.G_Diagnostics_Count
);

GVL_STATUS.G_Diagnostics.Freeze_Hardware_Event_Pending :=
    GVL_STATUS.G_Diagnostics.Freeze_Hardware_Event_Pending OR
    L_Critical_Fault OR
    L_Any_Heating_Device_OOS;

IF L_Critical_Fault AND L_Any_Heating_Device_OOS THEN
    L_Event_Text := CONCAT(L_Critical_Text, '; ');
    IF (LEN(L_Event_Text) + LEN(L_Device_Text)) < 200 THEN
        L_Event_Text := CONCAT(L_Event_Text, L_Device_Text);
    END_IF;
    GVL_STATUS.G_Diagnostics.Freeze_Hardware_Event_Text := L_Event_Text;

ELSIF L_Critical_Fault THEN
    GVL_STATUS.G_Diagnostics.Freeze_Hardware_Event_Text := L_Critical_Text;

ELSIF L_Any_Heating_Device_OOS THEN
    GVL_STATUS.G_Diagnostics.Freeze_Hardware_Event_Text := L_Device_Text;
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Diagnostics <<<
