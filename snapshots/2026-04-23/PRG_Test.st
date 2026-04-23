PROGRAM PRG_Test
VAR
    // Инстансы тестируемых блоков
    fbAnalogValidator : FB_Analog_Validator;
    fbRandomGenerator : FB_Random_Generator;
    fbTwoFactorAuth   : FB_TwoFactor_Auth;
    
    // Переменные для тестов
    L_Test_Step : INT := 0;
    L_Tests_Passed : INT := 0;
    L_Tests_Failed : INT := 0;
    L_System_Time : UDINT := 0;
    
    // Результаты тестов
    L_Test1_Passed : BOOL;
    L_Test2_Passed : BOOL;
    L_Test3_Passed : BOOL;
END_VAR

// Имитация системного времени
L_System_Time := L_System_Time + 10;

CASE L_Test_Step OF
    0: // Инициализация
        L_Test_Step := 1;
        
    1: // Тест 1: FB_Analog_Validator - Нормальное значение
        fbAnalogValidator(
            VI_Value := 25.0,
            VI_Min_Valid := 0.0,
            VI_Max_Valid := 50.0,
            VI_Fallback_Mode := 0,
            VI_Default_Value := 20.0
        );
        IF fbAnalogValidator.VO_Valid AND fbAnalogValidator.VO_Validated_Value = 25.0 THEN
            L_Test1_Passed := TRUE;
            L_Tests_Passed := L_Tests_Passed + 1;
        ELSE
            L_Test1_Passed := FALSE;
            L_Tests_Failed := L_Tests_Failed + 1;
        END_IF;
        L_Test_Step := 2;
        
    2: // Тест 2: FB_Analog_Validator - Выход за границы (Fallback = Default)
        fbAnalogValidator(
            VI_Value := 100.0,
            VI_Min_Valid := 0.0,
            VI_Max_Valid := 50.0,
            VI_Fallback_Mode := 1,
            VI_Default_Value := 20.0
        );
        IF NOT fbAnalogValidator.VO_Valid AND fbAnalogValidator.VO_Validated_Value = 20.0 THEN
            L_Test2_Passed := TRUE;
            L_Tests_Passed := L_Tests_Passed + 1;
        ELSE
            L_Test2_Passed := FALSE;
            L_Tests_Failed := L_Tests_Failed + 1;
        END_IF;
        L_Test_Step := 3;
        
    3: // Тест 3: FB_Random_Generator - Диапазон
        fbRandomGenerator.Seed(12345);
        fbRandomGenerator.Random_Int_Range(VI_min := 10, VI_max := 20, VI_System_Time_MS := L_System_Time);
        IF fbRandomGenerator.VO_Random_Value >= 10 AND fbRandomGenerator.VO_Random_Value <= 20 THEN
            L_Test3_Passed := TRUE;
            L_Tests_Passed := L_Tests_Passed + 1;
        ELSE
            L_Test3_Passed := FALSE;
            L_Tests_Failed := L_Tests_Failed + 1;
        END_IF;
        L_Test_Step := 100; // Завершение тестов
        
    100: // Тесты завершены
        // Здесь можно вывести результаты в лог или HMI
        ;
END_CASE;
// >>> BULK_SYNC_ANCHOR: PRG_Test <<<
