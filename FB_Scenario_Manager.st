FUNCTION_BLOCK FB_Scenario_Manager
VAR_INPUT
    VI_Preheat_Request : BOOL;
    VI_System_Time_MS : UDINT; // Системное время (мс)
    VI_Activate_Request : E_SCENARIO_TYPE; // Запрос на активацию сценария
    VI_IsActivePLC : BOOL; // Флаг: Данный ПЛК является ведущим
    VI_System_Mode : E_System_Operating_Mode; // Агрегированный режим работы системы
END_VAR
VAR_OUTPUT
    VO_Current_Scenario : E_SCENARIO_TYPE; // Текущий активный сценарий
    VO_Status_Msg : STRING(200); // Строковое сообщение о статусе
END_VAR

VAR
    L_Last_Scenario_Time : UDINT;
END_VAR

IF NOT VI_IsActivePLC THEN
    RETURN;
END_IF;

CASE VI_System_Mode OF
    E_System_Operating_Mode.MODE_SAFE_STOP,
    E_System_Operating_Mode.MODE_FREEZE_PROTECTION:
        IF VO_Current_Scenario <> E_SCENARIO_TYPE.SCENARIO_NONE THEN
            VO_Current_Scenario := E_SCENARIO_TYPE.SCENARIO_NONE;
            VO_Status_Msg := 'Сценарии принудительно отключены режимом безопасности';
        END_IF;
        RETURN;

    E_System_Operating_Mode.MODE_DEGRADED:
        VO_Status_Msg := 'Смена сценариев заблокирована: деградированный режим';
        RETURN;
END_CASE;

IF VI_Activate_Request <> VO_Current_Scenario THEN
    // Проверка минимального времени работы сценария
    IF (VI_System_Time_MS - L_Last_Scenario_Time) >= 60000 OR VO_Current_Scenario = E_SCENARIO_TYPE.SCENARIO_NONE THEN
        // Логика переключения сценариев
        VO_Current_Scenario := VI_Activate_Request;
        L_Last_Scenario_Time := VI_System_Time_MS;
        
        CASE VO_Current_Scenario OF
        E_SCENARIO_TYPE.SCENARIO_NONE:
            VO_Status_Msg := 'Сценарии отключены';
        E_SCENARIO_TYPE.SCENARIO_AWAY:
            VO_Status_Msg := 'Активирован сценарий: Вне дома (Охрана + Энергосбережение)';
        E_SCENARIO_TYPE.SCENARIO_SLEEP:
            VO_Status_Msg := 'Активирован сценарий: Сон (Ночное освещение + Климат)';
        E_SCENARIO_TYPE.SCENARIO_PRESENCE:
            VO_Status_Msg := 'Активирован сценарий: Имитация присутствия';
        END_CASE;
    END_IF;
END_IF;
// >>> BULK_SYNC_ANCHOR: FB_Scenario_Manager <<<


// --- PREHEAT SCENARIO INSERT ---
IF VI_Preheat_Request THEN
    GVL_HEATING.G_Preheat_Active := TRUE;
END_IF;
