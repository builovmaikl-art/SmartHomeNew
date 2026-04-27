# 01 — Repository State Verification

Дата: 2026-04-27
Назначение: первичная top-down / bottom-up верификация текущего состояния репозитория после rebaseline

---

## Режим проверки

```text
Direct Repository Modification Mode + Analytical Repository Verification
```

Что это означает:

- документ создан прямой правкой репозитория;
- проверка основана на чтении фактических файлов из GitHub repository state;
- runtime/build подтверждение этим документом не заявляется;
- terminal/full build verification остаётся отдельным обязательным шагом перед runtime-affecting изменениями.

---

## Цель текущей верификации

Проверить проект в двух направлениях:

```text
Top-down: MAIN -> PRG orchestration -> subsystem boundaries
Bottom-up: DUT/GVL/FB/PRG contracts -> integration points
```

Текущий документ фиксирует первый проход:

1. top-level execution order;
2. coordinator boundary;
3. presence/mode/policy observe chain;
4. heating integration status;
5. первичный список того, что не трогать и что проверить дальше.

---

## Источники текущего прохода

Проверены файлы:

```text
MAIN.st
PRG_System_Coordinator.st
FB_System_Coordinator.st
PRG_Presence_Manager.st
PRG_Mode_Manager.st
PRG_Heating_Policy_Observer.st
PRG_Heating.st
docs/2026-04-26_engineering_evolution/12_branch_migration_tasks.md
docs/2026-04-27_repository_rebaseline/00_STARTING_POINT.md
```

---

## TOP-DOWN-01 — MAIN execution order

Фактический порядок в `MAIN.st`:

```text
PRG_IO_Read();
PRG_Safety();
PRG_System();
PRG_Presence_Manager();
PRG_Heating_Policy_Observer();
PRG_Mode_Manager();
PRG_System_Coordinator();
PRG_Policy();
PRG_Command_Arbitration();
PRG_Command_Verifier();
PRG_Security();
PRG_Heating();
PRG_Ventilation();
PRG_Lighting();
PRG_IO_Write();
```

Сравнение с expected MAIN order из `12_branch_migration_tasks.md`:

```text
MATCH
```

Вывод:

- top-level orchestration соответствует зафиксированному migration baseline;
- `PRG_Safety()` вызывается до system/coordinator/arbitration/domain programs;
- `PRG_IO_Write()` остаётся последним;
- тестовый `PRG_Test()` не активен.

Статус:

```text
OK — DO NOT CHANGE WITHOUT SEPARATE ARCHITECTURE DECISION
```

---

## TOP-DOWN-02 — Safety ownership placement

По порядку `MAIN.st` safety остаётся ранним upstream слоем:

```text
PRG_IO_Read -> PRG_Safety -> PRG_System -> ... -> Arbitration -> Domain -> IO_Write
```

Это сохраняет правило:

```text
PRG_Safety remains the owner of safety-stop behavior.
Coordinator does not replace Safety.
```

Текущий проход не доказывает runtime correctness safety logic, но подтверждает, что top-level placement не нарушено.

Статус:

```text
OK — PLACEMENT PRESERVED
```

Дальше требуется отдельная фиксация:

```text
02_SAFETY_WORKFLOW_REALITY_CHECK.md
```

---

## TOP-DOWN-03 — Coordinator boundary

`PRG_System_Coordinator.st` вызывает `FB_System_Coordinator` и публикует только coordination constraints:

```text
GVL_SYSTEM_COORDINATION.G_Block_Heating
GVL_SYSTEM_COORDINATION.G_Block_Ventilation
GVL_SYSTEM_COORDINATION.G_Block_Lighting_Override
GVL_SYSTEM_COORDINATION.G_Block_Sockets_Override
GVL_SYSTEM_COORDINATION.G_System_Degraded
GVL_SYSTEM_COORDINATION.G_Coordination_Code
```

`FB_System_Coordinator.st` формирует только block/degraded/code outputs.

В текущем проходе не обнаружено прямой записи actuator state из Coordinator.

Вывод:

```text
Coordinator publishes constraints only.
Coordinator does not directly write actuator state.
```

Статус:

```text
OK — DO NOT CONVERT COORDINATOR INTO ACTUATOR OWNER
```

---

## TOP-DOWN-04 — Presence boundary

`PRG_Presence_Manager.st`:

- читает `GVL_STATE.G_Motion_Sensors`;
- вызывает `FB_Presence_Manager`;
- публикует данные в `GVL_PRESENCE`;
- ведёт per-zone occupied / last-motion состояние.

В текущем проходе не обнаружено прямого управления heating, lighting, ventilation, sockets из presence layer.

Вывод:

```text
Presence publishes occupancy data only.
```

Статус:

```text
OK — DO NOT ADD DIRECT DOMAIN CONTROL TO PRESENCE
```

---

## TOP-DOWN-05 — Mode boundary

`PRG_Mode_Manager.st`:

