# Heating Recovery Compatibility Check

Дата фиксации: 2026-04-23

## Цель документа
Выполнить шаг H-R3 для основного кандидата восстановления:
- `snapshots/2026-04-22/PRG_Heating.st`

Задача этапа:
- проверить совместимость кандидата с текущим live root,
- зафиксировать обязательные адаптации до восстановления,
- отделить recovery-изменения от redesign-изменений.

## Проверенные объекты
- `MAIN.st`
- основной кандидат `snapshots/2026-04-22/PRG_Heating.st`
- `FB_Heating_System_Manager.st`
- `FB_DHW_Manager.st`
- `GVL_HEATING_REQUEST.gvl`
- `GVL_STATE.gvl`
- `GVL_INTENT_USER.gvl`
- текущий `PRG_Policy.st`

## Итог compatibility check
Основной кандидат совместим с текущим live root не «как есть», а **как recovery candidate с ограниченным обязательным адаптационным слоем**.

То есть:
- кандидат нельзя бездумно вернуть в корень без проверки;
- но он достаточно близок к текущему live root, чтобы использовать его как базу восстановления;
- объем требуемых адаптаций выглядит ограниченным и контролируемым.

## Совместимость по узлам

### CC-001. Совместимость с MAIN
`MAIN.st` по-прежнему вызывает `PRG_Heating()` как отдельный live program.

Вывод:
- кандидат остается совместим по месту в верхнем call order;
- отдельной перестройки `MAIN.st` для восстановления heating wrapper не требуется.

Статус: COMPATIBLE.

### CC-002. Совместимость с FB_Heating_System_Manager
Основной кандидат вызывает `fbHeatingManager(...)` с полным и современным набором аргументов, включая:
- `VI_Preheat_Request`,
- `VI_System_Mode`,
- `VI_Emergency_Stop`,
- `VI_Gas_Safety_Stop`,
- `VI_DHW_Heating_Demand`,
- `VI_Scenario_Configs`,
- `VI_Manifold_End_Switches`,
- `VI_Valve_Test_Config`.

Это выглядит существенно ближе к текущему интерфейсу `FB_Heating_System_Manager.st`, чем резервный старый кандидат.

Вывод:
- по сигнатуре heating FB основной кандидат является подходящей базой восстановления.

Статус: MOSTLY COMPATIBLE.

### CC-003. Совместимость с FB_DHW_Manager
Основной кандидат вызывает `fbDHWManager(...)` с передачей:
- `VI_System_Mode`,
- `VI_Emergency_Stop`,
- `VI_IO_Modules_Online`,
- `VI_Reset_Errors`.

Это согласуется с текущим policy-driven интерфейсом `FB_DHW_Manager.st`.

Отдельно важно:
- кандидат использует `GVL_INTENT_USER.I_Reset_Errors`,
- а более старый резервный вариант использовал legacy `GVL_COMMAND.G_Reset_Errors`.

Для текущей архитектуры intent-layer вариант основного кандидата выглядит предпочтительнее.

Вывод:
- по DHW integration основной кандидат ближе к текущему live root и не требует возврата к legacy reset-path.

Статус: COMPATIBLE.

### CC-004. Совместимость по heating request layer
Это главный compatibility-вопрос этапа.

Основной кандидат использует:
- `GVL_HEATING_REQUEST.G_Preheat_Request`

Но в текущем live root одновременно существуют и поля в `GVL_STATE`:
- `G_Preheat_Request`
- `G_Freeze_Request`
- `G_Target_Temperature`

Кроме того, в текущем `PRG_Policy.st` heating bridge публикует heating requests именно через `GVL_STATE`, а не через `GVL_HEATING_REQUEST`.

При этом по текущему живому поиску `GVL_HEATING_REQUEST` почти не участвует в live-root call graph и выглядит как слой, который уже не является основным опубликованным owner-слоем heating-request логики.

