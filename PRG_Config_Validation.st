PROGRAM PRG_Config_Validation
VAR
    L_i : INT;
    L_Zone : INT;
    L_Sensor : INT;
    L_Manifold : INT;
    L_Config_Error : BOOL;
END_VAR

L_Config_Error := FALSE;

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

IF GVL_CONFIG.G_Max_Active_Manifolds < 1 THEN
    L_Config_Error := TRUE;
ELSIF GVL_CONFIG.G_Max_Active_Manifolds > GVL_CONSTANTS.C_MAX_MANIFOLDS THEN
    L_Config_Error := TRUE;
END_IF;

IF GVL_CONFIG.G_Max_Thermal_Budget <= 0.0 THEN
    L_Config_Error := TRUE;
END_IF;

IF L_Config_Error THEN
    GVL_STATUS.G_Diagnostics.Sensor_Fault := TRUE;
    GVL_STATUS.G_Diagnostics.Subsystem_Degraded := TRUE;
    GVL_STATUS.G_System_Mode_Text := 'CONFIG ERROR';
    GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
    GVL_COMMAND_SHADOW.G_Boiler_Stop := TRUE;
END_IF;

END_PROGRAM
// >>> BULK_SYNC_ANCHOR: PRG_Config_Validation <<<
