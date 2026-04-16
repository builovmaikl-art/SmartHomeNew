FUNCTION_BLOCK FB_DHW_Legacy_To_V2_Command_Adapter_DRAFT
VAR_INPUT
    VI_Tank_ID : INT;
    VI_Enable : BOOL;
    VI_Target_Temp : REAL;
    VI_Pump_Enable : BOOL;
    VI_Heating_Priority : BOOL;
END_VAR
VAR_OUTPUT
    VO_Command_V2 : ST_DHW_Command_V2;
    VO_Translation_OK : BOOL;
END_VAR

VO_Command_V2.Tank_ID := VI_Tank_ID;
VO_Command_V2.Enabled := VI_Enable;
VO_Command_V2.Target_Temp := VI_Target_Temp;
VO_Command_V2.Pump_Enable := VI_Pump_Enable;
VO_Command_V2.Heating_Priority := VI_Heating_Priority;
VO_Command_V2.Source_Mode := 0;
VO_Translation_OK := TRUE;
END_FUNCTION_BLOCK
