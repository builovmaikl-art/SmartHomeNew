# 09 — HP-1 / HP-2 Verification Result

Дата: 2026-04-27
Назначение: фиксация результата компиляции и ручной проверки internal test harness для HP-1 / HP-2

---

## Режим фиксации

```text
Manual Compile / Online Observation Report
```

Источник результата:

```text
ручная компиляция и наблюдение значений в CODESYS
```

Это не является hardware validation, так как реальное железо ещё не подобрано и не подключено.

---

## Compile result

Результат:

```text
COMPILE OK
0 compile errors reported after using the correct test harness
```

Важно:

```text
PRG_Test is legacy / wrong test PRG for this flow and must not be connected for current HP-1/HP-2 verification.
```

Правильный test harness:

```text
PRG_System_Test_Harness
GVL_TEST
```

---

## Test harness connection mode

`PRG_System_Test_Harness` был подключён вручную для проверки.

Статус:

```text
manual connection used for verification
MAIN permanent integration decision is not made by this document
```

---

## Observed HP-1 / HP-2 behavior

Проверяемое значение:

```text
GVL_TEST.G_HP_Manifold_Adjusted_Priority
```

Наблюдение:

```text
initial value: 11
with guest preheat / policy effect: 14
after disable/reset: 11
```

Вывод:

```text
priority adjustment is reversible and follows enable/disable state
```

---

## Confirmed behavior

Подтверждено:

```text
HP-1 policy priority bias path works
HP-2 guest preheat boost path works
Guest preheat enable/disable works as expected
Adjusted priority returns to baseline after disabling/resetting request
Config out-of-range check works as described
Compilation passes when correct harness is used
```

---

## Interpretation of 11 -> 14 -> 11

Изменение:

```text
11 -> 14 -> 11
```

означает, что mapped manifold получил суммарный additive priority effect:

```text
+3
```

Это допустимо, потому что текущая модель агрегирует contribution от heating circuits / zones к одному manifold.

Статус:

```text
EXPECTED FOR CURRENT AGGREGATED PRIORITY MODEL
```

---

## Legacy PRG_Test status

`PRG_Test` дал compile errors при ошибочном подключении.

Вывод:

```text
PRG_Test is not part of current verification flow.
PRG_Test should be treated as legacy / outdated until separately reviewed.
```

Do not use:

```text
PRG_Test
```

Use:

```text
PRG_System_Test_Harness
```

---

## What is not confirmed

Не подтверждено этим документом:

```text
real hardware behavior
actual IO module behavior
pump/valve physical reaction
thermal comfort behavior
target adjustment behavior
long-duration guest preheat lifecycle
```

---

## Current status

```text
HP-1 / HP-2 LOGIC VERIFICATION PASSED
COMPILE OK WITH CORRECT TEST HARNESS
LEGACY PRG_TEST MUST NOT BE USED FOR THIS FLOW
READY FOR NEXT CONTROLLED STEP
```

---

## Recommended next step

Перед следующей функциональной доработкой:

```text
decide whether PRG_System_Test_Harness should remain manually connected only or be gated in MAIN by GVL_TEST.G_Test_Enable
```

Next possible workstreams:

```text
1. Scenario-based test harness extension
2. HP-3 target adjustment design
3. Cleanup / quarantine decision for legacy PRG_Test
```
