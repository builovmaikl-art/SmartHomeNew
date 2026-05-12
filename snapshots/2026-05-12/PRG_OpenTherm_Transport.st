PROGRAM PRG_OpenTherm_Transport
VAR
    L_i : INT;
    L_Status_Word : WORD;
    L_Heartbeat : UDINT;
    L_Ack_Seq : UDINT;
END_VAR

// ======================================================
// REAL TRANSPORT LAYER CONTRACT
// ======================================================
// This layer converts high-level command/status structures
// into transport-safe wire images.
//
// Real Modbus RTU/TCP or serial IO code must:
//   1. Write G_Wire_Image command fields to adapter registers.
//   2. Read adapter status registers into G_Wire_Image status fields.
//
// This program keeps protocol encoding/decoding centralized.
// It does not claim transport online unless OpenTherm is enabled.
// ======================================================

IF NOT GVL_CONFIG.G_OpenTherm_Enabled THEN
    GVL_OPENTHERM_ADAPTER.G_Transport_Online := FALSE;
    GVL_OPENTHERM_ADAPTER.G_Transport_Error := FALSE;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
        GVL_OPENTHERM_ADAPTER.G_Wire_Image[L_i].Cmd_Enable := 0;
        GVL_OPENTHERM_ADAPTER.G_Wire_Image[L_i].Cmd_Setpoint_x10 := 0;
        GVL_OPENTHERM_ADAPTER.G_Wire_Image[L_i].Cmd_Seq_Lo := 0;
        GVL_OPENTHERM_ADAPTER.G_Wire_Image[L_i].Cmd_Seq_Hi := 0;

        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Raw_Online := FALSE;
        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Raw_Error := FALSE;
        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Raw_Flame := FALSE;
        GVL_OPENTHERM_ADAPTER.G_Status[L_i].Raw_Status_Word := 0;
    END_FOR;

    RETURN;
END_IF;

GVL_OPENTHERM_ADAPTER.G_Transport_Online := TRUE;
GVL_OPENTHERM_ADAPTER.G_Transport_Error := FALSE;
GVL_OPENTHERM_ADAPTER.G_Last_Transport_Update_MS := GVL_STATUS.G_System_Time_MS;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO

    // ======================================================
    // COMMAND → WIRE IMAGE
    // ======================================================
    IF GVL_OPENTHERM_ADAPTER.G_Command[L_i].Enable THEN
        GVL_OPENTHERM_ADAPTER.G_Wire_Image[L_i].Cmd_Enable := 1;
    ELSE
        GVL_OPENTHERM_ADAPTER.G_Wire_Image[L_i].Cmd_Enable := 0;
    END_IF;

    GVL_OPENTHERM_ADAPTER.G_Wire_Image[L_i].Cmd_Setpoint_x10 :=
        GVL_OPENTHERM_ADAPTER.G_Command[L_i].Setpoint_x10;

    GVL_OPENTHERM_ADAPTER.G_Wire_Image[L_i].Cmd_Seq_Lo :=
        UDINT_TO_WORD(GVL_OPENTHERM_ADAPTER.G_Command[L_i].Sequence AND 16#FFFF);

    GVL_OPENTHERM_ADAPTER.G_Wire_Image[L_i].Cmd_Seq_Hi :=
        UDINT_TO_WORD(SHR(GVL_OPENTHERM_ADAPTER.G_Command[L_i].Sequence, 16));

    // ======================================================
    // WIRE IMAGE → STATUS
    // ======================================================
    L_Heartbeat :=
        WORD_TO_UDINT(GVL_OPENTHERM_ADAPTER.G_Wire_Image[L_i].Status_Heartbeat_Lo)
        OR SHL(
            WORD_TO_UDINT(GVL_OPENTHERM_ADAPTER.G_Wire_Image[L_i].Status_Heartbeat_Hi),
            16
        );

    L_Ack_Seq :=
        WORD_TO_UDINT(GVL_OPENTHERM_ADAPTER.G_Wire_Image[L_i].Status_Ack_Seq_Lo)
        OR SHL(
            WORD_TO_UDINT(GVL_OPENTHERM_ADAPTER.G_Wire_Image[L_i].Status_Ack_Seq_Hi),
            16
        );

    GVL_OPENTHERM_ADAPTER.G_Status[L_i].Raw_Heartbeat := L_Heartbeat;
    GVL_OPENTHERM_ADAPTER.G_Status[L_i].Raw_Ack_Seq := L_Ack_Seq;

    L_Status_Word :=
        GVL_OPENTHERM_ADAPTER.G_Wire_Image[L_i].Status_Word;

    GVL_OPENTHERM_ADAPTER.G_Status[L_i].Raw_Online :=
        (L_Status_Word AND 16#0001) <> 0;

    GVL_OPENTHERM_ADAPTER.G_Status[L_i].Raw_Error :=
        (L_Status_Word AND 16#0002) <> 0;

    GVL_OPENTHERM_ADAPTER.G_Status[L_i].Raw_Flame :=
        (L_Status_Word AND 16#0004) <> 0;

    GVL_OPENTHERM_ADAPTER.G_Status[L_i].Raw_Status_Word :=
        L_Status_Word;

    GVL_OPENTHERM_ADAPTER.G_Status[L_i].Raw_Error_Code :=
        GVL_OPENTHERM_ADAPTER.G_Wire_Image[L_i].Error_Code;

    GVL_OPENTHERM_ADAPTER.G_Status[L_i].Raw_Modulation_x10 :=
        GVL_OPENTHERM_ADAPTER.G_Wire_Image[L_i].Modulation_x10;

    GVL_OPENTHERM_ADAPTER.G_Status[L_i].Raw_Boiler_Temp_x10 :=
        WORD_TO_INT(GVL_OPENTHERM_ADAPTER.G_Wire_Image[L_i].Boiler_Temp_x10);

END_FOR;

END_PROGRAM
