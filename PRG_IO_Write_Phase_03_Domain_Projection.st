PROGRAM PRG_IO_Write_Phase_03_Domain_Projection
// IO write phase 03: publish normal domain output projections.
VAR
    L_i : INT;
END_VAR

GVL_IO.DO_Gas_Valve_Close := GVL_COMMAND_SHADOW.G_Gas_Valve_Close;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    IF (L_i > GVL_SYSTEM_SIZE_CONFIG.G_Active_Heating_Circuits)
       OR GVL_IO_WRITE_RUNTIME_BUFFER.B_Heating_Forced_Off THEN
        GVL_IO.DO_Zone_Valves[L_i] := FALSE;
    ELSE
        GVL_IO.DO_Zone_Valves[L_i] := GVL_HEATING_OUTPUT.DO_Zone_Valves[L_i];
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF GVL_IO_WRITE_RUNTIME_BUFFER.B_Heating_Forced_Off
       AND NOT (GVL_IO_WRITE_RUNTIME_BUFFER.B_Gas_Safety_Stop
                AND GVL_IO_WRITE_RUNTIME_BUFFER.B_Freeze_Active) THEN
        GVL_IO.DO_Manifold_Pumps[L_i] := FALSE;
        GVL_IO.AO_Manifold_Valves[L_i] := 0;
    ELSE
        GVL_IO.DO_Manifold_Pumps[L_i] := GVL_HEATING_OUTPUT.DO_Manifold_Pumps[L_i];
        GVL_IO.AO_Manifold_Valves[L_i] := GVL_HEATING_OUTPUT.AO_Manifold_Valves[L_i];
    END_IF;
END_FOR;

IF GVL_IO_WRITE_RUNTIME_BUFFER.B_Heating_Forced_Off
   AND NOT (GVL_IO_WRITE_RUNTIME_BUFFER.B_Gas_Safety_Stop
            AND GVL_IO_WRITE_RUNTIME_BUFFER.B_Freeze_Active) THEN
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

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
    IF GVL_IO_WRITE_RUNTIME_BUFFER.B_Vent_Forced_Off THEN
        GVL_IO.AO_Supply_Fans[L_i] := 0;
    ELSE
        GVL_IO.AO_Supply_Fans[L_i] := GVL_VENT_OUTPUT.AO_Supply_Fans[L_i];
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
    IF GVL_IO_WRITE_RUNTIME_BUFFER.B_Vent_Forced_Off THEN
        GVL_IO.AO_Exhaust_Fans[L_i] := 0;
    ELSE
        GVL_IO.AO_Exhaust_Fans[L_i] := GVL_VENT_OUTPUT.AO_Exhaust_Fans[L_i];
    END_IF;
END_FOR;

// Water outputs. PRG_Water owns the domain projection in GVL_WATER_OUTPUT;
// command shadow remains the common-inlet emergency fallback.
// Water forced-off must suppress Open commands but must not suppress Close
// commands, because leak/safe-state authority is expressed as physical close.
IF GVL_IO_WRITE_RUNTIME_BUFFER.B_Water_Forced_Off THEN
    GVL_IO.DO_Water_Valve_35_Open := FALSE;
    GVL_IO.DO_Water_Valve_35_Close :=
        GVL_WATER_OUTPUT.DO_Water_Valve_35_Close
        OR GVL_COMMAND_SHADOW.G_Close_Valve_35;
    GVL_IO.DO_Water_Valve_36_Open := FALSE;
    GVL_IO.DO_Water_Valve_36_Close :=
        GVL_WATER_OUTPUT.DO_Water_Valve_36_Close
        OR GVL_COMMAND_SHADOW.G_Close_Valve_36;

    FOR L_i := 1 TO 6 DO
        GVL_IO.DO_Water_Local_Valve_Open[L_i] := FALSE;
        GVL_IO.DO_Water_Local_Valve_Close[L_i] :=
            GVL_WATER_OUTPUT.DO_Water_Local_Valve_Close[L_i];
    END_FOR;
ELSE
    GVL_IO.DO_Water_Valve_35_Open := GVL_WATER_OUTPUT.DO_Water_Valve_35_Open;
    GVL_IO.DO_Water_Valve_35_Close := GVL_WATER_OUTPUT.DO_Water_Valve_35_Close OR GVL_COMMAND_SHADOW.G_Close_Valve_35;
    GVL_IO.DO_Water_Valve_36_Open := GVL_WATER_OUTPUT.DO_Water_Valve_36_Open;
    GVL_IO.DO_Water_Valve_36_Close := GVL_WATER_OUTPUT.DO_Water_Valve_36_Close OR GVL_COMMAND_SHADOW.G_Close_Valve_36;

    FOR L_i := 1 TO 6 DO
        GVL_IO.DO_Water_Local_Valve_Open[L_i] := GVL_WATER_OUTPUT.DO_Water_Local_Valve_Open[L_i];
        GVL_IO.DO_Water_Local_Valve_Close[L_i] := GVL_WATER_OUTPUT.DO_Water_Local_Valve_Close[L_i];
    END_FOR;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_WATER_ZONES DO
    IF (L_i > GVL_SYSTEM_SIZE_CONFIG.G_Active_Water_Zones)
       OR GVL_IO_WRITE_RUNTIME_BUFFER.B_Water_Forced_Off THEN
        GVL_IO.DO_Water_Zone_Enable[L_i] := FALSE;
    ELSE
        GVL_IO.DO_Water_Zone_Enable[L_i] := GVL_WATER_OUTPUT.DO_Water_Zone_Enable[L_i];
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
    IF L_i > GVL_SYSTEM_SIZE_CONFIG.G_Active_Light_Zones THEN
        GVL_IO.AO_Lighting_Levels[L_i] := 0;
    ELSE
        GVL_IO.AO_Lighting_Levels[L_i] := GVL_LIGHTING_OUTPUT.AO_Lighting_Levels[L_i];
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BLINDS DO
    IF L_i > GVL_SYSTEM_SIZE_CONFIG.G_Active_Blinds THEN
        GVL_IO.AO_Blinds_Positions[L_i] := 1000;
    ELSE
        GVL_IO.AO_Blinds_Positions[L_i] := GVL_LIGHTING_OUTPUT.AO_Blinds_Positions[L_i];
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SOCKETS DO
    IF L_i > GVL_SYSTEM_SIZE_CONFIG.G_Active_Sockets THEN
        GVL_IO.DO_Sockets[L_i] := FALSE;
    ELSE
        GVL_IO.DO_Sockets[L_i] := GVL_LIGHTING_OUTPUT.DO_Sockets[L_i];
    END_IF;
END_FOR;

IF GVL_IO_WRITE_RUNTIME_BUFFER.B_Access_Forced_Off THEN
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

// >>> BULK_SYNC_ANCHOR: PRG_IO_Write_Phase_03_Domain_Projection <<<
END_PROGRAM