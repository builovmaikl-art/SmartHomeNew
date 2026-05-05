PROGRAM PRG_IO_Write
VAR
    L_i : INT;
    L_Heating_Forced_Off : BOOL;
    L_Vent_Forced_Off : BOOL;
    L_Water_Forced_Off : BOOL;
    L_Access_Forced_Off : BOOL;
    L_Access_Safety_Override : BOOL;
    L_Global_Hard_Stop : BOOL;
    L_Gas_Safety_Stop : BOOL;
    L_Freeze_Active : BOOL;
    L_Gas_Fire_Siren_Enable : BOOL;
    fbTrace : FB_Trace_Write;
END_VAR

// ======================================================
// GLOBAL SAFETY GUARD (ABSOLUTE LAST BARRIER)
// ======================================================
// IMPORTANT: Gas valve close is NOT a global hard-stop condition
// it must NOT disable ventilation or access (GAS policy requires them)
L_Global_Hard_Stop :=
    GVL_COMMAND_SHADOW.G_Heating_Emergency_Stop;

L_Gas_Safety_Stop :=
    GVL_COMMAND_SHADOW.G_Heating_Gas_Safety_Stop OR
    GVL_COMMAND_SHADOW.G_Boiler_Stop;

L_Freeze_Active := GVL_STATE.G_Safety_Freeze_Risk;
L_Gas_Fire_Siren_Enable := GVL_ALARM.G_Gas_Fire_Siren OR GVL_ALARM.G_Global_Siren OR GVL_ALARM.G_Global_Critical;

IF NOT GVL_STATUS.G_Is_Active_PLC OR L_Global_Hard_Stop THEN
    // HARD FAIL-SAFE: EVERYTHING OFF / SAFE

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
        GVL_IO.DO_Zone_Valves[L_i] := FALSE;
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        GVL_IO.DO_Manifold_Pumps[L_i] := FALSE;
        GVL_IO.AO_Manifold_Valves[L_i] := 0;
    END_FOR;

    GVL_IO.DO_DHW_Heating_Pump := FALSE;
    GVL_IO.DO_DHW_Circ_Pump := FALSE;
    GVL_IO.DO_Backup_Circulation_Pump := FALSE;
    GVL_IO.DO_Electric_Heater_Enable := FALSE;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
        GVL_IO.AO_Supply_Fans[L_i] := 0;
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
        GVL_IO.AO_Exhaust_Fans[L_i] := 0;
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_WATER_ZONES DO
        GVL_IO.DO_Water_Zone_Enable[L_i] := FALSE;
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
        GVL_IO.AO_Lighting_Levels[L_i] := 0;
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BLINDS DO
        GVL_IO.AO_Blinds_Positions[L_i] := 1000;
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SOCKETS DO
        GVL_IO.DO_Sockets[L_i] := FALSE;
    END_FOR;

    GVL_IO.DO_Gate_Open := FALSE;
    GVL_IO.DO_Wicket_Open := FALSE;
    GVL_IO.DO_Lock_1_Open := FALSE;
    GVL_IO.DO_Lock_1_Close := FALSE;
    GVL_IO.DO_Lock_2_Open := FALSE;
    GVL_IO.DO_Lock_2_Close := FALSE;

    GVL_IO.DO_Gas_Siren := L_Gas_Fire_Siren_Enable AND GVL_ALARM.G_Gas_Alarm_Active;
    GVL_IO.DO_Fire_Siren := L_Gas_Fire_Siren_Enable AND GVL_ALARM.G_Fire_Alarm_Active;
    GVL_IO.DO_Security_Siren := GVL_ALARM.G_Security_Siren OR (GVL_ALARM.G_Global_Siren AND GVL_ALARM.G_Security_Alarm);
    GVL_IO.DO_Gas_Valve_Close := TRUE;

    RETURN;
END_IF;

// ======================================================
// DOMAIN FORCED STATES
// ======================================================
L_Heating_Forced_Off := GVL_COMMAND_SHADOW.G_Heating_Block;

L_Vent_Forced_Off :=
    GVL_COMMAND_SHADOW.G_Vent_Stop OR
    GVL_COMMAND_SHADOW.G_Vent_Block;

L_Water_Forced_Off :=
    GVL_COMMAND_SHADOW.G_Water_Block OR
    GVL_COMMAND_SHADOW.G_Water_Emergency_Stop;

// Recovery blocks normal/manual access, but must not block emergency evacuation access.
// GAS: unlock/enable exit from the house; FIRE: open all exits and gate according to arbitration policy.
L_Access_Safety_Override :=
    (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = FIRE) OR
    (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = GAS);

