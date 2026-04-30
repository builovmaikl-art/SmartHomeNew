FUNCTION_BLOCK FB_Heating_Local_Context
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_Heating_Emergency_Stop : BOOL;
    VI_Heating_Gas_Safety_Stop : BOOL;
    VI_DHW_Block : BOOL;
    VI_Freeze_Request : BOOL;
    VI_Preheat_Request : BOOL;
    VI_DHW_Heating_Pump_Feedback : BOOL;
    VI_Policy_Target_Adjustment : REAL;
    VI_Boiler_Modulation_Raw : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF INT;
END_VAR
VAR_OUTPUT
    VO_Boiler_Modulation_REAL : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL;
    VO_Heating_Emergency_Stop : BOOL;
    VO_Heating_Gas_Safety_Stop : BOOL;
    VO_Heating_DHW_Demand : BOOL;
    VO_Target_Temperature : REAL;
    VO_Local_Mode : INT;
END_VAR
VAR
    L_Last_Mode : INT := 0;
    L_Mode_Hold_Timer : FB_System_Timer;
    L_i : INT;
END_VAR

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    VO_Boiler_Modulation_REAL[L_i] := TO_REAL(VI_Boiler_Modulation_Raw[L_i]);
END_FOR;

VO_Heating_Emergency_Stop := VI_Heating_Emergency_Stop;
VO_Heating_Gas_Safety_Stop := VI_Heating_Gas_Safety_Stop;
VO_Heating_DHW_Demand := VI_DHW_Heating_Pump_Feedback;

IF VO_Heating_Emergency_Stop THEN
    VO_Heating_Gas_Safety_Stop := FALSE;
    VO_Heating_DHW_Demand := FALSE;
ELSIF VO_Heating_Gas_Safety_Stop THEN
    VO_Heating_DHW_Demand := FALSE;
ELSIF VI_DHW_Block THEN
    VO_Heating_DHW_Demand := FALSE;
END_IF;

L_Mode_Hold_Timer(IN := TRUE, PT := T#30s, VI_System_Time_MS := VI_System_Time_MS);

IF L_Mode_Hold_Timer.Q THEN
    IF VI_Freeze_Request THEN L_Last_Mode := 2;
    ELSIF VI_Preheat_Request THEN L_Last_Mode := 1;
    ELSE L_Last_Mode := 0;
    END_IF;
END_IF;

CASE L_Last_Mode OF
    2: VO_Target_Temperature := 5.0;
    1: VO_Target_Temperature := 22.0;
    ELSE VO_Target_Temperature := 20.0;
END_CASE;

VO_Target_Temperature := VO_Target_Temperature + VI_Policy_Target_Adjustment;
IF VO_Target_Temperature < 5.0 THEN VO_Target_Temperature := 5.0;
ELSIF VO_Target_Temperature > 26.0 THEN VO_Target_Temperature := 26.0;
END_IF;

VO_Local_Mode := L_Last_Mode;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Local_Context <<<
