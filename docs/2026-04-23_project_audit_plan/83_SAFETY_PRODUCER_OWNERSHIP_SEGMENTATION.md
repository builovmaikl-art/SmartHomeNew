# Safety Producer Ownership Segmentation

Дата фиксации: 2026-04-23

## Назначение
Этот документ переводит `82_SAFETY_PRODUCER_OWNERSHIP_CLEANUP_PLAN.md` в следующий узкий этап:
**разложение `PRG_Safety.st` по ownership-clusters**.

Цель:
- сегментировать producer-side ownership concentration внутри `PRG_Safety.st`;
- отделить core safety semantics от test/recover/access-coupling хвостов;
- подготовить выбор наиболее подходящего minimal cleanup target.

## Основание
Документ опирается на:
- `77_SAFETY_LIVE_PROGRAM_AUDIT.md`
- `78_SAFETY_OWNERSHIP_AND_PUBLICATION_AUDIT.md`
- `79_SAFETY_CROSS_SUBSYSTEM_DEPENDENCY_AUDIT.md`
- `80_SAFETY_BOUNDARY_ARCHITECTURE_INTERPRETATION.md`
- `81_SAFETY_FIX_DIRECTION_DECISION.md`
- `82_SAFETY_PRODUCER_OWNERSHIP_CLEANUP_PLAN.md`
- текущее состояние `PRG_Safety.st`

## Главный вывод
`PRG_Safety.st` уже можно разложить не как один неясный heavy producer, а как минимум на **четыре различимых ownership-cluster**:

1. **Core hazard/interlock projection cluster**
2. **Operator/test/recover workflow cluster**
3. **Safety-access coupling cluster**
4. **Producer-heavier publication tail**

Это важный шаг, потому что теперь safety smell можно обсуждать не целиком по всему `PRG_Safety.st`, а по более узким subsets.

## Cluster 1. Core hazard / interlock projection

### Состав
К этому кластеру относятся:
- reset/init `GVL_INTENT_SAFETY` as main publication surface;
- alarm semantic projection:
  - `I_Fire_Alarm_Active`
  - `I_Gas_Alarm_Active`
  - `I_CO_Warning_Active`
  - `I_Leak_Alarm_Active`
- core required-action projection from latched safety state:
  - `I_System_Safe_Stop_Required`
  - `I_Gas_Close_Required`
  - `I_Boiler_Stop_Required`
  - `I_Vent_Stop_Required`
  - `I_Vent_Force_PV3_Boost`
  - `I_Vent_Force_Supply_100`
  - `I_Vent_Force_Supply_80`
  - `I_Water_Main_Close_Required`
- freeze-related projection:
  - `I_Freeze_Protection_Required`

### Почему это отдельный cluster
Этот слой:
- напрямую связан с hazard semantics;
- уже опирается на latched state и detector outputs;
- имеет наиболее явную связь с downstream operational effects.

### Оценка
Это выглядит как **ядро допустимой producer-role** `PRG_Safety.st`.

То есть именно этот кластер наиболее естественно оставлять внутри общего safety producer layer.

## Cluster 2. Operator / test / recover workflow

### Состав
К этому кластеру относятся:
- edge detection по:
  - `I_Water_Selective_Recover`
  - `I_Gas_Selective_Recover`
  - `I_Water_Valve_Test_Open`
  - `I_Water_Valve_Test_Close`
  - `I_Water_Valve_Test_Confirm`
  - `I_Gas_Valve_Test_Open`
  - `I_Gas_Valve_Test_Close`
  - `I_Gas_Valve_Test_Confirm`
- локальные workflow-state variables:
  - `L_Water_Test_Active`
  - `L_Water_Test_Deadline`
  - `L_Gas_Test_Active`
  - `L_Gas_Test_Deadline`
- timeout-driven projection into required actions.

### Почему это отдельный cluster
Этот слой:
- относится не к ядру hazard semantics,
- а к operator/test/recover behavior;
- имеет собственную mini-workflow/statefulness логику;
- живет в том же producer program, что и core safety semantics.

### Оценка
Это уже выглядит как **первый сильный candidate for cleanup segregation**.

Именно этот кластер добавляет `PRG_Safety.st` workflow-тяжесть сверх базовой producer-role.

## Cluster 3. Safety-access coupling

