# 11 — Heating Policy Observe Phase

Дата: 2026-04-26
Wave: 5.1
Scope: presence-aware heating policy / observe-only

---

## Цель

Добавить слой наблюдения за thermal occupancy policy без влияния на отопление.

```text
observe-only = calculate and publish, but do not control heating
```

---

## Ключевое уточнение

Некоторые помещения являются помещениями постоянного использования.

Примеры:

```text
- спальня
- детская
- ванная / санузел
- рабочий кабинет
```

Для них отсутствие движения не должно автоматически переводить комнату в deep eco.

---

## Новое правило

```text
Permanent-use zone MUST NOT enter deep eco automatically by absence duration.
```

Для таких зон допустимо:

```text
- occupied -> comfort
- short empty -> mild eco
- long empty -> still mild eco, not deep eco
```

Deep eco разрешён только для зон, которые не помечены как permanent-use.

---

## Observe outputs

```text
G_Zone_Empty_Duration_MS[]
G_Zone_Permanent_Use[]
G_Zone_Policy_Class[]
G_Zone_Target_Adjustment[]
G_Zone_Priority_Bias[]
```

---

## Policy classes

```text
0 = occupied / comfort
1 = short empty / mild eco
2 = long empty / deep eco
3 = guest preheat
4 = permanent-use mild eco
```

---

## Non-goals

```text
- no heating setpoint change yet
- no pump/valve control
- no direct modification of PRG_Heating behavior
```

---

## Future integration

Later phases may feed:

```text
G_Zone_Target_Adjustment[]
G_Zone_Priority_Bias[]
```

into heating decision/policy layer.

---

## Status

```text
DESIGN READY
```