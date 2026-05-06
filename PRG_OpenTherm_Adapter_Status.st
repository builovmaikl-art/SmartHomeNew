PROGRAM PRG_OpenTherm_Adapter_Status
VAR
    L_i : INT;
    L_Now_MS : UDINT;
    L_Heartbeat_Age : UDINT;
    L_Command_Age : UDINT;
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO

    // ======================================================
    // HEARTBEAT VALIDATION
    // ======================================================
    IF GVL_OPENTHERM_ADAPTER.G_Status[L_i].Raw_Heartbeat <>
       GVL_OPENTHERM_ADAPTER.G_Status[L_i].Last_Heartbeat THEN

        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Last_Heartbeat :=
            GVL_OPENTHERM_ADAPTER.G_Status[L_i].Raw_Heartbeat;

        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Last_Heartbeat_MS := L_Now_MS;
    END_IF;

    L_Heartbeat_Age :=
        L_Now_MS - GVL_OPENTHERM_ADAPTER.G_Status[L_i].Last_Heartbeat_MS;

    GVL_OPENTHERM_ADAPTER.G_Status[L_i].Heartbeat_Timeout :=
        (L_Heartbeat_Age > GVL_OPENTHERM_ADAPTER.G_Heartbeat_Timeout_MS);

    // ======================================================
    // COMMAND ACK VALIDATION
    // ======================================================
    GVL_OPENTHERM_ADAPTER.G_Status[L_i].Command_Ack :=
        (GVL_OPENTHERM_ADAPTER.G_Status[L_i].Raw_Ack_Seq =
         GVL_OPENTHERM_ADAPTER.G_Command[L_i].Sequence);

    L_Command_Age :=
        L_Now_MS - GVL_OPENTHERM_ADAPTER.G_Command[L_i].Last_Write_MS;

    GVL_OPENTHERM_ADAPTER.G_Status[L_i].Command_Timeout :=
        (NOT GVL_OPENTHERM_ADAPTER.G_Status[L_i].Command_Ack) AND
        (L_Command_Age > GVL_OPENTHERM_ADAPTER.G_Command_Ack_Timeout_MS);

    // ======================================================
    // FINAL ADAPTER STATE
    // ======================================================
    GVL_OPENTHERM_ADAPTER.G_Status[L_i].Adapter_Online :=
        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Raw_Online AND
        (NOT GVL_OPENTHERM_ADAPTER.G_Status[L_i].Heartbeat_Timeout) AND
        (NOT GVL_OPENTHERM_ADAPTER.G_Status[L_i].Command_Timeout);

    GVL_OPENTHERM_ADAPTER.G_Status[L_i].Adapter_Error :=
        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Raw_Error OR
        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Command_Timeout OR
        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Heartbeat_Timeout;

    // ======================================================
    // ENUM STATES
    // ======================================================
    IF GVL_OPENTHERM_ADAPTER.G_Status[L_i].Heartbeat_Timeout THEN
        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Adapter_State := OT_STATE_HEARTBEAT_TIMEOUT;
        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Error_State := OT_ERROR_HEARTBEAT_TIMEOUT;

    ELSIF GVL_OPENTHERM_ADAPTER.G_Status[L_i].Command_Timeout THEN
        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Adapter_State := OT_STATE_ACK_TIMEOUT;
        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Error_State := OT_ERROR_ACK_TIMEOUT;

    ELSIF GVL_OPENTHERM_ADAPTER.G_Status[L_i].Raw_Error THEN
        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Adapter_State := OT_STATE_ADAPTER_ERROR;
        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Error_State := OT_ERROR_ADAPTER_FAULT;

    ELSIF GVL_OPENTHERM_ADAPTER.G_Status[L_i].Adapter_Online THEN
        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Adapter_State := OT_STATE_ONLINE;
        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Error_State := OT_ERROR_NONE;

    ELSE
        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Adapter_State := OT_STATE_OFFLINE;
        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Error_State := OT_ERROR_COMMUNICATION;
    END_IF;

    // ======================================================
    // PUBLISH TO SYSTEM STATE
    // ======================================================
    GVL_STATE.G_Boiler_OT_Online[L_i] :=
        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Adapter_Online;

    GVL_STATE.G_Boiler_Error[L_i] :=
        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Adapter_Error;

    GVL_STATE.G_Boiler_Flame[L_i] :=
        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Raw_Flame;

END_FOR;

END_PROGRAM
