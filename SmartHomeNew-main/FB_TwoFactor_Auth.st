FUNCTION_BLOCK FB_TwoFactor_Auth
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_Start_Auth     : BOOL;
    VI_Method         : E_TwoFactor_Method;
    VI_User_Code      : STRING(6);
    VI_Reset_Success  : BOOL; // Сброс успешного состояния
END_VAR
VAR_OUTPUT
    VO_State          : ST_TwoFactor_Auth_State;
    VO_Send_Code_Req  : BOOL; // Запрос на отправку кода (например, через шлюз)
    VO_Code_To_Send   : STRING(6); // Сгенерированный код для отправки
END_VAR
VAR
    L_Generated_Code  : STRING(6) := '';
    L_Start_Time      : UDINT;
    R_Trig_Start      : R_TRIG;
    L_Prev_User_Code  : STRING(6);
    L_Lockout_Start_Time : UDINT; // Время начала блокировки
    fbHMAC            : FB_HMAC_SHA1;
    L_Elapsed_Time    : UDINT;
    L_Time_Step       : UDINT;
    L_Message         : ARRAY[0..7] OF BYTE;
    L_Key             : ARRAY[0..63] OF BYTE;
    L_Offset          : INT;
    L_Truncated_Hash  : UDINT;
    L_i               : INT;
    L_Current_TOTP    : STRING(6);
    L_Prev_TOTP       : STRING(6);
    L_Code_Valid      : BOOL;
END_VAR

R_Trig_Start(CLK := VI_Start_Auth);

IF VI_Reset_Success THEN
    VO_State.Is_Success := FALSE;
END_IF;

