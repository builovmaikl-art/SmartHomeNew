PROGRAM PRG_Input_Processing
VAR
    L_i : INT;
    L_TempDelta : REAL;
    L_HumDelta : REAL;
    L_LearningRate : REAL := 0.05;
    L_Decay : REAL := 0.01;
    L_MinConf : REAL := 0.1;
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

GVL_INPUT.IN_Min_Zone_Confidence := 1.0;
GVL_INPUT.IN_Worst_Zone := 0;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO

    GVL_INPUT.IN_Room_Temps[L_i] := GVL_STATE.G_Room_Temps[L_i];
    GVL_INPUT.IN_Room_Hum[L_i] := GVL_STATE.G_Room_Hum[L_i];

    // -----------------------------
    // VALIDATION (RESTORED)
    // -----------------------------

    IF (GVL_INPUT.IN_Room_Temps[L_i] < -40.0) OR (GVL_INPUT.IN_Room_Temps[L_i] > 80.0) THEN
        GVL_INPUT.IN_Validation_Failed := TRUE;
        GVL_INPUT.IN_Input_Degraded := TRUE;
        GVL_INPUT.IN_Validation_Reason := 'Temp out of range';
        GVL_INPUT.IN_Last_Invalid_Zone := L_i;
    END_IF;

    IF (GVL_INPUT.IN_Room_Hum[L_i] < 0.0) OR (GVL_INPUT.IN_Room_Hum[L_i] > 100.0) THEN
        GVL_INPUT.IN_Validation_Failed := TRUE;
        GVL_INPUT.IN_Input_Degraded := TRUE;
        GVL_INPUT.IN_Validation_Reason := 'Hum out of range';
        GVL_INPUT.IN_Last_Invalid_Zone := L_i;
    END_IF;

    L_TempDelta := ABS(GVL_INPUT.IN_Room_Temps[L_i] - GVL_INPUT.IN_Room_Temp_Prev[L_i]);
    L_HumDelta := ABS(GVL_INPUT.IN_Room_Hum[L_i] - GVL_INPUT.IN_Room_Hum_Prev[L_i]);

    // -----------------------------
    // INSTANT CONFIDENCE
    // -----------------------------

    GVL_INPUT.IN_Room_Temp_Confidence[L_i] := 1.0;
    GVL_INPUT.IN_Room_Hum_Confidence[L_i] := 1.0;

    IF L_TempDelta > GVL_INPUT_VALIDATION_CONFIG.G_Room_Temp_Spike_Threshold THEN
        GVL_INPUT.IN_Room_Temp_Confidence[L_i] := 0.3;
        GVL_INPUT.IN_Anomaly_Detected := TRUE;
        GVL_INPUT.IN_Anomaly_Reason := 'Temp spike';
    END_IF;

    IF L_HumDelta > GVL_INPUT_VALIDATION_CONFIG.G_Room_Hum_Spike_Threshold THEN
        GVL_INPUT.IN_Room_Hum_Confidence[L_i] := 0.3;
        GVL_INPUT.IN_Anomaly_Detected := TRUE;
        GVL_INPUT.IN_Anomaly_Reason := 'Hum spike';
    END_IF;

    // -----------------------------
    // REPUTATION LEARNING
    // -----------------------------

    GVL_INPUT.IN_Room_Temp_Reputation[L_i] :=
        GVL_INPUT.IN_Room_Temp_Reputation[L_i] * (1.0 - L_LearningRate) +
        GVL_INPUT.IN_Room_Temp_Confidence[L_i] * L_LearningRate;

    GVL_INPUT.IN_Room_Hum_Reputation[L_i] :=
        GVL_INPUT.IN_Room_Hum_Reputation[L_i] * (1.0 - L_LearningRate) +
        GVL_INPUT.IN_Room_Hum_Confidence[L_i] * L_LearningRate;

    // decay recovery
    GVL_INPUT.IN_Room_Temp_Reputation[L_i] :=
        GVL_INPUT.IN_Room_Temp_Reputation[L_i] + (1.0 - GVL_INPUT.IN_Room_Temp_Reputation[L_i]) * L_Decay;

    GVL_INPUT.IN_Room_Hum_Reputation[L_i] :=
        GVL_INPUT.IN_Room_Hum_Reputation[L_i] + (1.0 - GVL_INPUT.IN_Room_Hum_Reputation[L_i]) * L_Decay;

    // clamp
    IF GVL_INPUT.IN_Room_Temp_Reputation[L_i] < L_MinConf THEN
        GVL_INPUT.IN_Room_Temp_Reputation[L_i] := L_MinConf;
    END_IF;

    IF GVL_INPUT.IN_Room_Hum_Reputation[L_i] < L_MinConf THEN
        GVL_INPUT.IN_Room_Hum_Reputation[L_i] := L_MinConf;
    END_IF;

    // -----------------------------
    // FINAL CONFIDENCE
    // -----------------------------

    GVL_INPUT.IN_Zone_Confidence[L_i] :=
        (GVL_INPUT.IN_Room_Temp_Confidence[L_i] * GVL_INPUT.IN_Room_Temp_Reputation[L_i] +
         GVL_INPUT.IN_Room_Hum_Confidence[L_i] * GVL_INPUT.IN_Room_Hum_Reputation[L_i]) / 2.0;

    IF GVL_INPUT.IN_Zone_Confidence[L_i] < GVL_INPUT.IN_Min_Zone_Confidence THEN
        GVL_INPUT.IN_Min_Zone_Confidence := GVL_INPUT.IN_Zone_Confidence[L_i];
        GVL_INPUT.IN_Worst_Zone := L_i;
    END_IF;

    // store previous
    GVL_INPUT.IN_Room_Temp_Prev[L_i] := GVL_INPUT.IN_Room_Temps[L_i];
    GVL_INPUT.IN_Room_Hum_Prev[L_i] := GVL_INPUT.IN_Room_Hum[L_i];

END_FOR;

// >>> BULK_SYNC_ANCHOR: PRG_Input_Processing <<<
