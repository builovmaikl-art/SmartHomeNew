PROGRAM PRG_Safety
VAR
    L_CMD_Water_Selective_Recover_Prev : BOOL;
    L_CMD_Water_Selective_Recover_Edge : BOOL;
    L_CMD_Gas_Selective_Recover_Prev : BOOL;
    L_CMD_Gas_Selective_Recover_Edge : BOOL;
    L_CMD_Water_Valve_Test_Open_Prev : BOOL;
    L_CMD_Water_Valve_Test_Open_Edge : BOOL;
    L_CMD_Water_Valve_Test_Close_Prev : BOOL;
    L_CMD_Water_Valve_Test_Close_Edge : BOOL;
    L_CMD_Water_Valve_Test_Confirm_Prev : BOOL;
    L_CMD_Water_Valve_Test_Confirm_Edge : BOOL;
    L_CMD_Gas_Valve_Test_Open_Prev : BOOL;
    L_CMD_Gas_Valve_Test_Open_Edge : BOOL;
    L_CMD_Gas_Valve_Test_Close_Prev : BOOL;
    L_CMD_Gas_Valve_Test_Close_Edge : BOOL;
    L_CMD_Gas_Valve_Test_Confirm_Prev : BOOL;
    L_CMD_Gas_Valve_Test_Confirm_Edge : BOOL;
    fbWaterLeakageManager : FB_Water_Leakage_Manager;
    fbGasSmokeManager : FB_Gas_Smoke_Manager;
    L_i : INT;
    L_Water_Test_Active : BOOL;
    L_Water_Test_Deadline : UDINT;
    L_Gas_Test_Active : BOOL;
    L_Gas_Test_Deadline : UDINT;
    L_Water_Valve_Last_Exercise_MS : ARRAY[1..32] OF UDINT;
    L_Water_Valve_Exercise_Until_MS : ARRAY[1..32] OF UDINT;
    L_Water_Zone_Close_Last_Retry_MS : ARRAY[1..32] OF UDINT;
END_VAR

// === COMMAND EDGE PROCESSING ===
L_CMD_Water_Selective_Recover_Edge := GVL_COMMAND.CMD_Water_Selective_Recover AND NOT L_CMD_Water_Selective_Recover_Prev;
L_CMD_Gas_Selective_Recover_Edge := GVL_COMMAND.CMD_Gas_Selective_Recover AND NOT L_CMD_Gas_Selective_Recover_Prev;
L_CMD_Water_Valve_Test_Open_Edge := GVL_COMMAND.CMD_Water_Valve_Test_Open AND NOT L_CMD_Water_Valve_Test_Open_Prev;
L_CMD_Water_Valve_Test_Close_Edge := GVL_COMMAND.CMD_Water_Valve_Test_Close AND NOT L_CMD_Water_Valve_Test_Close_Prev;
L_CMD_Water_Valve_Test_Confirm_Edge := GVL_COMMAND.CMD_Water_Valve_Test_Confirm AND NOT L_CMD_Water_Valve_Test_Confirm_Prev;
L_CMD_Gas_Valve_Test_Open_Edge := GVL_COMMAND.CMD_Gas_Valve_Test_Open AND NOT L_CMD_Gas_Valve_Test_Open_Prev;
L_CMD_Gas_Valve_Test_Close_Edge := GVL_COMMAND.CMD_Gas_Valve_Test_Close AND NOT L_CMD_Gas_Valve_Test_Close_Prev;
L_CMD_Gas_Valve_Test_Confirm_Edge := GVL_COMMAND.CMD_Gas_Valve_Test_Confirm AND NOT L_CMD_Gas_Valve_Test_Confirm_Prev;

L_CMD_Water_Selective_Recover_Prev := GVL_COMMAND.CMD_Water_Selective_Recover;
L_CMD_Gas_Selective_Recover_Prev := GVL_COMMAND.CMD_Gas_Selective_Recover;
L_CMD_Water_Valve_Test_Open_Prev := GVL_COMMAND.CMD_Water_Valve_Test_Open;
L_CMD_Water_Valve_Test_Close_Prev := GVL_COMMAND.CMD_Water_Valve_Test_Close;
L_CMD_Water_Valve_Test_Confirm_Prev := GVL_COMMAND.CMD_Water_Valve_Test_Confirm;
L_CMD_Gas_Valve_Test_Open_Prev := GVL_COMMAND.CMD_Gas_Valve_Test_Open;
L_CMD_Gas_Valve_Test_Close_Prev := GVL_COMMAND.CMD_Gas_Valve_Test_Close;
L_CMD_Gas_Valve_Test_Confirm_Prev := GVL_COMMAND.CMD_Gas_Valve_Test_Confirm;

