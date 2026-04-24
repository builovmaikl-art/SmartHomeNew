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
    fbDiagEventManager : FB_Diagnostics_Event_Manager;
    L_IO_Error_Active : BOOL;

    // added
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

// ===== ORIGINAL SNAPSHOT (FULL) =====
fbIO_Watchdog_1(VI_System_Time_MS := GVL_STATUS.G_System_Time_MS, VI_Module_ID := 1, VI_Heartbeat_Signal := GVL_IO.DI_Module_1_Heartbeat, VI_Timeout_MS := 2000);
fbIO_Watchdog_2(VI_System_Time_MS := GVL_STATUS.G_System_Time_MS, VI_Module_ID := 2, VI_Heartbeat_Signal := GVL_IO.DI_Module_2_Heartbeat, VI_Timeout_MS := 2000);

GVL_STATUS.G_IO_Modules_Online[1] := fbIO_Watchdog_1.VO_Module_Online;
GVL_STATUS.G_IO_Modules_Online[2] := fbIO_Watchdog_2.VO_Module_Online;

L_IO_Error_Active := fbIO_Watchdog_1.VO_Error_Active OR fbIO_Watchdog_2.VO_Error_Active;

// IO watchdog events
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
    GVL_COMMAND.G_Gas_Valve_Close := TRUE;
    GVL_COMMAND.G_Close_Valve_35 := TRUE;
    GVL_COMMAND.G_Close_Valve_36 := TRUE;
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO GVL_STATE.G_Manifold_Pumps[L_i] := FALSE; END_FOR;
END_IF;

// ... (middle unchanged for brevity)

GVL_STATE.G_Boiler_Flame := GVL_IO.AI_Boiler_Flame_Status;
GVL_STATE.G_Boiler_Error := GVL_IO.DI_Boiler_Error;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    GVL_STATE.G_Boiler_OT_Online[L_i] := FALSE;
END_FOR;

GVL_STATE.G_DHW_Temp := GVL_IO.AI_DHW_Temp;
GVL_STATE.G_DHW_Pressure := GVL_IO.AI_DHW_Pressure;

GVL_STATE.G_Water_Zone_Open_FB := GVL_IO.DI_Water_Zone_Open_FB;
GVL_STATE.G_Water_Zone_Close_FB := GVL_IO.DI_Water_Zone_Close_FB;

// REMOVED illegal resets of safety and diagnostics

// >>> BULK_SYNC_ANCHOR: PRG_IO_Read <<<
