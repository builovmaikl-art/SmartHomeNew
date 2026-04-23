PROGRAM PRG_IO_Read
VAR
    L_i : INT;
    L_Debounce_Time : TIME := T#100MS;

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

    // calibration
    fbCalib_Outdoor_Temp : FB_Sensor_Calibration_Processor;
    fbCalib_Room_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF FB_Sensor_Calibration_Processor;
    fbCalib_Floor_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF FB_Sensor_Calibration_Processor;

    // diagnostics
    fbAnalog_Manifold_Pressure : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_Sensor_Analog_Processing;
    fbAnalog_Manifold_Current : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_Sensor_Analog_Processing;
END_VAR

// watchdog
fbIO_Watchdog_1(VI_System_Time_MS := GVL_STATUS.G_System_Time_MS, VI_Module_ID := 1, VI_Heartbeat_Signal := GVL_IO.DI_Module_1_Heartbeat, VI_Timeout_MS := 2000);
fbIO_Watchdog_2(VI_System_Time_MS := GVL_STATUS.G_System_Time_MS, VI_Module_ID := 2, VI_Heartbeat_Signal := GVL_IO.DI_Module_2_Heartbeat, VI_Timeout_MS := 2000);

GVL_STATUS.G_IO_Modules_Online[1] := fbIO_Watchdog_1.VO_Module_Online;
GVL_STATUS.G_IO_Modules_Online[2] := fbIO_Watchdog_2.VO_Module_Online;

// debounce switches
FOR L_i := 1 TO 8 DO
    fbDebounce_Switches[L_i](IN := GVL_IO.DI_Lighting_Switches[L_i], PT := L_Debounce_Time, VI_System_Time_MS := GVL_STATUS.G_System_Time_MS);
    GVL_STATE.G_Physical_Switches[L_i] := fbDebounce_Switches[L_i].Q;
END_FOR;

// analog manifold diagnostics
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    fbAnalog_Manifold_Pressure[L_i](VI_Value := INT_TO_REAL(GVL_IO.AI_Manifold_Pressures[L_i]));
    GVL_STATE.G_Manifold_Pressures[L_i] := fbAnalog_Manifold_Pressure[L_i].VO_Value;
    GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault[L_i] := fbAnalog_Manifold_Pressure[L_i].VO_Error;

    fbAnalog_Manifold_Current[L_i](VI_Value := INT_TO_REAL(GVL_IO.AI_Manifold_Currents[L_i]));
    GVL_STATE.G_Manifold_Currents[L_i] := fbAnalog_Manifold_Current[L_i].VO_Value;
    GVL_STATUS.G_Diagnostics.Manifold_Current_Fault[L_i] := fbAnalog_Manifold_Current[L_i].VO_Error;
END_FOR;

// >>> BULK_SYNC_ANCHOR: PRG_IO_Read <<<
