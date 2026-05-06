FUNCTION_BLOCK FB_Modbus_RTU_SysCom_Backend
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR

VAR
    L_Result : RTS_IEC_RESULT;
    L_Handle : RTS_IEC_HANDLE := RTS_INVALID_HANDLE;

    L_Settings : SysCom.SysComSettings;
    L_SettingsEx2 : SysCom.SysComSettingsEx2;

    L_Bytes_Written : UDINT;
    L_Bytes_Read : UDINT;

    L_RX_Buffer : ARRAY[0..255] OF BYTE;

    L_Open_Done : BOOL := FALSE;
    L_i : INT;
    L_Read_Count : INT;
END_VAR

// ======================================================
// MODBUS RTU SYSCOM BACKEND
// ======================================================
// Real serial backend using SysCom library.
//
// Responsibilities:
//   - COM open/configure
//   - TX write
//   - RX read
//   - RX frame byte collection
//   - basic online supervision
//
// Non responsibilities:
//   - Modbus frame build
//   - CRC validation
//   - register parsing
//   - retry policy
// ======================================================

IF NOT VI_Enable THEN

    IF L_Handle <> RTS_INVALID_HANDLE THEN
        SysCom.SysComClose(hCom := L_Handle);
        L_Handle := RTS_INVALID_HANDLE;
    END_IF;

    L_Open_Done := FALSE;
    GVL_MODBUS_SYSCOM_TRANSPORT.G_Transport_Attached := FALSE;

    RETURN;
END_IF;

// ======================================================
// OPEN + CONFIGURE FROM GVL_CONFIG
// ======================================================
IF NOT L_Open_Done THEN

    // COM port mapping. SysCom 3.5.17 exposes SYS_COMPORT1..4.
    CASE GVL_CONFIG.G_Modbus_RTU_Config.Port_Name OF
        'COM1':
            L_Settings.sPort := SysCom.SYS_COMPORT1;
        'COM2':
            L_Settings.sPort := SysCom.SYS_COMPORT2;
        'COM3':
            L_Settings.sPort := SysCom.SYS_COMPORT3;
        'COM4':
            L_Settings.sPort := SysCom.SYS_COMPORT4;
    ELSE
        L_Settings.sPort := SysCom.SYS_COMPORT1;
    END_CASE;

    // Baudrate mapping.
    CASE GVL_CONFIG.G_Modbus_RTU_Config.Baudrate OF
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

    // Parity mapping: config 0=None, 1=Even, 2=Odd.
    CASE GVL_CONFIG.G_Modbus_RTU_Config.Parity OF
        0:
            L_Settings.byParity := SysCom.SYS_NOPARITY;
        1:
            L_Settings.byParity := SysCom.SYS_EVENPARITY;
        2:
            L_Settings.byParity := SysCom.SYS_ODDPARITY;
    ELSE
        L_Settings.byParity := SysCom.SYS_EVENPARITY;
    END_CASE;

    // Stop bits mapping: config 1 or 2.
    CASE GVL_CONFIG.G_Modbus_RTU_Config.Stop_Bits OF
        1:
            L_Settings.byStopBits := SysCom.SYS_ONESTOPBIT;
        2:
            L_Settings.byStopBits := SysCom.SYS_TWOSTOPBITS;
    ELSE
        L_Settings.byStopBits := SysCom.SYS_ONESTOPBIT;
    END_CASE;

    L_Settings.ulTimeout := GVL_CONFIG.G_Modbus_RTU_Config.Request_Timeout_MS;
    L_Settings.ulBufferSize := 512;

    IF GVL_CONFIG.G_Modbus_RTU_Config.Data_Bits < 7 THEN
        L_SettingsEx2.byByteSize := 8;
    ELSIF GVL_CONFIG.G_Modbus_RTU_Config.Data_Bits > 8 THEN
        L_SettingsEx2.byByteSize := 8;
    ELSE
        L_SettingsEx2.byByteSize := GVL_CONFIG.G_Modbus_RTU_Config.Data_Bits;
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

    IF L_Handle <> RTS_INVALID_HANDLE THEN

        SysCom.SysComPurge(hCom := L_Handle);

        L_Open_Done := TRUE;

        GVL_MODBUS_SYSCOM_TRANSPORT.G_Transport_Attached := TRUE;

    ELSE

        GVL_MODBUS_SYSCOM_TRANSPORT.G_Transport_Attached := FALSE;
        GVL_MODBUS_SYSCOM_TRANSPORT.G_Total_Errors :=
            GVL_MODBUS_SYSCOM_TRANSPORT.G_Total_Errors + 1;

    END_IF;

    RETURN;
END_IF;

// ======================================================
// TX WRITE
// ======================================================
IF GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Request AND
   NOT GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Done THEN

    L_Bytes_Written := SysCom.SysComWrite(
        hCom := L_Handle,
        pbyBuffer := ADR(GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Buffer),
        ulSize := GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Length,
        ulTimeout := GVL_CONFIG.G_Modbus_RTU_Config.Request_Timeout_MS,
        pResult := ADR(L_Result)
    );

    IF L_Bytes_Written = GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Length THEN

        GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Done := TRUE;

    ELSE

        GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Error := TRUE;
        GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Error_Code := 16#0301;

    END_IF;

END_IF;

// ======================================================
// RX READ
// ======================================================
L_Bytes_Read := SysCom.SysComRead(
    hCom := L_Handle,
    pbyBuffer := ADR(L_RX_Buffer),
    ulSize := 256,
    ulTimeout := SysCom.SYS_NOWAIT,
    pResult := ADR(L_Result)
);

IF L_Bytes_Read > 0 THEN

    IF L_Bytes_Read > 256 THEN
        L_Read_Count := 256;
    ELSE
        L_Read_Count := UDINT_TO_INT(L_Bytes_Read);
    END_IF;

    GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Length := INT_TO_UINT(L_Read_Count);

    FOR L_i := 0 TO (L_Read_Count - 1) DO
        GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Buffer[L_i] :=
            L_RX_Buffer[L_i];
    END_FOR;

    GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Ready := TRUE;

END_IF;

END_FUNCTION_BLOCK
