PROGRAM PRG_IO_Read
VAR
    L_i : INT;
    L_Map_Index : INT;
    L_Glass_Index : INT;
    L_Debounce_Time : TIME := T#100MS;
    L_Manifold_Pressure_Raw : WORD;
    L_Manifold_Current_Raw : WORD;
    L_Filtered_Room_Temp : REAL;
    L_Filtered_Floor_Temp : REAL;
    
    fbDebounce_Switches : ARRAY[1..GVL_CONSTANTS.C_MAX_LIGHT_ZONES] OF FB_System_Timer;
    fbDebounce_Motion : ARRAY[1..GVL_CONSTANTS.C_MAX_LIGHT_ZONES] OF FB_System_Timer;
    fbDebounce_Security_Open : ARRAY[1..GVL_CONSTANTS.C_MAX_SECURITY_SENSORS] OF FB_System_Timer;
    fbDebounce_Security_Glass : ARRAY[1..GVL_CONSTANTS.C_MAX_SECURITY_SENSORS] OF FB_System_Timer;
    fbDebounce_Flood : ARRAY[1..GVL_CONSTANTS.C_MAX_FLOOD_SENSORS] OF FB_System_Timer;
    fbDebounce_Smoke : ARRAY[1..GVL_CONSTANTS.C_MAX_SMOKE_SENSORS] OF FB_System_Timer;
    fbDebounce_Group_2F : FB_System_Timer;
    
    fbIO_Watchdog_1 : FB_IO_Module_Watchdog;
    fbIO_Watchdog_2 : FB_IO_Module_Watchdog;
    fbDiagEventManager : FB_Diagnostics_Event_Manager;
    L_IO_Error_Active : BOOL;

    fbCalib_Outdoor_Temp : FB_Sensor_Calibration_Processor;
    fbCalib_Supply_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_SUPPLY_TEMPS] OF FB_Sensor_Calibration_Processor;
    fbCalib_Room_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF FB_Sensor_Calibration_Processor;
    fbCalib_Floor_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF FB_Sensor_Calibration_Processor;
    fbCalib_Room_Hum : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF FB_Sensor_Calibration_Processor;
    fbCalib_Room_CO2 : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF FB_Sensor_Calibration_Processor;
    fbCalib_Manifold_T_Supply : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_Sensor_Calibration_Processor;
    fbCalib_Manifold_T_Return : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_Sensor_Calibration_Processor;
    fbCalib_Methane : ARRAY[1..GVL_CONSTANTS.C_MAX_METHANE_SENSORS] OF FB_Sensor_Calibration_Processor;
    fbCalib_CO : ARRAY[1..GVL_CONSTANTS.C_MAX_CO_SENSORS] OF FB_Sensor_Calibration_Processor;

    fbAnalog_Manifold_Pressure : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_Sensor_Analog_Processing;
    fbAnalog_Manifold_Current : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_Sensor_Analog_Processing;
END_VAR

fbIO_Watchdog_1(VI_System_Time_MS := GVL_STATUS.G_System_Time_MS, VI_Module_ID := 1, VI_Heartbeat_Signal := GVL_IO.DI_Module_1_Heartbeat, VI_Timeout_MS := 2000);
fbIO_Watchdog_2(VI_System_Time_MS := GVL_STATUS.G_System_Time_MS, VI_Module_ID := 2, VI_Heartbeat_Signal := GVL_IO.DI_Module_2_Heartbeat, VI_Timeout_MS := 2000);

GVL_STATUS.G_IO_Modules_Online[1] := fbIO_Watchdog_1.VO_Module_Online;
GVL_STATUS.G_IO_Modules_Online[2] := fbIO_Watchdog_2.VO_Module_Online;

L_IO_Error_Active := fbIO_Watchdog_1.VO_Error_Active OR fbIO_Watchdog_2.VO_Error_Active;

fbDiagEventManager(
    VI_Code := 16#E001,
    VI_Severity := 4,
    VI_Active := NOT fbIO_Watchdog_1.VO_Module_Online,
    VI_Timestamp := GVL_STATUS.G_System_Time_MS,
    VI_Source := 1,
    VIO_Events := GVL_STATUS.G_Diagnostics_Events,
    VIO_Count := GVL_STATUS.G_Diagnostics_Count
);

