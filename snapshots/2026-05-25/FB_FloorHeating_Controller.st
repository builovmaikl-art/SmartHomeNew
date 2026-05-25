FUNCTION_BLOCK FB_FloorHeating_Controller
VAR_INPUT
    VI_Current_Temp : REAL;
    VI_Config : ST_FloorHeating_Circuit_Config;
    VI_Tariff : ST_Tariff_Config;
    VI_Current_Hour : UINT;
    VI_IsActivePLC : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR_OUTPUT
    VO_Pump_Run : BOOL;
    VO_Valve_Pos : REAL; // 0..100%
    VO_Valve_Bool : BOOL; // ШИМ выход для термоэлектрического привода
    VO_Effective_Setpoint : REAL;
END_VAR
VAR
    L_Is_Night : BOOL;
    L_PID : FB_PID_Controller;
    L_Last_Time : UDINT;
    L_Cycle_Time_S : REAL;
    L_PWM_Period_MS : UDINT;
    L_PWM_Duty_MS : UDINT;
    L_Current_Phase_MS : UDINT;
    L_PWM_Start_Time : UDINT;
END_VAR

// Вычисление времени цикла
IF L_Last_Time = 0 THEN
    L_Last_Time := VI_System_Time_MS;
    L_Cycle_Time_S := 1.0;
ELSE
    L_Cycle_Time_S := UDINT_TO_REAL((SEL(VI_System_Time_MS >= L_Last_Time, VI_System_Time_MS - L_Last_Time, (4294967295 - L_Last_Time) + VI_System_Time_MS + 1))) / 1000.0;
    L_Last_Time := VI_System_Time_MS;
END_IF;
IF L_Cycle_Time_S <= 0.0 THEN L_Cycle_Time_S := 0.01; END_IF;

// 1. Определение активного тарифа
IF VI_Tariff.Enabled THEN
    IF VI_Tariff.Night_Start_Hour > VI_Tariff.Night_End_Hour THEN
        // Переход через полночь (например, 23:00 - 07:00)
        L_Is_Night := (VI_Current_Hour >= VI_Tariff.Night_Start_Hour) OR (VI_Current_Hour < VI_Tariff.Night_End_Hour);
    ELSE
        // В пределах одного дня
        L_Is_Night := (VI_Current_Hour >= VI_Tariff.Night_Start_Hour) AND (VI_Current_Hour < VI_Tariff.Night_End_Hour);
    END_IF;
ELSE
    L_Is_Night := FALSE;
END_IF;

// 2. Расчет эффективной уставки
VO_Effective_Setpoint := VI_Config.design_temp;
IF L_Is_Night THEN
    VO_Effective_Setpoint := VO_Effective_Setpoint + VI_Tariff.Boost_Delta;
END_IF;

// 3. ПИД-регулирование
L_PID(
    VI_SetPoint := VO_Effective_Setpoint,
    VI_ProcessValue := VI_Current_Temp,
    VI_Kp := VI_Config.pid_kp,
    VI_Tn := 300.0,
    VI_Tv := 0.0,
    VI_Y_Min := 0.0,
    VI_Y_Max := 100.0,
    VI_Cycle_Time_S := L_Cycle_Time_S,
    VO_Output => VO_Valve_Pos
);

// 4. ШИМ-модуляция для термоэлектрического привода
IF VI_Config.pwm_period_s > 0 THEN
    L_PWM_Period_MS := TO_UDINT(VI_Config.pwm_period_s) * 1000;
ELSE
    L_PWM_Period_MS := 600000; // 10 минут
END_IF;

L_Current_Phase_MS := (SEL(VI_System_Time_MS >= L_PWM_Start_Time, VI_System_Time_MS - L_PWM_Start_Time, (4294967295 - L_PWM_Start_Time) + VI_System_Time_MS + 1));
IF L_Current_Phase_MS >= L_PWM_Period_MS THEN
    L_PWM_Start_Time := VI_System_Time_MS - (L_Current_Phase_MS - L_PWM_Period_MS); // Сохраняем остаток для точности
    L_Current_Phase_MS := (SEL(VI_System_Time_MS >= L_PWM_Start_Time, VI_System_Time_MS - L_PWM_Start_Time, (4294967295 - L_PWM_Start_Time) + VI_System_Time_MS + 1));
END_IF;

L_PWM_Duty_MS := TO_UDINT((VO_Valve_Pos / 100.0) * TO_REAL(L_PWM_Period_MS));

IF VI_IsActivePLC THEN
    VO_Pump_Run := (VO_Valve_Pos > 5.0);
    
    IF VO_Valve_Pos >= 100.0 THEN
        VO_Valve_Bool := TRUE;
    ELSIF VO_Valve_Pos <= 0.0 THEN
        VO_Valve_Bool := FALSE;
    ELSE
        VO_Valve_Bool := (L_Current_Phase_MS <= L_PWM_Duty_MS);
    END_IF;
ELSE
    VO_Pump_Run := FALSE;
    VO_Valve_Bool := FALSE;
END_IF;
END_FUNCTION_BLOCK
