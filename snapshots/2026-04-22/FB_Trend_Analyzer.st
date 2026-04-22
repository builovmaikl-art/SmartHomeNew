FUNCTION_BLOCK FB_Trend_Analyzer
VAR_INPUT
    VI_Count      : INT;
END_VAR
VAR_IN_OUT
    VI_Data       : ARRAY[1..GVL_CONSTANTS.C_MAX_TREND_DATA_POINTS] OF REAL;
END_VAR
VAR_OUTPUT
    VO_Average    : REAL;
    VO_Max        : REAL;
    VO_Min        : REAL;
    VO_Trend_Up   : BOOL;
    VO_Trend_Down : BOOL;
END_VAR
VAR
    L_i   : INT;
    L_Sum : REAL;
END_VAR

IF VI_Count > 0 AND VI_Count <= GVL_CONSTANTS.C_MAX_TREND_DATA_POINTS THEN
    VO_Max := VI_Data[1];
    VO_Min := VI_Data[1];
    L_Sum := 0.0;
    
    FOR L_i := 1 TO VI_Count DO
        IF VI_Data[L_i] > VO_Max THEN VO_Max := VI_Data[L_i]; END_IF;
        IF VI_Data[L_i] < VO_Min THEN VO_Min := VI_Data[L_i]; END_IF;
        L_Sum := L_Sum + VI_Data[L_i];
    END_FOR;
    
    VO_Average := L_Sum / INT_TO_REAL(VI_Count);
    
    IF VI_Count >= 2 THEN
        VO_Trend_Up := (VI_Data[VI_Count] > VI_Data[1]);
        VO_Trend_Down := (VI_Data[VI_Count] < VI_Data[1]);
    END_IF;
END_IF;