Вывод:
- возвращать кандидата «как есть» рискованно;
- перед восстановлением нужно принять одно из двух явных решений:
  1. либо считать `GVL_STATE` текущим owner heating requests и адаптировать кандидата под него;
  2. либо осознанно вернуть ownership в `GVL_HEATING_REQUEST`, но это уже будет не recovery, а частичный redesign.

Статус: REQUIRES ADAPTATION.

### CC-005. Совместимость по target temperature publication
Основной кандидат пишет итоговую целевую температуру в `GVL_STATE.G_Target_Temperature`.

Это поле существует в текущем live root, поэтому формально конфликт отсутствует.

Но так как `GVL_HEATING_REQUEST.gvl` тоже содержит `G_Target_Temperature`, в проекте уже есть потенциальное дублирование publication-layer.

Вывод:
- само по себе восстановление кандидата не ломает текущий root;
- но перед финальным возвратом нужно зафиксировать единый owner для target temperature publication.

Статус: COMPATIBLE WITH OWNERSHIP RISK.

### CC-006. Совместимость по diagnostics / maintenance gating
Основной кандидат содержит:
- integrated freeze-hardware diagnostics,
- maintenance gating для backup pump / electric heater / manifold pumps / DHW pumps,
- публикацию ряда статусных флагов в `GVL_STATUS.G_Diagnostics` и `GVL_STATE`.

Эти слои по смыслу согласуются с текущим live root и не выглядят как явный откат к старой архитектуре.

Но после восстановления они потребуют отдельного ownership audit, потому что program-layer снова становится writer для значимого числа global publications.

Вывод:
- для recovery допустимо сохранить этот слой;
- для дальнейшего cleanup он должен быть повторно пересмотрен отдельно.

Статус: ACCEPTABLE FOR RECOVERY.

## Обязательные адаптации до восстановления

### A-REC-01
Не вставлять кандидата в корень без решения по owner-слою heating requests.

### A-REC-02
Перед восстановлением заменить или явно подтвердить источник `VI_Preheat_Request`:
- либо `GVL_STATE.G_Preheat_Request`,
- либо осознанно оставить `GVL_HEATING_REQUEST.G_Preheat_Request`, если будет отдельно подтвержден возврат ownership в этот слой.

### A-REC-03
Перед восстановлением зафиксировать, какой слой считается основным owner для `Target_Temperature`:
- `GVL_STATE`,
- или `GVL_HEATING_REQUEST`.

### A-REC-04
Не менять при recovery сигнатуры вызовов `FB_Heating_System_Manager` и `FB_DHW_Manager`, если на это нет отдельного подтвержденного основания.

### A-REC-05
Не заменять intent-based `VI_Reset_Errors := GVL_INTENT_USER.I_Reset_Errors` на legacy command reset-path.

## Что можно считать recovery without redesign
Допустимыми recovery-изменениями считаются:
- возврат полного непрерывного текста `PRG_Heating.st` вместо placeholder-like root-файла,
- минимальная адаптация источника heating request к текущему owner-слою,
- сохранение текущих интерфейсов heating/DHW FB,
- сохранение текущего места `PRG_Heating` в `MAIN.st`.

## Что уже будет redesign
Следующие действия нельзя считать чистым recovery:
- возврат ownership heating requests в другой слой без отдельного решения,
- изменение policy semantics heating cluster,
- глубокий rework diagnostics publication,
- одновременное восстановление wrapper и переработка heating arbitration-логики.

## Решение по этапу H-R3
Основной кандидат
- пригоден для восстановления,
- но только после минимальной адаптации ownership-точек around heating request layer.

Критический вывод:
самое важное перед восстановлением — **не вернуть полный файл ценой скрытого rollback ownership**.

## Рекомендуемый следующий шаг
Подготовить следующий документ:
`08_HEATING_RECOVERY_CHANGESET_PLAN.md`

В нем нужно зафиксировать:
- минимальный список изменений для возврата полного `PRG_Heating.st` в корень,
- какие строки считаются recovery adaptation,
- какие изменения откладываются на post-recovery audit.