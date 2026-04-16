FUNCTION_BLOCK FB_Zone_Access_Manager
VAR_INPUT
    VI_System_Time_MS : UDINT; // Системное время (мс)
    VI_Operator_ID    : STRING(10); // Идентификатор оператора
    VI_Target_Zone    : INT; // Номер целевой зоны
    VI_Rights         : ST_Operator_Zone_Rights; // Права доступа оператора к зоне
END_VAR
VAR_OUTPUT
    VO_Access_Granted : BOOL; // Флаг: Доступ разрешен
END_VAR

// Проверка прав доступа к зоне
IF VI_Target_Zone >= 1 AND VI_Target_Zone <= 32 THEN
    // Если глобальный уровень доступа высокий (например, CONFIG или FULL), разрешаем доступ ко всем зонам
    IF VI_Rights.global_access_level >= TO_BYTE(E_Zone_Access_Level.ZONE_ACCESS_CONFIG) THEN
        VO_Access_Granted := TRUE;
    ELSE
        // Иначе проверяем битовую маску для конкретной зоны
        // Бит 0 соответствует зоне 1, бит 1 - зоне 2 и т.д.
        VO_Access_Granted := (VI_Rights.zone_masks AND SHL(DWORD#1, VI_Target_Zone - 1)) <> 0;
    END_IF;
ELSE
    VO_Access_Granted := FALSE;
END_IF;