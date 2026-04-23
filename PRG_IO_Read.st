PROGRAM PRG_IO_Read
VAR
    L_i : INT;
    L_Debounce_Time : TIME := T#100MS;
    L_Manifold_Pressure_Raw : WORD;
    L_Manifold_Current_Raw : WORD;
    
    fbDebounce_Switches : ARRAY[1..8] OF FB_System_Timer;
    fbDebounce_Motion : ARRAY[1..8] OF FB_System_Timer;
    fbDebounce_Security_Open : ARRAY[1..GVL_CONSTANTS.C_MAX_SECURITY_SENSORS] OF FB_System_Timer;
    fbDebounce_Security_Glass : ARRAY[1..GVL_CONSTANTS.C_MAX_SECURITY_SENSORS] OF FB_System_Timer;
    fbDebounce_Flood : ARRAY[1..GVL_CONSTANTS.C_MAX_FLOOD_SENSORS] OF FB_System_Timer;
    fbDebounce_Smoke : ARRAY[1..GVL_CONSTANTS.C_MAX_SMOKE_SENSORS] OF FB_System_Timer;
    fbDebounce_Group_2F : FB_System_Timer;
    
    fbIO_Watchdog_1 : FB_IO_Module_Watchdog;
    fbIO_Watchdog_2 : FB_IO_Module_Watchdog;
    L_IO_Error_Active : BOOL;

    // added
    fbCalib_Outdoor_Temp : FB_Sensor_Calibration_Processor;
    fbCalib_Room_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF FB_Sensor_Calibration_Processor;
    fbCalib_Floor_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF FB_Sensor_Calibration_Processor;

    fbAnalog_Manifold_Pressure : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_Sensor_Analog_Processing;
    fbAnalog_Manifold_Current : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_Sensor_Analog_Processing;
END_VAR

// ===== ORIGINAL SNAPSHOT (FULL) =====
fbIO_Watchdog_1(VI_System_Time_MS := GVL_STATUS.G_System_Time_MS, VI_Module_ID := 1, VI_Heartbeat_Signal := GVL_IO.DI_Module_1_Heartbeat, VI_Timeout_MS := 2000);
fbIO_Watchdog_2(VI_System_Time_MS := GVL_STATUS.G_System_Time_MS, VI_Module_ID := 2, VI_Heartbeat_Signal := GVL_IO.DI_Module_2_Heartbeat, VI_Timeout_MS := 2000);

GVL_STATUS.G_IO_Modules_Online[1] := fbIO_Watchdog_1.VO_Module_Online;
GVL_STATUS.G_IO_Modules_Online[2] := fbIO_Watchdog_2.VO_Module_Online;

L_IO_Error_Active := fbIO_Watchdog_1.VO_Error_Active OR fbIO_Watchdog_2.VO_Error_Active;

IF L_IO_Error_Active THEN
    GVL_COMMAND.G_Gas_Valve_Close := TRUE;
    GVL_COMMAND.G_Close_Valve_35 := TRUE;
    GVL_COMMAND.G_Close_Valve_36 := TRUE;
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO GVL_STATE.G_Manifold_Pumps[L_i] := FALSE; END_FOR;
END_IF;

FOR L_i := 1 TO 8 DO
    fbDebounce_Switches[L_i](IN := GVL_IO.DI_Lighting_Switches[L_i], PT := L_Debounce_Time, VI_System_Time_MS := GVL_STATUS.G_System_Time_MS);
    GVL_STATE.G_Physical_Switches[L_i] := fbDebounce_Switches[L_i].Q;
    
    fbDebounce_Motion[L_i](IN := GVL_IO.DI_Motion_Sensors[L_i], PT := L_Debounce_Time, VI_System_Time_MS := GVL_STATUS.G_System_Time_MS);
    GVL_STATE.G_Motion_Sensors[L_i] := fbDebounce_Motion[L_i].Q;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SOCKETS DO
    GVL_STATE.G_Socket_Switches[L_i] := FALSE;
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

FOR L_i := 1 TO 8 DO
    IF GVL_CONFIG.G_Window_Map[L_i] > 0 THEN
        IF GVL_CONFIG.G_Window_Map[L_i] <= GVL_CONSTANTS.C_MAX_SECURITY_SENSORS THEN
            GVL_STATE.G_Window_Sensors[L_i] := fbDebounce_Security_Open[GVL_CONFIG.G_Window_Map[L_i]].Q;
        ELSE
            GVL_STATE.G_Window_Sensors[L_i] := fbDebounce_Security_Glass[GVL_CONFIG.G_Window_Map[L_i] - GVL_CONSTANTS.C_MAX_SECURITY_SENSORS].Q;
        END_IF;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO
    fbDebounce_Flood[L_i](IN := GVL_IO.DI_Flood_Sensors[L_i], PT := L_Debounce_Time, VI_System_Time_MS := GVL_STATUS.G_System_Time_MS);
    GVL_STATE.G_Water_Sensors[L_i] := fbDebounce_Flood[L_i].Q;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SMOKE_SENSORS DO
    fbDebounce_Smoke[L_i](IN := GVL_IO.DI_Smoke_Sensors[L_i], PT := L_Debounce_Time, VI_System_Time_MS := GVL_STATUS.G_System_Time_MS);
    GVL_STATE.G_Smoke_Sensors[L_i] := fbDebounce_Smoke[L_i].Q;
END_FOR;

// ===== ENHANCED LAYER =====
fbCalib_Outdoor_Temp(
    VI_Raw_Value := GVL_IO.AI_Temp_Outdoor.rValue,
    VI_Record := GVL_CONFIG.G_Calib_Outdoor_Temp
);
GVL_STATE.G_Outdoor_Temp := fbCalib_Outdoor_Temp.VO_Calibrated_Value;

FOR L_i := 1 TO 8 DO
    fbCalib_Room_Temps[L_i](
        VI_Raw_Value := GVL_IO.AI_Room_Temps[L_i],
        VI_Record := GVL_CONFIG.G_Calib_Room_Temps[L_i]
    );
    GVL_STATE.G_Room_Temps[L_i] := fbCalib_Room_Temps[L_i].VO_Calibrated_Value;

    fbCalib_Floor_Temps[L_i](
        VI_Raw_Value := GVL_IO.AI_Floor_Temps[L_i],
        VI_Record := GVL_CONFIG.G_Calib_Floor_Temps[L_i]
    );
    GVL_STATE.G_Floor_Temps[L_i] := fbCalib_Floor_Temps[L_i].VO_Calibrated_Value;
END_FOR;

GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault_Active := FALSE;
GVL_STATUS.G_Diagnostics.Manifold_Pressure_First_Fault_Index := 0;
GVL_STATUS.G_Diagnostics.Manifold_Current_Fault_Active := FALSE;
GVL_STATUS.G_Diagnostics.Manifold_Current_First_Fault_Index := 0;

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
    IF fbAnalog_Manifold_Pressure[L_i].VO_Error AND NOT GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault_Active THEN
        GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault_Active := TRUE;
        GVL_STATUS.G_Diagnostics.Manifold_Pressure_First_Fault_Index := L_i;
    END_IF;

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
    IF fbAnalog_Manifold_Current[L_i].VO_Error AND NOT GVL_STATUS.G_Diagnostics.Manifold_Current_Fault_Active THEN
        GVL_STATUS.G_Diagnostics.Manifold_Current_Fault_Active := TRUE;
        GVL_STATUS.G_Diagnostics.Manifold_Current_First_Fault_Index := L_i;
    END_IF;
END_FOR;

// >>> BULK_SYNC_ANCHOR: PRG_IO_Read <<<
