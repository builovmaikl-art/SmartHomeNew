FUNCTION_BLOCK FB_DHW_Manager
VAR_INPUT
    VI_System_Time_MS : UDINT; // Системное время (мс)
    VI_Current_TOD : TOD; // Текущее время суток
    VI_IsActivePLC : BOOL; // Флаг: Данный ПЛК является ведущим
    VI_Temp : REAL; // Текущая температура воды в бойлере (°C)
    VI_Pressure : REAL; // Текущее давление в системе ГВС (бар)
    VI_Config : ST_DHW_Config; // Конфигурация системы ГВС (уставки, расписание)
    VI_Current_Day_Of_Week : UINT; // Текущий день недели (1-7)
    VI_Reset_Errors : BOOL; // Сброс ошибок
    VI_Emergency_Stop : BOOL; // Агрегированный аварийный стоп от подсистемы безопасности
    VI_System_Mode : E_System_Operating_Mode; // Агрегированный режим системы
    VI_IO_Modules_Online : ARRAY[1..GVL_CONSTANTS.C_MAX_MODULES] OF BOOL; // Статусы модулей ввода-вывода (только чтение)
END_VAR
// >>> SYNC_TEST_MARKER_001 <<<
VAR_OUTPUT
    VO_Status : ST_DHW_Status; // Сводный статус системы ГВС для HMI
    VO_Heating_Pump : BOOL; // Выход: Управление насосом нагрева (загрузка бойлера)
    VO_Circ_Pump : BOOL; // Выход: Управление насосом рециркуляции ГВС
END_VAR
VAR
    // DHW V2 staging layer
    fbDHWV2Staging : FB_DHW_V2_Staging;
    L_DHW_V2_Command_V2 : ST_DHW_Command_V2;
    L_DHW_V2_State_V2 : ST_DHW_State_V2;
    L_DHW_V2_Shadow_Diff_Found : BOOL;
    L_DHW_V2_Switch_Enabled : BOOL;
    L_DHW_V2_Path_Ready : BOOL;
    L_DHW_Using_Legacy_Fallback : BOOL;
    L_i : INT;
    L_Current_TOD : TOD; // Текущее время суток
    L_Legionella_Active : BOOL; // Флаг активного режима термической дезинфекции (Легионелла)
    L_Legionella_Timer : FB_System_Timer; // Таймер удержания температуры для дезинфекции
    L_Last_Good_Temp : REAL := 55.0; // Последнее достоверное значение температуры (для Fallback)
    L_Legionella_Done_Today : BOOL; // Признак выполнения термодезинфекции в текущие сутки
    L_Last_Legionella_Day : UINT; // День недели последнего сброса/контроля цикла легионеллы
    fbTempValidator : FB_Analog_Validator;
    fbPressValidator : FB_Analog_Validator;
    L_Error_Latched : BOOL;
    L_Error_ID_Latched : WORD;
    L_Policy_Degraded : BOOL;
    L_Policy_Freeze_Protection : BOOL;
    L_Policy_Safe_Stop : BOOL;
    L_Target_Temp_Adjusted : REAL;
END_VAR

IF NOT VI_IsActivePLC THEN RETURN; END_IF;

L_DHW_V2_Shadow_Diff_Found := FALSE;
L_DHW_V2_Switch_Enabled := TRUE;
L_DHW_V2_Path_Ready := FALSE;
L_DHW_Using_Legacy_Fallback := TRUE;

GVL_STATE.G_DHW_IO_Fault := FALSE;
GVL_STATE.G_DHW_Sensor_Fault := FALSE;
GVL_STATE.G_DHW_Subsystem_Degraded := FALSE;

IF VI_Emergency_Stop THEN
    VO_Heating_Pump := FALSE;
    VO_Circ_Pump := FALSE;
    VO_Status.Warning := FALSE;
    VO_Status.Error := TRUE;
    VO_Status.Error_ID := TO_WORD(GVL_CONFIG.ERR_DHW_IO_OFFLINE); // временно используем общий аварийный код до детализации safety-кодов
    VO_Status.Heating_Pump_On := FALSE;
    VO_Status.Circ_Pump_On := FALSE;
    RETURN;
END_IF;

// Фиксация текущего времени
L_Current_TOD := VI_Current_TOD;

// ========================================
// DHW POLICY LAYER
// ========================================
L_Policy_Safe_Stop := (VI_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP);
L_Policy_Freeze_Protection := (VI_System_Mode = E_System_Operating_Mode.MODE_FREEZE_PROTECTION);
L_Policy_Degraded := (VI_System_Mode = E_System_Operating_Mode.MODE_DEGRADED);
L_Target_Temp_Adjusted := VI_Config.Target_Temp;
IF L_Policy_Degraded THEN
    L_Target_Temp_Adjusted := VI_Config.Target_Temp - VI_Config.Degraded_Target_Delta;
