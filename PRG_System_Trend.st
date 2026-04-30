PROGRAM PRG_System_Trend
VAR
    fbTrendLogger : FB_Trend_Logger;
    fbTrendAdapter : FB_Trend_Adapter;
    L_TrendConfig : ST_Trend_Config;
    L_TrendData : ST_Trend_Data;
    L_Average : REAL;
    L_Min : REAL;
    L_Max : REAL;
    L_Trend_Up : BOOL;
    L_Trend_Down : BOOL;
END_VAR

// Minimal production trend channel: room temperature 1.
L_TrendConfig.enabled := TRUE;
L_TrendConfig.param_type := 1;
L_TrendConfig.zone_id := 1;
L_TrendConfig.deviation_threshold_percent := REAL#1.0;
L_TrendConfig.history_days := 7;

fbTrendLogger(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_Config := L_TrendConfig,
    VI_Current_Value := GVL_STATE.G_Room_Temps[1],
    VO_Data => L_TrendData
);

fbTrendAdapter(
    VI_Data := L_TrendData,
    VO_Average => L_Average,
    VO_Min => L_Min,
    VO_Max => L_Max,
    VO_Trend_Up => L_Trend_Up,
    VO_Trend_Down => L_Trend_Down
);

END_PROGRAM
