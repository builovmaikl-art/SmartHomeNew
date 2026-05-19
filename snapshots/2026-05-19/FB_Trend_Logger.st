FUNCTION_BLOCK FB_Trend_Logger
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_Config : ST_Trend_Config;
    VI_Current_Value : REAL;
END_VAR
VAR_OUTPUT
    VO_Data : ST_Trend_Data;
END_VAR
VAR
    L_Last_Log_Time : UDINT;
    L_Last_Value : REAL;
    L_Deviation : REAL;
    L_Elapsed_Time : UDINT;
    L_Write_Index : UDINT;
END_VAR

IF NOT VI_Config.enabled THEN
    RETURN;
END_IF;

L_Deviation := ABS(VI_Current_Value - L_Last_Value);
L_Elapsed_Time := SEL(
    VI_System_Time_MS >= L_Last_Log_Time,
    VI_System_Time_MS - L_Last_Log_Time,
    (4294967295 - L_Last_Log_Time) + VI_System_Time_MS + 1
);

IF (L_Deviation >= (ABS(L_Last_Value) * VI_Config.deviation_threshold_percent / REAL#100.0)) OR
   (L_Elapsed_Time >= GVL_CONSTANTS.C_MS_IN_HOUR) THEN

    L_Write_Index := (VO_Data.record_count MOD 100) + 1;
    VO_Data.write_index := L_Write_Index;
    VO_Data.values[L_Write_Index] := VI_Current_Value;
    VO_Data.timestamps[L_Write_Index] := VI_System_Time_MS;
    VO_Data.record_count := VO_Data.record_count + 1;
    VO_Data.sum_values := VO_Data.sum_values + VI_Current_Value;
    VO_Data.config := VI_Config;

    L_Last_Value := VI_Current_Value;
    L_Last_Log_Time := VI_System_Time_MS;
END_IF;

END_FUNCTION_BLOCK
