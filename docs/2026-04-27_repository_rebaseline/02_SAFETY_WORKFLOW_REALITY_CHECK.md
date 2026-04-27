# 02 — Safety Workflow Reality Check

Дата: 2026-04-27
Назначение: фиксация фактического состояния safety workflow после обнаруженного расхождения между ранними safety-документами и текущим кодом

---

## Режим проверки

```text
Direct Repository Modification Mode + Analytical Repository Verification
```

Что это означает:

- документ создан прямой правкой репозитория;
- факты взяты из текущих файлов репозитория;
- подтверждение выполнено по repository file state;
- runtime/build подтверждение этим документом не заявляется.

---

## Проверенные файлы

```text
PRG_Safety.st
FB_Safety_Workflow_Manager.st
docs/2026-04-23_project_audit_plan/85_SAFETY_WORKFLOW_CLUSTER_CLEANUP_PLAN.md
docs/2026-04-23_project_audit_plan/86_SAFETY_WORKFLOW_CLUSTER_MINIMAL_CHANGESET_DECISION.md
docs/2026-04-23_project_audit_plan/87_SAFETY_WORKFLOW_CLUSTER_LOCAL_STRUCTURE_PLAN.md
docs/2026-04-23_project_audit_plan/88_SAFETY_WORKFLOW_CLUSTER_EXECUTION_PLAN.md
docs/2026-04-23_project_audit_plan/90_SAFETY_INTERIM_STATUS.md
```

---

## Главный факт текущего кода

В текущем репозитории safety workflow уже вынесен в отдельный FB:

```text
FB_Safety_Workflow_Manager.st exists
```

`PRG_Safety.st` содержит экземпляр:

```text
fbSafetyWorkflow : FB_Safety_Workflow_Manager;
```

И вызывает его как отдельный workflow-layer:

```text
fbSafetyWorkflow(...)
```

Следствие:

```text
Helper-style extraction already exists in code.
```

---

## Расхождение с более ранними safety docs

Ранее safety-документы фиксировали более осторожный path:

```text
Option A — local structural segregation inside PRG_Safety.st
No new helper/POU yet
```

Но фактический код соответствует уже более сильному варианту:

```text
Option B — helper-style extraction in FB_Safety_Workflow_Manager
```

Вывод:

```text
Earlier docs 85–90 describe an earlier planning state and are no longer fully current for workflow implementation reality.
Implemented code is the current fact of implementation.
```

---

## Фактическая структура PRG_Safety.st

`PRG_Safety.st` сейчас читается как layered producer program:

```text
1. SAFETY_INTENT_RESET_INIT
2. SAFETY_WORKFLOW_FB
3. SAFETY_DETECTORS_AND_HEALTH_PROJECTION
4. OWNERSHIP WATCHDOG
5. SAFETY_CORE_HAZARD_INTERLOCK_PROJECTION
6. SAFETY_RESIDUAL_NON_WORKFLOW_PROJECTION
```

Это означает, что workflow больше не размазан по safety body, а представлен отдельным вызовом workflow FB и небольшой projection-точкой обратно в `GVL_INTENT_SAFETY`.

Статус:

```text
GOOD — STRUCTURE IS CLEANER THAN EARLIER LOCAL-SEGREGATION PLAN
```

---

## Фактическая роль FB_Safety_Workflow_Manager

`FB_Safety_Workflow_Manager.st` содержит:

```text
workflow input edge detection
water/gas valve test activity state
water/gas valve test deadlines
timeout-driven close-required outputs
```

Он не содержит:

```text
fire hazard projection
gas hazard projection
leak hazard projection
boiler/vent/smoke interlock policy
lock/access force-open policy
```

Вывод:

```text
FB_Safety_Workflow_Manager is a workflow state/timer helper, not a core hazard owner.
```

---

## Фактическая роль PRG_Safety после extraction

`PRG_Safety.st` остаётся owner для:

```text
GVL_INTENT_SAFETY reset/init
detector manager calls
health bridge projection
core hazard/interlock projection
ownership watchdog projection
residual freeze safety projection
```

`PRG_Safety.st` также остаётся единственной точкой, где workflow timeout outputs превращаются в safety intents:

```text
VO_Water_Test_Timeout_Close_Required -> I_Water_Main_Close_Required
VO_Gas_Test_Timeout_Close_Required -> I_Gas_Close_Required
```