// 7.5 Система защиты от протечек
fbWaterLeakageManager(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Sensors := GVL_STATE.G_Water_Sensors,
    VI_Config := GVL_CONFIG.G_HMI_Flood_Config,
    VO_Status_Msg => GVL_STATUS.G_Flood_Status_Msg,
    VO_Leak_Detected => GVL_HEALTH_BRIDGE.G_Leak_Detected,
    VO_Leak_Warning_Level => GVL_HEALTH_BRIDGE.G_Leak_Warning_Level
);
GVL_ALARM.G_Flood_Alarm_Active := GVL_HEALTH_BRIDGE.G_Leak_Detected;

// 8. Пожарная и газовая безопасность (Приоритет 1)
fbGasSmokeManager(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Methane_LEL := GVL_Safety_Selector.G_Methane_Effective_Array,
    VI_CO_PPM := GVL_Safety_Selector.G_CO_Effective_Array,
    VI_Smoke_Sensors := GVL_Safety_Selector.G_Smoke_Effective_Array,
    VI_Mute_Request := GVL_CONFIG.G_HMI_Mute_Alarm,
    VO_Smoke_Detected => GVL_HEALTH_BRIDGE.G_Smoke_Detected,
    VO_Gas_Detected => GVL_HEALTH_BRIDGE.G_Gas_Detected,
    VO_CO_Warning_Level => GVL_HEALTH_BRIDGE.G_CO_Warning_Level,
    VO_CO_Alarm_Level => GVL_HEALTH_BRIDGE.G_CO_Alarm_Level,
    VO_Status_Msg => GVL_STATUS.G_Gas_Status_Msg
);
GVL_ALARM.G_Fire_Alarm_Active := GVL_HEALTH_BRIDGE.G_Smoke_Detected;
GVL_ALARM.G_Gas_Alarm_Active := GVL_HEALTH_BRIDGE.G_Gas_Detected OR GVL_HEALTH_BRIDGE.G_CO_Alarm_Level;
// Нормализация приоритетов и защёлкнутых safety-команд
// 1. Пожар/дым имеет приоритет над газовой вентиляцией
IF GVL_STATE.G_Safety_Smoke_Latched THEN
    GVL_COMMAND.G_Boiler_Stop := TRUE;
    GVL_COMMAND.G_Vent_Stop := TRUE;
    GVL_COMMAND.G_Supply_100_Req := FALSE;
    GVL_COMMAND.G_Supply_80_Req := FALSE;
    GVL_COMMAND.G_Vent_PV3_Boost := FALSE;
    GVL_COMMAND.G_Exhaust_100_Req := FALSE;

    // Эвакуация: разблокируем электронные замки для свободного выхода людей.
    GVL_COMMAND.G_Lock_1_Open := TRUE;
    GVL_COMMAND.G_Lock_1_Close := FALSE;
    GVL_COMMAND.G_Lock_2_Open := TRUE;
    GVL_COMMAND.G_Lock_2_Close := FALSE;
END_IF;

// 2. Газовая авария защёлкивает закрытие газа и стоп котлов
IF GVL_STATE.G_Safety_Gas_Latched THEN
    GVL_COMMAND.G_Gas_Valve_Close := TRUE;
    GVL_COMMAND.G_Boiler_Stop := TRUE;
END_IF;

// 3. Протечка защёлкивает перекрытие воды
IF GVL_STATE.G_Safety_Leak_Latched THEN
    GVL_COMMAND.G_Close_Valve_35 := TRUE;
    GVL_COMMAND.G_Close_Valve_36 := TRUE;
END_IF;

// 3.1 Вентиляционные команды: единый owner = PRG_Safety
IF GVL_STATE.G_Safety_Gas_Latched THEN
    GVL_COMMAND.G_Vent_PV3_Boost := TRUE;
    GVL_COMMAND.G_Supply_100_Req := TRUE;
END_IF;

