PROGRAM PRG_IO_Write
VAR
    L_i : INT;
    L_Heating_Forced_Off : BOOL;
    L_Vent_Forced_Off : BOOL;
    L_Water_Forced_Off : BOOL;
    L_Access_Forced_Off : BOOL;
    fbTrace : FB_Trace_Write;
END_VAR

IF NOT GVL_STATUS.G_Is_Active_PLC THEN RETURN; END_IF;

// ========================================
// FINAL SAFETY CLAMPS
// ========================================
L_Heating_Forced_Off :=
    GVL_COMMAND_SHADOW.G_Heating_Block
    OR GVL_COMMAND_SHADOW.G_Heating_Emergency_Stop
    OR GVL_COMMAND_SHADOW.G_Boiler_Stop;

L_Vent_Forced_Off :=
    GVL_COMMAND_SHADOW.G_Vent_Stop
    OR GVL_COMMAND_SHADOW.G_Vent_Block;

L_Water_Forced_Off :=
    GVL_COMMAND_SHADOW.G_Water_Block
    OR GVL_COMMAND_SHADOW.G_Water_Emergency_Stop;

L_Access_Forced_Off :=
    GVL_SAFETY_RECOVERY.G_Recovery_Active;

// ========================================
// HEATING OUTPUTS
// ========================================
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    IF L_Heating_Forced_Off THEN
        GVL_IO.DO_Zone_Valves[L_i] := FALSE;
    ELSE
        GVL_IO.DO_Zone_Valves[L_i] := GVL_HEATING_OUTPUT.DO_Zone_Valves[L_i];
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF L_Heating_Forced_Off THEN
        GVL_IO.DO_Manifold_Pumps[L_i] := FALSE;
        GVL_IO.AO_Manifold_Valves[L_i] := 0;
    ELSE
        GVL_IO.DO_Manifold_Pumps[L_i] := GVL_HEATING_OUTPUT.DO_Manifold_Pumps[L_i];
        GVL_IO.AO_Manifold_Valves[L_i] := GVL_HEATING_OUTPUT.AO_Manifold_Valves[L_i];
    END_IF;
END_FOR;

IF L_Heating_Forced_Off THEN
    GVL_IO.DO_DHW_Heating_Pump := FALSE;
    GVL_IO.DO_DHW_Circ_Pump := FALSE;
    GVL_IO.DO_Backup_Circulation_Pump := FALSE;
    GVL_IO.DO_Electric_Heater_Enable := FALSE;
ELSE
    GVL_IO.DO_DHW_Heating_Pump := GVL_HEATING_OUTPUT.DO_DHW_Heating_Pump;
    GVL_IO.DO_DHW_Circ_Pump := GVL_HEATING_OUTPUT.DO_DHW_Circ_Pump;
    GVL_IO.DO_Backup_Circulation_Pump := GVL_HEATING_OUTPUT.DO_Backup_Circulation_Pump;
    GVL_IO.DO_Electric_Heater_Enable := GVL_HEATING_OUTPUT.DO_Electric_Heater_Enable;
END_IF;

// ========================================
// VENTILATION OUTPUTS
// ========================================
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
    IF L_Vent_Forced_Off THEN
        GVL_IO.AO_Supply_Fans[L_i] := 0;
    ELSE
        GVL_IO.AO_Supply_Fans[L_i] := GVL_VENT_OUTPUT.AO_Supply_Fans[L_i];
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
    IF L_Vent_Forced_Off THEN
        GVL_IO.AO_Exhaust_Fans[L_i] := 0;
    ELSE
        GVL_IO.AO_Exhaust_Fans[L_i] := GVL_VENT_OUTPUT.AO_Exhaust_Fans[L_i];
    END_IF;
END_FOR;

// ========================================
// WATER OUTPUTS
// ========================================
GVL_IO.DO_Water_Valve_35_Close := GVL_WATER_OUTPUT.DO_Water_Valve_35_Close OR GVL_COMMAND_SHADOW.G_Close_Valve_35;
GVL_IO.DO_Water_Valve_36_Close := GVL_WATER_OUTPUT.DO_Water_Valve_36_Close OR GVL_COMMAND_SHADOW.G_Close_Valve_36;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_WATER_ZONES DO
    IF L_Water_Forced_Off THEN
        GVL_IO.DO_Water_Zone_Enable[L_i] := FALSE;
    ELSE
        GVL_IO.DO_Water_Zone_Enable[L_i] := GVL_WATER_OUTPUT.DO_Water_Zone_Enable[L_i];
    END_IF;
END_FOR;

// ========================================
// ACCESS OUTPUTS
// ========================================
IF L_Access_Forced_Off THEN
    GVL_IO.DO_Gate_Open := FALSE;
    GVL_IO.DO_Wicket_Open := FALSE;
    GVL_IO.DO_Lock_1_Open := FALSE;
    GVL_IO.DO_Lock_1_Close := FALSE;
    GVL_IO.DO_Lock_2_Open := FALSE;
    GVL_IO.DO_Lock_2_Close := FALSE;
ELSE
    GVL_IO.DO_Gate_Open := GVL_ACCESS_OUTPUT.DO_Gate_Open;
    GVL_IO.DO_Wicket_Open := GVL_ACCESS_OUTPUT.DO_Wicket_Open;
    GVL_IO.DO_Lock_1_Open := GVL_ACCESS_OUTPUT.DO_Lock_1_Open;
    GVL_IO.DO_Lock_1_Close := GVL_ACCESS_OUTPUT.DO_Lock_1_Close;
    GVL_IO.DO_Lock_2_Open := GVL_ACCESS_OUTPUT.DO_Lock_2_Open;
    GVL_IO.DO_Lock_2_Close := GVL_ACCESS_OUTPUT.DO_Lock_2_Close;
END_IF;

// ========================================
// DIRECT SAFETY OUTPUTS
// ========================================
GVL_IO.DO_Gas_Valve_Close := GVL_COMMAND_SHADOW.G_Gas_Valve_Close;

fbTrace(
    iLayer := TRACE_IO,
    iSource := SRC_IO,
    iReason := REASON_DOMAIN_PROJECTION,
    iValueBool := TRUE,
    iValueReal := 0.0,
    iText := 'IO write projection executed'
);

// >>> BULK_SYNC_ANCHOR: PRG_IO_Write <<<
