# Ventilation Manager Diagnostics Output Contract Decision

Дата фиксации: 2026-04-23

## Назначение
Этот документ переводит `70_VENTILATION_MANAGER_DIAGNOSTICS_MINIMAL_CHANGESET_PLAN.md` в следующее узкое решение:
**каким должен быть target contract для новых diagnostics outputs `FB_Ventilation_System_Manager.st`**.

Цель:
- зафиксировать точную форму новых diagnostics outputs;
- убрать неопределенность перед execution-plan и реальной правкой;
- не раздувать scope beyond minimal changeset.

## Основание
Решение опирается на:
- `68_VENTILATION_MANAGER_DIAGNOSTICS_CLEANUP_PLAN.md`
- `69_VENTILATION_MANAGER_DIAGNOSTICS_OWNERSHIP_DECISION.md`
- `70_VENTILATION_MANAGER_DIAGNOSTICS_MINIMAL_CHANGESET_PLAN.md`
- текущее состояние `FB_Ventilation_System_Manager.st`
- текущее состояние `PRG_Ventilation.st`

## Что уже подтверждено
К текущему моменту уже зафиксировано:
- direct writes в `GVL_STATE.G_Ventilation_IO_Fault` и `GVL_STATE.G_Ventilation_Subsystem_Degraded` являются explicit cleanup target;
- requests path и normal outputs path вентиляции clean и не должны меняться;
- preferred remediation direction — diagnostics publication через явный output contract manager + wrapper publication.

Следовательно, осталось принять точное contract-level решение:
- какие outputs вводим,
- как они называются,
- где именно потом публикуем их наружу.

## Варианты contract naming

### Option A. Обобщенные internal-style names
Примеры по смыслу:
- `VO_Diagnostics_Fault`
- `VO_Subsystem_Degraded`

Плюс:
- коротко.

Минус:
- слишком общо;
- хуже читается в большом проекте с несколькими subsystem managers.

### Option B. Ventilation-specific explicit names
Примеры по смыслу:
- `VO_Ventilation_IO_Fault`
- `VO_Ventilation_Subsystem_Degraded`

Плюс:
- максимально однозначно;
- хорошо читается даже вне локального контекста блока;
- прямо отображает target publication fields.

Минус:
- чуть длиннее.

### Option C. Более abstract policy-state names
Примеры по смыслу:
- `VO_IO_Fault`
- `VO_Degraded`

Плюс:
- коротко и компактно.

Минус:
- слишком легко потерять subsystem-context;
- хуже подходит для явной boundary publication в глобальные поля.

## Решение
На текущем этапе принимается:

# Decision: Option B — ventilation-specific explicit output names

## Почему выбран именно этот вариант

### VOD-01. Нужно максимальное совпадение с target publication semantics
Текущие cleanup targets уже известны и конкретны:
- `GVL_STATE.G_Ventilation_IO_Fault`
- `GVL_STATE.G_Ventilation_Subsystem_Degraded`

Вывод:
- outputs с explicit ventilation-specific naming делают mapping почти самодокументируемым.

### VOD-02. Это снижает ambiguity в wrapper publication
Когда `PRG_Ventilation.st` будет связывать новые outputs с `GVL_STATE`, лучше, чтобы имена сигналов были прозрачными уже на уровне manager contract.

Вывод:
- explicit names уменьшают риск путаницы на boundary-step.

### VOD-03. Это пропорционально текущему scope
Мы не создаем общий diagnostics framework для всех subsystem blocks.

Мы решаем узкую задачу локального cleanup.

Вывод:
- лучше выбрать наиболее прямой и однозначный contract, а не абстрактный reusable naming.

## Точный target contract
В `FB_Ventilation_System_Manager.st` нужно добавить два новых `VAR_OUTPUT` сигнала:

- `VO_Ventilation_IO_Fault : BOOL`
- `VO_Ventilation_Subsystem_Degraded : BOOL`

## Целевая semantics новых outputs

### `VO_Ventilation_IO_Fault`
Должен отражать:
- текущий ventilation IO fault state,
- то есть тот же смысл, который сейчас публикуется через direct writes в `GVL_STATE.G_Ventilation_IO_Fault`.

### `VO_Ventilation_Subsystem_Degraded`
Должен отражать:
- текущий degraded state вентиляционного кластера,
- то есть тот же смысл, который сейчас публикуется через direct writes в `GVL_STATE.G_Ventilation_Subsystem_Degraded`.

## Где должна происходить публикация наружу
После добавления новых outputs target boundary должна выглядеть так:

### Внутри manager
- manager вычисляет diagnostics states;
- manager присваивает значения новым `VO_*` diagnostics outputs;
- manager больше не пишет эти два поля напрямую в `GVL_STATE`.

### Внутри wrapper `PRG_Ventilation.st`
- wrapper принимает:
  - `VO_Ventilation_IO_Fault`
  - `VO_Ventilation_Subsystem_Degraded`
- wrapper публикует их в:
  - `GVL_STATE.G_Ventilation_IO_Fault`
  - `GVL_STATE.G_Ventilation_Subsystem_Degraded`

## Что не меняется этим contract decision

### VOD-NO-01
Не меняются request inputs manager.

### VOD-NO-02
Не меняются fan outputs.

### VOD-NO-03
Не меняется `VO_Heater_Power`.

### VOD-NO-04
Не меняется `VO_Status_Msg`.

### VOD-NO-05
Не меняется broader ventilation policy/control logic только ради нового diagnostics contract.

## Практический смысл решения
После этого документа следующий шаг уже не должен решать naming с нуля.

Он может сразу переходить к execution-plan с фиксированным target contract:
- `VO_Ventilation_IO_Fault`
- `VO_Ventilation_Subsystem_Degraded`

Это делает следующий changeset:
- минимальным,
- однозначным,
- проверяемым по repository state.

## Следующий рекомендуемый документ
- `72_VENTILATION_MANAGER_DIAGNOSTICS_EXECUTION_PLAN.md`

Его задача:
- перевести этот contract decision в конкретный исполнительный порядок изменения `FB_Ventilation_System_Manager.st` и `PRG_Ventilation.st`.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения