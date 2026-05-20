PROGRAM PRG_Runtime_IO_Validation
VAR
    L_i : INT;
    L_Any_Exhaust_On : BOOL;
    L_Any_Supply_On : BOOL;
    L_Any_Heating_Output_On : BOOL;
    L_Any_Water_Zone_On : BOOL;
    L_Any_Access_Output_On : BOOL;
    L_Any_Lighting_Output_On : BOOL;
    L_Any_Socket_On : BOOL;
    L_Any_Freeze_Circulation_On : BOOL;
    L_Fire_Access_Valid : BOOL;
END_VAR

GVL_RUNTIME_IO_VALIDATION.G_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;
GVL_RUNTIME_IO_VALIDATION.G_Validation_Executed := TRUE;
GVL_RUNTIME_IO_VALIDATION.G_Validation_Valid := TRUE;

L_Any_Exhaust_On := FALSE;
L_Any_Supply_On := FALSE;
L_Any_Heating_Output_On := FALSE;
L_Any_Water_Zone_On := FALSE;
L_Any_Access_Output_On := FALSE;
L_Any_Lighting_Output_On := FALSE;
L_Any_Socket_On := FALSE;
L_Any_Freeze_Circulation_On := FALSE;
L_Fire_Access_Valid := TRUE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
    IF GVL_IO.AO_Exhaust_Fans[L_i] > 0 THEN
        L_Any_Exhaust_On := TRUE;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
    IF GVL_IO.AO_Supply_Fans[L_i] > 0 THEN
        L_Any_Supply_On := TRUE;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    IF GVL_IO.DO_Zone_Valves[L_i] THEN
        L_Any_Heating_Output_On := TRUE;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF GVL_IO.DO_Manifold_Pumps[L_i] OR (GVL_IO.AO_Manifold_Valves[L_i] > 0) THEN
        L_Any_Heating_Output_On := TRUE;
        L_Any_Freeze_Circulation_On := TRUE;
    END_IF;
END_FOR;

IF GVL_IO.DO_DHW_Heating_Pump
   OR GVL_IO.DO_DHW_Circ_Pump
   OR GVL_IO.DO_Backup_Circulation_Pump
   OR GVL_IO.DO_Electric_Heater_Enable THEN
    L_Any_Heating_Output_On := TRUE;
END_IF;

IF GVL_IO.DO_Backup_Circulation_Pump THEN
    L_Any_Freeze_Circulation_On := TRUE;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_WATER_ZONES DO
    IF GVL_IO.DO_Water_Zone_Enable[L_i] THEN
        L_Any_Water_Zone_On := TRUE;
    END_IF;
END_FOR;

L_Any_Access_Output_On :=
    GVL_IO.DO_Gate_Open
    OR GVL_IO.DO_Wicket_Open
    OR GVL_IO.DO_Lock_1_Open
    OR GVL_IO.DO_Lock_1_Close
    OR GVL_IO.DO_Lock_2_Open
    OR GVL_IO.DO_Lock_2_Close;

IF GVL_COMMAND_SHADOW.G_Lock_1_Open AND NOT GVL_IO.DO_Lock_1_Open THEN
    L_Fire_Access_Valid := FALSE;
END_IF;
IF GVL_COMMAND_SHADOW.G_Lock_2_Open AND NOT GVL_IO.DO_Lock_2_Open THEN
    L_Fire_Access_Valid := FALSE;
END_IF;
IF GVL_COMMAND_SHADOW.G_Gate_Open AND NOT GVL_IO.DO_Gate_Open THEN
    L_Fire_Access_Valid := FALSE;
END_IF;
IF GVL_COMMAND_SHADOW.G_Wicket_Open AND NOT GVL_IO.DO_Wicket_Open THEN
    L_Fire_Access_Valid := FALSE;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
    IF GVL_IO.AO_Lighting_Levels[L_i] > 0 THEN
        L_Any_Lighting_Output_On := TRUE;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SOCKETS DO
    IF GVL_IO.DO_Sockets[L_i] THEN
        L_Any_Socket_On := TRUE;
    END_IF;
