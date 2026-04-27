# 14 — HP Direction Freeze

Дата: 2026-04-27
Назначение: зафиксировать точку остановки Heating Policy направления до ручного прогона сценарных тестов

---

## Причина freeze

HP-направление уже дошло до состояния, где дальнейшие функциональные изменения без ручной проверки сценариев повышают риск накопления скрытых ошибок.

Текущий статус:

```text
HP-1 priority bias implemented
HP-2 config-driven guest preheat implemented
Internal self-check extended
Scenario test panel introduced
Scenario 1–6 defined
Manual scenario verification not yet completed
```

Следствие:

```text
HP-3 target adjustment must not start until Scenario 1–6 are manually verified.
```

---

## Что уже реализовано

### HP-1 — Priority bias

```text
GVL_HEATING_POLICY.G_Zone_Priority_Bias[]
-> adjusted manifold priority
-> FB_Heating_Decision_Context
```

Статус:

```text
IMPLEMENTED
COMPILE OK
BASIC MANUAL OBSERVATION PASSED
```

---

### HP-2 — Config-driven guest preheat

```text
GVL_HEATING_POLICY.G_Zone_Guest_Preheat_Request[]
+
GVL_HEATING_POLICY_CONFIG.G_Guest_Preheat_Priority_Boost
-> adjusted manifold priority
```

Статус:

```text
IMPLEMENTED
CONFIG-DRIVEN
COMPILE OK
BASIC MANUAL OBSERVATION PASSED
```

---

## Что подготовлено для проверки

Scenario panel:

```text
GVL_TEST_PANEL.gvl
PRG_Scenario_Test_Harness.st
```

Сценарии:

```text
1. Single circuit priority
2. Multi-zone aggregation
3. Preheat influence
4. Budget vs priority
5. Coordinator override
6. Safety dominance
```

Статус:

```text
DEFINED / IMPLEMENTED AS TEST MODEL
AWAITING MANUAL VERIFICATION
```

---

## Что запрещено до ручной проверки

До успешного ручного прогона Scenario 1–6 запрещено:

```text
начинать HP-3 target adjustment
менять target temperature logic
менять hysteresis / PID behavior
менять FB_Heating_Decision_Context signature
изменять order Safety > Coordinator > Budget > Priority
добавлять новые runtime-affecting heating changes
```

Причина:

```text
HP-3 влияет на comfort/setpoints и может усложнить диагностику, если базовая priority/budget/safety модель ещё не подтверждена вручную.
```

---

## Иерархия, которую нужно подтвердить тестами

```text
Safety
  > Coordinator
    > Budget / eligibility
      > Priority / policy bias / guest preheat
```

Scenario 4–6 являются ключевыми для подтверждения этой иерархии.

---

## Что можно делать безопасно вместо HP-3

Разрешённые направления до ручного прогона:

```text
1. Documentation cleanup
2. Legacy PRG_Test quarantine / documentation
3. Scenario test panel improvements that do not affect runtime logic
4. Backlog issue analysis without runtime changes
5. IO degraded aggregation design document only
```

Запрещено смешивать эти задачи с HP-3.

---

## Следующий обязательный HP-шаг

```text
Manual execution of Scenario 1–6
```

После прогона нужно создать:

```text
15_SCENARIO_1_6_MANUAL_VERIFICATION_RESULT.md
```

Документ должен содержать:

```text
compile result
which PRG was connected
Scenario 1 result
Scenario 2 result
Scenario 3 result
Scenario 4 result
Scenario 5 result
Scenario 6 result
observed values
fail codes if any
final go/no-go for HP-3
```

---

## Статус

```text
HP DIRECTION FROZEN
HP-3 BLOCKED UNTIL SCENARIO 1–6 MANUAL VERIFICATION
SAFE TO SWITCH TO NON-HP RISK REDUCTION WORK
```