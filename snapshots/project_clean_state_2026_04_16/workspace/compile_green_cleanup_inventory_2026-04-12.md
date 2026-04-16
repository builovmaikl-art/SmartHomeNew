# Cleanup inventory after first green compile baseline

Статус: проект компилируется в чистом проекте CODESYS без ошибок и предупреждений.

## 1. Временные сущности, добавленные для разблокировки компиляции

### Временные DRAFT/V2 FB stubs (`*.st`)
- FB_Rule_Compatibility_Package_DRAFT.st
- FB_Alarm_Compatibility_Package_DRAFT.st
- FB_History_V2_Core_DRAFT.st
- FB_BlackBox_V2_Core_DRAFT.st
- FB_Alarm_V2_Core_DRAFT.st
- FB_Heating_V2_Staging_DRAFT.st
- FB_DHW_V2_Staging_DRAFT.st
- FB_Ventilation_V2_Staging_DRAFT.st
- FB_Blinds_V2_Staging_DRAFT.st
- FB_Lighting_V2_Staging_DRAFT.st
- FB_Socket_V2_Staging_DRAFT.st
- FB_CoreKernel_Live_Observer_DRAFT.st

### Временные/спорные DRAFT/V2 DUT stubs (`*.dut`)
- Z_Temporary_V2_DRAFT_Stubs.dut
- Z_Temporary_DRAFT_FB_Only.dut

Примечание: эти файлы были нужны для снятия ошибок совместимости/переходного слоя. Их нельзя считать финальной архитектурой без отдельной ревизии.

## 2. Корректные и полезные добавления
- E_System_Severity.dut
- E_System_Root_Cause.dut
- CONSTANTS.dut

Примечание: эти файлы выглядят как нормальные долгоживущие сущности проекта.

## 3. Изменения, требующие архитектурной ревизии

### Literal array bounds
В ряде файлов границы массивов были заменены на литералы `8 / 16 / 32` для прохождения компиляции.
Это дало рабочий baseline, но требует последующей проверки на соответствие реальной конфигурации проекта.

Ключевые затронутые файлы:
- ST_System_State_Snapshot.dut
- FB_Gateway_Interface.st
- FB_Simulation_Manager.st
- FB_Rule_Engine.st
- ST_Security_Global_Config.dut
- FB_Security_System_Manager.st
- FB_Heating_System_Manager.st
- FB_Ventilation_System_Manager.st
- FB_Lighting_Blinds_Manager.st
- GVL_CONFIG.gvl
- GVL_STATE.gvl

## 4. Вывод по DRAFT/V2 слою
По структуре имён и характеру использования (`Compatibility`, `Roundtrip`, `Shadow`, `Staging`, `V2`, `DRAFT`) слой выглядит как незавершённый переход на новую модель, а не как полностью случайный мусор.

## 5. Следующий рекомендуемый этап
1. Зафиксировать зеленый baseline отдельным коммитом/тегом.
2. Проверить, какие из временных DRAFT/V2 stubs реально используются в runtime, а какие можно удалить.
3. Разобрать дубликаты типов при импорте (в первую очередь ST_TwoFactor_Auth_State).
4. Принять решение по literal-bound массивам: оставить как baseline или вернуть параметризацию через допустимый для CODESYS механизм.
5. После этого — по одному убирать временные stubs с обязательной повторной компиляцией после каждого шага.
