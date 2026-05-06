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
END_VAR

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO

    VO_OT_Enable[L_i] := FALSE;
    VO_OT_Setpoint[L_i] := 0.0;
    VO_OT_Command_Valid[L_i] := FALSE;

    // ======================================================
    // DEFAULT SAFE COMMANDS
    // ======================================================
    GVL_OPENTHERM_ADAPTER.G_Command[L_i].Enable := FALSE;
    GVL_OPENTHERM_ADAPTER.G_Command[L_i].Setpoint_x10 := 0;

    // ======================================================
    // COMMAND VALIDATION
    // ======================================================
    IF VI_Enable[L_i] AND VI_OT_Online[L_i] AND NOT VI_OT_Error[L_i] THEN

        L_Setpoint := LIMIT(20.0, VI_Setpoint[L_i], 80.0);

        // Publish logical command outputs
        VO_OT_Enable[L_i] := TRUE;
        VO_OT_Setpoint[L_i] := L_Setpoint;

        // Publish physical adapter commands
        GVL_OPENTHERM_ADAPTER.G_Command[L_i].Enable := TRUE;
        GVL_OPENTHERM_ADAPTER.G_Command[L_i].Setpoint_x10 :=
            REAL_TO_UINT(L_Setpoint * 10.0);

        // Command sequence tracking
        GVL_OPENTHERM_ADAPTER.G_Command[L_i].Sequence :=
            GVL_OPENTHERM_ADAPTER.G_Command[L_i].Sequence + 1;

        GVL_OPENTHERM_ADAPTER.G_Command[L_i].Last_Write_MS :=
            GVL_STATUS.G_System_Time_MS;

        // Command valid only if adapter confirmed delivery
        VO_OT_Command_Valid[L_i] :=
            GVL_OPENTHERM_ADAPTER.G_Status[L_i].Command_Ack AND
            (NOT GVL_OPENTHERM_ADAPTER.G_Status[L_i].Adapter_Error) AND
            GVL_OPENTHERM_ADAPTER.G_Status[L_i].Adapter_Online;

    END_IF;

END_FOR;

END_FUNCTION_BLOCK
