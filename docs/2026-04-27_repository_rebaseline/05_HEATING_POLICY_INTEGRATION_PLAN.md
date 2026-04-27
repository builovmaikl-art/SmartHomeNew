# 05 — Heating Policy Integration Plan

Дата: 2026-04-27
Назначение: финальная фиксация предстоящего controlled integration heating policy into decision layer с учётом незавершённых задач из migration document

---

## Режим фиксации

```text
Direct Repository Modification Mode + Analytical Repository Verification
```

Что это означает:

- документ создан прямой правкой репозитория;
- план основан на фактическом состоянии репозитория и документе `12_branch_migration_tasks.md`;
- runtime/build подтверждение этим документом не заявляется;
- любые code/runtime изменения должны выполняться отдельным controlled changeset с post-change verification.

---

## Основание

План опирается на:

```text
docs/2026-04-26_engineering_evolution/12_branch_migration_tasks.md
docs/2026-04-27_repository_rebaseline/00_STARTING_POINT.md
docs/2026-04-27_repository_rebaseline/01_REPOSITORY_STATE_VERIFICATION.md
docs/2026-04-27_repository_rebaseline/02_SAFETY_WORKFLOW_REALITY_CHECK.md
docs/2026-04-27_repository_rebaseline/03_BOTTOM_UP_CONTRACT_VERIFICATION.md
docs/2026-04-27_repository_rebaseline/04_COORDINATOR_DOMAIN_APPLICATION_CHECK.md
```

---

## Текущая проверенная база

К моменту этого документа подтверждено:

```text
MAIN order matches migration baseline
Safety ownership preserved
Safety workflow helper extraction accepted as current baseline
Coordinator / Presence / Mode / Policy Observe boundaries preserved
No contract breaks detected during analytical verification
Coordinator domain application has no critical violations detected
```

---

## Незавершённые задачи из migration document

Из `12_branch_migration_tasks.md` остаются незавершёнными:

```text
controlled integration heating policy в PRG_Heating.st
применение G_Zone_Target_Adjustment[]
применение G_Zone_Priority_Bias[]
guest preheat как реальное влияние на heating decision
пакетная runtime-проверка
```

Эти пункты становятся scope будущей controlled integration wave.

---

## Главный принцип следующего этапа

```text
Do not jump from observe-only policy directly to actuator control.
```

Heating Policy Observe остаётся расчётным слоем:

```text
policy class / target adjustment / priority bias only
```

`PRG_Heating.st` остаётся местом controlled application этих данных.

---

## Что запрещено на первом integration changeset

Запрещено:

```text
изменять PRG_IO_Read
писать pumps/valves напрямую из policy layer
менять MAIN order
менять PRG_Safety core logic
менять Coordinator role в сторону actuator owner
менять FB_Heating_Decision_Context signature без отдельного решения
одновременно чинить unrelated backlog issues
```

Причина:

```text
проект находится на этапе доведения до внедрения, поэтому каждое изменение должно быть узким, проверяемым и обратимым
```

---

## Safe integration direction

Первый безопасный path:

```text
1. В PRG_Heating создать локальные adjusted priority данные.
2. Использовать GVL_HEATING_POLICY.G_Zone_Priority_Bias[] только как bias.
3. Не применять G_Zone_Target_Adjustment[] в первом changeset.
4. Не менять FB_Heating_Decision_Context signature на первом changeset.
5. Маппить zone policy к manifold через GVL_CONFIG.G_HMI_FloorHeating_Configs[].manifold_id.
6. Сохранять Coordinator override после base heating orchestration.
7. Сохранять Safety / Coordinator priority выше behavior/policy.
```

---

## Stage HP-1 — Priority bias only

Цель:

```text
дать Heating Policy реальное, но ограниченное влияние на heating decision через priority bias
```

Разрешено:

```text
локальные массивы в PRG_Heating
локальный расчёт adjusted manifold priority
использование G_Zone_Priority_Bias[] как добавочного веса
```

Запрещено:

