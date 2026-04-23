# Ventilation Manager Diagnostics Ownership Decision

Дата фиксации: 2026-04-23

## Назначение
Этот документ переводит `68_VENTILATION_MANAGER_DIAGNOSTICS_CLEANUP_PLAN.md` в следующее узкое решение:
**как трактовать direct diagnostics/global-state writes внутри `FB_Ventilation_System_Manager.st`**.

Цель:
- определить, являются ли direct writes допустимым текущим pattern;
- или признать их explicit cleanup target следующей локальной волны;
- не раздувать проблему до premature redesign всего ventilation cluster.

## Основание
Решение опирается на:
- `66_VENTILATION_OWNERSHIP_STATUS_DIAGNOSTICS_AUDIT.md`
- `67_VENTILATION_FIX_DIRECTION_DECISION.md`
- `68_VENTILATION_MANAGER_DIAGNOSTICS_CLEANUP_PLAN.md`
- текущее состояние `FB_Ventilation_System_Manager.st`

## Что уже подтверждено
По текущему live root уже зафиксировано:
- requests path вентиляции clean и проходит через wrapper boundary;
- normal outputs path вентиляции clean и проходит через declared manager outputs;
- внутри `FB_Ventilation_System_Manager.st` есть direct writes в globals:
  - `GVL_STATE.G_Ventilation_IO_Fault`
  - `GVL_STATE.G_Ventilation_Subsystem_Degraded`
- эти direct writes сосредоточены внутри того же блока, который уже несет policy/control/status logic.

## Варианты трактовки

### Option A. Оставить direct writes как допустимый current pattern
Это означает:
- признать, что manager может напрямую владеть diagnostics/global-state flags;
- ограничиться documentation фиксацией;
- не открывать code cleanup по этому вопросу.

### Option B. Признать direct writes explicit cleanup target
Это означает:
- согласиться, что текущий pattern работает,
- но считать его архитектурно нежелательным ownership smell;
- подготовить минимальный changeset для более явной публикации diagnostics/degraded state.

### Option C. Считать это симптомом необходимости broad manager redesign
Это означает:
- трактовать direct writes как признак слишком тяжелого manager;
- поднимать вопрос о decomposition/policy split уже сейчас.

## Решение
На текущем этапе принимается:

# Decision: Option B — direct writes являются explicit cleanup target

## Почему выбран именно этот вариант

### VMDD-01. Это уже не просто stylistic detail
Direct writes находятся не в пустом helper, а внутри manager, который уже концентрирует:
- system policy,
- IO fault handling,
- control outputs,
- status publication.

Вывод:
- дополнительная global-state ownership внутри него усиливает already-confirmed concentration smell.

### VMDD-02. При этом текущая проблема еще не тянет на broad redesign
Не подтверждено, что нужно:
- немедленно декомпозировать manager,
- выносить policy слой полностью наружу,
- перепридумывать ventilation architecture целиком.

Вывод:
- proportional response — признать pattern нежелательным, но лечить его локально.

### VMDD-03. Clean paths уже отделены, значит можно целиться узко
Так как requests path и normal outputs path уже выглядят clean, есть возможность править только smell subset:
- diagnostics/degraded state publication.

Вывод:
- cleanup target хорошо локализован.

### VMDD-04. Это улучшит ownership clarity без ломки behavior model
Если diagnostics/degraded publication станет более явной и boundary-bounded, cluster станет понятнее без переписывания core control logic.

Вывод:
- высокий hygiene payoff при относительно малом scope.

## Что именно фиксируется этим решением

### RD-VM-01. `G_Ventilation_IO_Fault` считать cleanup target
Current direct write inside manager признается:
- working,
- but undesirable as long-term ownership pattern.

### RD-VM-02. `G_Ventilation_Subsystem_Degraded` считать cleanup target
Current direct write inside manager признается:
- working,
- but undesirable as long-term ownership pattern.

### RD-VM-03. Следующий шаг должен искать более явную publication boundary
Нужно рассмотреть minimal path, при котором:
- diagnostics/degraded signals публикуются более явно,
- а manager меньше зависит от direct mutation of `GVL_STATE`.

### RD-VM-04. Requests and normal outputs не трогать
На текущем этапе не нужно менять:
- request ingestion path;
- `VO_Supply_Fans` / `VO_Exhaust_Fans`;
- `VO_Heater_Power`;
- `VO_Status_Msg`.

## Что это решение НЕ означает
Это решение не означает:
- немедленный рефактор manager на несколько блоков;
- перенос всей diagnostics/policy logic из manager наружу;
- ventilation-wide redesign;
- что current behavior неверен runtime-wise.

Это означает только:
- ownership boundary здесь архитектурно недостаточно чистая и должна стать следующей локальной cleanup-целью.

## Практический смысл решения
После этого документа ventilation wave получает уже не общий smell-description, а конкретную рабочую позицию:
- direct writes не остаются просто «наблюдением»;
- они признаются целевым cleanup scope следующего минимального changeset.

Это переводит вентиляционную волну из purely analytical стадии в следующую локальную remediation фазу.

## Следующий рекомендуемый документ
- `70_VENTILATION_MANAGER_DIAGNOSTICS_MINIMAL_CHANGESET_PLAN.md`

Его задача:
- зафиксировать минимальный changeset, который уменьшит direct global-state ownership внутри manager без затрагивания clean paths и без premature redesign.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения