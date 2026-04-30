// ==============================================================================
// System gateway intent helper
//
// Internal helper for PRG_System / extracted system gateway contour.
// Owns gateway FB call, user intent publication, gateway command gates,
// and allowed configuration/time/scenario writes.
// ==============================================================================
FUNCTION_BLOCK FB_System_Gateway_Intent
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_IsActivePLC : BOOL;
    VI_Gateway_Writes_Allowed : BOOL;
END_VAR

VAR_IN_OUT
    VIO_FloorHeating_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF REAL;
    VIO_Zone_Valve_States : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
    VIO_Lighting_Base_Levels : ARRAY[1..32] OF BYTE;
    VIO_Scenario_Req_Gateway : E_SCENARIO_TYPE;
END_VAR

VAR
    fbGateway : FB_Gateway_Interface;
END_VAR

fbGateway(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_Local_PLC_Role := SEL(VI_IsActivePLC, E_PLC_ROLE.ROLE_STANDBY, E_PLC_ROLE.ROLE_ACTIVE),
    VI_Incoming_Command := GVL_GATEWAY.G_Gateway_Command,
    VI_Command_Received := GVL_GATEWAY.G_Gateway_Command_Received,
    VI_FloorHeating_Temps := VIO_FloorHeating_Temps,
    VI_Room_Temps := GVL_STATE.G_Room_Temps,
    VI_Zone_Valve_States := VIO_Zone_Valve_States,
    VI_Manifold_Pressures := GVL_STATE.G_Manifold_Pressures,
    VI_Manifold_Pump_States := GVL_STATE.G_Manifold_Pumps,
    VI_Outdoor_Temp := GVL_STATE.G_Outdoor_Temp,
    VI_Security_Armed := GVL_ALARM.G_Security_Armed,
    VI_Flood_Alarm_Active := GVL_ALARM.G_Flood_Alarm_Active,
    VI_Gas_Alarm_Active := GVL_ALARM.G_Gas_Alarm_Active,
    VI_Fire_Alarm_Active := GVL_ALARM.G_Fire_Alarm_Active,
    VI_Methane_Concentration := GVL_STATE.G_Methane_Sensors[1],
    VI_Lighting_Base_Levels := VIO_Lighting_Base_Levels,
    VI_Socket_States := GVL_STATE.G_Socket_States,
    VI_Blinds_Positions := GVL_STATE.G_Blinds_Positions,
    VI_Active_Scenario := GVL_STATUS.G_Current_Scenario,
    VI_Send_2FA_Req := GVL_COMMAND.G_Send_2FA_Req,
    VI_2FA_Code := GVL_COMMAND.G_2FA_Code_Out,
    VI_Allowed_IPs := GVL_CONFIG.G_Allowed_IPs,
    VO_Telegram_Msg => GVL_GATEWAY.G_Gateway_Telegram_Msg,
    VO_Send_Telegram => GVL_GATEWAY.G_Gateway_Send_Telegram,
    VO_HMI_Status_Message => GVL_GATEWAY.G_Gateway_HMI_Status_Message,

    VO_Data_Ready => GVL_GATEWAY.G_Gateway_Data_Ready,
    VO_Modbus_Registers => GVL_GATEWAY.G_Gateway_Modbus_Registers,
    VO_Arm_Req => GVL_COMMAND.G_Arm_Req,
    VO_Disarm_Req => GVL_COMMAND.G_Disarm_Req,
    VO_PIN_Code => GVL_COMMAND.G_PIN_Code,
    VO_RFID_Tag => GVL_COMMAND.G_RFID_Tag,
    VO_2FA_Code_In => GVL_COMMAND.G_2FA_Code_In,
    VO_Lighting_Override => GVL_COMMAND.G_Lighting_Override,
    VO_Blinds_Override => GVL_COMMAND.G_Blinds_Override,
    VO_Socket_Override => GVL_COMMAND.G_Socket_Override,
    VO_Reset_Errors_Req => GVL_COMMAND.G_Reset_Errors
);

