FUNCTION F_Modbus_RTU_CRC16 : WORD
VAR_INPUT
    VI_Data : ARRAY[0..255] OF BYTE;
    VI_Length : UINT;
END_VAR

VAR
    L_CRC : WORD := 16#FFFF;
    L_i : UINT;
    L_j : INT;
    L_Temp : WORD;
END_VAR

// ======================================================
// MODBUS RTU CRC16
// ======================================================
// Standard Modbus RTU CRC16 implementation.
// Pure function without side effects.
// ======================================================

IF VI_Length = 0 THEN
    F_Modbus_RTU_CRC16 := 16#FFFF;
    RETURN;
END_IF;

FOR L_i := 0 TO (VI_Length - 1) DO

    L_CRC := L_CRC XOR BYTE_TO_WORD(VI_Data[L_i]);

    FOR L_j := 0 TO 7 DO

        L_Temp := L_CRC AND 16#0001;

        L_CRC := SHR(L_CRC, 1);

        IF L_Temp <> 0 THEN
            L_CRC := L_CRC XOR 16#A001;
        END_IF;

    END_FOR;

END_FOR;

F_Modbus_RTU_CRC16 := L_CRC;

END_FUNCTION