```text
изменять насосы/клапаны напрямую из policy
использовать target adjustment
делать guest preheat через bypass safety/coordinator
```

Ожидаемый результат:

```text
policy начинает влиять на thermal allocation priority, но не становится actuator owner
```

---

## Stage HP-2 — Guest preheat influence

Цель:

```text
guest preheat becomes real influence on heating decision
```

Условие входа:

```text
HP-1 verified successfully
```

Правило приоритета:

```text
guest preheat remains higher priority than AWAY
```

Запрещено:

```text
guest preheat must not override safety stop, gas stop, coordinator block, IO degraded block
```

---

## Stage HP-3 — Target adjustment design

`G_Zone_Target_Adjustment[]` НЕ применять в первом changeset.

Причина:

```text
target adjustment меняет температурную цель и может повлиять на comfort/safety баланс шире, чем priority bias
```

Перед применением нужен отдельный документ:

```text
06_HEATING_TARGET_ADJUSTMENT_DESIGN.md
```

Он должен определить:

```text
как adjustment применяется к zone target
границы min/max target
поведение в AWAY/NIGHT/HOME
поведение при freeze/safety/degraded
fallback если policy data invalid
```

---

## Stage HP-4 — Runtime validation package

После code changes требуется пакетная runtime/smoke проверка из migration document:

```text
1. Normal mode
2. Night mode
3. Away mode
4. Maintenance mode
5. Presence auto-away
6. Presence return from away
7. Coordinator heating block
8. Coordinator ventilation block
9. Lighting override block
10. Socket override block
11. Gas/safety priority over behavior mode
12. IO degraded priority over behavior mode
```

Дополнительно для heating policy integration:

```text
13. Priority bias changes allocation priority only
14. Guest preheat does not bypass safety/coordinator
15. AWAY ignores permanent-use exception
16. HOME/NIGHT permanent-use empty zone maps to mild eco class
17. Policy disabled/zero-bias path equals previous behavior
```

---

## Backlog issues to keep separate

Из `03_BOTTOM_UP_CONTRACT_VERIFICATION.md` остаются отдельные issues:

```text
ISSUE-01 IO degraded aggregation — HIGH
ISSUE-02 Presence timeout hardcoded — MEDIUM
ISSUE-03 Heating manager signature complexity — MEDIUM
ISSUE-04 Unused safety workflow outputs — LOW
```

Важно:

```text
не смешивать их с HP-1 changeset, кроме случаев, где issue directly blocks verification
```

---

## Required post-change verification for future code edits

После каждого будущего code changeset обязательно:

```text
1. Перечитать изменённые файлы из репозитория.
2. Проверить отсутствие обрыва файла и placeholder text.
3. Проверить END_VAR / END_IF / END_FOR / END_CASE по изменённому срезу.
4. Проверить FB call signatures.
5. Проверить, что PRG_IO_Read не изменялся.
6. Проверить, что MAIN order не изменялся.
7. Проверить, что Safety / Coordinator priority не нарушен.
8. Выполнить доступную terminal/build/smoke проверку.
```

---

## What works and should remain stable

Не трогать без отдельного решения:

```text
MAIN execution order
PRG_Safety core and workflow baseline
Coordinator constraints-only model
Presence data-only model
Heating Policy observe-only model
Coordinator override after domain decision
PRG_IO_Read
```

---

## Recommended next implementation document

Перед кодом создать:

```text
06_HP1_PRIORITY_BIAS_CHANGESET_PLAN.md
```

Назначение:

```text
описать точный минимальный changeset для Stage HP-1
перечислить файлы
описать local arrays / mapping
описать verification checklist
```

---

## Статус

```text
FINAL REBASELINE PLANNING STAGE RECORDED
UNFINISHED MIGRATION TASKS CARRIED FORWARD
NEXT CODE WORK MUST START WITH HP-1 PRIORITY BIAS CHANGESET PLAN
NO RUNTIME-AFFECTING CHANGE MADE BY THIS DOCUMENT
```