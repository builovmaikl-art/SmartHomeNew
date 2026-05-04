FUNCTION_BLOCK FB_State_Manager
VAR_INPUT
    VI_System_Severity : E_System_Severity;
    VI_Root_Cause      : E_System_Root_Cause;
    VI_Freeze_Risk     : BOOL := FALSE;
END_VAR

VAR_OUTPUT
    VO_System_OK        : BOOL;
    VO_System_Warning   : BOOL;
    VO_System_Critical  : BOOL;
    VO_Status_Msg       : STRING(200);

    // compatibility output for existing orchestration
    VO_System_Mode      : E_System_Operating_Mode;
END_VAR

VO_System_OK := FALSE;
VO_System_Warning := FALSE;
VO_System_Critical := FALSE;
VO_Status_Msg := '';
VO_System_Mode := E_System_Operating_Mode.MODE_NORMAL;

CASE VI_System_Severity OF
    E_System_Severity.SEV_NORMAL:
        VO_System_OK := TRUE;
        VO_Status_Msg := 'Система в норме';
        VO_System_Mode := E_System_Operating_Mode.MODE_NORMAL;

    E_System_Severity.SEV_WARNING:
        VO_System_Warning := TRUE;
        VO_System_Mode := E_System_Operating_Mode.MODE_DEGRADED;
        CASE VI_Root_Cause OF
            E_System_Root_Cause.ROOT_WATER_LEAK:
                VO_Status_Msg := 'Предупреждение: протечка воды';
            E_System_Root_Cause.ROOT_CO_WARNING:
                VO_Status_Msg := 'Предупреждение: повышенный CO';
            ELSE
                VO_Status_Msg := 'Предупреждение системы';
        END_CASE;

    E_System_Severity.SEV_DEGRADED:
        VO_System_Warning := TRUE;
        VO_System_Mode := E_System_Operating_Mode.MODE_DEGRADED;
        CASE VI_Root_Cause OF
            E_System_Root_Cause.ROOT_SENSOR_FAULT:
                VO_Status_Msg := 'Деградация: ошибка датчика';
            E_System_Root_Cause.ROOT_IO_OFFLINE:
                VO_Status_Msg := 'Деградация: модуль IO недоступен';
            E_System_Root_Cause.ROOT_COMM_FAULT:
                VO_Status_Msg := 'Деградация: ошибка связи';
            E_System_Root_Cause.ROOT_WATCHDOG_FAULT:
                VO_Status_Msg := 'Деградация: watchdog fault';
            E_System_Root_Cause.ROOT_SUBSYSTEM_FAULT:
                VO_Status_Msg := 'Деградация: ошибка подсистемы';
            ELSE
                VO_Status_Msg := 'Деградация системы';
        END_CASE;

    E_System_Severity.SEV_CRITICAL:
        VO_System_Critical := TRUE;

        IF (VI_Root_Cause = E_System_Root_Cause.ROOT_GAS_LEAK OR
            VI_Root_Cause = E_System_Root_Cause.ROOT_CO_CRITICAL) AND
            VI_Freeze_Risk THEN
            VO_System_Mode := E_System_Operating_Mode.MODE_FREEZE_PROTECTION;
        ELSE
            VO_System_Mode := E_System_Operating_Mode.MODE_SAFE_STOP;
        END_IF;

        CASE VI_Root_Cause OF
            E_System_Root_Cause.ROOT_FIRE:
                VO_Status_Msg := 'АВАРИЯ: ПОЖАР';
            E_System_Root_Cause.ROOT_GAS_LEAK:
                VO_Status_Msg := 'АВАРИЯ: УТЕЧКА ГАЗА';
            E_System_Root_Cause.ROOT_CO_CRITICAL:
                VO_Status_Msg := 'АВАРИЯ: КРИТИЧЕСКИЙ CO';
            E_System_Root_Cause.ROOT_WATCHDOG_FAULT:
                VO_Status_Msg := 'АВАРИЯ: WATCHDOG';
            ELSE
                VO_Status_Msg := 'АВАРИЯ СИСТЕМЫ';
        END_CASE;
END_CASE;
// >>> BULK_SYNC_ANCHOR: FB_State_Manager <<<
END_FUNCTION_BLOCK
