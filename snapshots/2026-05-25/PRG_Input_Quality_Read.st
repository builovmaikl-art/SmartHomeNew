PROGRAM PRG_Input_Quality_Read
VAR
    L_i : INT;
    fbRoomTempQuality : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF FB_Input_Quality_Observer;
    fbFloorTempQuality : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF FB_Input_Quality_Observer;
END_VAR

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    fbRoomTempQuality[L_i](
        VI_Enable := GVL_INPUT_VALIDATION_CONFIG.G_Enable_Temporal_Anomaly_Detection,
        VI_Value := GVL_STATE.G_Room_Temps[L_i],
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
        VI_Spike_Threshold := GVL_INPUT_VALIDATION_CONFIG.G_Room_Temp_Spike_Threshold,
        VI_Stuck_Timeout_MS := GVL_INPUT_VALIDATION_CONFIG.G_Sensor_Stuck_Timeout_MS,
        VO_Quality => GVL_INPUT_QUALITY.G_Room_Temp_Quality[L_i]
    );
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    fbFloorTempQuality[L_i](
        VI_Enable := GVL_INPUT_VALIDATION_CONFIG.G_Enable_Temporal_Anomaly_Detection,
        VI_Value := GVL_STATE.G_Floor_Temps[L_i],
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
        VI_Spike_Threshold := GVL_INPUT_VALIDATION_CONFIG.G_Room_Temp_Spike_Threshold,
        VI_Stuck_Timeout_MS := GVL_INPUT_VALIDATION_CONFIG.G_Sensor_Stuck_Timeout_MS,
        VO_Quality => GVL_INPUT_QUALITY.G_Floor_Temp_Quality[L_i]
    );
END_FOR;

END_PROGRAM
