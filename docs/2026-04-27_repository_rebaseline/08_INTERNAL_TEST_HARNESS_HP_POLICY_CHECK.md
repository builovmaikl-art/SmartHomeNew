# 08 — Internal Test Harness HP Policy Check

Дата: 2026-04-27
Назначение: расширение существующего внутреннего test harness для проверки HP-1/HP-2 без железа

---

## Режим

```text
Direct Repository Modification Mode
```

---

## Обнаруженная база

В проекте уже есть test harness:

```text
PRG_System_Test_Harness.st
GVL_TEST.gvl
```

Он уже использует:

```text
GVL_TEST.G_Test_Enable
GVL_TEST.G_Test_Passed
GVL_TEST.G_Test_Failed_Checks
GVL_TEST.G_Test_Last_Failure_Code
```

Поэтому новый параллельный harness не создаётся.

---

## Цель изменения

Добавить проверку HP-1/HP-2 policy priority path:

```text
base manifold priority
+ G_Zone_Priority_Bias[]
+ guest preheat boost from GVL_HEATING_POLICY_CONFIG
-> adjusted manifold priority
-> FB_Heating_Decision_Context
```

---

## Ограничения

Test harness не должен:

```text
писать в GVL_STATE
писать в GVL_IO
писать в GVL_ACTUATORS
вызывать PRG_Heating
менять MAIN order
имитировать железо
```

Он должен только:

```text
читать текущие config/policy values
рассчитать локальные expected values
проверить invariants
публиковать результат в GVL_TEST
```

---

## Runtime files in scope

```text
GVL_TEST.gvl
PRG_System_Test_Harness.st
```

---

## Added checks

Добавить TEST 5:

```text
Heating policy adjusted priority consistency
```

Проверки:

```text
1. adjusted priority не ниже 1
2. guest preheat config в допустимом диапазоне
3. adjusted-priority allocation не включает запрещённый manifold
4. adjusted-priority allocation не превышает thermal budget
5. calculated adjusted priorities выводятся в GVL_TEST для удобного просмотра
```

---

## Failure codes

```text
1006 — HP adjusted priority lower-bound violation
1007 — HP guest preheat config out of range
1008 — HP adjusted allocation enabled not allowed
1009 — HP adjusted allocation budget exceeded
```

---

## Verification after edit

Обязательно проверить:

```text
1. GVL_TEST.gvl полный и без placeholder.
2. PRG_System_Test_Harness.st полный и без placeholder.
3. Нет записи в GVL_STATE / GVL_IO / GVL_ACTUATORS из нового TEST 5.
4. MAIN.st не изменён.
5. PRG_Heating.st не изменён этим шагом.
6. END_VAR / END_IF / END_FOR баланс сохранён.
```

---

## Статус

```text
INTERNAL TEST HARNESS HP POLICY CHECK PLAN RECORDED
IMPLEMENTATION ALLOWED ONLY IN GVL_TEST.gvl AND PRG_SYSTEM_TEST_HARNESS.st
```