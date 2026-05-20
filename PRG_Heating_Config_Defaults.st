PROGRAM PRG_Heating_Config_Defaults
VAR
    L_i : INT;
    L_Manifold : BYTE;
END_VAR

// Default per-circuit comfort/economy profiles.
// This initializer only fills empty records and does not overwrite HMI-edited
// records after circuit_id has been assigned.
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    IF GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].circuit_id = 0 THEN
        CASE L_i OF
            1, 2, 3, 4:
                L_Manifold := 1;
            5, 6, 7, 8:
                L_Manifold := 2;
            9, 10, 11, 12:
                L_Manifold := 3;
            13, 14:
                L_Manifold := 4;
        ELSE
                L_Manifold := 5;
        END_CASE;

        GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].circuit_id := TO_BYTE(L_i);
        GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].zone := TO_BYTE(L_i);
        GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].manifold_id := L_Manifold;
        GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].sensor_id := TO_BYTE(L_i);
        GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].valve_id := TO_BYTE(L_i);
        GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].control_type := 1;

        // Historical design_temp is kept, but explicit comfort_temp is now the
        // room comfort setpoint used by FB_Heating_Circuit_Control.
        GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].design_temp := 22.0;
        GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].use_in_normal := TRUE;
        GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].use_in_away_preheat := TRUE;
        GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].comfort_temp := 22.0;
        GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].economy_temp := 17.0;
        GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].long_away_temp := 12.0;

        GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].min_temp := 5.0;
        GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].max_temp := 30.0;
        GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].pid_kp := 2.0;
        GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].pwm_period_s := 600;
    END_IF;
END_FOR;

END_PROGRAM