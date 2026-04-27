# 11 — Scenario Tests Registry

Дата: 2026-04-27
Назначение: фиксировать все сценарные тесты и ожидаемое поведение до их фактического прогона

---

## Общий принцип

```text
сначала фиксируем сценарий → потом прогоняем → потом сверяем
```

Это позволяет:
- не терять логику
- понимать, что именно сломалось
- избегать "интуитивного" дебага

---

# TEST 1 — Single Circuit Priority

## Что меняем

```text
G_Selected_Circuit
G_Input_Policy_Bias
G_Input_Guest_Preheat_Request
G_Input_Guest_Preheat_Enabled
G_Input_Guest_Preheat_Boost
```

## Что ожидаем

```text
Adjusted = Base + Bias + Preheat
Lower bound >= 1
```

## Проверка

```text
Expected == Actual
```

## Результат

```text
TRUE / FALSE
```

---

# TEST 2 — Multi-Zone Aggregation

## Что меняем

```text
G_Input_Circuit_Enable[]
G_Input_Circuit_Bias[]
G_Input_Circuit_Guest_Preheat[]
```

## Что ожидаем

```text
Каждый manifold получает сумму всех активных circuit contributions
```

## Проверка

```text
Expected per manifold == Actual
```

## Результат

```text
TRUE / FALSE
```

---

# TEST 3 — Preheat Influence

## Что меняем

```text
включаем / выключаем preheat
```

## Что ожидаем

```text
при включении → приоритет увеличивается
при выключении → возвращается
```

## Результат

```text
TRUE / FALSE
```

---

# TEST 4 — Budget vs Priority (CRITICAL)

## Что меняем

```text
несколько контуров включены
разные bias
включён preheat
уменьшаем G_Input_Max_Thermal_Budget
```

## Что ожидаем

```text
НЕ все manifold будут включены
включаются только самые приоритетные
суммарный budget не превышен
```

## Проверка

```text
Enabled[] соответствует приоритету
Used_Budget <= Max_Budget
```

## Возможные отказы

```text
включены низкоприоритетные manifold
превышен бюджет
несогласованность Allowed/Enabled
```

## Результат

```text
TRUE / FALSE
```

---

# Статус

```text
SCENARIOS DEFINED
AWAITING MANUAL VERIFICATION
```

---

# Правило

```text
Если тест падает:
→ не правим код сразу
→ читаем этот документ
→ сравниваем ожидаемое и фактическое
→ локализуем проблему
```