IF GVL_HEALTH_BRIDGE.G_CO_Warning_Level OR GVL_HEALTH_BRIDGE.G_CO_Alarm_Level THEN
    GVL_COMMAND.G_Supply_80_Req := TRUE;
END_IF;

// Формирование зон опасности для направленной эвакуации через программную конфигурацию.
// Монтаж может быть выполнен произвольно: фактический вход ПЛК не определяет зону напрямую.
FOR L_i := 1 TO GVL_CONFIG.C_MAX_LIGHT_ZONES DO
    GVL_STATE.G_Evac_Hazard_Zone[L_i] := FALSE;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SMOKE_SENSORS DO
    IF GVL_STATE.G_Smoke_Sensors[L_i] THEN
        IF (GVL_CONFIG.G_Evac_Smoke_Zone_Map[L_i] >= 1) AND (GVL_CONFIG.G_Evac_Smoke_Zone_Map[L_i] <= GVL_CONFIG.C_MAX_LIGHT_ZONES) THEN
            GVL_STATE.G_Evac_Hazard_Zone[GVL_CONFIG.G_Evac_Smoke_Zone_Map[L_i]] := TRUE;
        END_IF;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO
    IF GVL_STATE.G_Water_Sensors[L_i] THEN
        IF (GVL_CONFIG.G_Evac_Leak_Zone_Map[L_i] >= 1) AND (GVL_CONFIG.G_Evac_Leak_Zone_Map[L_i] <= GVL_CONFIG.C_MAX_LIGHT_ZONES) THEN
            GVL_STATE.G_Evac_Hazard_Zone[GVL_CONFIG.G_Evac_Leak_Zone_Map[L_i]] := TRUE;
        END_IF;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_METHANE_SENSORS DO
    IF GVL_STATE.G_Methane_Sensors[L_i] >= 20.0 THEN
        IF (GVL_CONFIG.G_Evac_Gas_Zone_Map[L_i] >= 1) AND (GVL_CONFIG.G_Evac_Gas_Zone_Map[L_i] <= GVL_CONFIG.C_MAX_LIGHT_ZONES) THEN
            GVL_STATE.G_Evac_Hazard_Zone[GVL_CONFIG.G_Evac_Gas_Zone_Map[L_i]] := TRUE;
        END_IF;
    END_IF;
END_FOR;

// Публикация агрегированных safety-состояний в единый слой GVL_STATE
GVL_STATE.G_Safety_Leak_Alarm := GVL_ALARM.G_Flood_Alarm_Active;
GVL_STATE.G_Safety_Gas_Alarm := GVL_ALARM.G_Gas_Alarm_Active;
GVL_STATE.G_Safety_Smoke_Alarm := GVL_ALARM.G_Fire_Alarm_Active;

// Integrated water/freeze/valve/operator safety layer
GVL_STATUS.G_Diagnostics.Water_Recovery_Physical_Active := FALSE;
GVL_STATUS.G_Diagnostics.Water_Recovery_Physical_Zone_Name := '';
GVL_STATUS.G_Diagnostics.Water_Localization_Failed := FALSE;
GVL_STATUS.G_Diagnostics.Water_Main_Shutdown_Recommended := FALSE;
GVL_STATUS.G_Diagnostics.Water_Escalation_Text := '';
GVL_STATUS.G_Diagnostics.Water_Close_Fault_Active := FALSE;
GVL_STATUS.G_Diagnostics.Water_Close_Fault_Zone_Name := '';
GVL_STATUS.G_Diagnostics.Water_Close_Fault_Text := '';
GVL_STATUS.G_Diagnostics.Valve_Test_Validation_OK := FALSE;
GVL_STATUS.G_Diagnostics.Valve_Test_Validation_Text := '';
GVL_STATUS.G_Diagnostics.Valve_Test_Forced_Close := FALSE;
GVL_STATUS.G_Diagnostics.Water_Recovery_Target_Zone_Index := 0;
GVL_STATUS.G_Diagnostics.Gas_Recovery_Target_Zone_Index := 0;
GVL_STATUS.G_Diagnostics.Water_Recovery_Selective_Allowed := FALSE;
GVL_STATUS.G_Diagnostics.Gas_Recovery_Selective_Allowed := FALSE;
GVL_STATUS.G_Diagnostics.Water_Recovery_Selective_Text := '';
GVL_STATUS.G_Diagnostics.Gas_Recovery_Selective_Text := '';
GVL_STATUS.G_Diagnostics.Active_Leak_Sensor_Index := 0;
GVL_STATUS.G_Diagnostics.Active_Gas_Sensor_Index := 0;
GVL_STATUS.G_Diagnostics.Active_Leak_Zone_Name := '';
GVL_STATUS.G_Diagnostics.Active_Gas_Zone_Name := '';

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO
    IF (GVL_STATUS.G_Diagnostics.Active_Leak_Sensor_Index = 0) AND GVL_STATE.G_Water_Sensors[L_i] THEN
        GVL_STATUS.G_Diagnostics.Active_Leak_Sensor_Index := L_i;
        IF (GVL_CONFIG.G_Evac_Leak_Zone_Map[L_i] >= 1) AND (GVL_CONFIG.G_Evac_Leak_Zone_Map[L_i] <= 32) THEN
            GVL_STATUS.G_Diagnostics.Water_Recovery_Target_Zone_Index := GVL_CONFIG.G_Evac_Leak_Zone_Map[L_i];
            GVL_STATUS.G_Diagnostics.Active_Leak_Zone_Name := GVL_CONFIG.G_Evac_Zone_Names[GVL_CONFIG.G_Evac_Leak_Zone_Map[L_i]];
        END_IF;
        IF GVL_STATUS.G_Diagnostics.Active_Leak_Zone_Name = '' THEN
            GVL_STATUS.G_Diagnostics.Active_Leak_Zone_Name := CONCAT('Leak sensor ', INT_TO_STRING(L_i));
        END_IF;
    END_IF;
END_FOR;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_METHANE_SENSORS DO
    IF (GVL_STATUS.G_Diagnostics.Active_Gas_Sensor_Index = 0) AND (GVL_STATE.G_Methane_Sensors[L_i] >= 20.0) THEN
        GVL_STATUS.G_Diagnostics.Active_Gas_Sensor_Index := L_i;
        IF (GVL_CONFIG.G_Evac_Gas_Zone_Map[L_i] >= 1) AND (GVL_CONFIG.G_Evac_Gas_Zone_Map[L_i] <= 32) THEN
            GVL_STATUS.G_Diagnostics.Gas_Recovery_Target_Zone_Index := GVL_CONFIG.G_Evac_Gas_Zone_Map[L_i];
            GVL_STATUS.G_Diagnostics.Active_Gas_Zone_Name := GVL_CONFIG.G_Evac_Zone_Names[GVL_CONFIG.G_Evac_Gas_Zone_Map[L_i]];
        END_IF;
        IF GVL_STATUS.G_Diagnostics.Active_Gas_Zone_Name = '' THEN
            GVL_STATUS.G_Diagnostics.Active_Gas_Zone_Name := CONCAT('Gas sensor ', INT_TO_STRING(L_i));
        END_IF;
    END_IF;
END_FOR;

IF GVL_STATUS.G_Diagnostics.Active_Leak_Sensor_Index > 0 THEN
    GVL_STATUS.G_Diagnostics.Water_Recovery_Selective_Allowed := TRUE;
    GVL_STATUS.G_Diagnostics.Water_Recovery_Selective_Text := CONCAT('Селективное восстановление возможно для зоны ', GVL_STATUS.G_Diagnostics.Active_Leak_Zone_Name);
END_IF;
IF GVL_STATUS.G_Diagnostics.Active_Gas_Sensor_Index > 0 THEN
    GVL_STATUS.G_Diagnostics.Gas_Recovery_Selective_Allowed := TRUE;
    GVL_STATUS.G_Diagnostics.Gas_Recovery_Selective_Text := CONCAT('Газовый контекст локализован в зоне ', GVL_STATUS.G_Diagnostics.Active_Gas_Zone_Name);
END_IF;

FOR L_i := 1 TO 32 DO
    GVL_STATE.G_Water_Zone_Enable[L_i] := FALSE;
    GVL_STATUS.G_Diagnostics.Water_Zone_Open_Fault[L_i] := FALSE;
    GVL_STATUS.G_Diagnostics.Water_Zone_Close_Fault[L_i] := FALSE;
    GVL_STATUS.G_Diagnostics.Water_Zone_Critical_Close_Fault[L_i] := FALSE;
    GVL_STATUS.G_Diagnostics.Water_Zone_Close_Retry_Active[L_i] := FALSE;

    IF NOT GVL_STATE.G_Water_Zone_Enable[L_i] THEN
        IF NOT GVL_STATE.G_Water_Zone_Close_FB[L_i] THEN
            IF GVL_STATUS.G_Diagnostics.Water_Zone_Close_Retry_Count[L_i] < GVL_CONFIG.G_Water_Valve_Close_Retry_Count THEN
                IF (GVL_STATUS.G_System_Time_MS - L_Water_Zone_Close_Last_Retry_MS[L_i]) >= GVL_CONFIG.G_Water_Valve_Close_Retry_Delay_MS THEN
                    GVL_STATUS.G_Diagnostics.Water_Zone_Close_Retry_Active[L_i] := TRUE;
                    GVL_STATUS.G_Diagnostics.Water_Zone_Close_Retry_Count[L_i] := GVL_STATUS.G_Diagnostics.Water_Zone_Close_Retry_Count[L_i] + 1;
                    L_Water_Zone_Close_Last_Retry_MS[L_i] := GVL_STATUS.G_System_Time_MS;
                END_IF;
            ELSE
                GVL_STATUS.G_Diagnostics.Water_Zone_Critical_Close_Fault[L_i] := TRUE;
                GVL_STATUS.G_Diagnostics.Water_Close_Fault_Active := TRUE;
                GVL_STATUS.G_Diagnostics.Water_Close_Fault_Zone_Name := GVL_CONFIG.G_Evac_Zone_Names[L_i];
                IF GVL_STATUS.G_Diagnostics.Water_Close_Fault_Zone_Name = '' THEN
                    GVL_STATUS.G_Diagnostics.Water_Close_Fault_Zone_Name := CONCAT('Water zone ', INT_TO_STRING(L_i));
                END_IF;
                GVL_STATUS.G_Diagnostics.Water_Close_Fault_Text := CONCAT('Не подтверждено аварийное закрытие водяного клапана в зоне ', GVL_STATUS.G_Diagnostics.Water_Close_Fault_Zone_Name);
            END_IF;
        ELSE
            IF GVL_STATUS.G_Diagnostics.Water_Zone_Close_Retry_Count[L_i] > 0 THEN
                GVL_STATUS.G_Diagnostics.Water_Zone_Close_Recovered_After_Retry[L_i] := TRUE;
            END_IF;
            GVL_STATUS.G_Diagnostics.Water_Zone_Close_Retry_Count[L_i] := 0;
        END_IF;
    END_IF;

    IF GVL_CONFIG.G_Water_Valve_Exercise_Enabled AND GVL_STATUS.G_Is_Active_PLC AND
       (GVL_STATUS.G_Current_TOD >= GVL_CONFIG.G_Water_Valve_Exercise_Window_Start) AND
       (GVL_STATUS.G_Current_TOD <= GVL_CONFIG.G_Water_Valve_Exercise_Window_End) AND
       GVL_STATE.G_Water_Zone_Open_FB[L_i] AND
       (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL) AND
       (NOT GVL_STATE.G_Safety_Leak_Alarm) AND (NOT GVL_STATE.G_Safety_Gas_Alarm) THEN
        IF (GVL_STATUS.G_System_Time_MS - L_Water_Valve_Last_Exercise_MS[L_i]) >= GVL_CONFIG.G_Water_Valve_Exercise_Interval_MS THEN
            IF L_Water_Valve_Exercise_Until_MS[L_i] = 0 THEN
                L_Water_Valve_Exercise_Until_MS[L_i] := GVL_STATUS.G_System_Time_MS + GVL_CONFIG.G_Water_Valve_Exercise_Duration_MS;
                L_Water_Valve_Last_Exercise_MS[L_i] := GVL_STATUS.G_System_Time_MS;
            END_IF;
        END_IF;
    END_IF;

    IF L_Water_Valve_Exercise_Until_MS[L_i] <> 0 THEN
        IF GVL_STATUS.G_System_Time_MS < L_Water_Valve_Exercise_Until_MS[L_i] THEN
            GVL_STATE.G_Water_Zone_Enable[L_i] := TRUE;
            GVL_STATE.G_Water_Zone_Exercise_Active[L_i] := TRUE;
            GVL_STATUS.G_Diagnostics.Water_Valve_Exercise_Last_Zone := L_i;
            IF GVL_STATE.G_Water_Zone_Open_FB[L_i] THEN
                GVL_STATUS.G_Diagnostics.Water_Valve_Exercise_Last_Result := 'Прокрутка шарового крана подтверждена OPEN_FB';
            ELSE
                GVL_STATUS.G_Diagnostics.Water_Valve_Exercise_Last_Result := 'Прокрутка шарового крана выполняется';
            END_IF;
        ELSE
            L_Water_Valve_Exercise_Until_MS[L_i] := 0;
            GVL_STATE.G_Water_Zone_Enable[L_i] := FALSE;
            GVL_STATE.G_Water_Zone_Exercise_Active[L_i] := FALSE;
            IF GVL_STATE.G_Water_Zone_Close_FB[L_i] THEN
                GVL_STATUS.G_Diagnostics.Water_Valve_Exercise_Last_Result := 'Прокрутка шарового крана завершена и подтверждена CLOSE_FB';
            ELSE
                GVL_STATUS.G_Diagnostics.Water_Valve_Exercise_Last_Result := 'Прокрутка завершена, CLOSE_FB не подтверждён';
            END_IF;
        END_IF;
    END_IF;
END_FOR;

IF L_CMD_Water_Selective_Recover_Edge THEN
    IF GVL_STATUS.G_Diagnostics.Water_Recovery_Selective_Allowed AND (GVL_STATUS.G_Diagnostics.Water_Recovery_Target_Zone_Index >= 1) AND (GVL_STATUS.G_Diagnostics.Water_Recovery_Target_Zone_Index <= 32) THEN
        GVL_STATE.G_Water_Zone_Enable[GVL_STATUS.G_Diagnostics.Water_Recovery_Target_Zone_Index] := TRUE;
        GVL_STATUS.G_Diagnostics.Water_Recovery_Physical_Active := TRUE;
        GVL_STATUS.G_Diagnostics.Water_Recovery_Physical_Zone_Name := GVL_STATUS.G_Diagnostics.Active_Leak_Zone_Name;
        GVL_STATUS.G_Diagnostics.Water_Valve_Test_Context := CONCAT('Селективный тест воды для зоны ', GVL_STATUS.G_Diagnostics.Active_Leak_Zone_Name);
    ELSE
        GVL_STATUS.G_Diagnostics.Operator_Action_Blocked := TRUE;
        GVL_STATUS.G_Diagnostics.Operator_Block_Reason := 'Селективное восстановление воды недоступно: зона аварии не локализована';
    END_IF;
END_IF;

IF L_CMD_Gas_Selective_Recover_Edge THEN
    IF GVL_STATUS.G_Diagnostics.Gas_Recovery_Selective_Allowed THEN
        GVL_STATUS.G_Diagnostics.Gas_Valve_Test_Context := CONCAT('Селективный тест газа для зоны ', GVL_STATUS.G_Diagnostics.Active_Gas_Zone_Name);
    ELSE
        GVL_STATUS.G_Diagnostics.Operator_Action_Blocked := TRUE;
        GVL_STATUS.G_Diagnostics.Operator_Block_Reason := 'Селективное восстановление газа недоступно: зона аварии не локализована';
    END_IF;
END_IF;

IF L_CMD_Water_Valve_Test_Open_Edge THEN
    L_Water_Test_Active := TRUE;
    L_Water_Test_Deadline := GVL_STATUS.G_System_Time_MS + 60000;
    GVL_STATUS.G_Diagnostics.Water_Valve_Test_Mode_Active := TRUE;
    GVL_STATUS.G_Diagnostics.Water_Valve_Test_Deadline_MS := L_Water_Test_Deadline;
