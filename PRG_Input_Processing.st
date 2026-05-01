PROGRAM PRG_Input_Processing
VAR
    L_i : INT;
    L_TempDelta : REAL;
    L_HumDelta : REAL;
END_VAR

GVL_INPUT.IN_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;
GVL_INPUT.IN_Source_Valid := GVL_STATUS.G_Is_Active_PLC;

GVL_INPUT.IN_Validation_Failed := FALSE;
GVL_INPUT.IN_Anomaly_Detected := FALSE;
GVL_INPUT.IN_Validation_Reason := '';
GVL_INPUT.IN_Anomaly_Reason := '';
GVL_INPUT.IN_Last_Invalid_Zone := 0;

GVL_INPUT.IN_Min_Zone_Confidence := 1.0;
GVL_INPUT.IN_Worst_Zone := 0;

GVL_INPUT.IN_Input_Degraded := GVL_STATUS.G_Diagnostics.Subsystem_Degraded;
GVL_INPUT.IN_Sensor_Fault := GVL_STATUS.G_Diagnostics.Sensor_Fault;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO

    GVL_INPUT.IN_Room_Temps[L_i] := GVL_STATE.G_Room_Temps[L_i];
    GVL_INPUT.IN_Room_Hum[L_i] := GVL_STATE.G_Room_Hum[L_i];

    L_TempDelta := ABS(GVL_INPUT.IN_Room_Temps[L_i] - GVL_INPUT.IN_Room_Temp_Prev[L_i]);
    L_HumDelta := ABS(GVL_INPUT.IN_Room_Hum[L_i] - GVL_INPUT.IN_Room_Hum_Prev[L_i]);

    // Default confidence
    GVL_INPUT.IN_Room_Temp_Confidence[L_i] := 1.0;
    GVL_INPUT.IN_Room_Hum_Confidence[L_i] := 1.0;

    // Spike reduces confidence
    IF L_TempDelta > GVL_INPUT_VALIDATION_CONFIG.G_Room_Temp_Spike_Threshold THEN
        GVL_INPUT.IN_Room_Temp_Confidence[L_i] := 0.3;
        GVL_INPUT.IN_Anomaly_Detected := TRUE;
    END_IF;

    IF L_HumDelta > GVL_INPUT_VALIDATION_CONFIG.G_Room_Hum_Spike_Threshold THEN
        GVL_INPUT.IN_Room_Hum_Confidence[L_i] := 0.3;
        GVL_INPUT.IN_Anomaly_Detected := TRUE;
    END_IF;

    // Stuck reduces confidence
    IF L_TempDelta < GVL_INPUT_VALIDATION_CONFIG.G_Room_Temp_Stuck_Epsilon THEN
        IF (GVL_TIME_SERVICE.G_Now_MS - GVL_INPUT.IN_Last_Change_MS[L_i]) > GVL_INPUT_VALIDATION_CONFIG.G_Sensor_Stuck_Timeout_MS THEN
            GVL_INPUT.IN_Room_Temp_Confidence[L_i] := 0.2;
        END_IF;
    ELSE
        GVL_INPUT.IN_Last_Change_MS[L_i] := GVL_TIME_SERVICE.G_Now_MS;
    END_IF;

    // Combined zone confidence
    GVL_INPUT.IN_Zone_Confidence[L_i] :=
        (GVL_INPUT.IN_Room_Temp_Confidence[L_i] + GVL_INPUT.IN_Room_Hum_Confidence[L_i]) / 2.0;

    IF GVL_INPUT.IN_Zone_Confidence[L_i] < GVL_INPUT.IN_Min_Zone_Confidence THEN
        GVL_INPUT.IN_Min_Zone_Confidence := GVL_INPUT.IN_Zone_Confidence[L_i];
        GVL_INPUT.IN_Worst_Zone := L_i;
    END_IF;

    GVL_INPUT.IN_Room_Temp_Prev[L_i] := GVL_INPUT.IN_Room_Temps[L_i];
    GVL_INPUT.IN_Room_Hum_Prev[L_i] := GVL_INPUT.IN_Room_Hum[L_i];

END_FOR;

// >>> BULK_SYNC_ANCHOR: PRG_Input_Processing <<<
