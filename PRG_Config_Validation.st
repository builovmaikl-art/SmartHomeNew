PROGRAM PRG_Config_Validation
VAR
    fbConfigSimulation : FB_Config_Simulation;

    L_i : INT;
    L_Zone : INT;
    L_Sensor : INT;
    L_Manifold : INT;
    L_Map_Index : INT;
    L_Config_Error : BOOL;
END_VAR

// ======================================================
// CENTRAL CONFIGURATION VALIDATION
// ======================================================
// Diagnostic-only layer. It sets validation flags and degraded diagnostics,
// but does not write command/shadow/output structures.

L_Config_Error := FALSE;

// ======================================================
// ACTIVE SIZE CONFIGURATION
// ======================================================
IF (GVL_SYSTEM_SIZE_CONFIG.G_Active_Heating_Circuits < 1) OR
   (GVL_SYSTEM_SIZE_CONFIG.G_Active_Heating_Circuits > GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS) THEN
    L_Config_Error := TRUE;
END_IF;

IF (GVL_SYSTEM_SIZE_CONFIG.G_Active_Water_Zones < 1) OR
   (GVL_SYSTEM_SIZE_CONFIG.G_Active_Water_Zones > GVL_CONSTANTS.C_MAX_WATER_ZONES) THEN
    L_Config_Error := TRUE;
END_IF;

IF (GVL_SYSTEM_SIZE_CONFIG.G_Active_Light_Zones < 1) OR
   (GVL_SYSTEM_SIZE_CONFIG.G_Active_Light_Zones > GVL_CONSTANTS.C_MAX_LIGHT_ZONES) THEN
    L_Config_Error := TRUE;
END_IF;

IF (GVL_SYSTEM_SIZE_CONFIG.G_Active_Blinds < 0) OR
   (GVL_SYSTEM_SIZE_CONFIG.G_Active_Blinds > GVL_CONSTANTS.C_MAX_BLINDS) THEN
    L_Config_Error := TRUE;
END_IF;

IF (GVL_SYSTEM_SIZE_CONFIG.G_Active_Sockets < 0) OR
   (GVL_SYSTEM_SIZE_CONFIG.G_Active_Sockets > GVL_CONSTANTS.C_MAX_SOCKETS) THEN
    L_Config_Error := TRUE;
END_IF;

// ======================================================
// HEATING CIRCUIT CONFIGURATION
// ======================================================
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    L_Zone := BYTE_TO_INT(GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].zone);
    L_Sensor := BYTE_TO_INT(GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].sensor_id);
    L_Manifold := BYTE_TO_INT(GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].manifold_id);

    IF (L_Zone < 1) OR (L_Zone > GVL_CONSTANTS.C_MAX_ZONES) THEN
        L_Config_Error := TRUE;
    END_IF;

    IF (L_Sensor < 1) OR (L_Sensor > GVL_CONSTANTS.C_MAX_ZONES) THEN
        L_Config_Error := TRUE;
    END_IF;

    IF (L_Manifold < 1) OR (L_Manifold > GVL_CONSTANTS.C_MAX_MANIFOLDS) THEN
        L_Config_Error := TRUE;
    END_IF;

    IF GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].min_temp > GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].max_temp THEN
        L_Config_Error := TRUE;
    END_IF;
END_FOR;

IF (GVL_CONFIG.G_Max_Active_Manifolds < 1) OR
   (GVL_CONFIG.G_Max_Active_Manifolds > GVL_CONSTANTS.C_MAX_MANIFOLDS) THEN
    L_Config_Error := TRUE;
END_IF;

IF GVL_CONFIG.G_Max_Thermal_Budget <= 0.0 THEN
    L_Config_Error := TRUE;
END_IF;

IF GVL_CONFIG.G_Policy_Min_Hold_MS < 10000 THEN
    L_Config_Error := TRUE;
END_IF;

