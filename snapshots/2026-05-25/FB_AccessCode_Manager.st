FUNCTION_BLOCK FB_AccessCode_Manager
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_IsActivePLC    : BOOL;
    VI_Code_To_Check  : STRING(4);
    VI_RFID_To_Check  : STRING(20);
END_VAR
VAR_IN_OUT
    VI_Access_Codes   : ARRAY[1..GVL_CONSTANTS.C_MAX_ACCESS_CODES] OF DWORD;
    VI_RFID_Tags      : ARRAY[1..GVL_CONSTANTS.C_MAX_ACCESS_CODES] OF STRING(20);
END_VAR
VAR_OUTPUT
    VO_Code_Valid     : BOOL;
END_VAR
VAR
    L_i : INT;
    pCode : POINTER TO BYTE;
    L_CRC_Calc : FB_CRC32_Calculator;
    L_Input_Hash : DWORD;
END_VAR

VO_Code_Valid := FALSE;

// Вычисляем хэш введенного кода
IF LEN(VI_Code_To_Check) > 0 THEN
    pCode := ADR(VI_Code_To_Check);
    L_Input_Hash := 0;
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ACCESS_CODES DO
        IF VI_Access_Codes[L_i] <> 0 AND VI_Access_Codes[L_i] = L_Input_Hash THEN
            VO_Code_Valid := TRUE;
            RETURN;
        END_IF;
    END_FOR;
END_IF;

// Проверяем RFID метку
IF LEN(VI_RFID_To_Check) > 0 THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ACCESS_CODES DO
        IF VI_RFID_Tags[L_i] <> '' AND VI_RFID_Tags[L_i] = VI_RFID_To_Check THEN
            VO_Code_Valid := TRUE;
            RETURN;
        END_IF;
    END_FOR;
END_IF;
// >>> BULK_SYNC_ANCHOR: FB_AccessCode_Manager <<<
END_FUNCTION_BLOCK