Вывод:

```text
PRG_Safety remains the safety intent publisher and core safety producer.
Workflow FB does not publish GVL_INTENT_SAFETY directly.
```

---

## Архитектурная оценка

Текущая архитектура лучше разделяет ответственность, чем ранний local-only plan:

```text
Workflow state/timers -> FB_Safety_Workflow_Manager
Safety intent publication -> PRG_Safety
Core hazard semantics -> PRG_Safety
Downstream execution -> Command Arbitration / domain layers
```

Положительные эффекты:

```text
PRG_Safety is less cluttered
workflow state has a named owner
core hazard projection remains visible
GVL_INTENT_SAFETY boundary remains preserved
```

Статус:

```text
ACCEPT AS CURRENT BASELINE
```

---

## Потенциальные риски текущего состояния

### RISK-SW-01 — workflow actions share safety intent fields with real hazards

Workflow timeout can set:

```text
I_Water_Main_Close_Required
I_Gas_Close_Required
```

The same output fields may also be used for actual safety hazards.

This is acceptable as an action-level intent, but diagnostic cause is not explicitly separated here.

Potential future improvement:

```text
Add or document cause/source distinction for close-required actions if diagnostics need it.
```

Do not change now without separate design.

---

### RISK-SW-02 — workflow FB is more than a trivial helper

`FB_Safety_Workflow_Manager` owns persistent state:

```text
L_Water_Test_Active
L_Water_Test_Deadline
L_Gas_Test_Active
L_Gas_Test_Deadline
previous-command edge state
```

Therefore it should be treated as a real workflow subcomponent, not just formatting extraction.

Potential future improvement:

```text
Document workflow lifecycle and timeout semantics separately if more test/recover flows are added.
```

Do not expand scope now.

---

### RISK-SW-03 — unused workflow outputs

`FB_Safety_Workflow_Manager` publishes edge and active outputs that `PRG_Safety.st` currently does not consume, except timeout-close outputs.

This may be intentional future surface, or it may be leftover interface expansion.

Potential future check:

```text
Confirm whether VO_*_Edge and VO_*_Active outputs are intentionally reserved or should be consumed/documented.
```

Do not remove now without compile/runtime verification and downstream search.

---

## What works and should not be touched now

Do not change during current verification pass:

```text
PRG_Safety placement in MAIN
GVL_INTENT_SAFETY reset/init pattern
Core smoke/gas/leak hazard projection
Detector manager calls
FB_Safety_Workflow_Manager existence
Workflow timeout projection into PRG_Safety
Command arbitration boundary
Downstream consumers
```

Reason:

```text
Current structure is coherent and lower-risk than the older mixed workflow/core form.
```

---

## What must be fixed in documentation understanding

For all further planning, treat these statements as current truth:

```text
Safety workflow helper extraction is already implemented.
Earlier local-segregation-only decision docs are historical planning context.
PRG_Safety remains core safety producer and intent publisher.
FB_Safety_Workflow_Manager owns workflow edge/timer state only.
```

---

## What is not confirmed by this document

This document does not confirm:

```text
full compile success
PLC runtime correctness
all downstream intent behavior
all possible overflow/time wraparound behavior in UDINT timer comparisons
whether unused workflow outputs are required or redundant
```

These require separate verification.

---

## Recommended next checks

Continue verification with:

```text
03_BOTTOM_UP_CONTRACT_VERIFICATION.md
04_COORDINATOR_DOMAIN_APPLICATION_CHECK.md
05_HEATING_POLICY_INTEGRATION_PLAN.md
```

Recommended immediate next step:

```text
03_BOTTOM_UP_CONTRACT_VERIFICATION.md
```

Scope:

- verify FB call signatures for checked slices;
- verify GVL fields used by coordinator/mode/presence/policy/safety exist by repository inspection;
- identify contract risks before any functional change.

---

## Статус

```text
SAFETY WORKFLOW REALITY CHECK RECORDED
HELPER EXTRACTION ACCEPTED AS CURRENT CODE BASELINE
EARLIER LOCAL-SEGREGATION-ONLY DOCS MARKED AS HISTORICAL PLANNING CONTEXT
NO CODE CHANGE RECOMMENDED IN SAFETY DURING THIS PASS
```