- читает night/away/maintenance inputs;
- учитывает `GVL_PRESENCE.G_Auto_Away_Request`;
- публикует current behavior mode в `GVL_MODE`;
- фиксирует timestamp смены mode.

Вывод:

```text
Mode layer remains behavior-mode publisher, not actuator layer.
```

Статус:

```text
OK — MODE IS ORCHESTRATION CONTEXT, NOT ACTUATION
```

---

## TOP-DOWN-06 — Heating policy observe boundary

`PRG_Heating_Policy_Observer.st`:

- читает presence data;
- читает permanent-use / guest-preheat requests;
- читает behavior mode;
- вызывает `FB_Heating_Policy_Observer`;
- публикует:

```text
GVL_HEATING_POLICY.G_Zone_Empty_Duration_MS
GVL_HEATING_POLICY.G_Zone_Policy_Class
GVL_HEATING_POLICY.G_Zone_Target_Adjustment
GVL_HEATING_POLICY.G_Zone_Priority_Bias
```

В текущем проходе не обнаружено прямой записи pumps/valves/heating outputs из policy observe layer.

Вывод:

```text
Heating Policy Observe calculates policy data only.
It does not directly write pumps, valves or heating outputs.
```

Статус:

```text
OK — DO NOT TURN POLICY OBSERVE INTO CONTROL LAYER
```

---

## TOP-DOWN-07 — Heating integration status

`PRG_Heating.st` проверен на наличие фактического controlled integration heating policy в decision layer.

Наблюдение:

- `PRG_Heating.st` содержит decision context и coordinator gating;
- `GVL_SYSTEM_COORDINATION.G_Block_Heating` применяется после base heating orchestration;
- `GVL_HEATING_POLICY.G_Zone_Target_Adjustment[]` в текущем `PRG_Heating.st` не применяется;
- `GVL_HEATING_POLICY.G_Zone_Priority_Bias[]` в текущем `PRG_Heating.st` не применяется;
- guest preheat policy ещё не влияет на heating decision через policy outputs.

Это соответствует статусу из migration task list:

```text
controlled integration heating policy into PRG_Heating.st — not completed
```

Вывод:

```text
No partial heating-policy integration detected in PRG_Heating.st during this pass.
```

Статус:

```text
OK FOR BASELINE — NEXT FUNCTIONAL TARGET, BUT DO NOT START BEFORE VERIFICATION PASS IS COMPLETE
```

---

## Первичный список: что работает и не трогать без отдельного решения

Не трогать сейчас:

```text
MAIN.st order
PRG_Safety placement in MAIN
Coordinator constraint-only role
Presence data-only role
Heating Policy observe-only role
PRG_Heating absence of policy-output integration
PRG_IO_Read during this evolution wave
```

Причина:

- эти части соответствуют текущему migration baseline;
- преждевременная правка может смешать verification и functional integration;
- следующая задача должна быть сначала verification completion, а не code redesign.

---

## Первичный список: что требует дальнейшей проверки

Следующие зоны требуют отдельных документов / проходов:

```text
02_SAFETY_WORKFLOW_REALITY_CHECK.md
03_BOTTOM_UP_CONTRACT_VERIFICATION.md
04_COORDINATOR_DOMAIN_APPLICATION_CHECK.md
05_HEATING_POLICY_INTEGRATION_PLAN.md
```

Особенно важно:

1. Зафиксировать реальное состояние `FB_Safety_Workflow_Manager.st` vs более ранние safety docs.
2. Проверить FB call signatures по coordinator/mode/presence/policy/heating slices.
3. Проверить, что `PRG_Ventilation.st` и `PRG_Lighting.st` корректно применяют coordinator constraints.
4. Перед heating policy integration создать отдельный changeset plan.

---

## Ограничения текущей проверки

Этот документ не подтверждает:

- runtime behavior;
- full compile success текущего checkout;
- отсутствие всех возможных ST compiler errors;
- корректность PLC deployment;
- корректность всех GVL/DUT type declarations.

Текущий документ подтверждает только repository-state observations по перечисленным файлам.

---

## Post-change verification rule для дальнейших шагов

После каждой дальнейшей правки обязательно:

```text
1. Перечитать изменённый файл из репозитория.
2. Убедиться, что файл не обрезан.
3. Проверить корректность path.
4. Проверить, что изменение соответствует intended scope.
5. Для code files дополнительно проверить END_VAR / END_IF / END_FOR / END_CASE и FB call signatures по изменённому срезу.
```

---

## Статус

```text
INITIAL TOP-DOWN VERIFICATION RECORDED
MAIN ORDER MATCHES MIGRATION BASELINE
COORDINATOR / PRESENCE / MODE / POLICY OBSERVE BOUNDARIES PRESERVED
NO PARTIAL HEATING POLICY INTEGRATION DETECTED IN PRG_HEATING DURING THIS PASS
CONTINUE WITH SAFETY WORKFLOW REALITY CHECK
```