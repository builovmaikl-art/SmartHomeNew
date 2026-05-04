FUNCTION_BLOCK FB_Analog_Validator
VAR_INPUT
    VI_Value : REAL;
    VI_Min_Valid : REAL;
    VI_Max_Valid : REAL;
    VI_Fallback_Mode : INT := 0; // 0: Hold last good, 1: Default value
    VI_Default_Value : REAL := 0.0;
END_VAR
VAR_OUTPUT
    VO_Value : REAL;
    VO_Error : BOOL;
END_VAR
VAR
    L_Last_Good_Value : REAL;
    L_First_Valid : BOOL := FALSE;
END_VAR

IF VI_Value >= VI_Min_Valid AND VI_Value <= VI_Max_Valid THEN
    VO_Error := FALSE;
    VO_Value := VI_Value;
    L_Last_Good_Value := VI_Value;
    L_First_Valid := TRUE;
ELSE
    VO_Error := TRUE;
    IF VI_Fallback_Mode = 1 OR NOT L_First_Valid THEN
        VO_Value := VI_Default_Value;
    ELSE
        VO_Value := L_Last_Good_Value;
    END_IF;
END_IF;
// >>> BULK_SYNC_ANCHOR: FB_Analog_Validator <<<
