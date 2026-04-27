# 16 — Test Panel Commissioning UX

Дата: 2026-04-27
Назначение: улучшить GVL_TEST_PANEL как единое окно ручной проверки сценариев

---

## Цель

Сделать тестовую панель удобной для commissioning-проверки:

```text
выбрал сценарий
изменил входы
сразу видишь инструкцию, ожидаемые значения, actual, pass/fail
```

---

## Улучшения

Добавляются поля:

```text
G_Run_Counter
G_Last_Scenario_ID
G_Last_Result_Passed
G_Last_Fail_Code
G_Reset_Results_Request
G_Reset_Inputs_Request
G_Current_Test_Name
G_Expected_Summary
G_Actual_Summary
```

---

## Правила

Test panel не должен писать в runtime state:

```text
GVL_STATE
GVL_IO
GVL_ACTUATORS
```

---

## Важно

В ходе проверки обнаружено, что `PRG_Scenario_Test_Harness.st` потерял часть логики сценариев 1–3 при предыдущих правках.

Текущий changeset должен восстановить полный набор сценариев:

```text
Scenario 1–6
```

---

## Статус

```text
COMMISSIONING UX IMPROVEMENT RECORDED
FULL SCENARIO LOGIC MUST BE PRESENT AFTER EDIT
```