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

GVL_INPUT.IN_Min_Zone_Confidence := 1.0;
GVL_INPUT.IN_Worst_Zone := 0;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO

    GVL_INPUT.IN_Room_Temps[L_i] := GVL_STATE.G_Room_Temps[L_i];
    GVL_INPUT.IN_Room_Hum[L_i] := GVL_STATE.G_Room_Hum[L_i];

    L_TempDelta := ABS(GVL_INPUT.IN_Room_Temps[L_i] - GVL_INPUT.IN_Room_Temp_Prev[L_i]);
    L_HumDelta := ABS(GVL_INPUT.IN_Room_Hum[L_i] - GVL_INPUT.IN_Room_Hum_Prev[L_i]);

    // instant confidence
    GVL_INPUT.IN_Room_Temp_Confidence[L_i] := 1.0;
    GVL_INPUT.IN_Room_Hum_Confidence[L_i] := 1.0;

    IF L_TempDelta > GVL_INPUT_VALIDATION_CONFIG.G_Room_Temp_Spike_Threshold THEN
        GVL_INPUT.IN_Room_Temp_Confidence[L_i] := 0.3;
    END_IF;

    IF L_HumDelta > GVL_INPUT_VALIDATION_CONFIG.G_Room_Hum_Spike_Threshold THEN
        GVL_INPUT.IN_Room_Hum_Confidence[L_i] := 0.3;
    END_IF;

    // learning (EMA)
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

    // final confidence
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

// >>> BULK_SYNC_ANCHOR: PRG_Input_Processing <<<
