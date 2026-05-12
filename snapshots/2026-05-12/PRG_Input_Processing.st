PROGRAM PRG_Input_Processing
VAR
    L_i : INT;
    L_TempDelta : REAL;
    L_HumDelta : REAL;
END_VAR

GVL_INPUT.IN_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;
GVL_INPUT.IN_Source_Valid := GVL_STATUS.G_Is_Active_PLC;

// RESET FLAGS
GVL_INPUT.IN_Validation_Failed := FALSE;
GVL_INPUT.IN_Anomaly_Detected := FALSE;
GVL_INPUT.IN_Validation_Reason := '';
GVL_INPUT.IN_Anomaly_Reason := '';
GVL_INPUT.IN_Last_Invalid_Zone := 0;
GVL_INPUT.IN_Input_Degraded := FALSE;
GVL_INPUT.IN_Sensor_Fault := FALSE;

GVL_INPUT.IN_Min_Zone_Confidence := 1.0;
GVL_INPUT.IN_Worst_Zone := 0;

// ======================================================
// BASE ENVIRONMENT INPUT AGGREGATION
// ======================================================
GVL_INPUT.IN_Outdoor_Temp := GVL_STATE.G_Outdoor_Temp;
GVL_INPUT.IN_Preheat_Request := GVL_STATE.G_Preheat_Request;
GVL_INPUT.IN_Freeze_Request := GVL_STATE.G_Freeze_Request;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    GVL_INPUT.IN_Room_Temps[L_i] := GVL_STATE.G_Room_Temps[L_i];
    GVL_INPUT.IN_Room_Hum[L_i] := GVL_STATE.G_Room_Hum[L_i];
    GVL_INPUT.IN_Room_CO2[L_i] := GVL_STATE.G_Room_CO2[L_i];

    IF L_i <= GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS THEN
        GVL_INPUT.IN_Floor_Temps[L_i] := GVL_STATE.G_Floor_Temps[L_i];
    END_IF;

    // VALIDATION
    IF (GVL_INPUT.IN_Room_Temps[L_i] < GVL_INPUT_VALIDATION_CONFIG.G_Room_Temp_Min) OR
       (GVL_INPUT.IN_Room_Temps[L_i] > GVL_INPUT_VALIDATION_CONFIG.G_Room_Temp_Max) THEN
        GVL_INPUT.IN_Validation_Failed := TRUE;
        GVL_INPUT.IN_Input_Degraded := TRUE;
        GVL_INPUT.IN_Sensor_Fault := TRUE;
        GVL_INPUT.IN_Validation_Reason := 'Temp out of range';
        GVL_INPUT.IN_Last_Invalid_Zone := L_i;
    END_IF;

    IF (GVL_INPUT.IN_Room_Hum[L_i] < GVL_INPUT_VALIDATION_CONFIG.G_Room_Hum_Min) OR
       (GVL_INPUT.IN_Room_Hum[L_i] > GVL_INPUT_VALIDATION_CONFIG.G_Room_Hum_Max) THEN
        GVL_INPUT.IN_Validation_Failed := TRUE;
        GVL_INPUT.IN_Input_Degraded := TRUE;
        GVL_INPUT.IN_Sensor_Fault := TRUE;
        GVL_INPUT.IN_Validation_Reason := 'Hum out of range';
        GVL_INPUT.IN_Last_Invalid_Zone := L_i;
    END_IF;

    L_TempDelta := ABS(GVL_INPUT.IN_Room_Temps[L_i] - GVL_INPUT.IN_Room_Temp_Prev[L_i]);
    L_HumDelta := ABS(GVL_INPUT.IN_Room_Hum[L_i] - GVL_INPUT.IN_Room_Hum_Prev[L_i]);

    // INSTANT CONFIDENCE
    GVL_INPUT.IN_Room_Temp_Confidence[L_i] := GVL_INPUT_VALIDATION_CONFIG.G_Default_Confidence;
    GVL_INPUT.IN_Room_Hum_Confidence[L_i] := GVL_INPUT_VALIDATION_CONFIG.G_Default_Confidence;

    IF L_TempDelta > GVL_INPUT_VALIDATION_CONFIG.G_Room_Temp_Spike_Threshold THEN
        GVL_INPUT.IN_Room_Temp_Confidence[L_i] := GVL_INPUT_VALIDATION_CONFIG.G_Bad_Spike_Confidence;
        GVL_INPUT.IN_Anomaly_Detected := TRUE;
        GVL_INPUT.IN_Anomaly_Reason := 'Temp spike';
    END_IF;

    IF L_HumDelta > GVL_INPUT_VALIDATION_CONFIG.G_Room_Hum_Spike_Threshold THEN
        GVL_INPUT.IN_Room_Hum_Confidence[L_i] := GVL_INPUT_VALIDATION_CONFIG.G_Bad_Spike_Confidence;
        GVL_INPUT.IN_Anomaly_Detected := TRUE;
        GVL_INPUT.IN_Anomaly_Reason := 'Hum spike';
    END_IF;

    // REPUTATION
    IF GVL_INPUT_VALIDATION_CONFIG.G_Enable_Reputation_Learning THEN
        GVL_INPUT.IN_Room_Temp_Reputation[L_i] :=
            GVL_INPUT.IN_Room_Temp_Reputation[L_i] * (1.0 - GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Learning_Rate) +
            GVL_INPUT.IN_Room_Temp_Confidence[L_i] * GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Learning_Rate;

        GVL_INPUT.IN_Room_Hum_Reputation[L_i] :=
            GVL_INPUT.IN_Room_Hum_Reputation[L_i] * (1.0 - GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Learning_Rate) +
            GVL_INPUT.IN_Room_Hum_Confidence[L_i] * GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Learning_Rate;

        GVL_INPUT.IN_Room_Temp_Reputation[L_i] :=
            GVL_INPUT.IN_Room_Temp_Reputation[L_i] +
            (1.0 - GVL_INPUT.IN_Room_Temp_Reputation[L_i]) * GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Recovery_Decay;

        GVL_INPUT.IN_Room_Hum_Reputation[L_i] :=
            GVL_INPUT.IN_Room_Hum_Reputation[L_i] +
            (1.0 - GVL_INPUT.IN_Room_Hum_Reputation[L_i]) * GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Recovery_Decay;
    END_IF;

    IF GVL_INPUT.IN_Room_Temp_Reputation[L_i] < GVL_INPUT_VALIDATION_CONFIG.G_Min_Sensor_Confidence THEN
        GVL_INPUT.IN_Room_Temp_Reputation[L_i] := GVL_INPUT_VALIDATION_CONFIG.G_Min_Sensor_Confidence;
    END_IF;

    IF GVL_INPUT.IN_Room_Hum_Reputation[L_i] < GVL_INPUT_VALIDATION_CONFIG.G_Min_Sensor_Confidence THEN
        GVL_INPUT.IN_Room_Hum_Reputation[L_i] := GVL_INPUT_VALIDATION_CONFIG.G_Min_Sensor_Confidence;
    END_IF;

    // FINAL
    GVL_INPUT.IN_Zone_Confidence[L_i] :=
        (GVL_INPUT.IN_Room_Temp_Confidence[L_i] * GVL_INPUT.IN_Room_Temp_Reputation[L_i] +
         GVL_INPUT.IN_Room_Hum_Confidence[L_i] * GVL_INPUT.IN_Room_Hum_Reputation[L_i]) / 2.0;

    IF GVL_INPUT.IN_Zone_Confidence[L_i] < GVL_INPUT.IN_Min_Zone_Confidence THEN
        GVL_INPUT.IN_Min_Zone_Confidence := GVL_INPUT.IN_Zone_Confidence[L_i];
        GVL_INPUT.IN_Worst_Zone := L_i;
    END_IF;

    GVL_INPUT.IN_Room_Temp_Prev[L_i] := GVL_INPUT.IN_Room_Temps[L_i];
    GVL_INPUT.IN_Room_Hum_Prev[L_i] := GVL_INPUT.IN_Room_Hum[L_i];
END_FOR;

// ======================================================
// SAFETY SENSOR INPUT AGGREGATION
// ======================================================
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
END_PROGRAM
