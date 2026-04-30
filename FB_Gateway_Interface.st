FUNCTION_BLOCK FB_Gateway_Interface
VAR_INPUT
    VI_System_Time_MS           : UDINT;
    VI_Local_PLC_Role           : E_PLC_ROLE;
    VI_Incoming_Command         : ST_Gateway_Command;
    VI_Command_Received         : BOOL;
    
    VI_Outdoor_Temp             : REAL;
    VI_Security_Armed           : BOOL;
    VI_Flood_Alarm_Active       : BOOL;
    VI_Gas_Alarm_Active         : BOOL;
    VI_Fire_Alarm_Active        : BOOL;
    VI_Methane_Concentration    : REAL;
    VI_Active_Scenario          : E_SCENARIO_TYPE;
    
    VI_Send_2FA_Req             : BOOL;
    VI_2FA_Code                 : STRING(6);
END_VAR

VAR_IN_OUT
    VI_FloorHeating_Temps       : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF REAL;
    VI_Room_Temps               : ARRAY[1..16] OF REAL;
    VI_Zone_Valve_States        : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
    VI_Manifold_Pressures       : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_Manifold_Pump_States     : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Lighting_Base_Levels     : ARRAY[1..32] OF BYTE;
    VI_Socket_States            : ARRAY[1..GVL_CONSTANTS.C_MAX_SOCKETS] OF BOOL;
    VI_Blinds_Positions         : ARRAY[1..GVL_CONSTANTS.C_MAX_BLINDS] OF BYTE;
    VI_Allowed_IPs              : ARRAY[1..GVL_CONSTANTS.C_MAX_ALLOWED_IPS] OF STRING(15);
END_VAR

VAR_OUTPUT
    VO_Modbus_Registers         : ARRAY[0..GVL_CONSTANTS.C_MAX_MODBUS_REGISTERS-1] OF WORD;
    VO_Lighting_Override        : ARRAY[1..32] OF BYTE;
    VO_Blinds_Override          : ARRAY[1..GVL_CONSTANTS.C_MAX_BLINDS] OF BYTE;
    VO_Socket_Override          : ARRAY[1..GVL_CONSTANTS.C_MAX_SOCKETS] OF BOOL;
    VO_Arm_Req                  : BOOL;
    VO_Disarm_Req               : BOOL;
    VO_PIN_Code                 : STRING(4);
    VO_RFID_Tag                 : STRING(20);
    VO_2FA_Code_In              : STRING(6);
    VO_Data_Ready               : BOOL;
    VO_HMI_Status_Message       : STRING(200);
    VO_Telegram_Msg             : STRING(200);
    VO_Send_Telegram            : BOOL;
    VO_Set_Scenario_Req         : BOOL;
    VO_Target_Scenario          : E_SCENARIO_TYPE;
    VO_Set_Temp_Req             : BOOL;
    VO_Target_Zone              : INT;
    VO_Target_Temp              : REAL;
    VO_Set_Vent_Req             : BOOL;
    VO_Target_Vent_Speed        : BYTE;
    VO_Reset_Errors_Req         : BOOL;
    VO_Set_Config_Req           : BOOL;
    VO_Sync_Time_Req            : BOOL;
    VO_New_Time_MS              : UDINT;
END_VAR

VAR
    L_CRC_Calc : FB_CRC32_Calculator;
    L_Calculated_CRC : DWORD;
    L_Process_Command : ST_Gateway_Command;
    L_Has_Command_To_Process : BOOL;
END_VAR

// CRC check simplified
L_CRC_Calc();
L_Calculated_CRC := L_CRC_Calc.VO_CRC;

IF L_Has_Command_To_Process THEN
    IF L_Calculated_CRC = L_Process_Command.crc32 THEN
        VO_HMI_Status_Message := 'CRC OK';
    ELSE
        VO_HMI_Status_Message := 'CRC ERROR';
    END_IF;
END_IF;

END_FUNCTION_BLOCK