L_Access_Forced_Off := GVL_SAFETY_RECOVERY.G_Recovery_Active AND NOT L_Access_Safety_Override;

// ======================================================
// HEATING OUTPUTS
// ======================================================
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    IF (L_i > GVL_SYSTEM_SIZE_CONFIG.G_Active_Heating_Circuits) OR L_Heating_Forced_Off THEN
        GVL_IO.DO_Zone_Valves[L_i] := FALSE;
    ELSE
        GVL_IO.DO_Zone_Valves[L_i] := GVL_HEATING_OUTPUT.DO_Zone_Valves[L_i];
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF L_Heating_Forced_Off AND NOT (L_Gas_Safety_Stop AND L_Freeze_Active) THEN
        GVL_IO.DO_Manifold_Pumps[L_i] := FALSE;
        GVL_IO.AO_Manifold_Valves[L_i] := 0;
    ELSE
        GVL_IO.DO_Manifold_Pumps[L_i] := GVL_HEATING_OUTPUT.DO_Manifold_Pumps[L_i];
        GVL_IO.AO_Manifold_Valves[L_i] := GVL_HEATING_OUTPUT.AO_Manifold_Valves[L_i];
    END_IF;
END_FOR;

IF L_Heating_Forced_Off AND NOT (L_Gas_Safety_Stop AND L_Freeze_Active) THEN
    GVL_IO.DO_DHW_Heating_Pump := FALSE;
    GVL_IO.DO_DHW_Circ_Pump := FALSE;
    GVL_IO.DO_Backup_Circulation_Pump := FALSE;
    GVL_IO.DO_Electric_Heater_Enable := FALSE;
ELSE
    GVL_IO.DO_DHW_Heating_Pump := FALSE; // DHW heating is not allowed without gas
    GVL_IO.DO_DHW_Circ_Pump := GVL_HEATING_OUTPUT.DO_DHW_Circ_Pump;
    GVL_IO.DO_Backup_Circulation_Pump := GVL_HEATING_OUTPUT.DO_Backup_Circulation_Pump;
    GVL_IO.DO_Electric_Heater_Enable := GVL_HEATING_OUTPUT.DO_Electric_Heater_Enable;
END_IF;

// ======================================================
// VENTILATION OUTPUTS
// ======================================================
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

// ======================================================
// WATER OUTPUTS
// ======================================================
GVL_IO.DO_Water_Valve_35_Close := GVL_COMMAND_SHADOW.G_Close_Valve_35;
GVL_IO.DO_Water_Valve_36_Close := GVL_COMMAND_SHADOW.G_Close_Valve_36;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_WATER_ZONES DO
    IF (L_i > GVL_SYSTEM_SIZE_CONFIG.G_Active_Water_Zones) OR L_Water_Forced_Off THEN
        GVL_IO.DO_Water_Zone_Enable[L_i] := FALSE;
    ELSE
        GVL_IO.DO_Water_Zone_Enable[L_i] := GVL_WATER_OUTPUT.DO_Water_Zone_Enable[L_i];
    END_IF;
END_FOR;

// ======================================================
// LIGHTING / BLINDS / SOCKET OUTPUTS
// ======================================================
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
    GVL_IO.AO_Lighting_Levels[L_i] := BYTE_TO_UINT(GVL_STATE.G_Lighting_Levels[L_i]) * 10;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BLINDS DO
    GVL_IO.AO_Blinds_Positions[L_i] := BYTE_TO_UINT(GVL_STATE.G_Blinds_Positions[L_i]) * 10;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SOCKETS DO
    GVL_IO.DO_Sockets[L_i] := GVL_STATE.G_Socket_States[L_i];
END_FOR;

// ======================================================
// ACCESS OUTPUTS
// ======================================================
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

// ======================================================
// ALARM / SIREN / GAS VALVE OUTPUTS
// ======================================================
GVL_IO.DO_Gas_Siren := L_Gas_Fire_Siren_Enable AND GVL_ALARM.G_Gas_Alarm_Active;
GVL_IO.DO_Fire_Siren := L_Gas_Fire_Siren_Enable AND GVL_ALARM.G_Fire_Alarm_Active;
GVL_IO.DO_Security_Siren := GVL_ALARM.G_Security_Siren OR (GVL_ALARM.G_Global_Siren AND GVL_ALARM.G_Security_Alarm);
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
END_PROGRAM