END_IF;

// ========================================
// DHW POLICY OVERRIDE
// ========================================
IF L_Policy_Safe_Stop THEN
    VO_Heating_Pump := FALSE;
    VO_Circ_Pump := FALSE;
    RETURN;
END_IF;

IF L_Policy_Freeze_Protection THEN
    VO_Heating_Pump := FALSE;
    VO_Circ_Pump := FALSE;
    RETURN;
END_IF;

// Сброс признака выполнения термодезинфекции при смене дня.
IF L_Last_Legionella_Day <> VI_Current_Day_Of_Week THEN
    L_Legionella_Done_Today := FALSE;
    L_Last_Legionella_Day := VI_Current_Day_Of_Week;
END_IF;

// Базовый сброс незащёлкнутых статусных флагов на текущий цикл.
// Критические ошибки ниже могут зафиксироваться и завершить выполнение через RETURN.
VO_Status.Warning := FALSE;
VO_Status.Error := FALSE;
VO_Status.Error_ID := 0;

// Сброс ошибок
IF VI_Reset_Errors THEN
    L_Error_Latched := FALSE;
    L_Error_ID_Latched := 0;
END_IF;

// Проверка связи с модулями ввода-вывода
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MODULES DO
    IF NOT VI_IO_Modules_Online[L_i] THEN
        L_Error_Latched := TRUE;
        GVL_STATE.G_DHW_IO_Fault := TRUE;
        L_Error_ID_Latched := TO_WORD(GVL_CONFIG.ERR_DHW_IO_OFFLINE); // Потеря связи с модулями ввода-вывода
    END_IF;
END_FOR;

// 1. Обработка неисправностей датчиков и сервисных режимов (ТЗ 7.0)
fbTempValidator(
    VI_Value := VI_Temp,
    VI_Min_Valid := 0.0,
    VI_Max_Valid := 100.0,
    VI_Fallback_Mode := 0,
    VI_Default_Value := 55.0
);

fbPressValidator(
    VI_Value := VI_Pressure,
    VI_Min_Valid := 0.0,
    VI_Max_Valid := 10.0,
    VI_Fallback_Mode := 0
);

VO_Status.Temp := fbTempValidator.VO_Value;
VO_Status.Pressure := fbPressValidator.VO_Value;

// Сохраняем последнее достоверное значение температуры ГВС.
// Используется только для диагностики/сервиса, не для fallback-управления.
IF NOT fbTempValidator.VO_Error THEN
    L_Last_Good_Temp := VO_Status.Temp;
END_IF;

IF fbTempValidator.VO_Error THEN
    GVL_STATE.G_DHW_Sensor_Fault := TRUE;
    L_Error_Latched := TRUE;
    L_Error_ID_Latched := TO_WORD(GVL_CONFIG.ERR_DHW_TEMP_SENSOR_FAULT); // Критическая ошибка датчика температуры
ELSIF (VO_Status.Pressure < 1.0 OR VO_Status.Pressure > 4.0) AND NOT fbPressValidator.VO_Error THEN
    L_Error_Latched := TRUE;
    L_Error_ID_Latched := TO_WORD(GVL_CONFIG.ERR_DHW_PRESSURE_OUT_OF_RANGE); // Давление вне нормы
END_IF;

IF L_Error_Latched THEN
    // Критическая ошибка: переход в безопасное состояние с полной остановкой насосов.
    VO_Heating_Pump := FALSE;
    VO_Circ_Pump := FALSE;
    VO_Status.Warning := FALSE;
    VO_Status.Error := TRUE;
    VO_Status.Error_ID := L_Error_ID_Latched;
    VO_Status.Heating_Pump_On := FALSE;
    VO_Status.Circ_Pump_On := FALSE;
    RETURN;
END_IF;

// Ошибка датчика давления не останавливает ГВС,
// но переводит подсистему в режим предупреждения (degraded mode).
IF fbPressValidator.VO_Error THEN
    GVL_STATE.G_DHW_Sensor_Fault := TRUE;
    GVL_STATE.G_DHW_Subsystem_Degraded := TRUE;
    VO_Status.Warning := TRUE;
    VO_Status.Error := FALSE;
    VO_Status.Error_ID := TO_WORD(GVL_CONFIG.ERR_DHW_PRESSURE_SENSOR_FAULT);
END_IF;

