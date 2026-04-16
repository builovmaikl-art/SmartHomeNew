# Инвентарь DRAFT / V2 переходного слоя

Источник: compile-лог CODESYS и лог импорта XML от 2026-04-12.

## Наблюдаемые DRAFT FB
- FB_Rule_Compatibility_Package_DRAFT
- FB_Alarm_Compatibility_Package_DRAFT
- FB_Alarm_V2_Core_DRAFT
- FB_History_V2_Core_DRAFT
- FB_BlackBox_V2_Core_DRAFT
- FB_Heating_V2_Staging_DRAFT
- FB_DHW_V2_Staging_DRAFT
- FB_Ventilation_V2_Staging_DRAFT
- FB_Blinds_V2_Staging_DRAFT
- FB_Lighting_V2_Staging_DRAFT
- FB_Socket_V2_Staging_DRAFT
- FB_CoreKernel_Live_Observer_DRAFT

## Наблюдаемые V2 типы / state-command модели
- ST_Heating_Command_V2
- ST_Heating_State_V2
- ST_DHW_Command_V2
- ST_DHW_State_V2
- ST_Ventilation_Command_V2
- ST_Ventilation_State_V2
- ST_Blinds_Command_V2
- ST_Blinds_State_V2
- ST_Lighting_Command_V2
- ST_Lighting_State_V2
- ST_Socket_Command_V2
- ST_Socket_State_V2
- ST_History_Event_V2
- ST_BlackBox_Snapshot_V2
- ST_TwoFactor_Auth_State

## Признаки, что это переходный слой, а не ядро
- имена содержат DRAFT / V2 / Compatibility / Staging / Core;
- слой фигурирует рядом с shadow / roundtrip / compatibility проверками;
- в логах импорта и компиляции слой конфликтует с финальными объектами и не выглядит как единственный источник истины;
- основное боевое ядро проекта проходит через PRG_System, PRG_Safety, FB_System_Health, FB_State_Manager и subsystem managers.

## Предварительный вывод
Это похоже на незавершённый переход со старой модели на новую. Часть объектов явно служит мостом совместимости, часть — черновой V2-контур. До выяснения окончательной роли нельзя считать весь слой мусором, но и финальным контрактом его считать тоже нельзя.

## Практическое правило на импорт
При запросе о совпадении имён НЕ выбирать "Переименовать" как штатный режим, потому что это плодит _1/_2 и размывает модель типов. Предпочтительный вариант — остановиться и устранить причину дубля в экспортируемом наборе. Если нужно пройти импорт любой ценой для диагностики, переименование допустимо только как временная мера, после чего дубли надо удалить и повторить импорт на чистом наборе.
