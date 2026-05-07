FUNCTION_BLOCK FB_Modbus_RTU_SysCom_Backend
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR

VAR
    L_Result : UDINT;
    L_Handle : UDINT := 16#FFFFFFFF;

    L_Settings : SysCom.SysComSettings;
    L_SettingsEx2 : SysCom.SysComSettingsEx2;

    L_Bytes_Written : UDINT;
    L_Bytes_Read : UDINT;

    L_RX_Buffer : ARRAY[0..255] OF BYTE;

    L_Open_Done : BOOL := FALSE;
    L_i : INT;
    L_j : INT;
    L_Read_Count : INT;
    L_Target_Index : INT;
    L_Frame_Length : INT;

    L_CRC : WORD;
    L_CRC_Frame : WORD;

    L_Baudrate : UDINT;
    L_Interframe_MS : UDINT;
END_VAR

// ======================================================
// MODBUS RTU SYSCOM BACKEND
// ======================================================
// Industrial transport runtime:
//   - serial open/configure
//   - RX assembler
//   - CRC validation
//   - watchdog supervision
//   - reconnect supervision
// ======================================================

IF NOT VI_Enable THEN

    IF L_Handle <> 16#FFFFFFFF THEN
        SysCom.SysComClose(hCom := L_Handle);
        L_Handle := 16#FFFFFFFF;
    END_IF;

    L_Open_Done := FALSE;

    GVL_MODBUS_SYSCOM_TRANSPORT.G_Transport_Attached := FALSE;
    GVL_MODBUS_SYSCOM_TRANSPORT.G_Backend_Online := FALSE;

    GVL_MODBUS_SYSCOM_TRANSPORT.G_Backend_State :=
        MB_SYSCOM_CLOSED;

    GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_State :=
        MB_RTU_RX_IDLE;

    GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Assembler_Active := FALSE;
    GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Assembler_Length := 0;

    RETURN;
END_IF;

// ======================================================
// WATCHDOGS
// ======================================================
GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Watchdog_Timeout := FALSE;
GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Watchdog_Timeout := FALSE;
GVL_MODBUS_SYSCOM_TRANSPORT.G_Bus_Silent := FALSE;

IF GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Request THEN

    IF (VI_System_Time_MS -
        GVL_MODBUS_SYSCOM_TRANSPORT.G_Last_TX_Request_MS) >
        (GVL_CONFIG.G_Modbus_RTU_Request_Timeout_MS * 2) THEN

        GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Watchdog_Timeout := TRUE;

        GVL_MODBUS_SYSCOM_TRANSPORT.G_Total_TX_Watchdog :=
            GVL_MODBUS_SYSCOM_TRANSPORT.G_Total_TX_Watchdog + 1;

    END_IF;

END_IF;

IF GVL_MODBUS_SYSCOM_TRANSPORT.G_Backend_Online THEN

    IF (VI_System_Time_MS -
        GVL_MODBUS_SYSCOM_TRANSPORT.G_Last_RX_MS) > 30000 THEN

        GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Watchdog_Timeout := TRUE;

        GVL_MODBUS_SYSCOM_TRANSPORT.G_Total_RX_Watchdog :=
            GVL_MODBUS_SYSCOM_TRANSPORT.G_Total_RX_Watchdog + 1;

        GVL_MODBUS_SYSCOM_TRANSPORT.G_Bus_Silent := TRUE;

    END_IF;

END_IF;

// ======================================================
// RECONNECT WAIT STATE
// ======================================================
IF GVL_MODBUS_SYSCOM_TRANSPORT.G_Backend_State =
   MB_SYSCOM_RECONNECT_WAIT THEN

    IF (VI_System_Time_MS -
        GVL_MODBUS_SYSCOM_TRANSPORT.G_Backend_Last_Error_MS) >=
        GVL_MODBUS_SYSCOM_TRANSPORT.G_Backend_Reconnect_Delay_MS THEN

        GVL_MODBUS_SYSCOM_TRANSPORT.G_Backend_State :=
            MB_SYSCOM_OPENING;

    ELSE

        RETURN;

    END_IF;

