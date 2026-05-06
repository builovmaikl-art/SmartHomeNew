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
    IF GVL_OPENTHERM_ADAPTER.G_Raw_Heartbeat[L_i] <> GVL_OPENTHERM_ADAPTER.G_Last_Heartbeat[L_i] THEN
        GVL_OPENTHERM_ADAPTER.G_Last_Heartbeat[L_i] := GVL_OPENTHERM_ADAPTER.G_Raw_Heartbeat[L_i];
        GVL_OPENTHERM_ADAPTER.G_Last_Heartbeat_MS[L_i] := L_Now_MS;
    END_IF;

    L_Heartbeat_Age := L_Now_MS - GVL_OPENTHERM_ADAPTER.G_Last_Heartbeat_MS[L_i];

    GVL_OPENTHERM_ADAPTER.G_Heartbeat_Timeout[L_i] :=
        (L_Heartbeat_Age > GVL_OPENTHERM_ADAPTER.G_Heartbeat_Timeout_MS);

    // ======================================================
    // COMMAND ACK VALIDATION
    // ======================================================
    GVL_OPENTHERM_ADAPTER.G_Command_Ack[L_i] :=
        (GVL_OPENTHERM_ADAPTER.G_Raw_Ack_Seq[L_i] = GVL_OPENTHERM_ADAPTER.G_Cmd_Seq[L_i]);

    L_Command_Age := L_Now_MS - GVL_OPENTHERM_ADAPTER.G_Cmd_Last_Write_MS[L_i];

    GVL_OPENTHERM_ADAPTER.G_Command_Timeout[L_i] :=
        (NOT GVL_OPENTHERM_ADAPTER.G_Command_Ack[L_i]) AND
        (L_Command_Age > GVL_OPENTHERM_ADAPTER.G_Command_Ack_Timeout_MS);

    // ======================================================
    // FINAL ADAPTER STATE
    // ======================================================
    GVL_OPENTHERM_ADAPTER.G_Adapter_Online[L_i] :=
        GVL_OPENTHERM_ADAPTER.G_Raw_Online[L_i] AND
        (NOT GVL_OPENTHERM_ADAPTER.G_Heartbeat_Timeout[L_i]) AND
        (NOT GVL_OPENTHERM_ADAPTER.G_Command_Timeout[L_i]);

    GVL_OPENTHERM_ADAPTER.G_Adapter_Error[L_i] :=
        GVL_OPENTHERM_ADAPTER.G_Raw_Error[L_i] OR
        GVL_OPENTHERM_ADAPTER.G_Command_Timeout[L_i] OR
        GVL_OPENTHERM_ADAPTER.G_Heartbeat_Timeout[L_i];

    GVL_OPENTHERM_ADAPTER.G_Last_Error_Code[L_i] :=
        GVL_OPENTHERM_ADAPTER.G_Raw_Error_Code[L_i];

    // ======================================================
    // PUBLISH TO SYSTEM STATE
    // ======================================================
    GVL_STATE.G_Boiler_OT_Online[L_i] :=
        GVL_OPENTHERM_ADAPTER.G_Adapter_Online[L_i];

    GVL_STATE.G_Boiler_Error[L_i] :=
        GVL_OPENTHERM_ADAPTER.G_Adapter_Error[L_i];

    GVL_STATE.G_Boiler_Flame[L_i] :=
        GVL_OPENTHERM_ADAPTER.G_Raw_Flame[L_i];

END_FOR;

END_PROGRAM
