# 07 — Presence Layer

Дата: 2026-04-26
Wave: 5.1
Scope: presence detection / auto-away signal

---

## Цель

Добавить отдельный слой Presence, который определяет занятость дома по motion-сигналам и публикует auto-away request.

---

## Ownership

```text
PRG_IO_Read owns raw motion state
Presence layer owns occupancy interpretation
Mode layer owns behavior mode selection
Coordinator owns global constraints
```

---

## Proposed files

```text
GVL_PRESENCE.gvl
FB_Presence_Manager.st
PRG_Presence_Manager.st
```

---

## Inputs

```text
GVL_STATE.G_Motion_Sensors[1..32]
GVL_STATUS.G_System_Time_MS
```

---

## Outputs

```text
GVL_PRESENCE.G_Any_Motion
GVL_PRESENCE.G_Occupied
GVL_PRESENCE.G_Auto_Away_Request
GVL_PRESENCE.G_Last_Motion_TS
```

---

## Logic

```text
Any motion -> occupied TRUE and update last motion timestamp
No motion but timeout not expired -> occupied TRUE
No motion and timeout expired -> occupied FALSE, auto-away TRUE
```

---

## Initial behavior

At boot the manager initializes last motion timestamp to current system time to avoid immediate AWAY after startup.

---

## Integration

```text
PRG_Presence_Manager runs after PRG_IO_Read and before PRG_Mode_Manager
PRG_Mode_Manager consumes GVL_PRESENCE.G_Auto_Away_Request
```

---

## Non-goals

```text
- no direct coordinator writes
- no direct subsystem writes
- no changes to PRG_IO_Read
```

---

## Status

```text
DESIGN READY
```