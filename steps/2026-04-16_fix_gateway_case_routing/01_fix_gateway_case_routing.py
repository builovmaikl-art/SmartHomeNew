from pathlib import Path

path = Path("FB_Gateway_Interface.st")
text = path.read_text(encoding="utf-8")

old = """        E_Gateway_Command_Type.CMD_TELEGRAM_MSG: // Отправка сообщения в Telegram
            VO_Telegram_Msg := L_Process_Command.telegram_msg;
            VO_Send_Telegram := TRUE;
            VO_HMI_Status_Message := 'Gateway: Сообщение Telegram отправлено';
            VO_Sync_Time_Req := TRUE;
            VO_New_Time_MS := TO_UDINT(L_Process_Command.target_value);
            VO_HMI_Status_Message := 'Gateway: Время синхронизировано';
        END_CASE;
"""

new = """        E_Gateway_Command_Type.CMD_TELEGRAM_MSG: // Отправка сообщения в Telegram
            VO_Telegram_Msg := L_Process_Command.telegram_msg;
            VO_Send_Telegram := TRUE;
            VO_HMI_Status_Message := 'Gateway: Сообщение Telegram отправлено';

        E_Gateway_Command_Type.CMD_SYNC_TIME: // Синхронизация времени
            VO_Sync_Time_Req := TRUE;
            VO_New_Time_MS := TO_UDINT(L_Process_Command.target_value);
            VO_HMI_Status_Message := 'Gateway: Время синхронизировано';

        E_Gateway_Command_Type.CMD_RESET_ERRORS: // Квитирование / сброс ошибок
            VO_Reset_Errors_Req := TRUE;
            VO_HMI_Status_Message := 'Gateway: Запрос на сброс ошибок принят';

        E_Gateway_Command_Type.CMD_SET_CONFIG: // Применение конфигурации
            VO_Set_Config_Req := TRUE;
            VO_HMI_Status_Message := 'Gateway: Запрос на применение конфигурации принят';
        END_CASE;
"""

if old not in text:
    raise SystemExit("Target CASE tail not found in FB_Gateway_Interface.st")

text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
print("OK: gateway CASE routing fixed for telegram/sync/reset/config")
