# 09 — Multi-zone Presence

Дата: 2026-04-26
Wave: 5.1
Scope: zonal occupancy awareness

---

## Цель

Расширить Presence layer от глобального признака `occupied` до зонального присутствия.

---

## Размерности

```text
Motion sensors: 1..32
Climate / room zones: 1..16
```

Phase 1 использует простой mapping:

```text
motion[1..16] -> presence zone[1..16]
```

Motion sensors 17..32 продолжают участвовать в global Any Motion, но не публикуются как climate zones в текущем scope.

---

## Outputs

```text
G_Zone_Occupied[1..C_MAX_ZONES]
G_Zone_Last_Motion_TS[1..C_MAX_ZONES]
```

---

## Logic

```text
Motion in zone -> zone occupied and update zone timestamp
No zone motion but timeout not expired -> zone remains occupied
No zone motion and timeout expired -> zone not occupied
```

Global occupancy remains:

```text
Any zone occupied OR any recent motion
```

---

## Non-goals

```text
- no heating zone optimization yet
- no lighting per-zone policy yet
- no PRG_IO_Read changes
```

---

## Future use

```text
- occupied-zone heating bias
- room-level lighting decisions
- confidence model
- zone-to-sensor configurable mapping
```

---

## Status

```text
DESIGN READY
```