# Ventilation Manager Diagnostics Cleanup Result

Дата фиксации: 2026-04-23

## Что было сделано
Выполнен локальный cleanup ventilation diagnostics ownership around `FB_Ventilation_System_Manager.st` and `PRG_Ventilation.st`.

Изменение ограничено узким diagnostics scope:
- diagnostics/degraded flags переведены из direct global writes inside manager в explicit output contract manager + wrapper publication.

## Какие изменения внесены

### В `FB_Ventilation_System_Manager.st`
Добавлены новые `VAR_OUTPUT` сигналы:
- `VO_Ventilation_IO_Fault : BOOL`
- `VO_Ventilation_Subsystem_Degraded : BOOL`

Также:
- убраны direct writes в `GVL_STATE.G_Ventilation_IO_Fault`;
- убраны direct writes в `GVL_STATE.G_Ventilation_Subsystem_Degraded`;
- соответствующая diagnostics/degraded semantics теперь присваивается новым `VO_*` outputs.

### В `PRG_Ventilation.st`
Вызов `fbVentilationManager(...)` расширен двумя output bindings:
- `VO_Ventilation_IO_Fault => GVL_STATE.G_Ventilation_IO_Fault`
- `VO_Ventilation_Subsystem_Degraded => GVL_STATE.G_Ventilation_Subsystem_Degraded`

## Подтвержденные результаты по состоянию репозитория

### VMDCR-01. Direct diagnostics writes inside manager устранены
По состоянию репозитория в `FB_Ventilation_System_Manager.st` больше не используются direct writes в:
- `GVL_STATE.G_Ventilation_IO_Fault`
- `GVL_STATE.G_Ventilation_Subsystem_Degraded`

Вывод:
- основной confirmed ownership smell этой волны действительно устранен.

### VMDCR-02. Diagnostics publication стала explicit and wrapper-bounded
Теперь publication path выглядит так:
- manager вычисляет diagnostics/degraded state;
- manager публикует их через:
  - `VO_Ventilation_IO_Fault`
  - `VO_Ventilation_Subsystem_Degraded`;
- wrapper `PRG_Ventilation.st` публикует их в `GVL_STATE`.

Вывод:
- boundary стала заметно чище и более самодокументируемой.

### VMDCR-03. Clean paths не затронуты
Без изменений остались:
- request ingestion path из `GVL_COMMAND_SHADOW`;
- `VO_Supply_Fans` / `VO_Exhaust_Fans` path;
- `VO_Heater_Power` path;
- `VO_Status_Msg` path;
- wet-zone adapter и fan copy-out adapters wrapper-а.

Вывод:
- changeset остался точечным и пропорциональным.

### VMDCR-04. Ventilation cleanup не разросся в redesign
В ходе правки не выполнялись:
- wrapper refactor;
- manager decomposition;
- изменение scenario/policy/control logic beyond diagnostics publication shape.

Вывод:
- remediation осталась локальной и архитектурно аккуратной.

## Главный практический эффект этапа
После этой правки ventilation cluster выглядит чище именно там, где ранее был подтвержден ownership smell:
- diagnostics state больше не мутируется напрямую изнутри manager в globals;
- publication boundary стала согласованной с уже clean output/publication style остального wrapper/manager взаимодействия.

## Что этот результат НЕ означает
Этот результат не означает:
- compile/run подтверждение;
- что ventilation manager уже полностью идеален архитектурно;
- что broader ventilation decomposition никогда не понадобится.

Он означает только:
- локальный confirmed smell вокруг diagnostics/global-state ownership закрыт по состоянию репозитория.

## Следующий рекомендуемый документ
- `74_VENTILATION_INTERIM_STATUS.md`

Его задача:
- кратко зафиксировать, в каком состоянии оставляется ventilation wave после этого локального cleanup;
- оценить, пора ли переходить к следующему major scope проекта.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения