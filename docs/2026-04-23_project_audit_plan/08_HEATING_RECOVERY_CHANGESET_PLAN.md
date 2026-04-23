# Heating Recovery Changeset Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ фиксирует **минимальный recovery changeset**, который допустим для возврата полного `PRG_Heating.st` в живой корень.

Цель документа:
- не смешать восстановление источника с последующим рефакторингом,
- зафиксировать точный объем допустимых изменений,
- отделить обязательные recovery-адаптации от изменений, которые уже считаются redesign.

## Основание
План построен на результатах:
- `04_HEATING_CLUSTER_AUDIT.md`
- `05_HEATING_REMEDIATION_PLAN.md`
- `06_HEATING_SOURCE_RECOVERY_AUDIT.md`
- `07_HEATING_RECOVERY_COMPATIBILITY_CHECK.md`

## Базовый recovery source
Основной источник восстановления:
- `snapshots/2026-04-22/PRG_Heating.st`

Резервный источник:
- `snapshots/project_clean_state_2026_04_16/PRG_Heating.st`

## Главный принцип recovery changeset
В changeset должны входить только те изменения, без которых невозможно:
1. вернуть полный непрерывный `PRG_Heating.st` в корень;
2. сохранить совместимость с текущим live root;
3. избежать скрытого rollback ownership.

Все, что выходит за эти три рамки, считается не recovery, а redesign / cleanup следующего этапа.

## Минимальный допустимый changeset

### RC-001. Заменить сокращенный live-root `PRG_Heating.st` на полный непрерывный wrapper
Суть:
- убрать placeholder-like текст `omitted for brevity` / `rest unchanged`;
- вернуть в корень единый непрерывный program-layer на базе основного кандидата.

Это обязательное recovery-действие.

### RC-002. Адаптировать owner-источник heating request к текущему live root
Суть:
- при восстановлении не использовать `GVL_HEATING_REQUEST.G_Preheat_Request` как неявный основной owner без отдельного архитектурного решения;
- привести источник `VI_Preheat_Request` к текущему подтвержденному live-root owner-слою.

Текущее рабочее предположение для recovery:
- использовать `GVL_STATE.G_Preheat_Request` как источник `VI_Preheat_Request`,
- не возвращать ownership heating request в `GVL_HEATING_REQUEST` в рамках recovery.

Это обязательное recovery-действие.

### RC-003. Сохранить current-live publication через `GVL_STATE` для freeze / preheat / target temperature
Суть:
- не менять существующий слой, где live root уже хранит:
  - `GVL_STATE.G_Preheat_Request`
  - `GVL_STATE.G_Freeze_Request`
  - `GVL_STATE.G_Target_Temperature`
- не переносить эти публикации назад в другой слой в рамках recovery.

Это обязательное recovery-ограничение.

### RC-004. Сохранить intent-based reset path для DHW
Суть:
- в вызове `fbDHWManager(...)` оставить intent-based reset:
  - `VI_Reset_Errors := GVL_INTENT_USER.I_Reset_Errors`
- не возвращаться к legacy path через `GVL_COMMAND.G_Reset_Errors`.

Это обязательное recovery-действие.

### RC-005. Не менять место `PRG_Heating()` в `MAIN.st`
Суть:
- recovery не должен перестраивать верхний call order;
- `PRG_Heating` остается в текущем месте между `PRG_Security` и `PRG_Ventilation`.

Это recovery-ограничение.

### RC-006. Не менять сигнатуры вызовов heating / DHW FB
Суть:
- recovery не должен трогать интерфейсы:
  - `FB_Heating_System_Manager.st`
  - `FB_DHW_Manager.st`
- допустима только адаптация program wrapper к уже существующим интерфейсам.

Это recovery-ограничение.

## Что допускается сохранить без немедленного cleanup
Следующие части можно временно вернуть вместе с полным wrapper, даже если позже они потребуют отдельного ownership-аудита:
- integrated freeze-hardware diagnostics publication;
- maintenance gating backup pump / electric heater / manifold pumps / DHW pumps;
- copy-out layer `L_Zone_Valves_8 -> GVL_STATE.G_Zone_Valves`;
- локальную arbitration / stabilization логику внутри `PRG_Heating`, если она не ломает текущий owner-слой heating requests.

## Что нельзя включать в recovery changeset

### XR-001. Нельзя менять policy semantics heating cluster
Нельзя в рамках восстановления менять смысл:
- `NORMAL`
- `DEGRADED`
- `FREEZE_PROTECTION`
- `SAFE_STOP`

### XR-002. Нельзя одновременно делать deep cleanup global publications
Любое глубокое сокращение записей в `GVL_STATE` / `GVL_STATUS` / diagnostics publications откладывается на post-recovery этап.

### XR-003. Нельзя возвращать legacy ownership только потому, что он есть в snapshot
Наличие поля или вызова в snapshot не является достаточным основанием для его автоматического возврата в live root.

### XR-004. Нельзя одновременно перерабатывать heating arbitration design
Recovery не должен превращаться в переписывание request arbitration, target temperature arbitration или режима стабилизации.

### XR-005. Нельзя менять соседние подсистемы ради recovery heating
Recovery changeset должен быть локализован around `PRG_Heating.st` и только при необходимости касаться минимально связанных точек.

## Recovery checklist перед фактическим изменением корня
Перед фактическим восстановлением `PRG_Heating.st` должны быть выполнены все пункты:

1. Выбран основной recovery source.
2. Зафиксировано, что `GVL_STATE` остается owner-слоем для live heating requests.
3. Подтверждено, что `VI_Preheat_Request` будет адаптирован под live owner-слой.
4. Подтверждено, что `VI_Reset_Errors` останется intent-based.
5. Подтверждено, что `MAIN.st` не требует перестройки.
6. Подтверждено, что сигнатуры heating/DHW FB не меняются.
7. Отдельно зафиксировано, какие оставшиеся вопросы сознательно переносятся на post-recovery audit.

## Оставшиеся вопросы, которые переносятся на post-recovery этап
- нужен ли вообще отдельный `GVL_HEATING_REQUEST` как самостоятельный owner-layer;
- стоит ли переносить часть diagnostics publication из `PRG_Heating` выше в системный слой;
- нужно ли разделять heating arbitration и heating wrapper на несколько program/fb layers;
- какие записи в `GVL_STATE` должны остаться допустимыми после ownership cleanup.

## Формула следующего технического действия
Следующее техническое действие должно выглядеть так:

1. взять `snapshots/2026-04-22/PRG_Heating.st` как основу;
2. адаптировать heating request source к current-live owner-слою;
3. сохранить intent reset path и текущие FB interfaces;
4. вернуть полный `PRG_Heating.st` в корень без дополнительных логических redesign-изменений.

## Следующий документ
После этого плана должен появиться:
- `09_HEATING_RECOVERY_EXECUTION_PLAN.md`

Он должен уже описывать не анализ, а точный порядок внесения recovery-изменений в репозиторий.