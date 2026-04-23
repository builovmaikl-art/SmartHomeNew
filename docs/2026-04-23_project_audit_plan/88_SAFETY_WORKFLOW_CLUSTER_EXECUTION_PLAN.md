# Safety Workflow Cluster Execution Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ переводит `87_SAFETY_WORKFLOW_CLUSTER_LOCAL_STRUCTURE_PLAN.md` в **исполнительный порядок** для локального structural cleanup workflow-cluster внутри `PRG_Safety.st`.

Это не safety-wide redesign.

Это строго:
- локальная перестройка структуры `PRG_Safety.st`;
- явное выделение workflow-cluster как внутреннего sub-scope;
- сохранение текущей publication boundary через `GVL_INTENT_SAFETY`;
- repository-state verification после изменения.

## Основание
План опирается на:
- `84_SAFETY_MINIMAL_CLEANUP_TARGET_DECISION.md`
- `85_SAFETY_WORKFLOW_CLUSTER_CLEANUP_PLAN.md`
- `86_SAFETY_WORKFLOW_CLUSTER_MINIMAL_CHANGESET_DECISION.md`
- `87_SAFETY_WORKFLOW_CLUSTER_LOCAL_STRUCTURE_PLAN.md`
- текущее состояние `PRG_Safety.st`

## Цель исполнения
Получить такую внутреннюю структуру `PRG_Safety.st`, при которой:
- edge detection, workflow-state и timeout-driven projection для operator/test/recover semantics собраны в явный внутренний workflow sub-scope;
- core hazard/interlock projection остается отдельно читаемым и доминирующим слоем программы;
- `GVL_INTENT_SAFETY` publication model не меняется;
- runtime behavior меняется минимально или не меняется вовсе.

## Execution Mode
- Режим исполнения: Direct Repository Modification Mode.
- Тип проверки: repository state verification.
- Ограничение: без compile/run подтверждения.

## Зафиксированные инварианты перед изменением
Во время этого этапа нельзя менять:
- `GVL_INTENT_SAFETY` contract;
- downstream usage в `PRG_Command_Arbitration.st`;
- core hazard/interlock projection semantics;
- safety-access coupling subset beyond unavoidable local reordering;
- runtime behavior ради stylistic cleanup;
- создание нового FB/POU.

Допустим только минимальный local structural cleanup inside `PRG_Safety.st`.

## Исполнительный порядок

### Шаг SWE-01. Подтвердить текущую структуру `PRG_Safety.st`
Действие:
- перечитать текущий live `PRG_Safety.st`;
- подтвердить расположение:
  - workflow edge-detection logic,
  - `GVL_INTENT_SAFETY` reset/init,
  - detection managers,
  - core hazard/interlock projection,
  - workflow-state and timeout logic,
  - freeze/residual projection.

Ожидаемый результат:
- changeset будет вноситься по подтвержденному live-root состоянию, а не по памяти.

### Шаг SWE-02. Выделить workflow input normalization block
Действие:
- собрать в один явный contiguous block:
  - edge detection по `I_Water_Selective_Recover`
  - edge detection по `I_Gas_Selective_Recover`
  - edge detection по `I_Water_Valve_Test_Open`
  - edge detection по `I_Water_Valve_Test_Close`
  - edge detection по `I_Water_Valve_Test_Confirm`
  - edge detection по `I_Gas_Valve_Test_Open`
  - edge detection по `I_Gas_Valve_Test_Close`
  - edge detection по `I_Gas_Valve_Test_Confirm`
  - update всех `*_Prev` состояний
- оформить это как clearly marked section.

Ожидаемый результат:
- workflow input normalization становится отдельным внутренним слоем, а не общим прологом без четкой роли.

### Шаг SWE-03. Сохранить отдельным core safety intent reset/init block
Действие:
- оставить reset/init `GVL_INTENT_SAFETY` отдельным явным block;
- не смешивать его с workflow-specific logic.

Ожидаемый результат:
- boundary publication surface остается clearly readable and centralized.

### Шаг SWE-04. Оставить detection + core hazard projection как самостоятельный центральный block
Действие:
- `fbWaterLeakageManager(...)`, `fbGasSmokeManager(...)` и projection из latched state / health bridge оставить grouped together;
- не смешивать их с workflow-state and timeout handling.

Ожидаемый результат:
- core hazard/interlock producer semantics остается визуально и семантически главным слоем `PRG_Safety.st`.

### Шаг SWE-05. Выделить workflow state/timer + timeout projection block
Действие:
- собрать в один явный contiguous block:
  - `L_Water_Test_Active`
  - `L_Water_Test_Deadline`
  - `L_Gas_Test_Active`
  - `L_Gas_Test_Deadline`
  - activation logic по workflow edges
  - timeout progression
  - timeout-driven projection в:
    - `I_Water_Main_Close_Required`
    - `I_Gas_Close_Required`
- оформить этот блок как distinct workflow section.

Ожидаемый результат:
- stateful workflow semantics оказывается собранной в отдельном sub-scope внутри программы.

### Шаг SWE-06. Оставить residual non-workflow safety projection отдельным хвостом
Действие:
- freeze-related projection и прочие non-workflow residual safety effects оставить после workflow block как отдельный остаточный section.

Ожидаемый результат:
- финальная структура файла становится layered and readable.

### Шаг SWE-07. Не менять внешние bindings и publication behavior
Действие:
- не менять набор публикуемых полей `GVL_INTENT_SAFETY`;
- не менять downstream contracts;
- не вводить новый helper/POU.

Ожидаемый результат:
- cleanup остается purely structural and low-risk.

### Шаг SWE-08. Выполнить repository-state verification после правки
Действие:
- перечитать `PRG_Safety.st` после изменения.

Нужно подтвердить:
1. workflow-cluster выделен как отдельный внутренний block/sub-scope;
2. core hazard/interlock projection остается clearly separate;
3. `GVL_INTENT_SAFETY` contract не изменен;
4. downstream files не изменялись;
5. changeset не вырос в helper-extraction или broader redesign.

Ожидаемый результат:
- confirmed local structural cleanup of workflow-cluster.

### Шаг SWE-09. Только при необходимости сделать короткий documentary pass
Действие:
- если после перестройки локальные comments/section titles нужно выровнять, допустим короткий documentary cleanup.

Но:
- это optional secondary action;
- не основная часть fix.

## Что считается допустимым изменением
Допустимо:
- переставить локальные участки кода внутри `PRG_Safety.st`;
- добавить section-comments / anchors / headings;
- сгруппировать workflow logic в contiguous internal block;
- слегка выровнять локальные комментарии/форматирование.

## Что запрещено на этом шаге
Запрещено:
- создавать новый helper/POU;
- менять `GVL_INTENT_SAFETY` external contract;
- менять downstream consumers;
- менять core safety semantics ради структуры;
- выполнять broad safety refactor;
- переходить к safety-access coupling cleanup в том же changeset.

## Критерии успешного завершения execution plan
Этап считается успешно выполненным, если:
1. workflow-cluster внутри `PRG_Safety.st` структурно выделен;
2. core hazard/interlock projection остается отдельным и читаемым;
3. working publication boundary сохраняется;
4. changeset остается локальным и пропорциональным.

## Следующий документ после исполнения
После выполнения этого плана должен появиться:
- `89_SAFETY_WORKFLOW_CLUSTER_CLEANUP_RESULT.md`

В нем нужно будет зафиксировать:
- как именно перестроен `PRG_Safety.st`;
- что workflow-cluster стал отдельным внутренним sub-scope;
- что осталось следующим шагом в safety wave.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения