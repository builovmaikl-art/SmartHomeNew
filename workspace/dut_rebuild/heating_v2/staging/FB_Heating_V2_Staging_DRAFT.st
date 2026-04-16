FUNCTION_BLOCK FB_Heating_V2_Staging_DRAFT
VAR_INPUT
    VI_Zone_ID : INT;
    VI_Enable : BOOL;
    VI_Target_Temp : REAL;
    VI_Valve_Position_Setpoint : REAL;
    VI_Pump_Enable : BOOL;

    VI_Is_Active : BOOL;
    VI_Room_Temp : REAL;
    VI_Supply_Temp : REAL;
    VI_Return_Temp : REAL;
    VI_Valve_Position_Actual : REAL;
    VI_Alarm_Active : BOOL;
END_VAR
VAR_OUTPUT
    VO_Command_Shadow : ST_Heating_Command_V2;
    VO_State_Shadow : ST_Heating_State_V2;
END_VAR
VAR
    fbCmdAdapter : FB_Heating_Legacy_To_V2_Command_Adapter_DRAFT;
    fbStateAdapter : FB_Heating_Legacy_To_V2_State_Adapter_DRAFT;
    fbCore : FB_Heating_V2_Core_DRAFT;

    L_Command_V2 : ST_Heating_Command_V2;
    L_State_V2 : ST_Heating_State_V2;
END_VAR

fbCmdAdapter(VI_Zone_ID := VI_Zone_ID, VI_Enable := VI_Enable, VI_Target_Temp := VI_Target_Temp, VI_Valve_Position_Setpoint := VI_Valve_Position_Setpoint, VI_Pump_Enable := VI_Pump_Enable, VO_Command_V2 => L_Command_V2);
fbStateAdapter(VI_Zone_ID := VI_Zone_ID, VI_Is_Active := VI_Is_Active, VI_Room_Temp := VI_Room_Temp, VI_Supply_Temp := VI_Supply_Temp, VI_Return_Temp := VI_Return_Temp, VI_Valve_Position_Actual := VI_Valve_Position_Actual, VI_Alarm_Active := VI_Alarm_Active, VO_State_V2 => L_State_V2);
fbCore(VI_Command := L_Command_V2, VI_State_In := L_State_V2, VO_Command_Out => VO_Command_Shadow, VO_State_Out => VO_State_Shadow);
END_FUNCTION_BLOCK
