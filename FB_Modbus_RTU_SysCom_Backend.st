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

    RETURN;
END_IF;

// ======================================================
// OPEN + CONFIGURE
// ======================================================
IF NOT L_Open_Done THEN

    L_Settings.sPort := SysCom.SYS_COMPORT1;
    L_Settings.ulBaudrate := SysCom.SYS_BR_9600;
    L_Settings.byParity := SysCom.SYS_NOPARITY;
    L_Settings.byStopBits := SysCom.SYS_ONESTOPBIT;
    L_Settings.ulTimeout := 0;
    L_Settings.ulBufferSize := 512;

    L_SettingsEx2.byByteSize := 8;
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
        ulTimeout := 0,
        pResult := ADR(L_Result)
    );

    IF L_Bytes_Written = GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Length THEN

        GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Done := TRUE;

    ELSE

        GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Error := TRUE;
        GVL_MODBUS_SYSCOM_TRANSPORT.G_TX_Error_Code := WORD(L_Result);

    END_IF;

END_IF;

// ======================================================
// RX READ
// ======================================================
L_Bytes_Read := SysCom.SysComRead(
    hCom := L_Handle,
    pbyBuffer := ADR(L_RX_Buffer),
    ulSize := 256,
    ulTimeout := 0,
    pResult := ADR(L_Result)
);

IF L_Bytes_Read > 0 THEN

    GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Length := UINT(L_Bytes_Read);

    FOR L_i := 0 TO TO_INT(L_Bytes_Read - 1) DO
        GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Buffer[L_i] :=
            L_RX_Buffer[L_i];
    END_FOR;

    GVL_MODBUS_SYSCOM_TRANSPORT.G_RX_Ready := TRUE;

END_IF;

END_FUNCTION_BLOCK