END_FOR;

GVL_RUNTIME_IO_VALIDATION.Fire_IO_Valid :=
    (GVL_SAFETY_SHUTDOWN.G_Safety_Mode <> FIRE)
    OR (
        L_Any_Exhaust_On
        AND NOT L_Any_Supply_On
        AND L_Fire_Access_Valid
    );

GVL_RUNTIME_IO_VALIDATION.Gas_IO_Valid :=
    (GVL_SAFETY_SHUTDOWN.G_Safety_Mode <> GAS)
    OR (
        GVL_IO.DO_Gas_Valve_Close
        AND (L_Any_Exhaust_On OR L_Any_Supply_On)
        AND NOT GVL_IO.DO_DHW_Heating_Pump
    );

GVL_RUNTIME_IO_VALIDATION.Leak_IO_Valid :=
    (GVL_SAFETY_SHUTDOWN.G_Safety_Mode <> WATER_LEAK)
    OR (
        GVL_IO.DO_Water_Valve_35_Close
        AND GVL_IO.DO_Water_Valve_36_Close
    );

GVL_RUNTIME_IO_VALIDATION.Global_Stop_IO_Valid :=
    (GVL_SAFETY_SHUTDOWN.G_Safety_Mode <> GLOBAL_STOP)
    OR (
        NOT L_Any_Heating_Output_On
        AND NOT L_Any_Exhaust_On
        AND NOT L_Any_Supply_On
        AND NOT L_Any_Water_Zone_On
        AND NOT L_Any_Access_Output_On
        AND NOT L_Any_Lighting_Output_On
        AND NOT L_Any_Socket_On
        AND GVL_IO.DO_Water_Valve_35_Close
        AND GVL_IO.DO_Water_Valve_36_Close
        AND GVL_IO.DO_Gas_Valve_Close
    );

GVL_RUNTIME_IO_VALIDATION.Inactive_PLC_IO_Valid :=
    GVL_STATUS.G_Is_Active_PLC
    OR (
        NOT L_Any_Heating_Output_On
        AND NOT L_Any_Exhaust_On
        AND NOT L_Any_Supply_On
        AND NOT L_Any_Water_Zone_On
        AND NOT L_Any_Access_Output_On
        AND NOT L_Any_Lighting_Output_On
        AND NOT L_Any_Socket_On
        AND GVL_IO.DO_Water_Valve_35_Close
        AND GVL_IO.DO_Water_Valve_36_Close
        AND GVL_IO.DO_Gas_Valve_Close
    );

GVL_RUNTIME_IO_VALIDATION.Freeze_IO_Valid :=
    (NOT GVL_STATE.G_Safety_Freeze_Risk)
    OR L_Any_Freeze_Circulation_On;

GVL_RUNTIME_IO_VALIDATION.Any_IO_Invalid :=
    NOT GVL_RUNTIME_IO_VALIDATION.Fire_IO_Valid
    OR NOT GVL_RUNTIME_IO_VALIDATION.Gas_IO_Valid
    OR NOT GVL_RUNTIME_IO_VALIDATION.Leak_IO_Valid
    OR NOT GVL_RUNTIME_IO_VALIDATION.Global_Stop_IO_Valid
    OR NOT GVL_RUNTIME_IO_VALIDATION.Inactive_PLC_IO_Valid
    OR NOT GVL_RUNTIME_IO_VALIDATION.Freeze_IO_Valid;

IF GVL_RUNTIME_IO_VALIDATION.Any_IO_Invalid THEN
    GVL_RUNTIME_IO_VALIDATION.G_Validation_Valid := FALSE;
    GVL_RUNTIME_IO_VALIDATION.Status_Code := 1;
    GVL_RUNTIME_IO_VALIDATION.Status_Text := 'Runtime physical IO validation mismatch';
ELSE
    GVL_RUNTIME_IO_VALIDATION.Status_Code := 0;
    GVL_RUNTIME_IO_VALIDATION.Status_Text := 'Runtime physical IO validation nominal';
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_Runtime_IO_Validation <<<
END_PROGRAM