END_IF;
IF L_Water_Test_Active THEN
    IF GVL_STATUS.G_System_Time_MS < L_Water_Test_Deadline THEN
        GVL_STATUS.G_Diagnostics.Water_Valve_Test_Remaining_MS := L_Water_Test_Deadline - GVL_STATUS.G_System_Time_MS;
        IF NOT GVL_STATE.G_Safety_Leak_Alarm THEN
            GVL_STATUS.G_Diagnostics.Water_Valve_Test_Validation_OK := TRUE;
            GVL_STATUS.G_Diagnostics.Water_Valve_Test_Validation_Text := CONCAT('Утечка не обнаружена, зона: ', GVL_STATUS.G_Diagnostics.Active_Leak_Zone_Name);
        ELSE
            GVL_STATUS.G_Diagnostics.Water_Valve_Test_Validation_OK := FALSE;
            GVL_STATUS.G_Diagnostics.Water_Valve_Test_Validation_Text := CONCAT('Подтверждение запрещено: активна протечка в зоне ', GVL_STATUS.G_Diagnostics.Active_Leak_Zone_Name);
            GVL_STATUS.G_Diagnostics.Water_Valve_Test_Forced_Close := TRUE;
            GVL_COMMAND.G_Close_Valve_35 := TRUE;
            GVL_COMMAND.G_Close_Valve_36 := TRUE;
            L_Water_Test_Active := FALSE;
            GVL_STATUS.G_Diagnostics.Water_Valve_Test_Mode_Active := FALSE;
        END_IF;
    ELSE
        L_Water_Test_Active := FALSE;
        GVL_STATUS.G_Diagnostics.Water_Valve_Test_Mode_Active := FALSE;
        GVL_COMMAND.G_Close_Valve_35 := TRUE;
        GVL_COMMAND.G_Close_Valve_36 := TRUE;
    END_IF;
END_IF;
IF L_CMD_Water_Valve_Test_Close_Edge THEN
    L_Water_Test_Active := FALSE;
    GVL_STATUS.G_Diagnostics.Water_Valve_Test_Mode_Active := FALSE;
    GVL_COMMAND.G_Close_Valve_35 := TRUE;
    GVL_COMMAND.G_Close_Valve_36 := TRUE;
END_IF;
IF L_CMD_Water_Valve_Test_Confirm_Edge AND L_Water_Test_Active THEN
    IF GVL_STATUS.G_Diagnostics.Water_Valve_Test_Validation_OK THEN
        L_Water_Test_Active := FALSE;
        GVL_STATUS.G_Diagnostics.Water_Valve_Test_Mode_Active := FALSE;
    ELSE
        GVL_STATUS.G_Diagnostics.Operator_Action_Blocked := TRUE;
        GVL_STATUS.G_Diagnostics.Operator_Block_Reason := 'Подтверждение водяного теста запрещено: причина аварии не устранена';
    END_IF;
END_IF;

IF L_CMD_Gas_Valve_Test_Open_Edge THEN
    L_Gas_Test_Active := TRUE;
    L_Gas_Test_Deadline := GVL_STATUS.G_System_Time_MS + 60000;
    GVL_STATUS.G_Diagnostics.Gas_Valve_Test_Mode_Active := TRUE;
    GVL_STATUS.G_Diagnostics.Gas_Valve_Test_Deadline_MS := L_Gas_Test_Deadline;
END_IF;
IF L_Gas_Test_Active THEN
    IF GVL_STATUS.G_System_Time_MS < L_Gas_Test_Deadline THEN
        GVL_STATUS.G_Diagnostics.Gas_Valve_Test_Remaining_MS := L_Gas_Test_Deadline - GVL_STATUS.G_System_Time_MS;
        IF NOT GVL_STATE.G_Safety_Gas_Alarm THEN
            GVL_STATUS.G_Diagnostics.Gas_Valve_Test_Validation_OK := TRUE;
            GVL_STATUS.G_Diagnostics.Gas_Valve_Test_Validation_Text := CONCAT('Газ не обнаружен, зона: ', GVL_STATUS.G_Diagnostics.Active_Gas_Zone_Name);
        ELSE
            GVL_STATUS.G_Diagnostics.Gas_Valve_Test_Validation_OK := FALSE;
            GVL_STATUS.G_Diagnostics.Gas_Valve_Test_Validation_Text := CONCAT('Подтверждение запрещено: активен газ в зоне ', GVL_STATUS.G_Diagnostics.Active_Gas_Zone_Name);
            GVL_STATUS.G_Diagnostics.Gas_Valve_Test_Forced_Close := TRUE;
            GVL_COMMAND.G_Gas_Valve_Close := TRUE;
            L_Gas_Test_Active := FALSE;
            GVL_STATUS.G_Diagnostics.Gas_Valve_Test_Mode_Active := FALSE;
        END_IF;
    ELSE
        L_Gas_Test_Active := FALSE;
        GVL_STATUS.G_Diagnostics.Gas_Valve_Test_Mode_Active := FALSE;
        GVL_COMMAND.G_Gas_Valve_Close := TRUE;
    END_IF;
