PROGRAM PRG_Security
VAR
    L_i : INT;
    L_Motion_Sensors_16 : ARRAY[1..16] OF BOOL;
    fbSecurityManager : FB_Security_System_Manager;
    fbAccessControl : FB_Access_Control;
END_VAR


FOR L_i := 1 TO 16 DO
    L_Motion_Sensors_16[L_i] := GVL_STATE.G_Motion_Sensors[L_i];
END_FOR;
// 7. Система безопасности (Охранная сигнализация)
fbSecurityManager(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Motion_Sensors := L_Motion_Sensors_16,
    VI_Door_Sensors := GVL_STATE.G_Door_Sensors,
    VI_Window_Sensors := GVL_STATE.G_Window_Sensors,
    VI_Arm_Request := GVL_INTENT_USER.I_Arm_Request,
    VI_Disarm_Request := GVL_INTENT_USER.I_Disarm_Request,
    VI_PIN_Code := GVL_INTENT_USER.I_PIN_Code,
    VI_RFID_Tag := GVL_INTENT_USER.I_RFID_Tag,
    VI_2FA_Code := GVL_INTENT_USER.I_2FA_Code_In,
    VI_Config := GVL_CONFIG.G_Security_Config,
    VI_Bypass_Motion := GVL_CONFIG.G_Security_Config.bypass_motion,
    VI_Bypass_Doors := GVL_CONFIG.G_Security_Config.bypass_doors,
    VI_Bypass_Windows := GVL_CONFIG.G_Security_Config.bypass_windows,
    VI_Current_TOD := GVL_STATUS.G_Current_TOD,
    VO_Armed => GVL_ALARM.G_Security_Armed,
    VO_Alarm_Active => GVL_ALARM.G_Security_Alarm,
    VO_Siren_Active => GVL_ALARM.G_Security_Siren,
    VO_Status_Msg => GVL_STATUS.G_Security_Status_Msg,
    VO_Send_Code_Req => GVL_COMMAND.G_Send_2FA_Req,
    VO_Code_To_Send => GVL_COMMAND.G_2FA_Code_Out
);

// 7.1 Контроль доступа (СКУД)
fbAccessControl(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Armed := GVL_ALARM.G_Security_Armed,
    VI_System_Mode := GVL_STATE.G_System_Mode,
    VI_Gate_Open_Req := GVL_CONFIG.G_HMI_Gate_Open_Req,
    VI_Wicket_Open_Req := GVL_CONFIG.G_HMI_Wicket_Open_Req,
    VI_Lock_1_Open_Req := GVL_CONFIG.G_HMI_Lock_1_Open_Req,
    VI_Lock_1_Close_Req := GVL_CONFIG.G_HMI_Lock_1_Close_Req,
    VI_Lock_2_Open_Req := GVL_CONFIG.G_HMI_Lock_2_Open_Req,
    VI_Lock_2_Close_Req := GVL_CONFIG.G_HMI_Lock_2_Close_Req,
    VI_PIN_Code := GVL_INTENT_USER.I_PIN_Code,
    VI_RFID_Tag := GVL_INTENT_USER.I_RFID_Tag,
    VI_Access_Codes := GVL_Retain.G_Access_Codes,
    VI_RFID_Tags := GVL_Retain.G_RFID_Tags,
    VI_Config := GVL_CONFIG.G_Security_Config,
    VO_Gate_Open => GVL_INTENT_USER.I_Gate_Open_Request,
    VO_Wicket_Open => GVL_INTENT_USER.I_Wicket_Open_Request,
    VO_Lock_1_Open => GVL_INTENT_USER.I_Lock_1_Open_Request,
    VO_Lock_1_Close => GVL_INTENT_USER.I_Lock_1_Close_Request,
    VO_Lock_2_Open => GVL_INTENT_USER.I_Lock_2_Open_Request,
    VO_Lock_2_Close => GVL_INTENT_USER.I_Lock_2_Close_Request
);
END_PROGRAM
