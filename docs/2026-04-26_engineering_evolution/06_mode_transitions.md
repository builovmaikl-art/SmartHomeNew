# 06 — Wave 5.1 Mode Transitions

Дата: 2026-04-26
Wave: 5.1
Scope: behavior mode transition rules

---

## Цель

Добавить автоматический выбор Behavior Mode без нарушения ownership:

```text
FB_Mode_Manager owns behavior-mode selection
PRG_Mode_Manager publishes GVL_MODE
Coordinator consumes mode and produces constraints
```

---

## Priority model

```text
1. Maintenance request
2. Away request
3. Night condition
4. Home default
```

---

## Transition rules

### MAINTENANCE

```text
If maintenance request is active -> BEHAVIOR_MAINTENANCE
```

### AWAY

```text
If away request is active -> BEHAVIOR_AWAY
```

### NIGHT

```text
If night condition is active -> BEHAVIOR_NIGHT
```

### HOME

```text
Default mode when no higher-priority mode is active
```

---

## Hysteresis / hold

Phase 1 uses direct transition only.

Future extension:

```text
- away delay
- night confirmation delay
- minimum hold time
```

---

## Inputs

```text
VI_Is_Night
VI_Away_Request
VI_Maintenance_Request
VI_System_Time_MS
```

---

## Outputs

```text
VO_Mode
VO_Mode_Code
```

---

## Mode codes

```text
0   HOME
100 NIGHT
200 AWAY
300 MAINTENANCE
```

---

## Non-goals

```text
- no direct subsystem writes
- no safety-stop ownership change
- no scenario rewrite
```

---

## Status

```text
TRANSITION DESIGN READY
```