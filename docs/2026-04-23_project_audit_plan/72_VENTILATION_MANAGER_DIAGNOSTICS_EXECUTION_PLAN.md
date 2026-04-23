# Ventilation Manager Diagnostics Execution Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ переводит `71_VENTILATION_MANAGER_DIAGNOSTICS_OUTPUT_CONTRACT_DECISION.md` в **исполнительный порядок** для локального cleanup вентиляционного diagnostics ownership.

Это не ventilation-wide redesign.

Это строго:
- локальное расширение output contract `FB_Ventilation_System_Manager.st`;
- перенос publication двух diagnostics flags на wrapper boundary `PRG_Ventilation.st`;
- устранение direct global writes по этим двум полям внутри manager;
- repository-state verification после изменения.

## Основание
План опирается на:
- `69_VENTILATION_MANAGER_DIAGNOSTICS_OWNERSHIP_DECISION.md`
- `70_VENTILATION_MANAGER_DIAGNOSTICS_MINIMAL_CHANGESET_PLAN.md`
- `71_VENTILATION_MANAGER_DIAGNOSTICS_OUTPUT_CONTRACT_DECISION.md`
- текущее состояние `FB_Ventilation_System_Manager.st`
- текущее состояние `PRG_Ventilation.st`

## Цель исполнения
Получить такую ventilation boundary, при которой:
- `FB_Ventilation_System_Manager.st` больше не пишет напрямую в
  - `GVL_STATE.G_Ventilation_IO_Fault`
  - `GVL_STATE.G_Ventilation_Subsystem_Degraded`;
- manager публикует эти состояния через:
  - `VO_Ventilation_IO_Fault`
  - `VO_Ventilation_Subsystem_Degraded`;
- `PRG_Ventilation.st` принимает эти outputs и публикует их в соответствующие поля `GVL_STATE`.

## Execution Mode
- Режим исполнения: Direct Repository Modification Mode.
- Тип проверки: repository state verification.
- Ограничение: без compile/run подтверждения.

## Зафиксированные инварианты перед изменением
Во время этого этапа нельзя менять:
- request ingestion path из `GVL_COMMAND_SHADOW`;
- основной manager contract beyond two new diagnostics outputs;
- fan outputs path;
- heater power output path;
- `VO_Status_Msg` semantics;
- scenario/policy/control logic beyond diagnostics publication shape;
- wrapper structure beyond minimal publication additions.

Допустим только минимальный diagnostics ownership cleanup.

## Исполнительный порядок

### Шаг VDE-01. Подтвердить текущие direct writes в manager
Действие:
- перечитать `FB_Ventilation_System_Manager.st`;
- подтвердить direct writes в:
  - `GVL_STATE.G_Ventilation_IO_Fault`
  - `GVL_STATE.G_Ventilation_Subsystem_Degraded`

Ожидаемый результат:
- changeset вносится по подтвержденному live-root состоянию.

### Шаг VDE-02. Расширить `VAR_OUTPUT` в `FB_Ventilation_System_Manager.st`
Действие:
- добавить два новых outputs:
  - `VO_Ventilation_IO_Fault : BOOL`
  - `VO_Ventilation_Subsystem_Degraded : BOOL`

Ожидаемый результат:
- diagnostics/degraded state получает explicit output contract.

### Шаг VDE-03. Перенести diagnostics assignment внутрь новых outputs
Действие:
- заменить direct writes этих двух флагов в `GVL_STATE` на работу через новые `VO_*` outputs;
- при этом сохранить текущую runtime semantics настолько, насколько это возможно в рамках repository-state cleanup.

Нужно получить такую модель:
- manager вычисляет IO fault state;
- manager вычисляет degraded state;
- manager присваивает их в `VO_Ventilation_IO_Fault` и `VO_Ventilation_Subsystem_Degraded`;
- manager больше не мутирует напрямую эти два поля в `GVL_STATE`.

Ожидаемый результат:
- direct global diagnostics writes исчезают из manager.

### Шаг VDE-04. Расширить call-site в `PRG_Ventilation.st`
Действие:
- добавить bindings новых outputs в вызов `fbVentilationManager(...)`:
  - `VO_Ventilation_IO_Fault => ...`
  - `VO_Ventilation_Subsystem_Degraded => ...`

Предпочтительно публиковать их через локальные wrapper-boundary bindings в:
- `GVL_STATE.G_Ventilation_IO_Fault`
- `GVL_STATE.G_Ventilation_Subsystem_Degraded`

Ожидаемый результат:
- wrapper становится явной publication boundary для ventilation diagnostics flags.

### Шаг VDE-05. Не менять чистые paths
Действие:
- оставить без изменения:
  - all `VI_*_Req` request flow,
  - `VO_Supply_Fans`,
  - `VO_Exhaust_Fans`,
  - `VO_Heater_Power`,
  - `VO_Status_Msg`,
  - wet-zone adapter,
  - fan copy-out adapters.

Ожидаемый результат:
- changeset остается точечным.

### Шаг VDE-06. Выполнить repository-state verification после правки
Действие:
- перечитать `FB_Ventilation_System_Manager.st` и `PRG_Ventilation.st` после изменения.

Нужно подтвердить:
1. новые outputs добавлены именно как:
   - `VO_Ventilation_IO_Fault`
   - `VO_Ventilation_Subsystem_Degraded`;
2. direct writes в `GVL_STATE` по этим двум флагам внутри manager больше не используются;
3. `PRG_Ventilation.st` публикует эти два состояния наружу;
4. request path и normal outputs path не изменены без необходимости;
5. changeset не вырос в broader ventilation redesign.

Ожидаемый результат:
- confirmed minimal diagnostics ownership cleanup.

### Шаг VDE-07. Только при необходимости сделать короткий documentary pass
Действие:
- если после правки локальные comments в manager/wrapper будут вводить в заблуждение, допустим короткий documentary cleanup.

Но:
- это optional secondary action;
- не основная часть fix.

## Что считается допустимым изменением
Допустимо:
- добавить два diagnostics outputs в manager contract;
- заменить direct global writes на assignment в эти outputs;
- добавить два output bindings в wrapper call-site;
- опционально слегка выровнять локальное форматирование параметров/outputs.

## Что запрещено на этом шаге
Запрещено:
- менять broader manager architecture;
- менять request ingestion path;
- менять fan/heater/status message outputs semantics;
- менять global ventilation policy model beyond diagnostics publication shape;
- делать wrapper-heavy refactor;
- начинать manager decomposition.

## Критерии успешного завершения execution plan
Этап считается успешно выполненным, если:
1. diagnostics direct writes inside manager устранены;
2. diagnostics publication становится explicit and wrapper-bounded;
3. normal paths остаются чистыми и нетронутыми;
4. ventilation cleanup остается локальным и пропорциональным.

## Следующий документ после исполнения
После выполнения этого плана должен появиться:
- `73_VENTILATION_MANAGER_DIAGNOSTICS_CLEANUP_RESULT.md`

В нем нужно будет зафиксировать:
- какие outputs были добавлены;
- как именно исчезли direct writes;
- что осталось следующим шагом в ventilation wave.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения