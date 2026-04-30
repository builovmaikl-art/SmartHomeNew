PROGRAM PRG_System_Trend
VAR
    fbTrendLogger : FB_Trend_Logger;
    L_TrendData : ST_Trend_Data;
END_VAR

// minimal trend: log room temperature 1
fbTrendLogger(
    VI_Value := GVL_STATE.G_Room_Temps[1],
    VIO_Trend_Data := L_TrendData
);

END_PROGRAM