// ======================================================
// ACCESS / TIMING CONFIGURATION
// ======================================================
IF (GVL_CONFIG.G_Access_Pulse_MS < 100) OR (GVL_CONFIG.G_Access_Pulse_MS > 5000) THEN
    L_Config_Error := TRUE;
END_IF;

// ======================================================
// MAP CONFIGURATION
// ======================================================
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_DOOR_SENSORS DO
    L_Map_Index := GVL_CONFIG.G_Door_Map[L_i];
    IF (L_Map_Index < 1) OR (L_Map_Index > GVL_CONSTANTS.C_MAX_SECURITY_SENSORS) THEN
        L_Config_Error := TRUE;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    L_Map_Index := GVL_CONFIG.G_Window_Map[L_i];
    IF L_Map_Index <> 0 THEN
        IF (L_Map_Index < 1) OR (L_Map_Index > (GVL_CONSTANTS.C_MAX_SECURITY_SENSORS * 2)) THEN
            L_Config_Error := TRUE;
        END_IF;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    IF (GVL_CONFIG.G_FloorTemp_Map[L_i] < 1) OR (GVL_CONFIG.G_FloorTemp_Map[L_i] > GVL_CONSTANTS.C_MAX_ZONES) THEN
        L_Config_Error := TRUE;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    IF (GVL_CONFIG.G_RoomTemp_Map[L_i] < 1) OR (GVL_CONFIG.G_RoomTemp_Map[L_i] > GVL_CONSTANTS.C_MAX_ZONES) THEN
        L_Config_Error := TRUE;
    END_IF;
END_FOR;

// ======================================================
// HARDWARE SERVICE / RETRY CONFIGURATION
// ======================================================
IF GVL_CONFIG.G_Freeze_Hardware_Retry_Count < 0 THEN
    L_Config_Error := TRUE;
END_IF;

IF GVL_CONFIG.G_Freeze_Hardware_Retry_Delay_MS < 1000 THEN
    L_Config_Error := TRUE;
END_IF;

IF GVL_CONFIG.G_Pump_Exercise_Enabled THEN
    IF GVL_CONFIG.G_Pump_Exercise_Interval_MS < GVL_CONSTANTS.C_MS_IN_MINUTE THEN
        L_Config_Error := TRUE;
    END_IF;
    IF GVL_CONFIG.G_Pump_Exercise_Duration_MS < 1000 THEN
        L_Config_Error := TRUE;
    END_IF;
END_IF;

IF GVL_CONFIG.G_Water_Valve_Exercise_Enabled THEN
    IF GVL_CONFIG.G_Water_Valve_Exercise_Interval_MS < GVL_CONSTANTS.C_MS_IN_MINUTE THEN
        L_Config_Error := TRUE;
    END_IF;
    IF GVL_CONFIG.G_Water_Valve_Exercise_Duration_MS < 1000 THEN
        L_Config_Error := TRUE;
    END_IF;
END_IF;

IF GVL_CONFIG.G_Water_Valve_Close_Retry_Count < 0 THEN
    L_Config_Error := TRUE;
END_IF;

IF GVL_CONFIG.G_Water_Valve_Close_Retry_Delay_MS < 1000 THEN
    L_Config_Error := TRUE;
END_IF;

