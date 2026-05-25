PROGRAM PRG_IO_Read_Phase_05_Gas_DHW_Water_Feedback
VAR
    L_i : INT;

    fbDiagEventManager : FB_Diagnostics_Event_Manager;
    fbCalib_Methane : ARRAY[1..GVL_CONSTANTS.C_MAX_METHANE_SENSORS] OF FB_Sensor_Calibration_Processor;
    fbCalib_CO : ARRAY[1..GVL_CONSTANTS.C_MAX_CO_SENSORS] OF FB_Sensor_Calibration_Processor;
END_VAR

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_METHANE_SENSORS DO
    IF GVL_IO.AI_Methane_LEL[L_i].wStatus = 0 THEN
        fbCalib_Methane[L_i](
            VI_Raw_Value := GVL_IO.AI_Methane_LEL[L_i].rValue,
            VI_Record := GVL_CONFIG.G_Calib_Methane[L_i]
        );
        GVL_STATE.G_Methane_Sensors[L_i] := fbCalib_Methane[L_i].VO_Calibrated_Value;
        IF fbCalib_Methane[L_i].VO_Record_Fault THEN
            GVL_STATUS.G_Diagnostics.Sensor_Fault := TRUE;
        END_IF;
    END_IF;

    fbDiagEventManager(
        VI_Code := 16#E003,
        VI_Severity := 3,
        VI_Active := GVL_IO.AI_Methane_LEL[L_i].wStatus <> 0,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Source := 300 + L_i,
        VIO_Events := GVL_STATUS.G_Diagnostics_Events,
        VIO_Count := GVL_STATUS.G_Diagnostics_Count
    );
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_CO_SENSORS DO
    fbCalib_CO[L_i](
        VI_Raw_Value := GVL_IO.AI_CO_PPM[L_i],
        VI_Record := GVL_CONFIG.G_Calib_CO[L_i]
    );
    GVL_STATE.G_CO_Sensors[L_i] := fbCalib_CO[L_i].VO_Calibrated_Value;
    IF fbCalib_CO[L_i].VO_Record_Fault THEN
        GVL_STATUS.G_Diagnostics.Sensor_Fault := TRUE;
    END_IF;
END_FOR;

GVL_STATE.G_DHW_Temp := GVL_IO.AI_DHW_Temp;
GVL_STATE.G_DHW_Pressure := GVL_IO.AI_DHW_Pressure;

GVL_STATE.G_Water_Zone_Open_FB := GVL_IO.DI_Water_Zone_Open_FB;
GVL_STATE.G_Water_Zone_Close_FB := GVL_IO.DI_Water_Zone_Close_FB;

// >>> BULK_SYNC_ANCHOR: PRG_IO_Read_Phase_05_Gas_DHW_Water_Feedback <<<
END_PROGRAM
