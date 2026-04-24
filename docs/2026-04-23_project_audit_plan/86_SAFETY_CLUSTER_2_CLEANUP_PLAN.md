# 86 — Safety Cluster 2 Cleanup Plan

Дата фиксации: 2026-04-24
Режим: Direct Repository Modification Mode
Scope: documentation / cleanup planning only
Runtime-код: не изменялся

## Цель

Зафиксировать план безопасного выноса Cluster 2 из `PRG_Safety.st` без изменения поведения safety core.

Cluster 2 — это operator / test / recover workflow, который сейчас находится внутри `PRG_Safety.st`, но по ownership не является чистым safety producer ядром.

---

## Текущая структура `PRG_Safety.st`

По текущему коду `PRG_Safety.st` содержит следующие блоки:

```text
SAFETY_WORKFLOW_INPUT_NORMALIZATION
SAFETY_INTENT_RESET_INIT
SAFETY_DETECTORS_AND_HEALTH_PROJECTION
SAFETY_CORE_HAZARD_INTERLOCK_PROJECTION
SAFETY_WORKFLOW_CLUSTER
SAFETY_RESIDUAL_NON_WORKFLOW_PROJECTION
```

---

## Что считается Cluster 2

Cluster 2 включает:

### 1. Operator edge normalization

Блок:

```text
SAFETY_WORKFLOW_INPUT_NORMALIZATION
```

Содержит edge detection для user/operator intent:

```text
I_Water_Selective_Recover
I_Gas_Selective_Recover
I_Water_Valve_Test_Open
I_Water_Valve_Test_Close
I_Water_Valve_Test_Confirm
I_Gas_Valve_Test_Open
I_Gas_Valve_Test_Close
I_Gas_Valve_Test_Confirm
```

### 2. Test / recover workflow state

Блок:

```text
SAFETY_WORKFLOW_CLUSTER
```

Содержит:

```text
L_Water_Test_Active
L_Water_Test_Deadline
L_Gas_Test_Active
L_Gas_Test_Deadline
```

и timeout-driven effects:

```text
I_Water_Main_Close_Required := TRUE
I_Gas_Close_Required := TRUE
```

---

## Почему Cluster 2 нужно отделять

`PRG_Safety.st` должен оставаться producer ядром safety intent:

```text
hazard / latched state / detector health -> safety intent
```

Cluster 2 имеет другую природу:

```text
operator command -> workflow edge -> test/recover state -> possible safety action
```

Это workflow orchestration, а не core safety detection.

---

## Что НЕ трогаем

Следующие блоки не являются целью первого cleanup:

### 1. `SAFETY_DETECTORS_AND_HEALTH_PROJECTION`

Оставить в `PRG_Safety.st`.

Причина: это естественный bridge detector -> health -> safety intent.

### 2. `SAFETY_CORE_HAZARD_INTERLOCK_PROJECTION`

Оставить в `PRG_Safety.st`.

Причина: это чистое ядро safety producer.

### 3. `SAFETY_INTENT_RESET_INIT`

Пока оставить в `PRG_Safety.st`.

Причина: reset ownership связан с единственным producer safety intent. Выносить только после отдельного ownership review.

### 4. `SAFETY_RESIDUAL_NON_WORKFLOW_PROJECTION`

Пока оставить в `PRG_Safety.st`.

Причина: freeze hardware degraded -> freeze protection required является safety projection.

---

## Целевое разделение ownership

### `PRG_Safety.st`

Остаётся владельцем:

```text
- detector calls
- health bridge projection
- latched hazard interlocks
- safety intent reset/init
- residual safety projection
```

### Новый workflow owner

Кандидаты:

```text
FB_Safety_Workflow_Manager
```

или:

```text
PRG_Safety_Workflow
```

Рекомендация: начать с `FB_Safety_Workflow_Manager`, потому что workflow имеет внутреннее состояние, edge detection и timeout state.

---

## Предлагаемый интерфейс `FB_Safety_Workflow_Manager`

