# Инвентарь проблемных мест по GVL_CONSTANTS / границам массивов

Источник: compile-лог CODESYS от 2026-04-12.

Цель: адресно заменить использование `GVL_CONSTANTS.C_MAX_*` в границах массивов на compile-time константы из `CONSTANTS.dut`.

## Кандидаты на замену

### C_MAX_HEATING_CIRCUITS
- ST_System_State_Snapshot
- FB_Gateway_Interface
- FB_Rule_Engine
- FB_Heating_System_Manager
- GVL_CONFIG

### C_MAX_LIGHTING_ZONES
- ST_System_State_Snapshot
- FB_Gateway_Interface
- FB_Simulation_Manager
- FB_Lighting_Blinds_Manager
- GVL_CONFIG

### C_MAX_CLIMATE_ZONES
- FB_Gateway_Interface
- FB_Rule_Engine
- ST_Security_Global_Config
- FB_Security_System_Manager
- FB_Heating_System_Manager
- FB_Ventilation_System_Manager
- GVL_CONFIG

## Отдельно проверить
- GVL_STATE использует `GVL_CONFIG.C_MAX_LIGHT_ZONES` — это тоже не compile-time constant и потребует отдельной замены на прямую compile-time константу.

## Следующий шаг
1. Открыть перечисленные файлы.
2. Заменить размеры массивов:
   - `GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS` -> `C_MAX_HEATING_CIRCUITS`
   - `GVL_CONSTANTS.C_MAX_LIGHTING_ZONES` -> `C_MAX_LIGHTING_ZONES`
   - `GVL_CONSTANTS.C_MAX_CLIMATE_ZONES` -> `C_MAX_CLIMATE_ZONES`
3. Отдельно разобрать `GVL_CONFIG.C_MAX_LIGHT_ZONES` в `GVL_STATE`.

## Не делать
- не трогать runtime-сравнения и обычный код, где `GVL_CONSTANTS.C_MAX_*` используется не как граница массива;
- не делать массовую regex-замену по всему проекту без просмотра файлов.