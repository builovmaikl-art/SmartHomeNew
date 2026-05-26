PROGRAM PRG_OpenTherm_Command_Interface
VAR
    fbBoilerOpenThermInterface : FB_Boiler_OpenTherm_Interface;
    L_i : INT;
    L_Enable : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    L_Setpoint : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL;
    L_Safety_Stop : BOOL;
END_VAR

L_Safety_Stop :=
    GVL_COMMAND_SHADOW.G_Boiler_Stop OR
    GVL_COMMAND_SHADOW.G_Heating_Gas_Safety_Stop OR
    (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = GAS) OR
    (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = GLOBAL_STOP);

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    IF L_Safety_Stop THEN
        L_Enable[L_i] := FALSE;
        L_Setpoint[L_i] := 0.0;
    ELSE
        L_Enable[L_i] := GVL_STATE.G_Boiler_OT_Enable[L_i];
        L_Setpoint[L_i] := GVL_STATE.G_Boiler_OT_Setpoint[L_i];
    END_IF;
END_FOR;

fbBoilerOpenThermInterface(
    VI_Enable := L_Enable,
    VI_Setpoint := L_Setpoint,
    VI_OT_Online := GVL_STATE.G_Boiler_OT_Online,
    VI_OT_Error := GVL_STATE.G_Boiler_OT_Adapter_Error
);

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    GVL_STATE.G_Boiler_OT_Enable[L_i] := fbBoilerOpenThermInterface.VO_OT_Enable[L_i];
    GVL_STATE.G_Boiler_OT_Setpoint[L_i] := fbBoilerOpenThermInterface.VO_OT_Setpoint[L_i];
    GVL_STATE.G_Boiler_OT_Command_Ack[L_i] := fbBoilerOpenThermInterface.VO_OT_Command_Valid[L_i];
END_FOR;

// >>> BULK_SYNC_ANCHOR: PRG_OpenTherm_Command_Interface <<<
END_PROGRAM