### Состав
К этому кластеру относятся:
- `I_Lock_1_Force_Open`
- `I_Lock_1_Force_Close_Block`
- `I_Lock_2_Force_Open`
- `I_Lock_2_Force_Close_Block`
- косвенно также `I_Evacuation_Mode_Active`, если рассматривать его как часть access/egress semantics during fire conditions.

### Почему это отдельный cluster
Этот слой:
- лежит на границе между safety и access domain;
- влияет не на generic safety handling, а на lock/egress behavior;
- является cross-domain coupling subset внутри safety producer.

### Оценка
Это не выглядит случайным мусором.

Но это выглядит как **отдельный поддомен внутри producer-side ownership**, который не обязан быть смешан с остальной safety publication на одном уровне детализации.

## Cluster 4. Producer-heavier publication tail

### Состав
К этому кластеру относятся поля, для которых checked scope пока не дал столь же сильного downstream-consumer подтверждения, как для gas/vent/water/boiler effects.

Сюда предварительно попадают:
- `I_System_Safe_Stop_Required`
- `I_Evacuation_Mode_Active`
- `I_Freeze_Protection_Required`
- возможно часть recovery-related fields:
  - `I_Water_Selective_Recovery_Allowed`
  - `I_Water_Recovery_Target_Zone`

### Почему это отдельный cluster
Этот слой не обязательно лишний.

Но по текущему checked scope он выглядит как **publication surface шире, чем явно подтвержденный consumer set**.

### Оценка
Это скорее **audit-candidate tail**, а не immediate code-fix target.

То есть этот кластер важен для понимания ширины producer-role, но не обязательно является первым кандидатом на code cleanup.

## Сравнение кластеров по cleanup-ценности

### Cluster 1. Core hazard/interlock projection
- value of cleanup now: низкий
- reason: это выглядит как естественное ядро safety producer role

### Cluster 2. Operator/test/recover workflow
- value of cleanup now: высокий
- reason: stateful workflow semantics смешана с core safety producer semantics

### Cluster 3. Safety-access coupling
- value of cleanup now: средний/высокий
- reason: cross-domain subset уже отделим, но он тесно связан с fire/egress behavior

### Cluster 4. Producer-heavier publication tail
- value of cleanup now: средний
- reason: нужен скорее additional confirmation/clarification, чем immediate structural move

## Главный практический вывод сегментации
На текущем этапе наиболее promising minimal cleanup target выглядит так:

# Priority candidate = Cluster 2 (operator/test/recover workflow)

### Почему именно он
- он наиболее явно не относится к ядру hazard/interlock projection;
- он добавляет локальную stateful workflow-логику в и без того тяжелый producer layer;
- его можно обсуждать отдельно, не ломая `GVL_INTENT_SAFETY` boundary;
- он, вероятно, легче поддается локальному cleanup decision, чем broad safety-access coupling subset.

## Secondary candidate
Вторым по значимости cleanup-кандидатом выглядит:

# Secondary candidate = Cluster 3 (safety-access coupling)

Но его стоит рассматривать после Cluster 2, потому что:
- coupling с lock/egress behavior может оказаться оправданной частью fire-safety semantics;
- риск ошибочно вынести слишком важную safety-access связку здесь выше.

## Что этот этап НЕ утверждает

### SPCS-NO-01
Он не утверждает, что Cluster 2 обязательно должен быть физически вынесен в новый POU прямо сейчас.

### SPCS-NO-02
Он не утверждает, что Cluster 3 является ошибкой архитектуры.

### SPCS-NO-03
Он не утверждает, что Cluster 4 лишний.

Он утверждает только:
- `PRG_Safety.st` теперь достаточно хорошо сегментирован,
- и наиболее вероятный minimal cleanup target уже выделяется достаточно ясно.

## Практический эффект этапа
После этой сегментации следующий шаг уже может быть очень узким:
- не «что делать со всем `PRG_Safety.st`»,
- а «что делать с operator/test/recover workflow cluster внутри него».

Это и есть нужный уровень детализации перед локальным cleanup decision.

## Следующий рекомендуемый документ
- `84_SAFETY_MINIMAL_CLEANUP_TARGET_DECISION.md`

Его задача:
- подтвердить, что именно Cluster 2 является лучшим первым cleanup target;
- или, если найдутся возражения, честно выбрать другой sub-scope.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения