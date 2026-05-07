FUNCTION_BLOCK FB_Modbus_RTU_RX_Parser
VAR_INPUT
    VI_Frame : ST_Modbus_RTU_Frame;
    VI_Expected_Slave_ID : BYTE;
    VI_Expected_Function : E_Modbus_Function;
END_VAR

VAR_OUTPUT
    VO_Valid : BOOL;
    VO_Error : BOOL;
    VO_Error_Code : WORD;
    VO_Exception_Response : BOOL;
    VO_Register_Count : UINT;
    VO_Register_Value : ARRAY[1..32] OF WORD;
END_VAR

VAR
    L_CRC_Calc : WORD;
    L_CRC_Frame : WORD;
    L_Function_Byte : BYTE;
    L_Expected_Function : BYTE;
    L_Byte_Count : UINT;
    L_i : UINT;
    L_j : INT;
    L_Data_Index : UINT;
END_VAR

// ======================================================
// MODBUS RTU RX FRAME PARSER
// ======================================================

VO_Valid := FALSE;
VO_Error := FALSE;
VO_Error_Code := 0;
VO_Exception_Response := FALSE;
VO_Register_Count := 0;

FOR L_i := 1 TO 32 DO
    VO_Register_Value[L_i] := 0;
END_FOR;

IF NOT VI_Frame.Valid THEN
    VO_Error := TRUE;
    VO_Error_Code := 16#0201;
    RETURN;
END_IF;

IF VI_Frame.Length < 5 THEN
    VO_Error := TRUE;
    VO_Error_Code := 16#0202;
    RETURN;
END_IF;

CASE VI_Expected_Function OF
    MB_FC03_READ_HOLDING_REGISTERS:
        L_Expected_Function := 3;
    MB_FC04_READ_INPUT_REGISTERS:
        L_Expected_Function := 4;
    MB_FC06_WRITE_SINGLE_REGISTER:
        L_Expected_Function := 6;
    MB_FC16_WRITE_MULTIPLE_REGISTERS:
        L_Expected_Function := 16;
ELSE
    VO_Error := TRUE;
    VO_Error_Code := 16#0203;
    RETURN;
END_CASE;

// ======================================================
// CRC VALIDATION
// ======================================================
L_CRC_Frame :=
    BYTE_TO_WORD(VI_Frame.Data[VI_Frame.Length - 2]) OR
    SHL(BYTE_TO_WORD(VI_Frame.Data[VI_Frame.Length - 1]), 8);

L_CRC_Calc := 16#FFFF;

FOR L_i := 0 TO (VI_Frame.Length - UINT#3) DO

    L_CRC_Calc := L_CRC_Calc XOR BYTE_TO_WORD(VI_Frame.Data[L_i]);

    FOR L_j := 0 TO 7 DO
        IF (L_CRC_Calc AND 16#0001) <> 0 THEN
            L_CRC_Calc := SHR(L_CRC_Calc, 1);
            L_CRC_Calc := L_CRC_Calc XOR 16#A001;
        ELSE
            L_CRC_Calc := SHR(L_CRC_Calc, 1);
        END_IF;
    END_FOR;

END_FOR;

IF L_CRC_Calc <> L_CRC_Frame THEN
    VO_Error := TRUE;
    VO_Error_Code := 16#0204;
    RETURN;
END_IF;

IF VI_Frame.Data[0] <> VI_Expected_Slave_ID THEN
    VO_Error := TRUE;
    VO_Error_Code := 16#0205;
    RETURN;
END_IF;

L_Function_Byte := VI_Frame.Data[1];

IF L_Function_Byte = (L_Expected_Function OR 16#80) THEN
    VO_Exception_Response := TRUE;
    VO_Error := TRUE;
    VO_Error_Code := 16#0206;
    RETURN;
END_IF;

IF L_Function_Byte <> L_Expected_Function THEN
    VO_Error := TRUE;
    VO_Error_Code := 16#0207;
    RETURN;
END_IF;

CASE VI_Expected_Function OF

    MB_FC03_READ_HOLDING_REGISTERS,
    MB_FC04_READ_INPUT_REGISTERS:

        L_Byte_Count := VI_Frame.Data[2];

        IF (L_Byte_Count = 0) OR ((L_Byte_Count MOD 2) <> 0) THEN
            VO_Error := TRUE;
            VO_Error_Code := 16#0208;
            RETURN;
        END_IF;

        VO_Register_Count := L_Byte_Count / 2;

        IF VO_Register_Count > 32 THEN
            VO_Error := TRUE;
            VO_Error_Code := 16#0209;
            RETURN;
        END_IF;

        L_Data_Index := 3;

        FOR L_i := 1 TO VO_Register_Count DO

            VO_Register_Value[L_i] :=
                SHL(BYTE_TO_WORD(VI_Frame.Data[L_Data_Index]), 8) OR
                BYTE_TO_WORD(VI_Frame.Data[L_Data_Index + 1]);

            L_Data_Index := L_Data_Index + 2;

        END_FOR;

    MB_FC06_WRITE_SINGLE_REGISTER,
    MB_FC16_WRITE_MULTIPLE_REGISTERS:

        VO_Register_Count := 0;

ELSE
    VO_Error := TRUE;
    VO_Error_Code := 16#020A;
    RETURN;
END_CASE;

VO_Valid := TRUE;

END_FUNCTION_BLOCK