### Inputs

```text
VI_System_Time_MS : UDINT
VI_Water_Selective_Recover : BOOL
VI_Gas_Selective_Recover : BOOL
VI_Water_Valve_Test_Open : BOOL
VI_Water_Valve_Test_Close : BOOL
VI_Water_Valve_Test_Confirm : BOOL
VI_Gas_Valve_Test_Open : BOOL
VI_Gas_Valve_Test_Close : BOOL
VI_Gas_Valve_Test_Confirm : BOOL
```

### Outputs

```text
VO_Water_Test_Active : BOOL
VO_Gas_Test_Active : BOOL
VO_Water_Test_Timeout_Close_Required : BOOL
VO_Gas_Test_Timeout_Close_Required : BOOL
```

### Internal state

```text
L_CMD_*_Prev
L_CMD_*_Edge
L_Water_Test_Deadline
L_Gas_Test_Deadline
```

---

## Как `PRG_Safety.st` должен использовать результат

После выноса `PRG_Safety.st` не должен выполнять edge detection сам.

Он должен только принимать outputs workflow manager и проецировать их в safety intent:

```text
IF fbSafetyWorkflow.VO_Water_Test_Timeout_Close_Required THEN
    GVL_INTENT_SAFETY.I_Water_Main_Close_Required := TRUE;
END_IF;

IF fbSafetyWorkflow.VO_Gas_Test_Timeout_Close_Required THEN
    GVL_INTENT_SAFETY.I_Gas_Close_Required := TRUE;
END_IF;
```

---

## Safety invariants

При любом рефакторинге Cluster 2 должны быть сохранены инварианты:

```text
1. Smoke latched always requires safe stop and evacuation.
2. Gas latched always requires gas close and boiler stop.
3. Leak latched always requires water main close.
4. CO warning/alarm ventilation forcing remains unaffected.
5. Timeout during valve test must fail safe to close.
6. Workflow must not clear or mask latched hazards.
7. Workflow must not own detector or health bridge state.
8. Workflow must not publish directly to actuator commands.
```

---

## Migration plan

### Step 1 — Extract FB skeleton

Create:

```text
FB_Safety_Workflow_Manager.st
```

Move only internal workflow state and edge detection.

No behavior change.

### Step 2 — Wire FB into `PRG_Safety.st`

Replace local edge variables and local test state with FB call.

`PRG_Safety.st` still owns final safety intent projection.

### Step 3 — Verify file-state

Check:

```text
- no duplicated edge detection in PRG_Safety
- no missing test timeout behavior
- core hazard block unchanged
- detector block unchanged
```

### Step 4 — Compile verification

Required for runtime confirmation:

```text
Full Verification Mode
steps/* -> terminal execution -> git diff -> compile log
```

Direct repository state confirmation is not enough for final runtime confirmation.

---

## What not to do

Do not:

```text
- move core hazard logic together with workflow
- change safety intent names
- change latch semantics
- clear hazards from workflow
- write directly to GVL_COMMAND from workflow
- introduce new actuator ownership in the FB
```

---

## Acceptance criteria

Cleanup is acceptable only if:

```text
[ ] `SAFETY_WORKFLOW_INPUT_NORMALIZATION` removed from PRG_Safety or reduced to FB call
[ ] `SAFETY_WORKFLOW_CLUSTER` removed from PRG_Safety or reduced to FB result projection
[ ] core hazard/interlock block unchanged
[ ] detector/health block unchanged
[ ] test timeout still fails safe
[ ] no direct actuator command added
[ ] compile log has 0 errors
```

---

## Recommended next step

Create implementation step package:

```text
steps/2026-04-24_safety_cluster_2_extract/01_extract_safety_workflow_manager.py
```

Do not perform runtime refactor without Full Verification Mode or explicit approval for Direct Repository Modification Mode on runtime code.

---

## Статус

P1 Safety Cluster 2 cleanup plan fixed.

Runtime unchanged.
