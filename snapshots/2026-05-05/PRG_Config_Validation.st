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

    IF (L_Zone < 1) OR (L_Zone > GVL_CONSTANTS.C_MAX_ZONES) THEN L_Config_Error := TRUE; END_IF;
    IF (L_Sensor < 1) OR (L_Sensor > GVL_CONSTANTS.C_MAX_ZONES) THEN L_Config_Error := TRUE; END_IF;
    IF (L_Manifold < 1) OR (L_Manifold > GVL_CONSTANTS.C_MAX_MANIFOLDS) THEN L_Config_Error := TRUE; END_IF;
END_FOR;

IF (GVL_CONFIG.G_Max_Active_Manifolds < 1) OR
   (GVL_CONFIG.G_Max_Active_Manifolds > GVL_CONSTANTS.C_MAX_MANIFOLDS) THEN
    L_Config_Error := TRUE;
END_IF;

IF GVL_CONFIG.G_Max_Thermal_Budget <= 0.0 THEN L_Config_Error := TRUE; END_IF;

IF (GVL_CONFIG.G_Access_Pulse_MS < 100) OR (GVL_CONFIG.G_Access_Pulse_MS > 5000) THEN
    L_Config_Error := TRUE;
END_IF;

// store flags
GVL_CONFIG_VALIDATION.G_Config_Valid := NOT L_Config_Error;
GVL_CONFIG_VALIDATION.G_Config_Critical_Error := L_Config_Error;

IF L_Config_Error THEN
    GVL_STATUS.G_Diagnostics.Subsystem_Degraded := TRUE;
    GVL_STATUS.G_System_Mode_Text := 'CONFIG ERROR';
END_IF;

END_PROGRAM
