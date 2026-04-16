FUNCTION_BLOCK FB_DHW_V2_Staging_DRAFT
VAR_INPUT
    VI_Tank_ID : INT;
    VI_Enable : BOOL;
    VI_Target_Temp : REAL;
    VI_Pump_Enable : BOOL;
    VI_Heating_Priority : BOOL;

    VI_Is_Active : BOOL;
    VI_Tank_Temp : REAL;
    VI_Supply_Temp : REAL;
    VI_Return_Temp : REAL;
    VI_Pump_Actual : BOOL;
    VI_Alarm_Active : BOOL;
END_VAR
VAR_OUTPUT
    VO_Command_Shadow : ST_DHW_Command_V2;
    VO_State_Shadow : ST_DHW_State_V2;
END_VAR
VAR
    fbCmdAdapter : FB_DHW_Legacy_To_V2_Command_Adapter_DRAFT;
    fbStateAdapter : FB_DHW_Legacy_To_V2_State_Adapter_DRAFT;
    fbCore : FB_DHW_V2_Core_DRAFT;
    L_Command_V2 : ST_DHW_Command_V2;
    L_State_V2 : ST_DHW_State_V2;
END_VAR

fbCmdAdapter(
    VI_Tank_ID := VI_Tank_ID,
    VI_Enable := VI_Enable,
    VI_Target_Temp := VI_Target_Temp,
    VI_Pump_Enable := VI_Pump_Enable,
    VI_Heating_Priority := VI_Heating_Priority,
    VO_Command_V2 => L_Command_V2
);

fbStateAdapter(
    VI_Tank_ID := VI_Tank_ID,
    VI_Is_Active := VI_Is_Active,
    VI_Tank_Temp := VI_Tank_Temp,
    VI_Supply_Temp := VI_Supply_Temp,
    VI_Return_Temp := VI_Return_Temp,
    VI_Pump_Actual := VI_Pump_Actual,
    VI_Alarm_Active := VI_Alarm_Active,
    VO_State_V2 => L_State_V2
);

fbCore(
    VI_Command := L_Command_V2,
    VI_State_In := L_State_V2,
    VO_Command_Out => VO_Command_Shadow,
    VO_State_Out => VO_State_Shadow
);

END_FUNCTION_BLOCK
