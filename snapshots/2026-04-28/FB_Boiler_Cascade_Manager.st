FUNCTION_BLOCK FB_Boiler_Cascade_Manager
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
    VI_Boiler_Stop : BOOL;

    VI_DHW_Heating_Demand : BOOL;
    VI_DHW_Target_Temp : REAL;

    VI_Target_Supply_Temp : REAL;
    VI_Demand_Power : REAL; // 0..500% (сумма запросов от 5 смесительных узлов)

    VI_Boiler_Flame_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VI_Boiler_Error_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VI_Boiler_OT_Online : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VI_Boiler_Modulation : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL;
END_VAR

VAR_OUTPUT
    VO_Boiler_Enable : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VO_Boiler_Setpoint : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL;
    VO_Lead_Boiler : BYTE;
END_VAR

VAR
    L_i : INT;
    L_Lead_Boiler : BYTE := 1;

    L_Last_Rotation_MS : UDINT := 0;
    L_Rotation_Initialized : BOOL := FALSE;
    L_Rotation_Period_MS : UDINT := 604800000; // 168h

    L_Lead_Available : BOOL;
    L_Reserve_Available : BOOL;
    L_Reserve_Boiler : BYTE;
    L_Start_Reserve : BOOL;
    L_Target_Setpoint : REAL;
    L_Flame_Miss_Timer : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF TON;
END_VAR

// Сброс выходов по умолчанию
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    VO_Boiler_Enable[L_i] := FALSE;
    VO_Boiler_Setpoint[L_i] := 0.0;
END_FOR;

// Инициализация ротации
IF NOT L_Rotation_Initialized THEN
    L_Last_Rotation_MS := VI_System_Time_MS;
    L_Rotation_Initialized := TRUE;
END_IF;

// Принудительная остановка
IF VI_Boiler_Stop THEN
    VO_Lead_Boiler := L_Lead_Boiler;
    RETURN;
END_IF;

// Ротация строго каждые 168 часов
IF (VI_System_Time_MS - L_Last_Rotation_MS) >= L_Rotation_Period_MS THEN
    IF GVL_CONSTANTS.C_MAX_BOILERS > 1 THEN
        L_Lead_Boiler := 3 - L_Lead_Boiler;
    END_IF;
    L_Last_Rotation_MS := VI_System_Time_MS;
END_IF;

L_Reserve_Boiler := SEL(L_Lead_Boiler = 1, 1, 2);

L_Lead_Available :=
    VI_Boiler_OT_Online[L_Lead_Boiler] AND
    NOT VI_Boiler_Error_Status[L_Lead_Boiler];

L_Reserve_Available :=
    (GVL_CONSTANTS.C_MAX_BOILERS > 1) AND
    VI_Boiler_OT_Online[L_Reserve_Boiler] AND
    NOT VI_Boiler_Error_Status[L_Reserve_Boiler];

// Контроль "команда есть, пламени нет" для ведущего котла
L_Flame_Miss_Timer[L_Lead_Boiler](
    IN := VI_Enable AND L_Lead_Available AND NOT VI_DHW_Heating_Demand AND NOT VI_Boiler_Flame_Status[L_Lead_Boiler],
    PT := T#120s
);

IF L_Flame_Miss_Timer[L_Lead_Boiler].Q AND L_Reserve_Available THEN
    L_Lead_Boiler := L_Reserve_Boiler;
    L_Last_Rotation_MS := VI_System_Time_MS;
    L_Lead_Available :=
        VI_Boiler_OT_Online[L_Lead_Boiler] AND
        NOT VI_Boiler_Error_Status[L_Lead_Boiler];
    L_Reserve_Boiler := SEL(L_Lead_Boiler = 1, 1, 2);
    L_Reserve_Available :=
        (GVL_CONSTANTS.C_MAX_BOILERS > 1) AND
        VI_Boiler_OT_Online[L_Reserve_Boiler] AND
        NOT VI_Boiler_Error_Status[L_Reserve_Boiler];
END_IF;

// Нет запроса тепла
IF NOT VI_Enable THEN
    VO_Lead_Boiler := L_Lead_Boiler;
    RETURN;
END_IF;

// Целевая уставка
IF VI_DHW_Heating_Demand THEN
    L_Target_Setpoint := LIMIT(20.0, VI_DHW_Target_Temp + 15.0, 85.0);
ELSE
    L_Target_Setpoint := LIMIT(20.0, VI_Target_Supply_Temp + 5.0, 80.0);
END_IF;

// Выбор ведущего по доступности
IF NOT L_Lead_Available AND L_Reserve_Available THEN
    L_Lead_Boiler := L_Reserve_Boiler;
    L_Lead_Available := TRUE;
    L_Reserve_Boiler := SEL(L_Lead_Boiler = 1, 1, 2);
    L_Reserve_Available :=
        (GVL_CONSTANTS.C_MAX_BOILERS > 1) AND
        VI_Boiler_OT_Online[L_Reserve_Boiler] AND
        NOT VI_Boiler_Error_Status[L_Reserve_Boiler];
END_IF;

// Основной котёл
IF L_Lead_Available THEN
    VO_Boiler_Enable[L_Lead_Boiler] := TRUE;
    VO_Boiler_Setpoint[L_Lead_Boiler] := L_Target_Setpoint;
END_IF;

// Резервный котёл: >80% или отказ основного
L_Start_Reserve :=
    L_Reserve_Available AND
    (
        (VI_Demand_Power > 80.0) OR
        (NOT L_Lead_Available)
    );

IF L_Start_Reserve THEN
    VO_Boiler_Enable[L_Reserve_Boiler] := TRUE;
    VO_Boiler_Setpoint[L_Reserve_Boiler] := L_Target_Setpoint;
END_IF;

VO_Lead_Boiler := L_Lead_Boiler;
