# Safety Workflow Cluster Local Structure Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ переводит `86_SAFETY_WORKFLOW_CLUSTER_MINIMAL_CHANGESET_DECISION.md` в следующий практический шаг:
**конкретный local-structure plan для workflow-cluster внутри `PRG_Safety.st`**.

Цель:
- минимально изолировать operator/test/recover workflow semantics внутри текущего `PRG_Safety.st`;
- снизить ownership clutter без создания нового POU;
- сохранить working publication boundary через `GVL_INTENT_SAFETY` и не затронуть core hazard/interlock projection.

## Основание
План опирается на:
- `84_SAFETY_MINIMAL_CLEANUP_TARGET_DECISION.md`
- `85_SAFETY_WORKFLOW_CLUSTER_CLEANUP_PLAN.md`
- `86_SAFETY_WORKFLOW_CLUSTER_MINIMAL_CHANGESET_DECISION.md`
- текущее состояние `PRG_Safety.st`

## Уже принятое базовое решение
К текущему моменту уже зафиксировано:
- first cleanup target = workflow-cluster inside `PRG_Safety.st`;
- first remediation path = local structural segregation inside the same program;
- core hazard/interlock projection не должен меняться;
- `GVL_INTENT_SAFETY` publication model не должен меняться;
- новый helper/POU на этом шаге не требуется.

Следовательно, следующий шаг — не extraction, а **минимальная локальная перестройка текущего файла**.

## Цель local-structure changeset
Получить такую внутреннюю структуру `PRG_Safety.st`, при которой:
- workflow-cluster читается как отдельный внутренний sub-scope;
- edge detection, workflow state и timeout-driven projection перестают быть размазаны по общему safety flow;
- core safety projection остается отдельным и визуально доминирующим слоем;
- runtime semantics меняется минимально или не меняется вовсе.

## Что именно должно быть структурно выделено

### SWLSP-01. Workflow input normalization block
Нужно сделать явным отдельный локальный блок для:
- edge detection по `I_Water_Selective_Recover`
- edge detection по `I_Gas_Selective_Recover`
- edge detection по `I_Water_Valve_Test_Open`
- edge detection по `I_Water_Valve_Test_Close`
- edge detection по `I_Water_Valve_Test_Confirm`
- edge detection по `I_Gas_Valve_Test_Open`
- edge detection по `I_Gas_Valve_Test_Close`
- edge detection по `I_Gas_Valve_Test_Confirm`

Это должен быть один clearly marked sub-scope, а не scattered prelude к остальному safety body.

### SWLSP-02. Workflow state/timer block
Нужно сделать явным отдельный локальный блок для:
- `L_Water_Test_Active`
- `L_Water_Test_Deadline`
- `L_Gas_Test_Active`
- `L_Gas_Test_Deadline`
- их activation / timeout progression.

Это должен быть один clearly marked workflow-state section.

### SWLSP-03. Workflow-to-intent projection block
Нужно сделать явным отдельный локальный блок, где workflow semantics проектируется в `GVL_INTENT_SAFETY`, а именно:
- timeout-driven переходы в
  - `I_Water_Main_Close_Required`
  - `I_Gas_Close_Required`
- при наличии иной workflow-driven projection — сгруппировать ее в тот же section.

Это важная boundary-точка, потому что здесь workflow layer соприкасается с общей safety publication surface.

## Предпочтительная внутренняя структура файла после cleanup

### Block A. Input / edge normalization for workflow cluster
Содержит только:
- edge detection по workflow-related user inputs;
- update `*_Prev` state.

### Block B. Core safety intent reset/init
Содержит только:
- общий reset/init `GVL_INTENT_SAFETY`.

### Block C. Detection managers and hazard semantic projection
Содержит только:
- `fbWaterLeakageManager(...)`
- `fbGasSmokeManager(...)`
- projection из latched state / health bridge в core safety intents.

### Block D. Workflow cluster
Содержит только:
- activation of test flows,
- deadlines/timeouts,
- workflow-driven publication effects.

### Block E. Freeze / residual safety projections
Содержит только:
- remaining non-workflow safety projections like freeze-related intent projection.

## Почему такая структура предпочтительна
- она не требует нового external contract;
- она clearly отделяет workflow semantics от core safety semantics;
- она уменьшает producer clutter уже на уровне читаемости и ownership segmentation;
- она делает возможным later extraction, если он когда-либо понадобится.

## Что допустимо в рамках этого changeset

### SWLSP-04
Допустимо:
- переставить локальные участки кода внутри `PRG_Safety.st` для более явной структуры;
- добавить явные section-comments / anchors / headings;
- сгруппировать workflow logic в contiguous block;
- слегка выровнять локальные имена/комментарии, если это помогает читаемости.

## Что НЕ должно входить в этот changeset

### SWLSP-NO-01
Не создавать новый FB/POU.

### SWLSP-NO-02
Не менять `GVL_INTENT_SAFETY` contract.

### SWLSP-NO-03
Не менять downstream usage в `PRG_Command_Arbitration.st`.

### SWLSP-NO-04
Не менять core hazard/interlock projection semantics.

### SWLSP-NO-05
Не трогать safety-access coupling subset beyond unavoidable local reordering.

### SWLSP-NO-06
Не менять runtime behavior ради stylistic perfection.

## Минимальный ожидаемый эффект
После такой перестройки `PRG_Safety.st` должен:
- лучше читаться как layered producer program;
- иметь явный workflow-cluster, а не смешанную workflow/hazard semantics массу;
- стать cleaner without requiring new interfaces.

Это именно тот тип минимального structural payoff, который нужен на первой remediation-волне.

## Критерии успешного завершения planning-этапа
Этап считается правильно зафиксированным, если:
1. workflow-cluster описан как конкретный внутренний structural sub-scope;
2. граница с core safety semantics явно определена;
3. allowed vs forbidden changes четко разграничены;
4. следующий шаг становится достаточно точным для execution-plan.

## Практический следующий документ
- `88_SAFETY_WORKFLOW_CLUSTER_EXECUTION_PLAN.md`

Его задача:
- перевести этот local-structure plan в конкретный исполнительный порядок изменения `PRG_Safety.st`.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения