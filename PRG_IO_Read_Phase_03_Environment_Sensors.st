PROGRAM PRG_IO_Read_Phase_03_Environment_Sensors
VAR
    L_i : INT;
    L_Filtered_Room_Temp : REAL;
    L_Filtered_Floor_Temp : REAL;

    fbCalib_Outdoor_Temp : FB_Sensor_Calibration_Processor;
    fbCalib_Supply_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_SUPPLY_TEMPS] OF FB_Sensor_Calibration_Processor;
    fbCalib_Room_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF FB_Sensor_Calibration_Processor;
    fbCalib_Floor_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF FB_Sensor_Calibration_Processor;
    fbCalib_Room_Hum : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF FB_Sensor_Calibration_Processor;
    fbCalib_Room_CO2 : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF FB_Sensor_Calibration_Processor;
END_VAR

fbCalib_Outdoor_Temp(
    VI_Raw_Value := GVL_IO.AI_Temp_Outdoor.rValue,
    VI_Record := GVL_CONFIG.G_Calib_Outdoor_Temp
);
GVL_STATE.G_Outdoor_Temp := fbCalib_Outdoor_Temp.VO_Calibrated_Value;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_TEMPS DO
    IF GVL_IO.AI_Supply_Temps[L_i].wStatus = 0 THEN
        fbCalib_Supply_Temps[L_i](
            VI_Raw_Value := GVL_IO.AI_Supply_Temps[L_i].rValue,
            VI_Record := GVL_CONFIG.G_Calib_Supply_Temps[L_i]
        );
        GVL_STATE.G_Supply_Temps[L_i] := fbCalib_Supply_Temps[L_i].VO_Calibrated_Value;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    fbCalib_Room_Hum[L_i](
        VI_Raw_Value := GVL_IO.AI_Room_Hum[L_i],
        VI_Record := GVL_CONFIG.G_Calib_Humidity[L_i]
    );
    GVL_STATE.G_Room_Hum[L_i] := fbCalib_Room_Hum[L_i].VO_Calibrated_Value;

    fbCalib_Room_CO2[L_i](
        VI_Raw_Value := GVL_IO.AI_Room_CO2[L_i],
        VI_Record := GVL_CONFIG.G_Calib_CO2[L_i]
    );
    GVL_STATE.G_Room_CO2[L_i] := fbCalib_Room_CO2[L_i].VO_Calibrated_Value;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    fbCalib_Room_Temps[L_i](
        VI_Raw_Value := GVL_IO.AI_Room_Temps[L_i],
        VI_Record := GVL_CONFIG.G_Calib_Room_Temps[L_i]
    );

    IF GVL_STATE.G_Last_Valid_Room_Temps[L_i] = 0.0 THEN
        L_Filtered_Room_Temp := fbCalib_Room_Temps[L_i].VO_Calibrated_Value;
    ELSE
        L_Filtered_Room_Temp := (GVL_STATE.G_Last_Valid_Room_Temps[L_i] * 0.9) + (fbCalib_Room_Temps[L_i].VO_Calibrated_Value * 0.1);
    END_IF;

    IF (L_Filtered_Room_Temp < -50.0) OR (L_Filtered_Room_Temp > 100.0) THEN
        GVL_STATE.G_Temp_Sensor_Fault[L_i] := TRUE;
        GVL_STATE.G_Room_Temps[L_i] := GVL_STATE.G_Last_Valid_Room_Temps[L_i];
        GVL_STATUS.G_Diagnostics.Sensor_Fault := TRUE;
    ELSE
        GVL_STATE.G_Temp_Sensor_Fault[L_i] := FALSE;
        GVL_STATE.G_Room_Temps[L_i] := L_Filtered_Room_Temp;
        GVL_STATE.G_Last_Valid_Room_Temps[L_i] := L_Filtered_Room_Temp;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    IF L_i <= GVL_CONSTANTS.C_MAX_ZONES THEN
        fbCalib_Floor_Temps[L_i](
            VI_Raw_Value := GVL_IO.AI_Floor_Temps[L_i],
            VI_Record := GVL_CONFIG.G_Calib_Floor_Temps[L_i]
        );

        IF GVL_STATE.G_Last_Valid_Floor_Temps[L_i] = 0.0 THEN
            L_Filtered_Floor_Temp := fbCalib_Floor_Temps[L_i].VO_Calibrated_Value;
        ELSE
            L_Filtered_Floor_Temp := (GVL_STATE.G_Last_Valid_Floor_Temps[L_i] * 0.9) + (fbCalib_Floor_Temps[L_i].VO_Calibrated_Value * 0.1);
        END_IF;

        IF (L_Filtered_Floor_Temp < -50.0) OR (L_Filtered_Floor_Temp > 100.0) THEN
            GVL_STATE.G_Floor_Temp_Sensor_Fault[L_i] := TRUE;
            GVL_STATE.G_Floor_Temps[L_i] := GVL_STATE.G_Last_Valid_Floor_Temps[L_i];
            GVL_STATUS.G_Diagnostics.Sensor_Fault := TRUE;
        ELSE
            GVL_STATE.G_Floor_Temp_Sensor_Fault[L_i] := FALSE;
            GVL_STATE.G_Floor_Temps[L_i] := L_Filtered_Floor_Temp;
            GVL_STATE.G_Last_Valid_Floor_Temps[L_i] := L_Filtered_Floor_Temp;
        END_IF;
    ELSE
        GVL_STATE.G_Floor_Temp_Sensor_Fault[L_i] := TRUE;
        GVL_STATE.G_Floor_Temps[L_i] := GVL_STATE.G_Last_Valid_Floor_Temps[L_i];
    END_IF;
END_FOR;

// >>> BULK_SYNC_ANCHOR: PRG_IO_Read_Phase_03_Environment_Sensors <<<
END_PROGRAM
