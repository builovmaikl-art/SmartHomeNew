FUNCTION_BLOCK FB_Ventilation_V2_Staging_DRAFT
VAR_INPUT
    VI_Zone_ID : INT;
    VI_Enable : BOOL;
    VI_Fan_Speed_Setpoint : REAL;
    VI_Damper_Position_Setpoint : REAL;
    VI_Heat_Recovery_Enabled : BOOL;

    VI_Is_Active : BOOL;
    VI_Fan_Speed_Actual : REAL;
    VI_Supply_Temp : REAL;
    VI_Extract_Temp : REAL;
    VI_Filter_Dirty : BOOL;
    VI_Alarm_Active : BOOL;
END_VAR
VAR_OUTPUT
    VO_Command_Shadow : ST_Ventilation_Command_V2;
    VO_State_Shadow : ST_Ventilation_State_V2;
END_VAR
VAR
    fbCmdAdapter : FB_Ventilation_Legacy_To_V2_Command_Adapter_DRAFT;
    fbStateAdapter : FB_Ventilation_Legacy_To_V2_State_Adapter_DRAFT;
    fbCore : FB_Ventilation_V2_Core_DRAFT;

    L_Command_V2 : ST_Ventilation_Command_V2;
    L_State_V2 : ST_Ventilation_State_V2;
END_VAR

// Build V2 command
fbCmdAdapter(
    VI_Zone_ID := VI_Zone_ID,
    VI_Enable := VI_Enable,
    VI_Fan_Speed_Setpoint := VI_Fan_Speed_Setpoint,
    VI_Damper_Position_Setpoint := VI_Damper_Position_Setpoint,
    VI_Heat_Recovery_Enabled := VI_Heat_Recovery_Enabled,
    VO_Command_V2 => L_Command_V2
);

// Build V2 state
fbStateAdapter(
    VI_Zone_ID := VI_Zone_ID,
    VI_Is_Active := VI_Is_Active,
    VI_Fan_Speed_Actual := VI_Fan_Speed_Actual,
    VI_Supply_Temp := VI_Supply_Temp,
    VI_Extract_Temp := VI_Extract_Temp,
    VI_Filter_Dirty := VI_Filter_Dirty,
    VI_Alarm_Active := VI_Alarm_Active,
    VO_State_V2 => L_State_V2
);

// Run V2 core
fbCore(
    VI_Command := L_Command_V2,
    VI_State_In := L_State_V2,
    VO_Command_Out => VO_Command_Shadow,
    VO_State_Out => VO_State_Shadow
);

END_FUNCTION_BLOCK
