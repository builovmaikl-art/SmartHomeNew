PROGRAM PRG_IO_Write
VAR
    L_i : INT;
    L_Heating_Forced_Off : BOOL;
END_VAR

// ============================================================
// STANDBY BEHAVIOR
// ============================================================
IF NOT GVL_STATUS.G_Is_Active_PLC THEN
    FOR L_i := 1 TO 8 DO
        GVL_IO.DO_Zone_Valves[L_i] := FALSE;
        GVL_IO.AO_Lighting_Levels[L_i] := 0;
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        GVL_IO.DO_Manifold_Pumps[L_i] := FALSE;
        GVL_IO.AO_Manifold_Valves[L_i] := 0;
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
        GVL_IO.AO_Supply_Fans[L_i] := 0;
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
        GVL_IO.AO_Exhaust_Fans[L_i] := 0;
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BLINDS DO
        GVL_IO.AO_Blinds_Positions[L_i] := 0;
    END_FOR;

    FOR L_i := 1 TO 32 DO
        GVL_IO.DO_Water_Zone_Enable[L_i] := FALSE;
    END_FOR;

    GVL_IO.DO_DHW_Heating_Pump := FALSE;
    GVL_IO.DO_DHW_Circ_Pump := FALSE;
    GVL_IO.DO_Backup_Circulation_Pump := FALSE;
    GVL_IO.DO_Electric_Heater_Enable := FALSE;

    GVL_IO.DO_Gas_Siren := FALSE;
    GVL_IO.DO_Fire_Siren := FALSE;
    GVL_IO.DO_Security_Siren := FALSE;

    GVL_IO.DO_Water_Valve_35_Close := FALSE;
    GVL_IO.DO_Water_Valve_36_Close := FALSE;
    GVL_IO.DO_Gas_Valve_Close := FALSE;

    GVL_IO.DO_Lock_1_Open := FALSE;
    GVL_IO.DO_Lock_1_Close := FALSE;
    GVL_IO.DO_Lock_2_Open := FALSE;
    GVL_IO.DO_Lock_2_Close := FALSE;
    GVL_IO.DO_Gate_Open := FALSE;
    GVL_IO.DO_Wicket_Open := FALSE;

    RETURN;
END_IF;

// ============================================================
// HEATING FINAL SAFETY CLAMP (COMMAND > STATE)
// ============================================================
L_Heating_Forced_Off := 
    GVL_COMMAND_SHADOW.G_Heating_Block OR 
    GVL_COMMAND_SHADOW.G_Heating_Emergency_Stop;

// ============================================================
// OUTPUT WRITE
// ============================================================

// Heating — zone valves
FOR L_i := 1 TO 8 DO
    IF L_Heating_Forced_Off THEN
        GVL_IO.DO_Zone_Valves[L_i] := FALSE;
    ELSE
        GVL_IO.DO_Zone_Valves[L_i] := GVL_STATE.G_Zone_Valves[L_i];
    END_IF;
END_FOR;

// Manifolds
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF L_Heating_Forced_Off THEN
        GVL_IO.DO_Manifold_Pumps[L_i] := FALSE;
        GVL_IO.AO_Manifold_Valves[L_i] := 0;
    ELSE
        GVL_IO.DO_Manifold_Pumps[L_i] := GVL_STATE.G_Manifold_Pumps[L_i];
        GVL_IO.AO_Manifold_Valves[L_i] := REAL_TO_UINT(GVL_STATE.G_Manifold_Valves[L_i] * 1000.0);
    END_IF;
END_FOR;

// Ventilation
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
    GVL_IO.AO_Supply_Fans[L_i] := REAL_TO_UINT(GVL_STATE.G_Supply_Fans[L_i] * 100.0);
END_FOR;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
    GVL_IO.AO_Exhaust_Fans[L_i] := REAL_TO_UINT(GVL_STATE.G_Exhaust_Fans[L_i] * 100.0);
END_FOR;

// DHW
IF L_Heating_Forced_Off THEN
    GVL_IO.DO_DHW_Heating_Pump := FALSE;
    GVL_IO.DO_DHW_Circ_Pump := FALSE;
    GVL_IO.DO_Backup_Circulation_Pump := FALSE;
    GVL_IO.DO_Electric_Heater_Enable := FALSE;
ELSE
    GVL_IO.DO_DHW_Heating_Pump := GVL_STATE.G_DHW_Heating_Pump;
    GVL_IO.DO_DHW_Circ_Pump := GVL_STATE.G_DHW_Circ_Pump;
    GVL_IO.DO_Backup_Circulation_Pump := GVL_STATE.G_Backup_Circulation_Pump;
    GVL_IO.DO_Electric_Heater_Enable := GVL_STATE.G_Electric_Heater_Enable;
END_IF;

// Lighting / blinds
FOR L_i := 1 TO 8 DO
    GVL_IO.AO_Lighting_Levels[L_i] := BYTE_TO_UINT(GVL_STATE.G_Lighting_Levels[L_i]) * 10;
END_FOR;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BLINDS DO
    GVL_IO.AO_Blinds_Positions[L_i] := BYTE_TO_UINT(GVL_STATE.G_Blinds_Positions[L_i]) * 10;
END_FOR;

// Alarms
GVL_IO.DO_Gas_Siren := (GVL_ALARM.G_Gas_Fire_Siren AND GVL_ALARM.G_Gas_Alarm_Active);
GVL_IO.DO_Fire_Siren := (GVL_ALARM.G_Gas_Fire_Siren AND GVL_ALARM.G_Fire_Alarm_Active);
GVL_IO.DO_Security_Siren := GVL_ALARM.G_Security_Siren;

// Shadow commands
GVL_IO.DO_Water_Valve_35_Close := GVL_COMMAND_SHADOW.G_Close_Valve_35;
GVL_IO.DO_Water_Valve_36_Close := GVL_COMMAND_SHADOW.G_Close_Valve_36;
GVL_IO.DO_Gas_Valve_Close := GVL_COMMAND_SHADOW.G_Gas_Valve_Close;

GVL_IO.DO_Lock_1_Open := GVL_COMMAND_SHADOW.G_Lock_1_Open;
GVL_IO.DO_Lock_1_Close := GVL_COMMAND_SHADOW.G_Lock_1_Close;
GVL_IO.DO_Lock_2_Open := GVL_COMMAND_SHADOW.G_Lock_2_Open;
GVL_IO.DO_Lock_2_Close := GVL_COMMAND_SHADOW.G_Lock_2_Close;

GVL_IO.DO_Gate_Open := GVL_COMMAND_SHADOW.G_Gate_Open;
GVL_IO.DO_Wicket_Open := GVL_COMMAND_SHADOW.G_Wicket_Open;

// Sockets
GVL_IO.DO_Sockets := GVL_STATE.G_Socket_States;

// Water zones
FOR L_i := 1 TO 32 DO
    GVL_IO.DO_Water_Zone_Enable[L_i] := GVL_STATE.G_Water_Zone_Enable[L_i];
END_FOR;

// >>> BULK_SYNC_ANCHOR: PRG_IO_Write <<<
