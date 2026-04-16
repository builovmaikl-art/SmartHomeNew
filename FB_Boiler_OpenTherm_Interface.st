FUNCTION_BLOCK FB_Boiler_OpenTherm_Interface
VAR_INPUT
    VI_Enable : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VI_Setpoint : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL;

    VI_OT_Online : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VI_OT_Error : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
END_VAR

VAR_OUTPUT
    VO_OT_Enable : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    VO_OT_Setpoint : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL;
    VO_OT_Command_Valid : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
END_VAR

VAR
    L_i : INT;
END_VAR

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    VO_OT_Enable[L_i] := FALSE;
    VO_OT_Setpoint[L_i] := 0.0;
    VO_OT_Command_Valid[L_i] := FALSE;

    IF VI_Enable[L_i] AND VI_OT_Online[L_i] AND NOT VI_OT_Error[L_i] THEN
        VO_OT_Enable[L_i] := TRUE;
        VO_OT_Setpoint[L_i] := LIMIT(20.0, VI_Setpoint[L_i], 80.0);
        VO_OT_Command_Valid[L_i] := TRUE;
    END_IF;
END_FOR;
