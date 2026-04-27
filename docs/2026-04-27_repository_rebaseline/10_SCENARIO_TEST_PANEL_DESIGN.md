# 10 — Scenario Test Panel Design

Дата: 2026-04-27
Назначение: создать один удобный test panel для проверки сценариев без переключения по множеству GVL/окон

---

## Идея

Нужен один GVL, который можно открыть в CODESYS watch/online view и видеть:

```text
верх: входы сценария, которые меняет оператор
низ: ожидаемые/рассчитанные значения и статус проверки
```

Это снижает риск ручного поиска значений по разным вкладкам.

---

## Реализация

Добавляются два файла:

```text
GVL_TEST_PANEL.gvl
PRG_Scenario_Test_Harness.st
```

---

## Принцип безопасности

`PRG_Scenario_Test_Harness` не должен:

```text
писать в GVL_STATE
писать в GVL_IO
писать в GVL_ACTUATORS
вызывать PRG_Heating
менять реальные входы/выходы проекта
```

Он должен:

```text
читать GVL_TEST_PANEL scenario inputs
читать config/policy reference values при необходимости
рассчитать ожидаемый результат
записать результат обратно только в GVL_TEST_PANEL
```

---

## Один экран

`GVL_TEST_PANEL` делится на зоны:

```text
1. Control
2. Scenario inputs
3. Calculated mapping
4. Expected outputs
5. Status / result
```

---

## Первый сценарий

Scenario 1:

```text
HP selected circuit priority calculation
```

Проверяет:

```text
base manifold priority
+ manual policy bias from panel
+ guest preheat boost from panel
= expected adjusted priority
```

---

## Почему отдельный PRG, а не расширение PRG_System_Test_Harness

`PRG_System_Test_Harness` остаётся системным self-check.

`PRG_Scenario_Test_Harness` — это операторский commissioning panel:

```text
manual inputs -> immediate calculated outputs
```

Так мы не смешиваем automated assertions и interactive scenario testing.

---

## Как использовать

Временно подключить:

```text
PRG_Scenario_Test_Harness();
```

Открыть `GVL_TEST_PANEL` в watch/online view.

Менять:

```text
G_Enable
G_Selected_Circuit
G_Input_Policy_Bias
G_Input_Guest_Preheat_Request
G_Input_Guest_Preheat_Enabled
G_Input_Guest_Preheat_Boost
```

Смотреть ниже:

```text
G_Result_Passed
G_Result_Status_Msg
G_Result_Mapped_Manifold
G_Result_Base_Priority
G_Result_Adjusted_Priority
G_Result_Delta
```

---

## Статус

```text
SCENARIO TEST PANEL DESIGN RECORDED
IMPLEMENTATION ALLOWED IN GVL_TEST_PANEL.gvl AND PRG_Scenario_Test_Harness.st
```