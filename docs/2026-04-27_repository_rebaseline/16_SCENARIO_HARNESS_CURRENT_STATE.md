# 16 - Scenario Harness Current State

Date: 2026-04-27

Purpose: фиксирует текущую рабочую архитектуру scenario harness после разделения RESULT / DEBUG и восстановления полной логики TEST 1-7.

---

## Current status

```text
STATUS: SCENARIO HARNESS RESTORED AND EXTENDED
SCOPE: TEST 1-7
UI MODEL: RESULT as HMI, DEBUG as diagnostics
RUN MODEL: hold-preset
```

---

## Files

### Engine

```text
PRG_Scenario_Test_Harness.st
```

Назначение:

```text
- выполняет сценарии TEST 1-7
- применяет preset-входы
- считает результаты
- формирует PASS / FAIL
- зеркалирует рабочий результат в RESULT
- зеркалирует диагностическую информацию в DEBUG
```

### Main operator window

```text
GVL_TEST_PANEL_RESULT.gvl
```

Назначение:

```text
основное рабочее окно / HMI для проверки сценариев
```

Используется для управления:

```text
G_Enable
G_Scenario_Run
G_Scenario_ID
```

И для просмотра:

```text
G_Test_Result_Line
G_Result_Passed
G_Result_Status_Msg
G_Result_Fail_Code
G_Result_Base_Priority
G_Result_Expected_Adjusted_Priority
G_Result_Actual_Adjusted_Priority
G_Result_Delta
G_Result_Budget_Exceeded
G_Result_Used_Thermal_Budget
G_Result_Manifold_Enabled[]
```

### Diagnostic window

```text
GVL_TEST_PANEL_DEBUG.gvl
```

Назначение:

```text
открывается только при поиске причин ошибки или расхождения
```

Содержит:

```text
G_Test_Description
G_Test_What_To_Change
G_Test_Expected_Text
G_Expected_Summary
G_Actual_Summary
G_Error_Text
G_System_State_Line
input snapshots
```

### Core state / internal panel

```text
GVL_TEST_PANEL.gvl
```

Назначение:

```text
внутреннее состояние test harness
```

Прямо использовать как основное окно больше не рекомендуется.

---

## Control flow

```text
GVL_TEST_PANEL_RESULT
    -> PRG_Scenario_Test_Harness
        -> GVL_TEST_PANEL
            -> scenario calculation
                -> GVL_TEST_PANEL_RESULT
                -> GVL_TEST_PANEL_DEBUG
```

---

## Hold-preset run model

Текущая модель запуска:

```text
G_Scenario_Run = TRUE
    selected scenario continuously holds its preset inputs

G_Scenario_Run = FALSE
    scenario inputs return to neutral defaults
```

Причина выбора:

```text
- проще для online проверки
- не требует ловить фронты
- смена Scenario_ID сразу должна менять входы и результаты
- поведение понятно в одном рабочем окне
```

---

## Operator workflow

Открыть:

```text
GVL_TEST_PANEL_RESULT
```

Установить:

```text
G_Enable := TRUE
G_Scenario_Run := TRUE
```

Переключать:

```text
G_Scenario_ID := 1..7
```

Ожидать:

```text
G_Test_Result_Line changes according to selected scenario
G_Result_Passed shows final PASS / FAIL
G_Result_Fail_Code stays 0 on PASS
```

При ошибке открыть:

```text
GVL_TEST_PANEL_DEBUG
```

---

## Implemented scenarios

### TEST 1 - Single circuit priority

Проверяет:

```text
base priority + policy bias + guest preheat boost
```

### TEST 2 - Multi-zone aggregation

Проверяет:

```text
aggregation of multiple circuit contributions into manifold priorities
```

### TEST 3 - Preheat influence

Проверяет:

```text
guest preheat affects priority only when enabled and requested
```

### TEST 4 - Budget vs priority

Проверяет:

```text
budget allocation does not exceed max thermal budget
```

### TEST 5 - Coordinator override

Проверяет:

```text
coordinator block disables manifolds in the scenario model
```

### TEST 6 - Safety dominance

Проверяет:

```text
safety stop dominates and disables manifolds in the scenario model
```

### TEST 7 - Conflict dominance

Проверяет:

```text
combined conflict: preheat + priority + low budget + block + safety
expected result: safety remains dominant
```

---

## Verification status

Manual online verification before latest RESULT/DEBUG restructuring:

```text
TEST 1-6: manually observed PASS
```

Current expected verification after latest restructuring:

```text
compile project
open GVL_TEST_PANEL_RESULT
set G_Enable = TRUE
set G_Scenario_Run = TRUE
switch G_Scenario_ID 1..7
confirm G_Test_Result_Line and key values update
```

Important:

```text
The latest RESULT-as-HMI change must be re-run in CODESYS.
```

---

## Known limitations

```text
1. TEST 5-7 are scenario-model checks, not full hardware checks.
2. Hardware IO is not validated by this harness.
3. TEST 7 currently checks dominance model, not all real FB paths.
4. The harness is still CASE-based; it can be migrated later to data-driven STRUCT scenarios.
```

---

## Next recommended improvements

### 1. Data-driven scenario architecture

Move from:

```text
CASE G_Scenario_ID OF
```

to:

```text
ST_TestScenario + scenario array
```

Purpose:

```text
adding tests as data instead of rewriting PRG logic
```

### 2. AUTO / MANUAL mode

Future option:

```text
AUTO   = scenario holds preset inputs
MANUAL = engineer edits inputs directly
```

### 3. More edge-case scenarios

Candidates:

```text
invalid circuit index
zero budget
max load
preheat vs budget conflict
pump/service fault
pressure/current fault
```

---

## Process rule reinforced

Any future change to scenario harness must follow:

```text
1. modify one file
2. immediately re-read modified file from repo
3. confirm file is complete
4. only then continue
```

Do not insert placeholders such as:

```text
... unchanged ...
ONLY PATCHED PART
rest unchanged
```

These are forbidden because they previously caused loss of full PRG logic.
