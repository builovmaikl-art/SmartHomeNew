# PRG_System — что доделать позже

## Текущее состояние
- PRG_System компилируется.
- Основные синтаксические хвосты убраны.
- LogEvent / FB_LogEvent приведён к рабочему виду.
- Проблемы сборщика не считаются проблемами PRG_System.

## Что проверить позже

### Event logging
- Проверить запись в GVL_EVENT (ID, Type, Timestamp, Param1/2)
- Проверить отсутствие дублей

### Scenario pipeline
- raw -> validation -> Req_Final -> Intent -> apply
- Решить судьбу L_Scenario_Req_Final (trace или удалить)

### Dangerous actions
- request / confirm / deny / maintenance
- проверить anti-flood

### Архитектура
- PRG_System перегружен
- позже вынести telemetry / scenario / history

### GVL/DUT
- следить за *.gvl и *.dut

## Важно
Сначала NVRAM, потом возвращаемся сюда.