END_IF;
IF L_CMD_Gas_Valve_Test_Close_Edge THEN
    L_Gas_Test_Active := FALSE;
    GVL_STATUS.G_Diagnostics.Gas_Valve_Test_Mode_Active := FALSE;
    GVL_COMMAND.G_Gas_Valve_Close := TRUE;
END_IF;
IF L_CMD_Gas_Valve_Test_Confirm_Edge AND L_Gas_Test_Active THEN
    IF GVL_STATUS.G_Diagnostics.Gas_Valve_Test_Validation_OK THEN
        L_Gas_Test_Active := FALSE;
        GVL_STATUS.G_Diagnostics.Gas_Valve_Test_Mode_Active := FALSE;
    ELSE
        GVL_STATUS.G_Diagnostics.Operator_Action_Blocked := TRUE;
        GVL_STATUS.G_Diagnostics.Operator_Block_Reason := 'Подтверждение газового теста запрещено: причина аварии не устранена';
    END_IF;
END_IF;

IF GVL_STATE.G_Safety_Leak_Alarm THEN
    FOR L_i := 1 TO 32 DO
        IF GVL_STATUS.G_Diagnostics.Water_Zone_Critical_Close_Fault[L_i] THEN
            GVL_STATUS.G_Diagnostics.Water_Localization_Failed := TRUE;
            GVL_STATUS.G_Diagnostics.Water_Main_Shutdown_Recommended := TRUE;
            IF GVL_CONFIG.G_Evac_Zone_Names[L_i] <> '' THEN
                GVL_STATUS.G_Diagnostics.Water_Escalation_Text := CONCAT('Реальная протечка не локализована, рекомендуется перекрыть общий ввод воды: ', GVL_CONFIG.G_Evac_Zone_Names[L_i]);
            ELSE
                GVL_STATUS.G_Diagnostics.Water_Escalation_Text := CONCAT('Реальная протечка не локализована, рекомендуется перекрыть общий ввод воды: зона ', INT_TO_STRING(L_i));
            END_IF;
        END_IF;
    END_FOR;
END_IF;
IF GVL_STATUS.G_Diagnostics.Water_Main_Shutdown_Recommended THEN
    GVL_STATUS.G_Diagnostics.Operator_Action_Blocked := TRUE;
    GVL_STATUS.G_Diagnostics.Operator_Block_Reason := GVL_STATUS.G_Diagnostics.Water_Escalation_Text;
END_IF;

IF GVL_STATE.G_Freeze_Hardware_Degraded THEN
    GVL_STATUS.G_Diagnostics.Freeze_Hardware_Event_Pending := TRUE;
END_IF;

// === Global System Arbitration ===
IF GVL_STATE.G_Safety_Emergency_Stop THEN
    GVL_STATE.G_System_Mode := E_System_Operating_Mode.MODE_SAFE_STOP;

ELSIF GVL_STATE.G_Safety_Smoke_Latched THEN
    GVL_STATE.G_System_Mode := E_System_Operating_Mode.MODE_SAFE_STOP;

ELSIF GVL_STATE.G_Safety_Gas_Latched THEN
    GVL_STATE.G_System_Mode := E_System_Operating_Mode.MODE_SAFE_STOP;

ELSIF GVL_STATE.G_Safety_Freeze_Risk THEN
    GVL_STATE.G_System_Mode := E_System_Operating_Mode.MODE_FREEZE_PROTECTION;

ELSIF GVL_STATE.G_Freeze_Hardware_Degraded OR GVL_STATUS.G_Diagnostics.IO_Offline THEN
    GVL_STATE.G_System_Mode := E_System_Operating_Mode.MODE_DEGRADED;

ELSE
    GVL_STATE.G_System_Mode := GVL_STATE.G_System_Mode;
END_IF;

// === AUTO-RECOVERY FROM DEGRADED ===
// Disabled in current compile pass: mode recovery is handled by PRG_System / StateManager.


// >>> BULK_SYNC_ANCHOR: PRG_Safety <<<
