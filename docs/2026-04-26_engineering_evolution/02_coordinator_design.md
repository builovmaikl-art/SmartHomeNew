# 02 — System Coordinator Design

Дата: 2026-04-26
Wave: 5.0

---

## Цель

Определить конкретную структуру:

```text
FB_System_Coordinator
GVL_SYSTEM_COORDINATION
PRG_System_Coordinator
```

без вмешательства в существующие PRG.

---

## GVL_SYSTEM_COORDINATION

```st
{attribute 'qualified_only'}
VAR_GLOBAL
    // global flags
    G_System_Degraded : BOOL := FALSE;
    G_System_Safe_Stop_Required : BOOL := FALSE;

    // domain block flags
    G_Block_Heating : BOOL := FALSE;
    G_Block_Ventilation : BOOL := FALSE;
    G_Block_Lighting_Override : BOOL := FALSE;
    G_Block_Sockets_Override : BOOL := FALSE;

    // status
    G_Coordination_Code : UDINT := 0;
    G_Coordination_Status_Msg : STRING(200) := '';
END_VAR
```

---

## FB_System_Coordinator

### Inputs

```st
VAR_INPUT
    // safety
    VI_Fire_Latched : BOOL;
    VI_Gas_Latched : BOOL;
    VI_Leak_Latched : BOOL;

    // system state
    VI_IO_Offline : BOOL;
    VI_Ownership_Violation : BOOL;

    // modes (future)
    VI_Mode_Away : BOOL;
    VI_Mode_Night : BOOL;
END_VAR
```

---

### Outputs

```st
VAR_OUTPUT
    VO_Block_Heating : BOOL;
    VO_Block_Ventilation : BOOL;
    VO_Block_Lighting : BOOL;
    VO_Block_Sockets : BOOL;

    VO_System_Degraded : BOOL;
    VO_System_Safe_Stop : BOOL;

    VO_Code : UDINT;
END_VAR
```

---

## Decision Logic (core)

```text
priority order:
1. Fire
2. Gas
3. Leak
4. IO offline
5. Ownership violation
6. Modes
```

---

### Pseudocode

```st
// reset
VO_Block_Heating := FALSE;
VO_Block_Ventilation := FALSE;
VO_Block_Lighting := FALSE;
VO_Block_Sockets := FALSE;
VO_System_Degraded := FALSE;
VO_System_Safe_Stop := FALSE;
VO_Code := 0;

// FIRE
IF VI_Fire_Latched THEN
    VO_System_Safe_Stop := TRUE;
    VO_Block_Heating := TRUE;
    VO_Block_Ventilation := TRUE;
    VO_Block_Lighting := FALSE; // evacuation lighting allowed
    VO_Block_Sockets := TRUE;
    VO_Code := 100;
    RETURN;
END_IF;

// GAS
IF VI_Gas_Latched THEN
    VO_System_Safe_Stop := TRUE;
    VO_Block_Heating := TRUE;
    VO_Block_Ventilation := FALSE; // ventilation allowed/forced
    VO_Block_Lighting := TRUE;
    VO_Block_Sockets := TRUE;
    VO_Code := 200;
    RETURN;
END_IF;

// LEAK
IF VI_Leak_Latched THEN
    VO_Block_Heating := TRUE;
    VO_Block_Ventilation := FALSE;
    VO_Code := 300;
END_IF;

// IO OFFLINE
IF VI_IO_Offline THEN
    VO_System_Degraded := TRUE;
    VO_Block_Heating := TRUE;
    VO_Code := 400;
END_IF;

// OWNERSHIP
IF VI_Ownership_Violation THEN
    VO_System_Safe_Stop := TRUE;
    VO_Code := 500;
END_IF;
```

---

## PRG_System_Coordinator

```st
PROGRAM PRG_System_Coordinator
VAR
    fbCoord : FB_System_Coordinator;
END_VAR

fbCoord(
    VI_Fire_Latched := GVL_STATE.G_Safety_Smoke_Latched,
    VI_Gas_Latched := GVL_STATE.G_Safety_Gas_Latched,
    VI_Leak_Latched := GVL_STATE.G_Safety_Leak_Latched,
    VI_IO_Offline := NOT GVL_STATUS.G_IO_Modules_Online[1],
    VI_Ownership_Violation := GVL_TEST.G_Ownership_Violation
);

GVL_SYSTEM_COORDINATION.G_Block_Heating := fbCoord.VO_Block_Heating;
GVL_SYSTEM_COORDINATION.G_Block_Ventilation := fbCoord.VO_Block_Ventilation;
GVL_SYSTEM_COORDINATION.G_Block_Lighting_Override := fbCoord.VO_Block_Lighting;
GVL_SYSTEM_COORDINATION.G_Block_Sockets_Override := fbCoord.VO_Block_Sockets;

GVL_SYSTEM_COORDINATION.G_System_Degraded := fbCoord.VO_System_Degraded;
GVL_SYSTEM_COORDINATION.G_System_Safe_Stop_Required := fbCoord.VO_System_Safe_Stop;

GVL_SYSTEM_COORDINATION.G_Coordination_Code := fbCoord.VO_Code;
```

---

## Минимальный scope Wave 5.0

```text
✔ Coordinator считает
✔ публикует
❌ не вмешивается в PRG_Heating / Lighting / Ventilation
```

---

## Acceptance

```text
- компилируется
- не ломает систему
- виден в trace / diagnostics
```

---

## Статус

```text
DESIGN READY
```
