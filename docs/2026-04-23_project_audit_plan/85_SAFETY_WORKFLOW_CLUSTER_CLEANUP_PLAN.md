# Safety Workflow Cluster Cleanup Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ переводит `84_SAFETY_MINIMAL_CLEANUP_TARGET_DECISION.md` в следующий практический шаг:
**локальный cleanup-plan вокруг operator/test/recover workflow cluster в `PRG_Safety.st`**.

Цель:
- сузить remediation scope до выбранного minimal cleanup target;
- разгрузить `PRG_Safety.st` от stateful workflow semantics, не ломая core hazard/interlock projection;
- сохранить working publication boundary через `GVL_INTENT_SAFETY`.

## Основание
План опирается на:
- `82_SAFETY_PRODUCER_OWNERSHIP_CLEANUP_PLAN.md`
- `83_SAFETY_PRODUCER_OWNERSHIP_SEGMENTATION.md`
- `84_SAFETY_MINIMAL_CLEANUP_TARGET_DECISION.md`
- текущее состояние `PRG_Safety.st`

## Уже принятое базовое решение
К текущему моменту уже зафиксировано:
- safety boundary через `GVL_INTENT_SAFETY` working and meaningful;
- core hazard/interlock projection не является текущим problem-center;
- first cleanup target = Cluster 2 (operator/test/recover workflow);
- broad safety redesign и decomposition всего `PRG_Safety.st` на этом этапе не требуются.

Следовательно, правильный следующий шаг — focused cleanup around workflow semantics only.

## Цель cleanup-этапа
Привести `PRG_Safety.st` к более чистой producer boundary, при которой:
- stateful workflow logic для valve-test / selective-recover явно отделена от core hazard/interlock projection;
- intent publication model сохраняется;
- runtime semantics меняется минимально или не меняется вовсе;
- scope остается локальным и безопасным.

## Что именно входит в cleanup первой волны

### SWCP-01. Edge-detection layer for workflow inputs
Нужно отдельно рассматривать и ограничить scope вокруг:
- `I_Water_Selective_Recover`
- `I_Gas_Selective_Recover`
- `I_Water_Valve_Test_Open`
- `I_Water_Valve_Test_Close`
- `I_Water_Valve_Test_Confirm`
- `I_Gas_Valve_Test_Open`
- `I_Gas_Valve_Test_Close`
- `I_Gas_Valve_Test_Confirm`

Почему это first priority:
- именно этот слой уже является distinct workflow-normalization subset внутри `PRG_Safety.st`.

Приоритет: HIGH.

### SWCP-02. Activity/deadline workflow state
Нужно отдельно рассматривать и ограничить scope вокруг:
- `L_Water_Test_Active`
- `L_Water_Test_Deadline`
- `L_Gas_Test_Active`
- `L_Gas_Test_Deadline`

Почему это важно:
- это явная stateful mini-workflow semantics, не являющаяся ядром hazard projection.

Приоритет: HIGH.

### SWCP-03. Timeout-driven projection into required actions
Нужно отдельно зафиксировать workflow-driven переходы в required actions, где test-flow по таймауту переводится в:
- `I_Water_Main_Close_Required`
- `I_Gas_Close_Required`

Почему это важно:
- здесь workflow semantics пересекается с core safety publication surface;
- это ключевая граница, которую нужно cleanup-ить максимально аккуратно.

Приоритет: HIGH.

## Что пока НЕ входит в cleanup первой волны

### SWCP-NO-01
Не трогать общий reset/init `GVL_INTENT_SAFETY`.

### SWCP-NO-02
Не трогать core hazard/interlock projection from latched state.

### SWCP-NO-03
Не трогать gas / vent / water / boiler required-action semantics, если они не происходят именно из workflow-cluster.

### SWCP-NO-04
Не трогать safety-access coupling subset как first step.

### SWCP-NO-05
Не менять `GVL_INTENT_SAFETY` publication model.

### SWCP-NO-06
Не менять `PRG_Command_Arbitration.st` и downstream consumers.

## Предпочтительное направление cleanup

### SWCP-04. Сделать workflow semantics более явным локальным sub-scope
Предпочтительный путь на следующем шаге:
- не разносить сразу весь `PRG_Safety.st`,
- а сначала сделать operator/test/recover workflow более явным, обособленным и легко читаемым sub-scope внутри текущего program.

Это может означать на следующем decision step:
- либо локальную structural segregation внутри `PRG_Safety.st`,
- либо минимальный extraction-style move,
- но только если это действительно уменьшит ownership concentration без расширения scope.

## Почему cleanup должен начинаться именно так
- это бьет в наиболее clearly non-core subset;
- это не ломает working publication boundary;
- это не затрагивает already-confirmed healthy downstream chain;
- это снижает producer heaviness с минимальным риском задеть core hazard semantics.

## Очередность cleanup-работ

### Этап SWC-1. Workflow subset boundary clarification
Результат:
- станет ясно, достаточно ли локальной structural segregation inside `PRG_Safety.st`, или нужен более явный extraction target.

### Этап SWC-2. Minimal changeset direction decision
Результат:
- появится точный ответ, какой минимальный remediation step лучше:
  - internal structural cleanup,
  - helper-style extraction,
  - либо documentary/semantic narrowing only.

### Этап SWC-3. Только после этого переходить к code-level execution plan
Результат:
- remediation останется пропорциональной и безопасной.

## Критерии успеха cleanup-плана
Этап считается правильно запущенным, если:
1. cleanup остается внутри workflow cluster;
2. core hazard/interlock projection не затрагивается без необходимости;
3. working safety publication boundary сохраняется;
4. следующий шаг становится достаточно узким для безопасного code-level решения.

## Практический следующий документ
- `86_SAFETY_WORKFLOW_CLUSTER_MINIMAL_CHANGESET_DECISION.md`

Его задача:
- принять решение, какой minimal remediation path лучше для workflow-cluster:
  - local structural segregation,
  - helper extraction,
  - или более легкий narrowing/documentation cleanup.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения