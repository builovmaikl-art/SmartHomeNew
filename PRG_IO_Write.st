PROGRAM PRG_IO_Write
VAR
    L_i : INT;
END_VAR

// ============================================================
// STANDBY BEHAVIOR (Step 3.2)
// ============================================================
// Standby PLC must not drive physical outputs.
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

// 2. ЗАПИСЬ ВЫХОДОВ (GVL_STATE -> GVL_IO)

// 2.1. Отопление (Термоэлектрические приводы)
FOR L_i := 1 TO 8 DO
    GVL_IO.DO_Zone_Valves[L_i] := GVL_STATE.G_Zone_Valves[L_i];
END_FOR;

// 2.2. Коллекторы (Насосы и смесительные клапаны)
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    GVL_IO.DO_Manifold_Pumps[L_i] := GVL_STATE.G_Manifold_Pumps[L_i];
    GVL_IO.AO_Manifold_Valves[L_i] := REAL_TO_UINT(GVL_STATE.G_Manifold_Valves[L_i] * 1000.0);
END_FOR;

// 2.4. Вентиляция
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
    GVL_IO.AO_Supply_Fans[L_i] := REAL_TO_UINT(GVL_STATE.G_Supply_Fans[L_i] * 100.0);
END_FOR;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
    GVL_IO.AO_Exhaust_Fans[L_i] := REAL_TO_UINT(GVL_STATE.G_Exhaust_Fans[L_i] * 100.0);
END_FOR;

// 2.5. ГВС
GVL_IO.DO_DHW_Heating_Pump := GVL_STATE.G_DHW_Heating_Pump;
GVL_IO.DO_DHW_Circ_Pump := GVL_STATE.G_DHW_Circ_Pump;
GVL_IO.DO_Backup_Circulation_Pump := GVL_STATE.G_Backup_Circulation_Pump;
GVL_IO.DO_Electric_Heater_Enable := GVL_STATE.G_Electric_Heater_Enable;

// 2.6. Освещение и шторы
FOR L_i := 1 TO 8 DO
    GVL_IO.AO_Lighting_Levels[L_i] := BYTE_TO_UINT(GVL_STATE.G_Lighting_Levels[L_i]) * 10;
END_FOR;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BLINDS DO
    GVL_IO.AO_Blinds_Positions[L_i] := BYTE_TO_UINT(GVL_STATE.G_Blinds_Positions[L_i]) * 10;
END_FOR;

// 2.7. Аварийные выходы (Сирены и клапаны)
GVL_IO.DO_Gas_Siren := (GVL_ALARM.G_Gas_Fire_Siren AND GVL_ALARM.G_Gas_Alarm_Active);
GVL_IO.DO_Fire_Siren := (GVL_ALARM.G_Gas_Fire_Siren AND GVL_ALARM.G_Fire_Alarm_Active);
GVL_IO.DO_Security_Siren := GVL_ALARM.G_Security_Siren;

// === STAGE H2: USE SHADOW COMMANDS ===
GVL_IO.DO_Water_Valve_35_Close := GVL_COMMAND_SHADOW.G_Close_Valve_35;
GVL_IO.DO_Water_Valve_36_Close := GVL_COMMAND_SHADOW.G_Close_Valve_36;
GVL_IO.DO_Gas_Valve_Close := GVL_COMMAND_SHADOW.G_Gas_Valve_Close;

// Access control (shadow)
GVL_IO.DO_Lock_1_Open := GVL_COMMAND_SHADOW.G_Lock_1_Open;
GVL_IO.DO_Lock_1_Close := GVL_COMMAND_SHADOW.G_Lock_1_Close;
GVL_IO.DO_Lock_2_Open := GVL_COMMAND_SHADOW.G_Lock_2_Open;
GVL_IO.DO_Lock_2_Close := GVL_COMMAND_SHADOW.G_Lock_2_Close;

// Gate/Wicket — now via shadow
GVL_IO.DO_Gate_Open := GVL_COMMAND_SHADOW.G_Gate_Open;
GVL_IO.DO_Wicket_Open := GVL_COMMAND_SHADOW.G_Wicket_Open;

// 2.9. Розетки
GVL_IO.DO_Sockets := GVL_STATE.G_Socket_States;

// Selective zonal water recovery outputs
FOR L_i := 1 TO 32 DO
    GVL_IO.DO_Water_Zone_Enable[L_i] := GVL_STATE.G_Water_Zone_Enable[L_i];
END_FOR;

// >>> BULK_SYNC_ANCHOR: PRG_IO_Write <<<