fbDiagEventManager(
    VI_Code := 16#E002,
    VI_Severity := 4,
    VI_Active := NOT fbIO_Watchdog_2.VO_Module_Online,
    VI_Timestamp := GVL_STATUS.G_System_Time_MS,
    VI_Source := 2,
    VIO_Events := GVL_STATUS.G_Diagnostics_Events,
    VIO_Count := GVL_STATUS.G_Diagnostics_Count
);

IF L_IO_Error_Active THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        GVL_STATE.G_Manifold_Pumps[L_i] := FALSE;
    END_FOR;
END_IF;

// Lighting and motion are sized by C_MAX_LIGHT_ZONES.
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
    fbDebounce_Switches[L_i](IN := GVL_IO.DI_Lighting_Switches[L_i], PT := L_Debounce_Time, VI_System_Time_MS := GVL_STATUS.G_System_Time_MS);
    GVL_STATE.G_Physical_Switches[L_i] := fbDebounce_Switches[L_i].Q;
    
    fbDebounce_Motion[L_i](IN := GVL_IO.DI_Motion_Sensors[L_i], PT := L_Debounce_Time, VI_System_Time_MS := GVL_STATUS.G_System_Time_MS);
    GVL_STATE.G_Motion_Sensors[L_i] := fbDebounce_Motion[L_i].Q;
END_FOR;

// Socket hardware inputs are propagated instead of being forced to FALSE.
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SOCKETS DO
    GVL_STATE.G_Socket_Switches[L_i] := GVL_IO.DI_Socket_Switches[L_i];
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SECURITY_SENSORS DO
    fbDebounce_Security_Open[L_i](IN := GVL_IO.DI_Security_Open[L_i], PT := L_Debounce_Time, VI_System_Time_MS := GVL_STATUS.G_System_Time_MS);
    fbDebounce_Security_Glass[L_i](IN := GVL_IO.DI_Security_Glass[L_i], PT := L_Debounce_Time, VI_System_Time_MS := GVL_STATUS.G_System_Time_MS);
END_FOR;

fbDebounce_Group_2F(IN := GVL_IO.DI_Security_2F_Group, PT := L_Debounce_Time, VI_System_Time_MS := GVL_STATUS.G_System_Time_MS);

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_DOOR_SENSORS DO
    IF GVL_CONFIG.G_Door_Map[L_i] > 0 AND GVL_CONFIG.G_Door_Map[L_i] <= GVL_CONSTANTS.C_MAX_SECURITY_SENSORS THEN
        GVL_STATE.G_Door_Sensors[L_i] := fbDebounce_Security_Open[GVL_CONFIG.G_Door_Map[L_i]].Q;
    END_IF;
END_FOR;

// Window/opening mapping is limited by C_MAX_ZONES and protected by bounds checks.
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    L_Map_Index := GVL_CONFIG.G_Window_Map[L_i];
    IF L_Map_Index > 0 THEN
        IF L_Map_Index <= GVL_CONSTANTS.C_MAX_SECURITY_SENSORS THEN
            GVL_STATE.G_Window_Sensors[L_i] := fbDebounce_Security_Open[L_Map_Index].Q;
        ELSE
            L_Glass_Index := L_Map_Index - GVL_CONSTANTS.C_MAX_SECURITY_SENSORS;
            IF (L_Glass_Index >= 1) AND (L_Glass_Index <= GVL_CONSTANTS.C_MAX_SECURITY_SENSORS) THEN
                GVL_STATE.G_Window_Sensors[L_i] := fbDebounce_Security_Glass[L_Glass_Index].Q;
            END_IF;
        END_IF;
    END_IF;