GVL_INTENT_USER.I_Source_Valid := TRUE;
GVL_INTENT_USER.I_Last_Update_MS := VI_System_Time_MS;
GVL_INTENT_USER.I_Arm_Request := GVL_COMMAND.G_Arm_Req;
GVL_INTENT_USER.I_Disarm_Request := GVL_COMMAND.G_Disarm_Req;
GVL_INTENT_USER.I_PIN_Code := GVL_COMMAND.G_PIN_Code;
GVL_INTENT_USER.I_RFID_Tag := GVL_COMMAND.G_RFID_Tag;
GVL_INTENT_USER.I_2FA_Code_In := GVL_COMMAND.G_2FA_Code_In;
GVL_INTENT_USER.I_Lighting_Override_32 := GVL_COMMAND.G_Lighting_Override;
GVL_INTENT_USER.I_Blinds_Override_32 := GVL_COMMAND.G_Blinds_Override;
GVL_INTENT_USER.I_Socket_Override_32 := GVL_COMMAND.G_Socket_Override;
GVL_INTENT_USER.I_Reset_Errors := GVL_COMMAND.G_Reset_Errors;
GVL_INTENT_USER.I_Set_Temp_Req := fbGateway.VO_Set_Temp_Req;
GVL_INTENT_USER.I_Target_Zone := fbGateway.VO_Target_Zone;
GVL_INTENT_USER.I_Target_Temperature := fbGateway.VO_Target_Temp;
GVL_INTENT_USER.I_Set_Vent_Req := fbGateway.VO_Set_Vent_Req;
GVL_INTENT_USER.I_Target_Vent_Speed := fbGateway.VO_Target_Vent_Speed;
GVL_INTENT_USER.I_Set_Config_Req := fbGateway.VO_Set_Config_Req;
GVL_INTENT_USER.I_Time_Sync_Req := fbGateway.VO_Sync_Time_Req;
GVL_INTENT_USER.I_New_Time_MS := fbGateway.VO_New_Time_MS;

IF VI_Gateway_Writes_Allowed AND
   fbGateway.VO_Set_Scenario_Req AND
   ((GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL) OR
    (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_DEGRADED)) THEN
    VIO_Scenario_Req_Gateway := fbGateway.VO_Target_Scenario;
END_IF;

IF VI_Gateway_Writes_Allowed AND
   fbGateway.VO_Set_Temp_Req AND
   (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL) THEN
    GVL_CONFIG.G_HMI_FloorHeating_Configs[fbGateway.VO_Target_Zone].design_temp := fbGateway.VO_Target_Temp;
END_IF;

IF VI_Gateway_Writes_Allowed AND
   fbGateway.VO_Set_Vent_Req AND
   (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL) THEN
    GVL_CONFIG.G_HMI_Vent_Global_Config.default_supply_speed := fbGateway.VO_Target_Vent_Speed;
END_IF;

IF VI_Gateway_Writes_Allowed AND
   fbGateway.VO_Set_Config_Req AND
   (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL) THEN
    GVL_CONFIG.G_HMI_Apply_Settings := TRUE;
END_IF;

IF VI_Gateway_Writes_Allowed AND
   fbGateway.VO_Sync_Time_Req AND
   (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL) THEN
    GVL_STATUS.G_Time_Of_Day_MS := fbGateway.VO_New_Time_MS;
END_IF;

GVL_INTENT_USER.I_Scenario_Request := VIO_Scenario_Req_Gateway;
GVL_INTENT_USER.I_Gate_Open_Request := GVL_COMMAND.G_Gate_Open;
GVL_INTENT_USER.I_Wicket_Open_Request := GVL_COMMAND.G_Wicket_Open;
GVL_INTENT_USER.I_Lock_1_Open_Request := GVL_COMMAND.G_Lock_1_Open;
GVL_INTENT_USER.I_Lock_1_Close_Request := GVL_COMMAND.G_Lock_1_Close;
GVL_INTENT_USER.I_Lock_2_Open_Request := GVL_COMMAND.G_Lock_2_Open;
GVL_INTENT_USER.I_Lock_2_Close_Request := GVL_COMMAND.G_Lock_2_Close;
GVL_INTENT_USER.I_Dangerous_Action_Request := GVL_COMMAND.CMD_Dangerous_Action_Request;
GVL_INTENT_USER.I_Dangerous_Action_Confirm := GVL_COMMAND.CMD_Dangerous_Action_Confirm;
GVL_INTENT_USER.I_User_Access_Level := GVL_COMMAND.CMD_User_Access_Level;
GVL_INTENT_USER.I_Water_Selective_Recover := GVL_COMMAND.CMD_Water_Selective_Recover;
GVL_INTENT_USER.I_Gas_Selective_Recover := GVL_COMMAND.CMD_Gas_Selective_Recover;

// >>> BULK_SYNC_ANCHOR: FB_System_Gateway_Intent <<<
