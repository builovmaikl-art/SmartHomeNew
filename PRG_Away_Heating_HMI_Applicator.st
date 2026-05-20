PROGRAM PRG_Away_Heating_HMI_Applicator
VAR
    L_Circuit : INT;
    L_Delay_MS : UDINT;
    L_Preheat_Lead_MS : UDINT;
    L_Return_Grace_MS : UDINT;
END_VAR

// HMI per-circuit profile update.
IF GVL_AWAY_HEATING_HMI.G_Set_Circuit_Profile_Req THEN
    L_Circuit := GVL_AWAY_HEATING_HMI.G_Profile_Circuit;

    IF (L_Circuit >= 1) AND (L_Circuit <= GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS) THEN
        IF (GVL_AWAY_HEATING_HMI.G_Profile_Comfort_Temp >= REAL#5.0) AND
           (GVL_AWAY_HEATING_HMI.G_Profile_Comfort_Temp <= REAL#30.0) AND
           (GVL_AWAY_HEATING_HMI.G_Profile_Economy_Temp >= REAL#5.0) AND
           (GVL_AWAY_HEATING_HMI.G_Profile_Economy_Temp <= GVL_AWAY_HEATING_HMI.G_Profile_Comfort_Temp) AND
           (GVL_AWAY_HEATING_HMI.G_Profile_Long_Away_Temp >= REAL#5.0) AND
           (GVL_AWAY_HEATING_HMI.G_Profile_Long_Away_Temp <= GVL_AWAY_HEATING_HMI.G_Profile_Economy_Temp) THEN

            GVL_CONFIG.G_HMI_FloorHeating_Configs[L_Circuit].use_in_normal := GVL_AWAY_HEATING_HMI.G_Profile_Use_In_Normal;
            GVL_CONFIG.G_HMI_FloorHeating_Configs[L_Circuit].use_in_away_preheat := GVL_AWAY_HEATING_HMI.G_Profile_Use_In_Away_Preheat;
            GVL_CONFIG.G_HMI_FloorHeating_Configs[L_Circuit].comfort_temp := GVL_AWAY_HEATING_HMI.G_Profile_Comfort_Temp;
            GVL_CONFIG.G_HMI_FloorHeating_Configs[L_Circuit].economy_temp := GVL_AWAY_HEATING_HMI.G_Profile_Economy_Temp;
            GVL_CONFIG.G_HMI_FloorHeating_Configs[L_Circuit].long_away_temp := GVL_AWAY_HEATING_HMI.G_Profile_Long_Away_Temp;
            GVL_CONFIG.G_HMI_FloorHeating_Configs[L_Circuit].design_temp := GVL_AWAY_HEATING_HMI.G_Profile_Comfort_Temp;

            GVL_AWAY_HEATING_HMI.G_Last_Error := FALSE;
            GVL_AWAY_HEATING_HMI.G_Last_Status_Text := 'Away heating profile applied';
        ELSE
            GVL_AWAY_HEATING_HMI.G_Last_Error := TRUE;
            GVL_AWAY_HEATING_HMI.G_Last_Status_Text := 'Away heating profile rejected: invalid temperatures';
        END_IF;
    ELSE
        GVL_AWAY_HEATING_HMI.G_Last_Error := TRUE;
        GVL_AWAY_HEATING_HMI.G_Last_Status_Text := 'Away heating profile rejected: invalid circuit';
    END_IF;

    GVL_AWAY_HEATING_HMI.G_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;
    GVL_AWAY_HEATING_HMI.G_Set_Circuit_Profile_Req := FALSE;
END_IF;

// Gateway compatibility: CMD_SET_TEMP updates comfort temperature for one circuit.
IF GVL_INTENT_USER.I_Set_Temp_Req THEN
    L_Circuit := GVL_INTENT_USER.I_Target_Zone;

    IF (L_Circuit >= 1) AND (L_Circuit <= GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS) AND
       (GVL_INTENT_USER.I_Target_Temperature >= REAL#5.0) AND
       (GVL_INTENT_USER.I_Target_Temperature <= REAL#30.0) THEN
        GVL_CONFIG.G_HMI_FloorHeating_Configs[L_Circuit].comfort_temp := GVL_INTENT_USER.I_Target_Temperature;
        GVL_CONFIG.G_HMI_FloorHeating_Configs[L_Circuit].design_temp := GVL_INTENT_USER.I_Target_Temperature;

        IF GVL_CONFIG.G_HMI_FloorHeating_Configs[L_Circuit].economy_temp <= REAL#0.0 THEN
            GVL_CONFIG.G_HMI_FloorHeating_Configs[L_Circuit].economy_temp := GVL_INTENT_USER.I_Target_Temperature - REAL#3.0;
        END_IF;

        IF GVL_CONFIG.G_HMI_FloorHeating_Configs[L_Circuit].long_away_temp <= REAL#0.0 THEN
            GVL_CONFIG.G_HMI_FloorHeating_Configs[L_Circuit].long_away_temp := GVL_POLICY.G_Away_Long_Economy_Setpoint_C;
        END_IF;
    END_IF;
END_IF;

// HMI planned return update. Delay is relative to current monotonic PLC time.
IF GVL_AWAY_HEATING_HMI.G_Set_Planned_Return_Req THEN
    IF GVL_AWAY_HEATING_HMI.G_Planned_Return_Enabled AND (GVL_AWAY_HEATING_HMI.G_Planned_Return_Delay_Hours > REAL#0.0) THEN
        L_Delay_MS := REAL_TO_UDINT(GVL_AWAY_HEATING_HMI.G_Planned_Return_Delay_Hours * REAL#3600000.0);
        L_Preheat_Lead_MS := REAL_TO_UDINT(GVL_AWAY_HEATING_HMI.G_Preheat_Lead_Hours * REAL#3600000.0);
        L_Return_Grace_MS := REAL_TO_UDINT(GVL_AWAY_HEATING_HMI.G_Return_Grace_Hours * REAL#3600000.0);

        IF L_Preheat_Lead_MS = 0 THEN
            L_Preheat_Lead_MS := 10800000;
        END_IF;
        IF L_Return_Grace_MS = 0 THEN
            L_Return_Grace_MS := 86400000;
        END_IF;

        GVL_POLICY.G_Away_Planned_Return_Enabled := TRUE;
        GVL_POLICY.G_Away_Planned_Return_MS := GVL_TIME_SERVICE.G_Now_MS + L_Delay_MS;
        GVL_POLICY.G_Away_Preheat_Lead_MS := L_Preheat_Lead_MS;
        GVL_POLICY.G_Away_Return_Grace_MS := L_Return_Grace_MS;
        GVL_POLICY.G_Away_Return_Expired := FALSE;
        GVL_POLICY.G_Away_Return_Grace_Active := FALSE;
        GVL_POLICY.G_Away_Return_Preheat_Active := FALSE;

        GVL_AWAY_HEATING_HMI.G_Last_Error := FALSE;
        GVL_AWAY_HEATING_HMI.G_Last_Status_Text := 'Planned return configured';
    ELSE
        GVL_POLICY.G_Away_Planned_Return_Enabled := FALSE;
        GVL_POLICY.G_Away_Return_Preheat_Active := FALSE;
        GVL_POLICY.G_Away_Return_Grace_Active := FALSE;
        GVL_POLICY.G_Away_Return_Expired := FALSE;

        GVL_AWAY_HEATING_HMI.G_Last_Error := FALSE;
        GVL_AWAY_HEATING_HMI.G_Last_Status_Text := 'Planned return disabled';
    END_IF;

    GVL_AWAY_HEATING_HMI.G_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;
    GVL_AWAY_HEATING_HMI.G_Set_Planned_Return_Req := FALSE;
END_IF;

IF GVL_AWAY_HEATING_HMI.G_Clear_Planned_Return_Req THEN
    GVL_POLICY.G_Away_Planned_Return_Enabled := FALSE;
    GVL_POLICY.G_Away_Return_Preheat_Active := FALSE;
    GVL_POLICY.G_Away_Return_Grace_Active := FALSE;
    GVL_POLICY.G_Away_Return_Expired := FALSE;
    GVL_AWAY_HEATING_HMI.G_Last_Error := FALSE;
    GVL_AWAY_HEATING_HMI.G_Last_Status_Text := 'Planned return cleared';
    GVL_AWAY_HEATING_HMI.G_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;
    GVL_AWAY_HEATING_HMI.G_Clear_Planned_Return_Req := FALSE;
END_IF;

// Gateway compatibility: CMD_SET_CONFIG with zone 0 configures/clears planned return.
IF GVL_INTENT_USER.I_Set_Config_Req AND (GVL_INTENT_USER.I_Target_Zone = 0) THEN
    IF GVL_GATEWAY.G_Gateway_Command.target_on_off AND (GVL_GATEWAY.G_Gateway_Command.target_value > REAL#0.0) THEN
        L_Delay_MS := REAL_TO_UDINT(GVL_GATEWAY.G_Gateway_Command.target_value * REAL#3600000.0);
        GVL_POLICY.G_Away_Planned_Return_Enabled := TRUE;
        GVL_POLICY.G_Away_Planned_Return_MS := GVL_TIME_SERVICE.G_Now_MS + L_Delay_MS;
        GVL_POLICY.G_Away_Return_Expired := FALSE;
        GVL_POLICY.G_Away_Return_Grace_Active := FALSE;
        GVL_POLICY.G_Away_Return_Preheat_Active := FALSE;
    ELSE
        GVL_POLICY.G_Away_Planned_Return_Enabled := FALSE;
        GVL_POLICY.G_Away_Return_Preheat_Active := FALSE;
        GVL_POLICY.G_Away_Return_Grace_Active := FALSE;
        GVL_POLICY.G_Away_Return_Expired := FALSE;
    END_IF;
END_IF;

END_PROGRAM