END_FOR;
GVL_STATE.G_Window_Sensors[16] := fbDebounce_Group_2F.Q;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO
    fbDebounce_Flood[L_i](IN := GVL_IO.DI_Flood_Sensors[L_i], PT := L_Debounce_Time, VI_System_Time_MS := GVL_STATUS.G_System_Time_MS);
    GVL_STATE.G_Water_Sensors[L_i] := fbDebounce_Flood[L_i].Q;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SMOKE_SENSORS DO
    fbDebounce_Smoke[L_i](IN := GVL_IO.DI_Smoke_Sensors[L_i], PT := L_Debounce_Time, VI_System_Time_MS := GVL_STATUS.G_System_Time_MS);
    GVL_STATE.G_Smoke_Sensors[L_i] := fbDebounce_Smoke[L_i].Q;
END_FOR;

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

// Humidity and CO2 IO/state/calibration arrays are sized by C_MAX_ZONES.
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

// Room temperature filtering and range validation
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

// Floor temperature filtering and range validation
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

GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault_Active := FALSE;
GVL_STATUS.G_Diagnostics.Manifold_Pressure_First_Fault_Index := 0;
GVL_STATUS.G_Diagnostics.Manifold_Current_Fault_Active := FALSE;
GVL_STATUS.G_Diagnostics.Manifold_Current_First_Fault_Index := 0;
GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault_Text := '';
GVL_STATUS.G_Diagnostics.Manifold_Current_Fault_Text := '';

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF GVL_IO.AI_Manifold_Pressures[L_i] < 0 THEN
        L_Manifold_Pressure_Raw := 0;
    ELSE
        L_Manifold_Pressure_Raw := INT_TO_WORD(GVL_IO.AI_Manifold_Pressures[L_i]);
    END_IF;

    IF GVL_IO.AI_Manifold_Currents[L_i] < 0 THEN
        L_Manifold_Current_Raw := 0;
    ELSE
        L_Manifold_Current_Raw := INT_TO_WORD(GVL_IO.AI_Manifold_Currents[L_i]);
    END_IF;

    fbAnalog_Manifold_Pressure[L_i](
        VI_Raw_Value := L_Manifold_Pressure_Raw,
        VI_Sensor_Type := 0,
        VI_Min_Scale := 0.0,
        VI_Max_Scale := 10.0,
        VI_Offset := 0.0,
        VI_Multiplier := 1.0,
        VI_Filter_Time_MS := GVL_CONSTANTS.C_MS_IN_SECOND,
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
        VI_Fallback_Mode := 0,
        VI_Default_Value := 0.0
    );
    GVL_STATE.G_Manifold_Pressures[L_i] := fbAnalog_Manifold_Pressure[L_i].VO_Value;
    GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault[L_i] := fbAnalog_Manifold_Pressure[L_i].VO_Error;
    GVL_STATUS.G_Diagnostics.Manifold_Pressure_Diag_Code[L_i] := fbAnalog_Manifold_Pressure[L_i].VO_Diag_Code;

    fbDiagEventManager(
        VI_Code := GVL_CONFIG.ERR_PRESSURE_OUT_OF_RANGE,
        VI_Severity := 3,
        VI_Active := fbAnalog_Manifold_Pressure[L_i].VO_Error,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Source := 100 + L_i,
        VIO_Events := GVL_STATUS.G_Diagnostics_Events,
        VIO_Count := GVL_STATUS.G_Diagnostics_Count
    );

    fbAnalog_Manifold_Current[L_i](
        VI_Raw_Value := L_Manifold_Current_Raw,
        VI_Sensor_Type := 0,
        VI_Min_Scale := 0.0,
        VI_Max_Scale := 16.0,
        VI_Offset := 0.0,
        VI_Multiplier := 1.0,
        VI_Filter_Time_MS := GVL_CONSTANTS.C_MS_IN_SECOND,
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
        VI_Fallback_Mode := 0,
        VI_Default_Value := 0.0
    );
    GVL_STATE.G_Manifold_Currents[L_i] := fbAnalog_Manifold_Current[L_i].VO_Value;
    GVL_STATUS.G_Diagnostics.Manifold_Current_Fault[L_i] := fbAnalog_Manifold_Current[L_i].VO_Error;
    GVL_STATUS.G_Diagnostics.Manifold_Current_Diag_Code[L_i] := fbAnalog_Manifold_Current[L_i].VO_Diag_Code;

    fbDiagEventManager(
        VI_Code := GVL_CONFIG.ERR_PUMP_UNDERCURRENT,
        VI_Severity := 3,
        VI_Active := fbAnalog_Manifold_Current[L_i].VO_Error,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Source := 200 + L_i,
        VIO_Events := GVL_STATUS.G_Diagnostics_Events,
        VIO_Count := GVL_STATUS.G_Diagnostics_Count
    );

    IF GVL_IO.AI_Manifold_Temps_Supply[L_i].wStatus = 0 THEN
        fbCalib_Manifold_T_Supply[L_i](
            VI_Raw_Value := GVL_IO.AI_Manifold_Temps_Supply[L_i].rValue,
            VI_Record := GVL_CONFIG.G_Calib_Manifold_T_Supply[L_i]
        );
        GVL_STATE.G_Manifold_T_Supply[L_i] := fbCalib_Manifold_T_Supply[L_i].VO_Calibrated_Value;
    END_IF;

    fbCalib_Manifold_T_Return[L_i](
        VI_Raw_Value := INT_TO_REAL(GVL_IO.AI_Manifold_Temps_Return[L_i]) / 10.0,
        VI_Record := GVL_CONFIG.G_Calib_Manifold_T_Return[L_i]
    );
    GVL_STATE.G_Manifold_T_Return[L_i] := fbCalib_Manifold_T_Return[L_i].VO_Calibrated_Value;
    GVL_STATE.G_Manifold_End_Switches[L_i] := GVL_IO.DI_Manifold_End_Switches[L_i];

    IF GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault[L_i] OR GVL_STATUS.G_Diagnostics.Manifold_Current_Fault[L_i] THEN
        GVL_STATUS.G_Diagnostics.Sensor_Fault := TRUE;
        GVL_STATUS.G_Diagnostics.Subsystem_Degraded := TRUE;
    END_IF;

    IF GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault[L_i] AND GVL_STATUS.G_Diagnostics.Manifold_Current_Fault[L_i] THEN
        GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault_Text := 'Correlated pressure/current fault detected';
        GVL_STATUS.G_Diagnostics.Manifold_Current_Fault_Text := 'Correlated pressure/current fault detected';
    ELSIF GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault[L_i] AND (GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault_Text = '') THEN
        GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault_Text := 'Pressure sensor fault detected';
    ELSIF GVL_STATUS.G_Diagnostics.Manifold_Current_Fault[L_i] AND (GVL_STATUS.G_Diagnostics.Manifold_Current_Fault_Text = '') THEN
        GVL_STATUS.G_Diagnostics.Manifold_Current_Fault_Text := 'Current sensor fault detected';
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_METHANE_SENSORS DO
    IF GVL_IO.AI_Methane_LEL[L_i].wStatus = 0 THEN
        fbCalib_Methane[L_i](
            VI_Raw_Value := GVL_IO.AI_Methane_LEL[L_i].rValue,
            VI_Record := GVL_CONFIG.G_Calib_Methane[L_i]
        );
        GVL_STATE.G_Methane_Sensors[L_i] := fbCalib_Methane[L_i].VO_Calibrated_Value;
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
END_FOR;

GVL_STATE.G_Boiler_Flame := GVL_IO.AI_Boiler_Flame_Status;
GVL_STATE.G_Boiler_Error := GVL_IO.DI_Boiler_Error;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    GVL_STATE.G_Boiler_OT_Online[L_i] := FALSE;
END_FOR;

GVL_STATE.G_DHW_Temp := GVL_IO.AI_DHW_Temp;
GVL_STATE.G_DHW_Pressure := GVL_IO.AI_DHW_Pressure;

GVL_STATE.G_Water_Zone_Open_FB := GVL_IO.DI_Water_Zone_Open_FB;
GVL_STATE.G_Water_Zone_Close_FB := GVL_IO.DI_Water_Zone_Close_FB;

// >>> BULK_SYNC_ANCHOR: PRG_IO_Read <<<
END_PROGRAM
