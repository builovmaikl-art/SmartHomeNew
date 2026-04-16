FUNCTION_BLOCK FB_Calibration_Manager
VAR_INPUT
    VI_Raw_Value : REAL;
    VI_Type : BYTE; // 1-Temp, 2-Pressure, 3-Gas
    VI_Calib_Record : ST_Sensor_Calibration_Record;
    VI_System_Time_MS : UDINT;
    VI_Start_Verification : BOOL;
END_VAR
VAR_OUTPUT
    VO_Calibrated_Value : REAL;
    VO_Verification_Active : BOOL;
    VO_Verification_Failed : BOOL;
    VO_Deviation_Percent : REAL;
END_VAR
VAR
    L_Verification_Timer : FB_System_Timer;
    L_Initial_Value : REAL;
END_VAR

// 1. Расчет калиброванного значения
CASE VI_Type OF
    1: VO_Calibrated_Value := VI_Raw_Value + VI_Calib_Record.offset;
    2, 3: VO_Calibrated_Value := (VI_Raw_Value * VI_Calib_Record.multiplier) + VI_Calib_Record.offset;
END_CASE;

// 2. Верификация через 1 час (ТЗ 9.5)
IF VI_Start_Verification AND NOT VO_Verification_Active THEN
    VO_Verification_Active := TRUE;
    L_Initial_Value := VO_Calibrated_Value;
END_IF;

L_Verification_Timer(IN := VO_Verification_Active, PT := T#1h, VI_System_Time_MS := VI_System_Time_MS);

IF L_Verification_Timer.Q THEN
    VO_Verification_Active := FALSE;
    
    // ТЗ 9.5: Отклонение ≤2.0% (норма) / >5.0% (ошибка)
    IF L_Initial_Value <> 0 THEN
        VO_Deviation_Percent := ABS(VO_Calibrated_Value - L_Initial_Value) / L_Initial_Value * 100.0;
    ELSE
        VO_Deviation_Percent := 0.0;
    END_IF;
    
    VO_Verification_Failed := (VO_Deviation_Percent > 5.0);
END_IF;