END_IF;

// ======================================================
// OPEN + CONFIGURE
// ======================================================
IF NOT L_Open_Done THEN

    GVL_MODBUS_SYSCOM_TRANSPORT.G_Backend_State :=
        MB_SYSCOM_OPENING;

    L_Baudrate := GVL_CONFIG.G_Modbus_RTU_Baudrate;

    IF L_Baudrate <= 9600 THEN
        L_Interframe_MS := 5;
    ELSIF L_Baudrate <= 19200 THEN
        L_Interframe_MS := 3;
    ELSE
        L_Interframe_MS := 2;
    END_IF;

    GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Assembler_InterFrame_MS :=
        L_Interframe_MS;

    CASE GVL_CONFIG.G_Modbus_RTU_Port_Number OF
        1:
            L_Settings.sPort := SysCom.SYS_COMPORT1;
        2:
            L_Settings.sPort := SysCom.SYS_COMPORT2;
        3:
            L_Settings.sPort := SysCom.SYS_COMPORT3;
        4:
            L_Settings.sPort := SysCom.SYS_COMPORT4;
    ELSE
        L_Settings.sPort := SysCom.SYS_COMPORT1;
    END_CASE;

    CASE GVL_CONFIG.G_Modbus_RTU_Baudrate OF
        4800:
            L_Settings.ulBaudrate := SysCom.SYS_BR_4800;
        9600:
            L_Settings.ulBaudrate := SysCom.SYS_BR_9600;
        19200:
            L_Settings.ulBaudrate := SysCom.SYS_BR_19200;
        38400:
            L_Settings.ulBaudrate := SysCom.SYS_BR_38400;
        57600:
            L_Settings.ulBaudrate := SysCom.SYS_BR_57600;
        115200:
            L_Settings.ulBaudrate := SysCom.SYS_BR_115200;
    ELSE
        L_Settings.ulBaudrate := SysCom.SYS_BR_9600;
    END_CASE;

    CASE GVL_CONFIG.G_Modbus_RTU_Parity OF
        0:
            L_Settings.byParity := SysCom.SYS_NOPARITY;
        1:
            L_Settings.byParity := SysCom.SYS_EVENPARITY;
        2:
            L_Settings.byParity := SysCom.SYS_ODDPARITY;
    ELSE
        L_Settings.byParity := SysCom.SYS_EVENPARITY;
    END_CASE;

    CASE GVL_CONFIG.G_Modbus_RTU_Stop_Bits OF
        1:
            L_Settings.byStopBits := SysCom.SYS_ONESTOPBIT;
        2:
            L_Settings.byStopBits := SysCom.SYS_TWOSTOPBITS;
    ELSE
        L_Settings.byStopBits := SysCom.SYS_ONESTOPBIT;
    END_CASE;

    L_Settings.ulTimeout := GVL_CONFIG.G_Modbus_RTU_Request_Timeout_MS;
    L_Settings.ulBufferSize := 512;

    IF GVL_CONFIG.G_Modbus_RTU_Data_Bits < 7 THEN
        L_SettingsEx2.byByteSize := 8;
    ELSIF GVL_CONFIG.G_Modbus_RTU_Data_Bits > 8 THEN
        L_SettingsEx2.byByteSize := 8;
    ELSE
        L_SettingsEx2.byByteSize := GVL_CONFIG.G_Modbus_RTU_Data_Bits;
    END_IF;

    L_SettingsEx2.bBinary := TRUE;
    L_SettingsEx2.bOutxCtsFlow := FALSE;
    L_SettingsEx2.bOutxDsrFlow := FALSE;
    L_SettingsEx2.byDtrControl := 0;
    L_SettingsEx2.bDsrSensitivity := FALSE;
    L_SettingsEx2.byRtsControl := 0;
    L_SettingsEx2.bTXContinueOnXoff := FALSE;
    L_SettingsEx2.bOutX := FALSE;
    L_SettingsEx2.bInX := FALSE;
    L_SettingsEx2.byXonChar := 0;
    L_SettingsEx2.byXoffChar := 0;
    L_SettingsEx2.wXonLim := 0;
    L_SettingsEx2.wXoffLim := 0;

    L_Handle := SysCom.SysComOpen3(
        pSettings := ADR(L_Settings),
        pSettingsEx2 := ADR(L_SettingsEx2),
        pResult := ADR(L_Result)
    );

    IF L_Handle <> 16#FFFFFFFF THEN

        SysCom.SysComPurge(hCom := L_Handle);

        L_Open_Done := TRUE;

        GVL_MODBUS_SYSCOM_TRANSPORT.G_Transport_Attached := TRUE;
        GVL_MODBUS_SYSCOM_TRANSPORT.G_Backend_Online := TRUE;

        GVL_MODBUS_SYSCOM_TRANSPORT.G_Backend_State :=
            MB_SYSCOM_ONLINE;

    ELSE

        GVL_MODBUS_SYSCOM_TRANSPORT.G_Transport_Attached := FALSE;
        GVL_MODBUS_SYSCOM_TRANSPORT.G_Backend_Online := FALSE;

        GVL_MODBUS_SYSCOM_TRANSPORT.G_Backend_State :=
            MB_SYSCOM_RECONNECT_WAIT;

        GVL_MODBUS_SYSCOM_TRANSPORT.G_Backend_Last_Error_MS :=
            VI_System_Time_MS;

        GVL_MODBUS_SYSCOM_TRANSPORT.G_Backend_Reconnect_Attempts :=
            GVL_MODBUS_SYSCOM_TRANSPORT.G_Backend_Reconnect_Attempts + 1;

        GVL_MODBUS_SYSCOM_TRANSPORT.G_Total_Reconnects :=
            GVL_MODBUS_SYSCOM_TRANSPORT.G_Total_Reconnects + 1;

        GVL_MODBUS_SYSCOM_TRANSPORT.G_Total_Errors :=
            GVL_MODBUS_SYSCOM_TRANSPORT.G_Total_Errors + 1;

    END_IF;

    RETURN;
