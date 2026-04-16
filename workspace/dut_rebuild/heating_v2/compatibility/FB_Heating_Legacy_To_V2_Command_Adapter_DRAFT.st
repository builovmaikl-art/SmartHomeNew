FUNCTION_BLOCK FB_Heating_Legacy_To_V2_Command_Adapter_DRAFT
VAR_INPUT
    VI_Zone_ID : INT;
    VI_Enable : BOOL;
    VI_Target_Temp : REAL;
    VI_Valve_Position_Setpoint : REAL;
    VI_Pump_Enable : BOOL;
END_VAR
VAR_OUTPUT
    VO_Command_V2 : ST_Heating_Command_V2;
    VO_Translation_OK : BOOL;
END_VAR

VO_Command_V2.Zone_ID := VI_Zone_ID;
VO_Command_V2.Enabled := VI_Enable;
VO_Command_V2.Target_Temp := VI_Target_Temp;
VO_Command_V2.Valve_Position_Setpoint := VI_Valve_Position_Setpoint;
VO_Command_V2.Pump_Enable := VI_Pump_Enable;
VO_Command_V2.Source_Mode := 0;
VO_Translation_OK := TRUE;
END_FUNCTION_BLOCK
