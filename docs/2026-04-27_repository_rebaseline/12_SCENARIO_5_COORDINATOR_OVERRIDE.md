# 12 — Scenario 5: Coordinator Override

Дата: 2026-04-27
Назначение: проверить, что глобальная координация системы может переопределять heating независимо от приоритетов

---

## Суть

Даже если:

```text
priority высокий
budget позволяет
```

система должна уметь:

```text
полностью отключить heating
```

через:

```text
GVL_SYSTEM_COORDINATION.G_Block_Heating
```

---

## Что меняем

```text
включаем несколько контуров
задаём высокий приоритет
включаем preheat
ставим G_Block_Heating = TRUE
```

---

## Что ожидаем

```text
ВСЕ manifold отключены
все насосы/клапаны считаются заблокированными
priority не имеет значения
```

---

## Проверка

```text
Enabled[] = FALSE для всех manifold
```

---

## Возможные ошибки

```text
manifold остаётся включён
частичное отключение
priority продолжает влиять
```

---

## Результат

```text
TRUE / FALSE
```

---

## Статус

```text
SCENARIO DEFINED
AWAITING IMPLEMENTATION IN TEST PANEL
```