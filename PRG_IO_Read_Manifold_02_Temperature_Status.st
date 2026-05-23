PROGRAM PRG_IO_Read_Manifold_02_Temperature_Status
VAR
    L_i : INT;

    fbCalib_Manifold_T_Supply : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_Sensor_Calibration_Processor;
    fbCalib_Manifold_T_Return : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_Sensor_Calibration_Processor;
END_VAR

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF GVL_IO.AI_Manifold_Temps_Supply[L_i].wStatus = 0 THEN
        fbCalib_Manifold_T_Supply[L_i](
            VI_Raw_Value := GVL_IO.AI_Manifold_Temps_Supply[L_i].rValue,
            VI_Record := GVL_CONFIG.G_Calib_Manifold_T_Supply[L_i]
        );
        GVL_STATE.G_Manifold_T_Supply[L_i] := fbCalib_Manifold_T_Supply[L_i].VO_Calibrated_Value;
        IF fbCalib_Manifold_T_Supply[L_i].VO_Record_Fault THEN
            GVL_STATUS.G_Diagnostics.Sensor_Fault := TRUE;
        END_IF;
    ELSE
        GVL_STATUS.G_Diagnostics.Sensor_Fault := TRUE;
    END_IF;

    fbCalib_Manifold_T_Return[L_i](
        VI_Raw_Value := INT_TO_REAL(GVL_IO.AI_Manifold_Temps_Return[L_i]) / 10.0,
        VI_Record := GVL_CONFIG.G_Calib_Manifold_T_Return[L_i]
    );
    GVL_STATE.G_Manifold_T_Return[L_i] := fbCalib_Manifold_T_Return[L_i].VO_Calibrated_Value;
    IF fbCalib_Manifold_T_Return[L_i].VO_Record_Fault THEN
        GVL_STATUS.G_Diagnostics.Sensor_Fault := TRUE;
    END_IF;

    GVL_STATE.G_Manifold_End_Switches[L_i] := GVL_IO.DI_Manifold_End_Switches[L_i];
END_FOR;

// >>> BULK_SYNC_ANCHOR: PRG_IO_Read_Manifold_02_Temperature_Status <<<
END_PROGRAM