END_IF;

GVL_MODBUS_SYSCOM_TRANSPORT.G_Backend_State :=
    MB_SYSCOM_ONLINE;

// ======================================================
// TX WRITE
// ======================================================
IF GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Request AND
   NOT GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Done THEN

    L_Bytes_Written := SysCom.SysComWrite(
        hCom := L_Handle,
        pbyBuffer := ADR(GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Buffer),
        ulSize := GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Length,
        ulTimeout := GVL_CONFIG.G_Modbus_RTU_Request_Timeout_MS,
        pResult := ADR(L_Result)
    );

    IF L_Bytes_Written = GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Length THEN

        GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Done := TRUE;

    ELSE

        GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Error := TRUE;

        GVL_MODBUS_SYSCOM_TRANSPORT.G_Backend_State :=
            MB_SYSCOM_ERROR;

    END_IF;

END_IF;

// ======================================================
// RX STREAM READ
// ======================================================
L_Bytes_Read := SysCom.SysComRead(
    hCom := L_Handle,
    pbyBuffer := ADR(L_RX_Buffer),
    ulSize := 256,
    ulTimeout := SysCom.SYS_NOWAIT,
    pResult := ADR(L_Result)
);

IF L_Bytes_Read > 0 THEN

    GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_State :=
        MB_RTU_RX_RECEIVING;

    IF L_Bytes_Read > 256 THEN
        L_Read_Count := 256;
    ELSE
        L_Read_Count := UDINT_TO_INT(L_Bytes_Read);
    END_IF;

    GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Assembler_Active := TRUE;

    GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Assembler_Last_Byte_MS :=
        VI_System_Time_MS;

    FOR L_i := 0 TO (L_Read_Count - 1) DO

        L_Target_Index :=
            UINT_TO_INT(GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Assembler_Length);

        IF L_Target_Index >= 256 THEN

            GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_State :=
                MB_RTU_RX_OVERFLOW;

            GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Assembler_Overflow := TRUE;

            GVL_MODBUS_SYSCOM_TRANSPORT.G_Total_RX_Overflow :=
                GVL_MODBUS_SYSCOM_TRANSPORT.G_Total_RX_Overflow + 1;

            GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Assembler_Active := FALSE;
            GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Assembler_Length := 0;

            EXIT;

        END_IF;

        GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Buffer[L_Target_Index] :=
            L_RX_Buffer[L_i];

        GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Assembler_Length :=
            GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Assembler_Length + 1;

    END_FOR;

