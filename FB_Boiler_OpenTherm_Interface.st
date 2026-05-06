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
    L_Setpoint : REAL;
    L_Setpoint_x10 : UINT;
    L_Command_Enable : BOOL;
    L_Command_Changed : BOOL;
    L_Last_Command_Enable : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    L_Last_Command_Setpoint_x10 : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF UINT;
END_VAR

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO

    VO_OT_Enable[L_i] := FALSE;
    VO_OT_Setpoint[L_i] := 0.0;
    VO_OT_Command_Valid[L_i] := FALSE;

    L_Command_Enable := FALSE;
    L_Setpoint := 0.0;
    L_Setpoint_x10 := 0;

    // ======================================================
    // COMMAND VALIDATION
    // ======================================================
    IF VI_Enable[L_i] AND VI_OT_Online[L_i] AND NOT VI_OT_Error[L_i] THEN
        L_Command_Enable := TRUE;
        L_Setpoint := LIMIT(20.0, VI_Setpoint[L_i], 80.0);
        L_Setpoint_x10 := REAL_TO_UINT(L_Setpoint * 10.0);

        VO_OT_Enable[L_i] := TRUE;
        VO_OT_Setpoint[L_i] := L_Setpoint;
    END_IF;

    // ======================================================
    // PHYSICAL ADAPTER COMMAND IMAGE
    // ======================================================
    GVL_OPENTHERM_ADAPTER.G_Command[L_i].Enable := L_Command_Enable;
    GVL_OPENTHERM_ADAPTER.G_Command[L_i].Setpoint_x10 := L_Setpoint_x10;

    // Sequence is advanced only when the actual command image changes.
    // This keeps the command stable long enough for adapter ACK validation.
    L_Command_Changed :=
        (L_Command_Enable <> L_Last_Command_Enable[L_i]) OR
        (L_Setpoint_x10 <> L_Last_Command_Setpoint_x10[L_i]);

    IF L_Command_Changed THEN
        GVL_OPENTHERM_ADAPTER.G_Command[L_i].Sequence :=
            GVL_OPENTHERM_ADAPTER.G_Command[L_i].Sequence + 1;

        GVL_OPENTHERM_ADAPTER.G_Command[L_i].Last_Write_MS :=
            GVL_STATUS.G_System_Time_MS;

        L_Last_Command_Enable[L_i] := L_Command_Enable;
        L_Last_Command_Setpoint_x10[L_i] := L_Setpoint_x10;
    END_IF;

    // Command is valid only when the adapter confirms the current stable sequence.
    VO_OT_Command_Valid[L_i] :=
        L_Command_Enable AND
        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Command_Ack AND
        (NOT GVL_OPENTHERM_ADAPTER.G_Status[L_i].Adapter_Error) AND
        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Adapter_Online;

END_FOR;

END_FUNCTION_BLOCK
