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

    // === SENSOR CALIBRATION PROCESSORS ===
    fbCalib_Outdoor_Temp : FB_Sensor_Calibration_Processor;

    fbCalib_Room_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF FB_Sensor_Calibration_Processor;
    fbCalib_Floor_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF FB_Sensor_Calibration_Processor;
    fbCalib_CO2 : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF FB_Sensor_Calibration_Processor;
    fbCalib_Humidity : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF FB_Sensor_Calibration_Processor;

    fbCalib_Manifold_T_Supply : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_Sensor_Calibration_Processor;

    fbCalib_Methane : ARRAY[1..GVL_CONSTANTS.C_MAX_METHANE_SENSORS] OF FB_Sensor_Calibration_Processor;
    fbCalib_CO : ARRAY[1..GVL_CONSTANTS.C_MAX_CO_SENSORS] OF FB_Sensor_Calibration_Processor;

    // === SENSOR SAFETY PROCESSING ===
    fbAnalog_Manifold_Pressure : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_Sensor_Analog_Processing;
    fbAnalog_Manifold_Current : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_Sensor_Analog_Processing;
    fbAnalog_Manifold_T_Return : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_Sensor_Analog_Processing;
END_VAR

// init diagnostics
GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault_Active := FALSE;
GVL_STATUS.G_Diagnostics.Manifold_Pressure_First_Fault_Index := 0;
GVL_STATUS.G_Diagnostics.Manifold_Current_Fault_Active := FALSE;
GVL_STATUS.G_Diagnostics.Manifold_Current_First_Fault_Index := 0;

// ... остальной код без изменений до цикла manifold ...

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    fbAnalog_Manifold_Pressure[L_i](...);
    GVL_STATE.G_Manifold_Pressures[L_i] := fbAnalog_Manifold_Pressure[L_i].VO_Value;

    GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault[L_i] := fbAnalog_Manifold_Pressure[L_i].VO_Error;
    GVL_STATUS.G_Diagnostics.Manifold_Pressure_Diag_Code[L_i] := fbAnalog_Manifold_Pressure[L_i].VO_Diag_Code;
    IF fbAnalog_Manifold_Pressure[L_i].VO_Error AND NOT GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault_Active THEN
        GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault_Active := TRUE;
        GVL_STATUS.G_Diagnostics.Manifold_Pressure_First_Fault_Index := L_i;
    END_IF;

    fbAnalog_Manifold_Current[L_i](...);
    GVL_STATE.G_Manifold_Currents[L_i] := fbAnalog_Manifold_Current[L_i].VO_Value;

    GVL_STATUS.G_Diagnostics.Manifold_Current_Fault[L_i] := fbAnalog_Manifold_Current[L_i].VO_Error;
    GVL_STATUS.G_Diagnostics.Manifold_Current_Diag_Code[L_i] := fbAnalog_Manifold_Current[L_i].VO_Diag_Code;
    IF fbAnalog_Manifold_Current[L_i].VO_Error AND NOT GVL_STATUS.G_Diagnostics.Manifold_Current_Fault_Active THEN
        GVL_STATUS.G_Diagnostics.Manifold_Current_Fault_Active := TRUE;
        GVL_STATUS.G_Diagnostics.Manifold_Current_First_Fault_Index := L_i;
    END_IF;
END_FOR;

// >>> BULK_SYNC_ANCHOR: PRG_IO_Read <<<