END_IF;

// ======================================================
// INTER-FRAME FINALIZATION
// ======================================================
IF GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Assembler_Active THEN

    IF (VI_System_Time_MS -
        GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Assembler_Last_Byte_MS) >=
        GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Assembler_InterFrame_MS THEN

        L_Frame_Length :=
            UINT_TO_INT(GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Assembler_Length);

        IF L_Frame_Length >= 4 THEN

            L_CRC := 16#FFFF;

            FOR L_i := 0 TO (L_Frame_Length - 3) DO

                L_CRC := L_CRC XOR
                    BYTE_TO_WORD(
                        GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Buffer[L_i]
                    );

                FOR L_j := 0 TO 7 DO

                    IF (L_CRC AND 16#0001) <> 0 THEN
                        L_CRC := SHR(L_CRC, 1);
                        L_CRC := L_CRC XOR 16#A001;
                    ELSE
                        L_CRC := SHR(L_CRC, 1);
                    END_IF;

                END_FOR;

            END_FOR;

            L_CRC_Frame :=
                BYTE_TO_WORD(
                    GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Buffer[L_Frame_Length - 2]
                );

            L_CRC_Frame :=
                L_CRC_Frame OR
                SHL(
                    BYTE_TO_WORD(
                        GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Buffer[L_Frame_Length - 1]
                    ),
                    8
                );

            GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Assembler_CRC_Calc :=
                L_CRC;

            GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Assembler_CRC_Frame :=
                L_CRC_Frame;

            IF L_CRC = L_CRC_Frame THEN

                GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_State :=
                    MB_RTU_RX_FRAME_READY;

                GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Assembler_CRC_OK := TRUE;

                GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Length :=
                    GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Assembler_Length;

                GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Ready := TRUE;

                GVL_MODBUS_SYSCOM_TRANSPORT.G_Total_RX :=
                    GVL_MODBUS_SYSCOM_TRANSPORT.G_Total_RX + 1;

                GVL_MODBUS_SYSCOM_TRANSPORT.G_Last_RX_MS :=
                    VI_System_Time_MS;

            ELSE

                GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_State :=
                    MB_RTU_RX_CRC_ERROR;

                GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Assembler_CRC_OK := FALSE;

                GVL_MODBUS_SYSCOM_TRANSPORT.G_Total_RX_CRC_Error :=
                    GVL_MODBUS_SYSCOM_TRANSPORT.G_Total_RX_CRC_Error + 1;

            END_IF;

        ELSE

            GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_State :=
                MB_RTU_RX_SHORT_FRAME;

            GVL_MODBUS_SYSCOM_TRANSPORT.G_Total_RX_Short_Frame :=
                GVL_MODBUS_SYSCOM_TRANSPORT.G_Total_RX_Short_Frame + 1;

        END_IF;

        GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Assembler_Active := FALSE;
        GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Assembler_Length := 0;

    END_IF;

END_IF;

IF NOT GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Assembler_Active AND
   NOT GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Ready AND
   (GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_State = MB_RTU_RX_FRAME_READY) THEN

    GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_State :=
        MB_RTU_RX_IDLE;

END_IF;

END_FUNCTION_BLOCK