// 2. Логика поддержания температуры воды в бойлере (Нагрев)
// На этом этапе FB уже выполняется только на активном ПЛК.
    
// Термическая дезинфекция (Легионелла)
IF VI_Config.Anti_Legionella_Enabled
   AND (VI_Current_Day_Of_Week = VI_Config.Anti_Legionella_Day)
   AND (L_Current_TOD >= TOD#02:00)
   AND (L_Current_TOD <= TOD#04:00)
   AND NOT L_Legionella_Done_Today THEN
    L_Legionella_Active := TRUE;
ELSE
    L_Legionella_Active := FALSE;
END_IF;

L_Legionella_Timer(IN := L_Legionella_Active AND VO_Status.Temp >= 70.0, PT := T#30m, VI_System_Time_MS := VI_System_Time_MS);
IF L_Legionella_Timer.Q THEN
    L_Legionella_Active := FALSE; // Дезинфекция завершена
    L_Legionella_Done_Today := TRUE; // Повторно в те же сутки не запускать
END_IF;

// Двухпозиционное регулирование с гистерезисом
IF L_Legionella_Active THEN
    IF VO_Status.Temp < 70.0 THEN
        VO_Heating_Pump := TRUE;
    ELSIF VO_Status.Temp > 72.0 THEN
        VO_Heating_Pump := FALSE;
    END_IF;
ELSE
    IF VO_Status.Temp < (L_Target_Temp_Adjusted - VI_Config.Hysteresis) THEN
        VO_Heating_Pump := TRUE;
    ELSIF VO_Status.Temp > (L_Target_Temp_Adjusted + VI_Config.Hysteresis) THEN
        VO_Heating_Pump := FALSE;
    END_IF;
END_IF;

// 3. Управление циркуляционным насосом ГВС по расписанию
// Рециркуляция обеспечивает мгновенное наличие горячей воды у потребителя
VO_Circ_Pump := SEL(VI_Config.Circulation_Schedule_Enabled AND NOT (VI_Config.Night_Mode_Enabled AND (L_Current_TOD < VI_Config.Circulation_Start OR L_Current_TOD > VI_Config.Circulation_End)), FALSE, TRUE);

// Формирование статусных данных для визуализации.
// К этому моменту статус уже консистентен:
// - Error = критическая ошибка с остановкой ГВС
// - Warning = деградация без остановки
VO_Status.Heating_Pump_On := VO_Heating_Pump;
VO_Status.Circ_Pump_On := VO_Circ_Pump;

// ========================================
// DHW V2 staging execution
// ========================================
fbDHWV2Staging(
    VI_Tank_ID := 1,
    VI_Enable := TRUE,
    VI_Target_Temp := VI_Config.Target_Temp,
    VI_Pump_Enable := VO_Heating_Pump,
    VI_Heating_Priority := FALSE,

    VI_Is_Active := VO_Heating_Pump,
    VI_Tank_Temp := VO_Status.Temp,
    VI_Supply_Temp := VO_Status.Pressure,
    VI_Return_Temp := VO_Status.Temp,
    VI_Pump_Actual := VO_Heating_Pump,
    VI_Alarm_Active := VO_Status.Error,

    VO_Command_Shadow => L_DHW_V2_Command_V2,
    VO_State_Shadow => L_DHW_V2_State_V2
);

// ========================================
// DHW V2 staging validation
// ========================================
IF VO_Heating_Pump <> (L_DHW_V2_Command_V2.Pump_Enable > 0.5) THEN
    L_DHW_V2_Shadow_Diff_Found := TRUE;
END_IF;
IF ABS(VO_Status.Temp - L_DHW_V2_State_V2.Tank_Temp) > 0.1 THEN
    L_DHW_V2_Shadow_Diff_Found := TRUE;
END_IF;
IF ABS(VO_Status.Pressure - L_DHW_V2_State_V2.Supply_Temp) > 0.1 THEN
    L_DHW_V2_Shadow_Diff_Found := TRUE;
END_IF;

// Guarded DHW V2 enable
IF L_DHW_V2_Switch_Enabled THEN
    IF NOT L_DHW_V2_Shadow_Diff_Found THEN
        L_DHW_V2_Path_Ready := TRUE;
        L_DHW_Using_Legacy_Fallback := FALSE;
    ELSE
        L_DHW_V2_Path_Ready := FALSE;
        L_DHW_Using_Legacy_Fallback := TRUE;
    END_IF;
ELSE
    L_DHW_V2_Path_Ready := FALSE;
    L_DHW_Using_Legacy_Fallback := TRUE;
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_DHW_Manager <<<
