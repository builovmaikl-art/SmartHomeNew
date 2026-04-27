# 13 — Scenario 6: Safety Dominance

Дата: 2026-04-27
Назначение: проверить верхний приоритет safety над policy, budget и coordinator-level heating decision

---

## Суть

Даже если:

```text
priority высокий
budget позволяет
coordinator не блокирует heating
```

safety должен иметь высший приоритет.

---

## Что меняем

```text
G_Input_Safety_Stop := TRUE
G_Input_Block_Heating := FALSE
G_Input_Max_Thermal_Budget высокий
policy/preheat дают высокий priority
```

---

## Что ожидаем

```text
Enabled[] = FALSE для всех manifold
Safety stop dominates policy / budget / preheat
```

---

## Проверка

```text
если G_Input_Safety_Stop = TRUE
то все G_Result_Manifold_Enabled[] должны быть FALSE
```

---

## Возможные ошибки

```text
manifold остаётся enabled при safety stop
priority или budget побеждают safety
частичная блокировка вместо полной
```

---

## Статус

```text
SCENARIO DEFINED
AWAITING MANUAL VERIFICATION
```