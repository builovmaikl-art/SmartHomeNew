FUNCTION_BLOCK FB_Modbus_RTU_TX_Builder
VAR_INPUT
    VI_Request_Valid : BOOL;
    VI_Slave_ID : BYTE;
    VI_Function_Code : E_Modbus_Function;
    VI_Start_Register : UINT;
    VI_Register_Count : UINT;
    VI_Write_Value : ARRAY[1..32] OF WORD;
END_VAR

VAR_OUTPUT
    VO_Frame : ST_Modbus_RTU_Frame;
    VO_Error : BOOL;
    VO_Error_Code : WORD;
END_VAR

VAR
    L_i : INT;
    L_Pos : UINT;
    L_CRC : WORD;
    L_Byte_Count : UINT;
END_VAR

// ======================================================
// MODBUS RTU TX FRAME BUILDER
// ======================================================
// Builds Modbus RTU request frames only.
// This FB does not send data and does not modify response state.
//
// Supported function codes:
//   FC03 Read Holding Registers
//   FC04 Read Input Registers
//   FC06 Write Single Register
//   FC16 Write Multiple Registers
// ======================================================

VO_Error := FALSE;
VO_Error_Code := 0;
VO_Frame.Valid := FALSE;
VO_Frame.Length := 0;
VO_Frame.CRC := 0;

FOR L_i := 0 TO 255 DO
    VO_Frame.Data[L_i] := 0;
END_FOR;

IF NOT VI_Request_Valid THEN
    RETURN;
END_IF;

IF VI_Slave_ID = 0 THEN
    VO_Error := TRUE;
    VO_Error_Code := 16#0101;
    RETURN;
END_IF;

IF (VI_Register_Count = 0) OR (VI_Register_Count > 32) THEN
    VO_Error := TRUE;
    VO_Error_Code := 16#0102;
    RETURN;
END_IF;

// ======================================================
// COMMON HEADER
// ======================================================
VO_Frame.Data[0] := VI_Slave_ID;
VO_Frame.Data[1] := E_Modbus_Function_TO_BYTE(VI_Function_Code);
VO_Frame.Data[2] := WORD_TO_BYTE(SHR(UINT_TO_WORD(VI_Start_Register), 8));
VO_Frame.Data[3] := WORD_TO_BYTE(UINT_TO_WORD(VI_Start_Register) AND 16#00FF);

CASE VI_Function_Code OF

    MB_FC03_READ_HOLDING_REGISTERS,
    MB_FC04_READ_INPUT_REGISTERS:

        VO_Frame.Data[4] := WORD_TO_BYTE(SHR(UINT_TO_WORD(VI_Register_Count), 8));
        VO_Frame.Data[5] := WORD_TO_BYTE(UINT_TO_WORD(VI_Register_Count) AND 16#00FF);

        VO_Frame.Length := 6;

    MB_FC06_WRITE_SINGLE_REGISTER:

        VO_Frame.Data[4] := WORD_TO_BYTE(SHR(VI_Write_Value[1], 8));
        VO_Frame.Data[5] := WORD_TO_BYTE(VI_Write_Value[1] AND 16#00FF);

        VO_Frame.Length := 6;

    MB_FC16_WRITE_MULTIPLE_REGISTERS:

        L_Byte_Count := VI_Register_Count * 2;

        IF L_Byte_Count > 64 THEN
            VO_Error := TRUE;
            VO_Error_Code := 16#0103;
            RETURN;
        END_IF;

        VO_Frame.Data[4] := WORD_TO_BYTE(SHR(UINT_TO_WORD(VI_Register_Count), 8));
        VO_Frame.Data[5] := WORD_TO_BYTE(UINT_TO_WORD(VI_Register_Count) AND 16#00FF);
        VO_Frame.Data[6] := UINT_TO_BYTE(L_Byte_Count);

        L_Pos := 7;

        FOR L_i := 1 TO UINT_TO_INT(VI_Register_Count) DO
            VO_Frame.Data[L_Pos] := WORD_TO_BYTE(SHR(VI_Write_Value[L_i], 8));
            VO_Frame.Data[L_Pos + 1] := WORD_TO_BYTE(VI_Write_Value[L_i] AND 16#00FF);
            L_Pos := L_Pos + 2;
        END_FOR;

        VO_Frame.Length := 7 + L_Byte_Count;

ELSE
    VO_Error := TRUE;
    VO_Error_Code := 16#0104;
    RETURN;
END_CASE;

// ======================================================
// CRC APPEND
// ======================================================
L_CRC := F_Modbus_RTU_CRC16(
    VI_Data := VO_Frame.Data,
    VI_Length := VO_Frame.Length
);

VO_Frame.CRC := L_CRC;
VO_Frame.Data[VO_Frame.Length] := WORD_TO_BYTE(L_CRC AND 16#00FF);
VO_Frame.Data[VO_Frame.Length + 1] := WORD_TO_BYTE(SHR(L_CRC, 8));
VO_Frame.Length := VO_Frame.Length + 2;
VO_Frame.Valid := TRUE;

END_FUNCTION_BLOCK
