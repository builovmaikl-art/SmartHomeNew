# Safety Workflow Cluster Minimal Changeset Decision

Дата фиксации: 2026-04-23

## Назначение
Этот документ переводит `85_SAFETY_WORKFLOW_CLUSTER_CLEANUP_PLAN.md` в следующее узкое решение:
**какой minimal remediation path лучше для workflow-cluster внутри `PRG_Safety.st`**.

Цель:
- выбрать наиболее безопасный и пропорциональный путь первой remediation-волны;
- не раздувать cleanup до premature extraction/refactor;
- сохранить working safety publication boundary и core hazard/interlock projection.

## Основание
Решение опирается на:
- `83_SAFETY_PRODUCER_OWNERSHIP_SEGMENTATION.md`
- `84_SAFETY_MINIMAL_CLEANUP_TARGET_DECISION.md`
- `85_SAFETY_WORKFLOW_CLUSTER_CLEANUP_PLAN.md`
- текущее состояние `PRG_Safety.st`

## Что уже подтверждено
К текущему моменту уже зафиксировано:
- first cleanup target = operator/test/recover workflow cluster;
- этот cluster включает edge detection, activity/deadline state и timeout-driven projection;
- core hazard/interlock projection не является текущим problem-center;
- `GVL_INTENT_SAFETY` publication model working and meaningful;
- broad decomposition `PRG_Safety.st` на этом этапе не требуется.

Следовательно, сейчас нужно выбрать не "что чинить", а **как именно чинить этот cluster минимальным changeset**.

## Варианты remediation path

### Option A. Local structural segregation inside `PRG_Safety.st`
Суть:
- оставить workflow-cluster внутри текущего `PRG_Safety.st`;
- но сделать его более явно отделенным блоком/секцией/подscope внутри программы;
- выровнять локальную структуру так, чтобы workflow-state and timeout logic не были смешаны с core safety semantics визуально и семантически.

Плюсы:
- минимальный риск;
- не ломает current publication model;
- не требует нового POU или нового interface contract;
- уменьшает ownership clutter уже на первом шаге.

Минусы:
- producer concentration уменьшается частично, а не радикально.

### Option B. Helper-style extraction in a new local helper/FB
Суть:
- вынести workflow-cluster в отдельный helper-style block/POU;
- оставить `PRG_Safety.st` как consumer его outputs.

Плюсы:
- сильнее разгружает `PRG_Safety.st`.

Минусы:
- уже требует нового contract/interface;
- больше риск зацепить runtime semantics;
- для первой remediation-волны это может быть непропорционально широко.

### Option C. Narrowing/documentation-only cleanup
Суть:
- не менять структуру кода;
- ограничиться только documentation/semantic marking workflow-subscope.

Плюсы:
- почти нулевой риск.

Минусы:
- почти не снижает реальную ownership concentration;
- слабый hygiene payoff по сравнению с подтвержденным smell.

## Решение
На текущем этапе принимается:

# Decision: Option A — local structural segregation inside `PRG_Safety.st`

## Почему выбран именно этот вариант

### SWMCD-01. Это самый пропорциональный первый шаг
Workflow-cluster уже подтвержден как distinct non-core subset.

Но пока нет достаточных оснований сразу вводить новый helper/POU и новый interface.

Вывод:
- сначала лучше добиться более чистой локальной структуры внутри существующего program-layer.

### SWMCD-02. Это снижает ownership clutter без ломки boundary model
Local structural segregation позволяет:
- сделать workflow semantics более явной и отделенной;
- не трогать core hazard/interlock projection;
- не трогать `GVL_INTENT_SAFETY` boundary;
- не трогать downstream consumers.

Вывод:
- высокий hygiene payoff при низком риске.

### SWMCD-03. Helper extraction пока преждевременен
Хотя helper-style extraction выглядит архитектурно возможным second step, для него пока не хватает подтверждения, что local segregation будет недостаточно.

Вывод:
- extraction стоит оставлять как possible next step only if local cleanup proves insufficient.

### SWMCD-04. Documentation-only cleanup уже слабоват
Мы уже дошли до стадии, где smell достаточно локализован и понятен.

Следовательно, purely documentary move уже слабее, чем оправданный minimum structural cleanup.

## Что именно фиксируется этим решением

### RD-SWMCD-01. First remediation path = local structural segregation
Следующий practical step должен быть направлен на:
- явное локальное выделение workflow-cluster внутри `PRG_Safety.st`;
- улучшение читаемости и ownership separation без нового external contract.

### RD-SWMCD-02. No new helper contract yet
На этом этапе не требуется:
- новый FB/POU,
- новые `VI_*` / `VO_*` contracts,
- новая downstream integration path.

### RD-SWMCD-03. Core producer logic stays in place
Не нужно трогать:
- core hazard/interlock projection,
- safety intent publication model,
- downstream command arbitration integration.

### RD-SWMCD-04. Helper extraction stays as reserve option
Если после local structural segregation cluster все еще будет выглядеть слишком тяжелым, helper-style extraction можно рассматривать как next-step option, но не как first remediation move.

## Что это решение НЕ означает
Это решение не означает:
- что workflow-cluster должен оставаться inside `PRG_Safety.st` forever;
- что helper extraction никогда не понадобится;
- что code change уже обязательно будет большим.

Это означает только:
- первый минимальный remediation step должен быть **локальным структурным**, а не interface-expanding.

## Практический смысл решения
После этого документа следующий шаг можно формулировать очень конкретно:
- не обсуждать заново strategy,
- а уже описывать minimal structural changeset inside `PRG_Safety.st`.

Это делает последующую execution planning фазу:
- узкой,
- управляемой,
- совместимой с safe incremental cleanup.

## Следующий рекомендуемый документ
- `87_SAFETY_WORKFLOW_CLUSTER_LOCAL_STRUCTURE_PLAN.md`

Его задача:
- описать конкретную минимальную локальную перестройку `PRG_Safety.st`, которая изолирует workflow-cluster как явный внутренний sub-scope без создания нового POU.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения