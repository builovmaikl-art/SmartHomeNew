PROGRAM PRG_Input_Processing
VAR
    L_i : INT;
END_VAR

GVL_INPUT.IN_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;
GVL_INPUT.IN_Source_Valid := GVL_STATUS.G_Is_Active_PLC;

// Reset validation flags
GVL_INPUT.IN_Validation_Failed := FALSE;
GVL_INPUT.IN_Anomaly_Detected := FALSE;
GVL_INPUT.IN_Validation_Reason := '';
GVL_INPUT.IN_Anomaly_Reason := '';
GVL_INPUT.IN_Last_Invalid_Zone := 0;

GVL_INPUT.IN_Input_Degraded := GVL_STATUS.G_Diagnostics.Subsystem_Degraded;
GVL_INPUT.IN_Sensor_Fault := GVL_STATUS.G_Diagnostics.Sensor_Fault;

GVL_INPUT.IN_Outdoor_Temp := GVL_STATE.G_Outdoor_Temp;
GVL_INPUT.IN_Preheat_Request := GVL_STATE.G_Preheat_Request;
GVL_INPUT.IN_Freeze_Request := GVL_STATE.G_Freeze_Request;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO

    GVL_INPUT.IN_Room_Temps[L_i] := GVL_STATE.G_Room_Temps[L_i];
    GVL_INPUT.IN_Floor_Temps[L_i] := GVL_STATE.G_Floor_Temps[L_i];
    GVL_INPUT.IN_Room_Hum[L_i] := GVL_STATE.G_Room_Hum[L_i];
    GVL_INPUT.IN_Room_CO2[L_i] := GVL_STATE.G_Room_CO2[L_i];

    IF GVL_INPUT_VALIDATION_CONFIG.G_Enable_Input_Validation THEN

        IF (GVL_INPUT.IN_Room_Hum[L_i] < GVL_INPUT_VALIDATION_CONFIG.G_Room_Hum_Min) OR
           (GVL_INPUT.IN_Room_Hum[L_i] > GVL_INPUT_VALIDATION_CONFIG.G_Room_Hum_Max) THEN
            GVL_INPUT.IN_Validation_Failed := TRUE;
            GVL_INPUT.IN_Input_Degraded := TRUE;
            GVL_INPUT.IN_Validation_Reason := 'Humidity out of range';
            GVL_INPUT.IN_Last_Invalid_Zone := L_i;
        END_IF;

        IF (GVL_INPUT.IN_Room_Temps[L_i] < GVL_INPUT_VALIDATION_CONFIG.G_Room_Temp_Min) OR
           (GVL_INPUT.IN_Room_Temps[L_i] > GVL_INPUT_VALIDATION_CONFIG.G_Room_Temp_Max) THEN
            GVL_INPUT.IN_Validation_Failed := TRUE;
            GVL_INPUT.IN_Input_Degraded := TRUE;
            GVL_INPUT.IN_Validation_Reason := 'Temperature out of range';
            GVL_INPUT.IN_Last_Invalid_Zone := L_i;
        END_IF;

    END_IF;

    IF GVL_INPUT_VALIDATION_CONFIG.G_Enable_Temporal_Anomaly_Detection THEN

        IF ABS(GVL_INPUT.IN_Room_Temps[L_i] - GVL_INPUT.IN_Room_Temp_Prev[L_i]) >
           GVL_INPUT_VALIDATION_CONFIG.G_Room_Temp_Spike_Threshold THEN
            GVL_INPUT.IN_Anomaly_Detected := TRUE;
            GVL_INPUT.IN_Anomaly_Reason := 'Temp spike';
        END_IF;

        IF ABS(GVL_INPUT.IN_Room_Hum[L_i] - GVL_INPUT.IN_Room_Hum_Prev[L_i]) >
           GVL_INPUT_VALIDATION_CONFIG.G_Room_Hum_Spike_Threshold THEN
            GVL_INPUT.IN_Anomaly_Detected := TRUE;
            GVL_INPUT.IN_Anomaly_Reason := 'Humidity spike';
        END_IF;

        IF ABS(GVL_INPUT.IN_Room_Temps[L_i] - GVL_INPUT.IN_Room_Temp_Prev[L_i]) <
           GVL_INPUT_VALIDATION_CONFIG.G_Room_Temp_Stuck_Epsilon THEN

            IF (GVL_TIME_SERVICE.G_Now_MS - GVL_INPUT.IN_Last_Change_MS[L_i]) >
               GVL_INPUT_VALIDATION_CONFIG.G_Sensor_Stuck_Timeout_MS THEN
                GVL_INPUT.IN_Anomaly_Detected := TRUE;
                GVL_INPUT.IN_Anomaly_Reason := 'Temp sensor stuck';
            END_IF;

        ELSE
            GVL_INPUT.IN_Last_Change_MS[L_i] := GVL_TIME_SERVICE.G_Now_MS;
        END_IF;

        IF (GVL_INPUT.IN_Room_Hum[L_i] > GVL_INPUT_VALIDATION_CONFIG.G_Condensation_Hum_Threshold) AND
           (GVL_INPUT.IN_Room_Temps[L_i] < GVL_INPUT_VALIDATION_CONFIG.G_Condensation_Temp_Threshold) THEN
            GVL_INPUT.IN_Anomaly_Detected := TRUE;
            GVL_INPUT.IN_Anomaly_Reason := 'Condensation anomaly';
        END_IF;

    END_IF;

    GVL_INPUT.IN_Room_Temp_Prev[L_i] := GVL_INPUT.IN_Room_Temps[L_i];
    GVL_INPUT.IN_Room_Hum_Prev[L_i] := GVL_INPUT.IN_Room_Hum[L_i];

END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO
    GVL_INPUT.IN_Water_Sensors[L_i] := GVL_STATE.G_Water_Sensors[L_i];
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SMOKE_SENSORS DO
    GVL_INPUT.IN_Smoke_Sensors[L_i] := GVL_STATE.G_Smoke_Sensors[L_i];
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_METHANE_SENSORS DO
    GVL_INPUT.IN_Methane_Sensors[L_i] := GVL_STATE.G_Methane_Sensors[L_i];
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_CO_SENSORS DO
    GVL_INPUT.IN_CO_Sensors[L_i] := GVL_STATE.G_CO_Sensors[L_i];
END_FOR;

// >>> BULK_SYNC_ANCHOR: PRG_Input_Processing <<<