// ======================================================
// OPENTHERM / MODBUS RTU CONFIGURATION
// ======================================================
IF GVL_CONFIG.G_OpenTherm_Enabled THEN

    IF GVL_CONFIG.G_OpenTherm_Heartbeat_Timeout_MS < 1000 THEN
        L_Config_Error := TRUE;
    END_IF;

    IF GVL_CONFIG.G_OpenTherm_Command_Ack_Timeout_MS < 500 THEN
        L_Config_Error := TRUE;
    END_IF;

    IF GVL_CONFIG.G_Modbus_RTU_Baudrate < 1200 THEN
        L_Config_Error := TRUE;
    END_IF;

    IF (GVL_CONFIG.G_Modbus_RTU_Parity > 2) THEN
        L_Config_Error := TRUE;
    END_IF;

    IF (GVL_CONFIG.G_Modbus_RTU_Stop_Bits < 1) OR
       (GVL_CONFIG.G_Modbus_RTU_Stop_Bits > 2) THEN
        L_Config_Error := TRUE;
    END_IF;

    IF (GVL_CONFIG.G_Modbus_RTU_Data_Bits < 7) OR
       (GVL_CONFIG.G_Modbus_RTU_Data_Bits > 8) THEN
        L_Config_Error := TRUE;
    END_IF;

    IF GVL_CONFIG.G_Modbus_RTU_Slave_ID = 0 THEN
        L_Config_Error := TRUE;
    END_IF;

    IF GVL_CONFIG.G_Modbus_RTU_Poll_Interval_MS < 50 THEN
        L_Config_Error := TRUE;
    END_IF;

    IF GVL_CONFIG.G_Modbus_RTU_Request_Timeout_MS < 50 THEN
        L_Config_Error := TRUE;
    END_IF;

    IF GVL_CONFIG.G_Modbus_RTU_Retry_Count < 0 THEN
        L_Config_Error := TRUE;
    END_IF;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
        IF GVL_CONFIG.G_OpenTherm_Register_Map[L_i].Cmd_Enable_Offset = GVL_CONFIG.G_OpenTherm_Register_Map[L_i].Status_Word_Offset THEN
            L_Config_Error := TRUE;
        END_IF;

        IF GVL_CONFIG.G_OpenTherm_Register_Map[L_i].Cmd_Setpoint_x10_Offset = GVL_CONFIG.G_OpenTherm_Register_Map[L_i].Status_Word_Offset THEN
            L_Config_Error := TRUE;
        END_IF;
    END_FOR;
END_IF;

// ======================================================
// SENSOR COUNT SANITY
// ======================================================
IF GVL_CONSTANTS.C_MAX_METHANE_SENSORS < 2 THEN
    L_Config_Error := TRUE;
END_IF;

IF GVL_CONSTANTS.C_MAX_SMOKE_SENSORS < 6 THEN
    L_Config_Error := TRUE;
END_IF;

IF GVL_CONSTANTS.C_MAX_CO_SENSORS < 8 THEN
    L_Config_Error := TRUE;
END_IF;

IF GVL_CONSTANTS.C_MAX_FLOOD_SENSORS < 9 THEN
    L_Config_Error := TRUE;
END_IF;

// ======================================================
// CONFIG SIMULATION / COMMISSIONING VALIDATION
// ======================================================
fbConfigSimulation(
    VI_Enable := TRUE,
    VI_Request := GVL_CONFIG_SIMULATION.G_Simulation_Request,
    VI_Confirm := GVL_CONFIG_SIMULATION.G_Simulation_Confirm
);

IF fbConfigSimulation.VO_Executed AND NOT fbConfigSimulation.VO_Result_OK THEN
    L_Config_Error := TRUE;
END_IF;

// ======================================================
// STORE FLAGS
// ======================================================
GVL_CONFIG_VALIDATION.G_Config_Valid := NOT L_Config_Error;
GVL_CONFIG_VALIDATION.G_Config_Critical_Error := L_Config_Error;
GVL_CONFIG_VALIDATION.G_Config_Last_Update_MS := GVL_STATUS.G_System_Time_MS;

IF L_Config_Error THEN
    GVL_CONFIG_VALIDATION.G_Config_Last_Error_Text := 'CONFIG VALIDATION ERROR';
    GVL_STATUS.G_Diagnostics.Subsystem_Degraded := TRUE;
    GVL_STATUS.G_System_Mode_Text := 'CONFIG ERROR';
ELSE
    GVL_CONFIG_VALIDATION.G_Config_Last_Error_Text := '';
END_IF;

END_PROGRAM
