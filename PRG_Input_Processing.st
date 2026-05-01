PROGRAM PRG_Input_Processing
VAR
    L_i : INT;
END_VAR

// This layer is a normalized read-model between PRG_IO_Read/GVL_STATE and higher-level logic.

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

    // Validation: humidity range
    IF (GVL_INPUT.IN_Room_Hum[L_i] < 0.0) OR (GVL_INPUT.IN_Room_Hum[L_i] > 100.0) THEN
        GVL_INPUT.IN_Validation_Failed := TRUE;
        GVL_INPUT.IN_Input_Degraded := TRUE;
        GVL_INPUT.IN_Validation_Reason := 'Humidity out of range';
        GVL_INPUT.IN_Last_Invalid_Zone := L_i;
    END_IF;

    // Validation: temperature range (basic plausibility)
    IF (GVL_INPUT.IN_Room_Temps[L_i] < -40.0) OR (GVL_INPUT.IN_Room_Temps[L_i] > 80.0) THEN
        GVL_INPUT.IN_Validation_Failed := TRUE;
        GVL_INPUT.IN_Input_Degraded := TRUE;
        GVL_INPUT.IN_Validation_Reason := 'Temperature out of range';
        GVL_INPUT.IN_Last_Invalid_Zone := L_i;
    END_IF;

    // Anomaly: impossible combination (high humidity + very low temp)
    IF (GVL_INPUT.IN_Room_Hum[L_i] > 90.0) AND (GVL_INPUT.IN_Room_Temps[L_i] < 0.0) THEN
        GVL_INPUT.IN_Anomaly_Detected := TRUE;
        GVL_INPUT.IN_Anomaly_Reason := 'Condensation anomaly';
    END_IF;

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
