# 08 — Presence / Mode Hysteresis

Дата: 2026-04-26
Wave: 5.1
Scope: stability / anti-flapping

---

## Цель

Предотвратить быстрые прыжки режимов HOME/AWAY из-за единичных motion-событий, дребезга датчиков или кратковременного отсутствия движения.

---

## Ownership

```text
Presence layer owns occupancy hysteresis
Mode layer consumes stable auto-away request
Coordinator consumes mode
```

---

## Rules

### Away delay

```text
No motion for timeout -> Auto Away TRUE
```

Initial value:

```text
15 minutes
```

### Return delay

```text
Motion after Away -> Occupied TRUE immediately
```

Rationale:

```text
returning home must be responsive
```

### Boot protection

```text
At boot, last motion timestamp = current time
```

Prevents immediate AWAY at startup.

---

## Future extension

```text
- configurable timeout from HMI
- per-zone presence
- minimum away hold time
- confidence score
```

---

## Implementation target

```text
FB_Presence_Manager
GVL_PRESENCE
```

---

## Status

```text
DESIGN READY
```