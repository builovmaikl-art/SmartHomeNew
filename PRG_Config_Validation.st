PROGRAM PRG_Config_Validation
VAR
    L_i : INT;
    L_Zone : INT;
    L_Sensor : INT;
    L_Manifold : INT;
    L_Config_Error : BOOL;
END_VAR

// ======================================================
// CENTRAL CONFIGURATION VALIDATION
// ======================================================
// This program is diagnostic-only. It must not write GVL_COMMAND_SHADOW,
// because command arbitration runs later in MAIN and owns command outputs.

L_Config_Error := FALSE;

// Heating circuit configuration
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

    IF (GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].design_temp < GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].min_temp) OR
       (GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].design_temp > GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].max_temp) THEN
        L_Config_Error := TRUE;
    END_IF;
END_FOR;

// Heating policy limits
IF GVL_CONFIG.G_Max_Active_Manifolds < 1 THEN
    L_Config_Error := TRUE;
ELSIF GVL_CONFIG.G_Max_Active_Manifolds > GVL_CONSTANTS.C_MAX_MANIFOLDS THEN
    L_Config_Error := TRUE;
END_IF;

IF GVL_CONFIG.G_Max_Thermal_Budget <= 0.0 THEN
    L_Config_Error := TRUE;
END_IF;

IF GVL_CONFIG.G_Policy_Min_Hold_MS < 10000 THEN
    L_Config_Error := TRUE;
END_IF;

// Access pulse configuration
IF GVL_CONFIG.G_Access_Pulse_MS < 100 THEN
    L_Config_Error := TRUE;
ELSIF GVL_CONFIG.G_Access_Pulse_MS > 5000 THEN
    L_Config_Error := TRUE;
END_IF;

// Freeze hardware retry configuration
IF GVL_CONFIG.G_Freeze_Hardware_Retry_Count < 0 THEN
    L_Config_Error := TRUE;
END_IF;

IF GVL_CONFIG.G_Freeze_Hardware_Retry_Delay_MS < 1000 THEN
    L_Config_Error := TRUE;
END_IF;

// Pump exercise configuration
IF GVL_CONFIG.G_Pump_Exercise_Enabled THEN
    IF GVL_CONFIG.G_Pump_Exercise_Interval_MS < GVL_CONSTANTS.C_MS_IN_MINUTE THEN
        L_Config_Error := TRUE;
    END_IF;

    IF GVL_CONFIG.G_Pump_Exercise_Duration_MS < 1000 THEN
        L_Config_Error := TRUE;
    END_IF;
END_IF;

// Water valve exercise / retry configuration
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

// IO mapping sanity
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    IF (GVL_CONFIG.G_FloorTemp_Map[L_i] < 1) OR (GVL_CONFIG.G_FloorTemp_Map[L_i] > GVL_CONSTANTS.C_MAX_ZONES) THEN
        L_Config_Error := TRUE;
    END_IF;
END_FOR;

FOR L_i := 1 TO 16 DO
    IF (GVL_CONFIG.G_RoomTemp_Map[L_i] < 1) OR (GVL_CONFIG.G_RoomTemp_Map[L_i] > GVL_CONSTANTS.C_MAX_ZONES) THEN
        L_Config_Error := TRUE;
    END_IF;

    IF (GVL_CONFIG.G_Window_Map[L_i] < 1) OR (GVL_CONFIG.G_Window_Map[L_i] > GVL_CONSTANTS.C_MAX_INPUTS) THEN
        L_Config_Error := TRUE;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_DOOR_SENSORS DO
    IF (GVL_CONFIG.G_Door_Map[L_i] < 1) OR (GVL_CONFIG.G_Door_Map[L_i] > GVL_CONSTANTS.C_MAX_INPUTS) THEN
        L_Config_Error := TRUE;
    END_IF;
END_FOR;

IF L_Config_Error THEN
    GVL_STATUS.G_Diagnostics.Sensor_Fault := TRUE;
    GVL_STATUS.G_Diagnostics.Subsystem_Degraded := TRUE;
    GVL_STATUS.G_System_Mode_Text := 'CONFIG ERROR';
END_IF;

END_PROGRAM
// >>> BULK_SYNC_ANCHOR: PRG_Config_Validation <<<