IF R_Trig_Start.Q AND NOT VO_State.is_pending AND NOT VO_State.Is_Locked THEN
    VO_State.is_pending := TRUE;
    VO_State.Auth_Method := VI_Method;
    L_Start_Time := VI_System_Time_MS;
    VO_State.Attempts_Left := 3;
    VO_State.Is_Success := FALSE;
    VO_State.Is_Locked := FALSE;
    L_Prev_User_Code := '';
    
    IF VI_Method <> E_TwoFactor_Method.TF_METHOD_TOTP THEN
        // Генерируем одноразовый код через HMAC (без упрощенного алгоритма "по времени")
        L_Time_Step := VI_System_Time_MS / 30000;
        L_Key[0] := 16#31; L_Key[1] := 16#32; L_Key[2] := 16#33; L_Key[3] := 16#34; // Секрет-шаблон, заменяется из конфигурации
        FOR L_i := 0 TO 7 DO L_Message[7 - L_i] := TO_BYTE(SHR(L_Time_Step + L_Start_Time, L_i * 8) AND 16#FF); END_FOR;
        fbHMAC(Key := L_Key, KeyLength := 4, Message := L_Message, MessageLength := 8);
        L_Offset := TO_INT(fbHMAC.Hash[19] AND 16#0F);
        L_Truncated_Hash := (SHL(TO_UDINT(fbHMAC.Hash[L_Offset] AND 16#7F), 24) OR SHL(TO_UDINT(fbHMAC.Hash[L_Offset+1] AND 16#FF), 16) OR SHL(TO_UDINT(fbHMAC.Hash[L_Offset+2] AND 16#FF), 8) OR TO_UDINT(fbHMAC.Hash[L_Offset+3] AND 16#FF));
        L_Generated_Code := UDINT_TO_STRING(L_Truncated_Hash MOD 1000000);
        WHILE LEN(L_Generated_Code) < 6 DO
            L_Generated_Code := CONCAT('0', L_Generated_Code);
        END_WHILE;
        
        VO_Code_To_Send := L_Generated_Code;
        VO_Send_Code_Req := TRUE;
    ELSE
        // Для TOTP код не отправляем
        VO_Code_To_Send := '';
        VO_Send_Code_Req := FALSE;
    END_IF;
ELSE
    VO_Send_Code_Req := FALSE;
END_IF;

IF VO_State.is_pending THEN
    L_Elapsed_Time := (SEL(VI_System_Time_MS >= L_Start_Time, VI_System_Time_MS - L_Start_Time, (4294967295 - L_Start_Time) + VI_System_Time_MS + 1));

    IF L_Elapsed_Time < (GVL_CONSTANTS.C_MS_IN_MINUTE * 5) THEN
        VO_State.Time_Left_S := TO_UINT(((GVL_CONSTANTS.C_MS_IN_MINUTE * 5) - L_Elapsed_Time) / 1000);
    ELSE
        VO_State.Time_Left_S := 0;
    END_IF;
    
    IF VI_User_Code <> '' AND VI_User_Code <> L_Prev_User_Code THEN
        L_Code_Valid := FALSE;
        
        IF VI_Method = E_TwoFactor_Method.TF_METHOD_TOTP THEN
            // Вычисляем TOTP для текущего шага времени (30 секунд)
            L_Time_Step := VI_System_Time_MS / 30000; 
            
            // Подготовка ключа (в реальном проекте берется из GVL_CONFIG)
            L_Key[0] := 16#31; L_Key[1] := 16#32; L_Key[2] := 16#33; L_Key[3] := 16#34; // '1234'
            
            // Проверка текущего шага
            FOR L_i := 0 TO 7 DO L_Message[7 - L_i] := TO_BYTE(SHR(L_Time_Step, L_i * 8) AND 16#FF); END_FOR;
            fbHMAC(Key := L_Key, KeyLength := 4, Message := L_Message, MessageLength := 8);
            L_Offset := TO_INT(fbHMAC.Hash[19] AND 16#0F);
            L_Truncated_Hash := (SHL(TO_UDINT(fbHMAC.Hash[L_Offset] AND 16#7F), 24) OR SHL(TO_UDINT(fbHMAC.Hash[L_Offset+1] AND 16#FF), 16) OR SHL(TO_UDINT(fbHMAC.Hash[L_Offset+2] AND 16#FF), 8) OR TO_UDINT(fbHMAC.Hash[L_Offset+3] AND 16#FF));
            L_Current_TOTP := UDINT_TO_STRING(L_Truncated_Hash MOD 1000000);
            WHILE LEN(L_Current_TOTP) < 6 DO L_Current_TOTP := CONCAT('0', L_Current_TOTP); END_WHILE;
            
            // Проверка предыдущего шага (для компенсации рассинхронизации)
            FOR L_i := 0 TO 7 DO L_Message[7 - L_i] := TO_BYTE(SHR(L_Time_Step - 1, L_i * 8) AND 16#FF); END_FOR;
            fbHMAC(Key := L_Key, KeyLength := 4, Message := L_Message, MessageLength := 8);
            L_Offset := TO_INT(fbHMAC.Hash[19] AND 16#0F);
            L_Truncated_Hash := (SHL(TO_UDINT(fbHMAC.Hash[L_Offset] AND 16#7F), 24) OR SHL(TO_UDINT(fbHMAC.Hash[L_Offset+1] AND 16#FF), 16) OR SHL(TO_UDINT(fbHMAC.Hash[L_Offset+2] AND 16#FF), 8) OR TO_UDINT(fbHMAC.Hash[L_Offset+3] AND 16#FF));
            L_Prev_TOTP := UDINT_TO_STRING(L_Truncated_Hash MOD 1000000);
            WHILE LEN(L_Prev_TOTP) < 6 DO L_Prev_TOTP := CONCAT('0', L_Prev_TOTP); END_WHILE;
            
            IF VI_User_Code = L_Current_TOTP OR VI_User_Code = L_Prev_TOTP THEN
                L_Code_Valid := TRUE;
            END_IF;
        ELSE
            IF VI_User_Code = L_Generated_Code THEN
                L_Code_Valid := TRUE;
            END_IF;
        END_IF;
        
        IF L_Code_Valid THEN
            VO_State.Is_Success := TRUE;
            VO_State.is_pending := FALSE;
        ELSE
            IF VO_State.Attempts_Left > 0 THEN
                VO_State.Attempts_Left := VO_State.Attempts_Left - 1;
            END_IF;
            
            IF VO_State.Attempts_Left = 0 THEN
                VO_State.Is_Locked := TRUE;
                VO_State.is_pending := FALSE;
                L_Lockout_Start_Time := VI_System_Time_MS; // Блокировка на 5 минут
            END_IF;
        END_IF;
    END_IF;
    L_Prev_User_Code := VI_User_Code;
    
    IF L_Elapsed_Time > (GVL_CONSTANTS.C_MS_IN_MINUTE * 5) THEN
        VO_State.is_pending := FALSE; // Таймаут
    END_IF;
END_IF;

IF VO_State.Is_Locked THEN
    IF (SEL(VI_System_Time_MS >= L_Lockout_Start_Time, VI_System_Time_MS - L_Lockout_Start_Time, (4294967295 - L_Lockout_Start_Time) + VI_System_Time_MS + 1)) >= (GVL_CONSTANTS.C_MS_IN_MINUTE * 5) THEN
        VO_State.Is_Locked := FALSE;
    END_IF;
END_IF;