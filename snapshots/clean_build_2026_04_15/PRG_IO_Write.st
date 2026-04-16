PROGRAM PRG_IO_Write
VAR
    L_i : INT;
END_VAR

// 2. ЗАПИСЬ ВЫХОДОВ (GVL_STATE -> GVL_IO)

// 2.1. Отопление (Термоэлектрические приводы)
FOR L_i := 1 TO 8 DO
    GVL_IO.DO_Zone_Valves[L_i] := GVL_STATE.G_Zone_Valves[L_i];
END_FOR;

// 2.2. Коллекторы (Насосы и смесительные клапаны)
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    GVL_IO.DO_Manifold_Pumps[L_i] := GVL_STATE.G_Manifold_Pumps[L_i];
    // Масштабирование 0.0-1.0 в 0-1000 для аналогового выхода (0-10В)
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
IF GVL_STATUS.G_Is_Active_PLC THEN
    GVL_IO.DO_Backup_Circulation_Pump := GVL_STATE.G_Backup_Circulation_Pump;
    GVL_IO.DO_Electric_Heater_Enable := GVL_STATE.G_Electric_Heater_Enable;
ELSE
    GVL_IO.DO_Backup_Circulation_Pump := FALSE;
    GVL_IO.DO_Electric_Heater_Enable := FALSE;
END_IF;

// 2.6. Освещение и шторы (полноценная выдача в физические каналы 0-10В)
FOR L_i := 1 TO 8 DO
    GVL_IO.AO_Lighting_Levels[L_i] := BYTE_TO_UINT(GVL_STATE.G_Lighting_Levels[L_i]) * 10;
END_FOR;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BLINDS DO
    GVL_IO.AO_Blinds_Positions[L_i] := BYTE_TO_UINT(GVL_STATE.G_Blinds_Positions[L_i]) * 10;
END_FOR;

// 2.7. Аварийные выходы (Сирены и клапаны)
IF GVL_ALARM.G_Gas_Fire_Siren AND GVL_ALARM.G_Gas_Alarm_Active THEN
    GVL_IO.DO_Gas_Siren := TRUE;
ELSE
    GVL_IO.DO_Gas_Siren := FALSE;
END_IF;

IF GVL_ALARM.G_Gas_Fire_Siren AND GVL_ALARM.G_Fire_Alarm_Active THEN
    GVL_IO.DO_Fire_Siren := TRUE;
ELSE
    GVL_IO.DO_Fire_Siren := FALSE;
END_IF;

IF GVL_ALARM.G_Security_Siren THEN
    GVL_IO.DO_Security_Siren := TRUE;
ELSE
    GVL_IO.DO_Security_Siren := FALSE;
END_IF;

IF GVL_COMMAND.G_Close_Valve_35 THEN
    GVL_IO.DO_Water_Valve_35_Close := TRUE;
ELSE
    GVL_IO.DO_Water_Valve_35_Close := FALSE;
END_IF;

IF GVL_COMMAND.G_Close_Valve_36 THEN
    GVL_IO.DO_Water_Valve_36_Close := TRUE;
ELSE
    GVL_IO.DO_Water_Valve_36_Close := FALSE;
END_IF;

IF GVL_COMMAND.G_Gas_Valve_Close THEN
    GVL_IO.DO_Gas_Valve_Close := TRUE;
ELSE
    GVL_IO.DO_Gas_Valve_Close := FALSE;
END_IF;

// 2.8. Управление доступом (Периметральная автоматика)
GVL_IO.DO_Gate_Open := GVL_COMMAND.G_Gate_Open;
GVL_IO.DO_Wicket_Open := GVL_COMMAND.G_Wicket_Open;
GVL_IO.DO_Lock_1_Open := GVL_COMMAND.G_Lock_1_Open;
GVL_IO.DO_Lock_1_Close := GVL_COMMAND.G_Lock_1_Close;
GVL_IO.DO_Lock_2_Open := GVL_COMMAND.G_Lock_2_Open;
GVL_IO.DO_Lock_2_Close := GVL_COMMAND.G_Lock_2_Close;

// 2.9. Розетки
GVL_IO.DO_Sockets := GVL_STATE.G_Socket_States;

// Selective zonal water recovery outputs
FOR L_i := 1 TO 32 DO
    GVL_IO.DO_Water_Zone_Enable[L_i] := GVL_STATE.G_Water_Zone_Enable[L_i];
END_FOR;
// >>> BULK_SYNC_ANCHOR: PRG_IO_Write <<<
