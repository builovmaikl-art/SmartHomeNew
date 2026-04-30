# HMI / WEB DASHBOARD ARCHITECTURE — 2026-05-01

## 1. Purpose

This document defines the correct HMI / web-dashboard structure for the current SmartHome control architecture.

The dashboard must not become a second control system.

It must be an engineering and operator-facing view over existing system state.

---

## 2. Core Rule

```text
Dashboard reads.
System controls.
```

The dashboard must not write directly to:

```text
GVL_IO
GVL_STATE
GVL_COMMAND_SHADOW
Domain Output GVLs
Safety / Recovery internals
Adaptive weights directly
```

Allowed write paths, if control is needed later:

```text
User action → GVL_INTENT_USER → Command Arbitration → Domain → IO
```

---

## 3. Primary Data Sources

The dashboard should primarily read:

```text
GVL_DEBUG_VIEW
```

Secondary / drill-down sources:

```text
GVL_TRACE
GVL_EXPLAINABILITY
GVL_INTENT_BEHAVIOR
GVL_SAFETY_SHUTDOWN
GVL_SAFETY_RECOVERY
GVL_BEHAVIOR_ADAPT
GVL_STATUS
GVL_ALARM
```

Physical IO should not be the default dashboard source.

If displayed, it must be marked as final physical output state.

---

## 4. Dashboard Layers

### 4.1 Operator Overview

Purpose:

```text
show whether the house is OK and what it is currently doing
```

Widgets:

```text
System status
Safety mode
Recovery phase
Current behavior scenario
Global reason
Main active command summary
Last trace event
```

Source:

```text
GVL_DEBUG_VIEW
```

---

### 4.2 Safety & Recovery Page

Purpose:

```text
show emergency state and recovery progress
```

Widgets:

```text
Safety mode
Safety active flag
Recovery phase
Recovery active flag
Global reason text
Domain-specific safety explanations
```

Sources:

```text
GVL_DEBUG_VIEW
GVL_SAFETY_SHUTDOWN
GVL_SAFETY_RECOVERY
GVL_EXPLAINABILITY
```

Rules:

```text
No automatic reset from dashboard unless routed through GVL_INTENT_USER.
Manual reset must be explicit and confirmed.
```

---

### 4.3 Behavior / Scenario Page

Purpose:

```text
show why the house selected current behavior
```

Widgets:

```text
Current scenario text
Behavior reason
Night score
Preheat score
VentBoost score
AccessSecure score
Active behavior intents
```

Sources:

```text
GVL_DEBUG_VIEW
GVL_INTENT_BEHAVIOR
```

Important:

```text
This page must explain decisions, not modify them directly.
```

---

### 4.4 Adaptation Page

Purpose:

```text
show how the system is learning
```

Widgets:

```text
Global scenario weights
Main VentBoost zone
Max / min zone weight
Zone confidence table
Zone activation counters
Zone success rate
Decay factor
Learning rate
Confidence learning rate
```

Sources:

```text
GVL_DEBUG_VIEW
GVL_BEHAVIOR_ADAPT
```

Controls:

Direct editing should be avoided initially.

If tuning is later required, all changes should go through a dedicated configuration layer, not direct writes.

---

### 4.5 Trace / Blackbox Page

Purpose:

```text
inspect recent decision chain and system events
```

Widgets:

```text
Last trace event
Trace ring buffer table
Filter by layer
Filter by reason
Filter by source
Timestamp view
```

Sources:

```text
GVL_TRACE
GVL_DEBUG_VIEW
```

Important:

```text
Trace is history.
Debug View is current snapshot.
Do not duplicate trace data into another log.
```

---

### 4.6 Domain Pages

Separate domain pages may exist for:

```text
Heating
Ventilation
Water
Access
Lighting
```

Each page should show:

```text
intent
command
domain output
final IO state
explanation
```

Read order:

```text
GVL_INTENT_* / GVL_COMMAND_SHADOW / Domain Output GVL / GVL_IO / GVL_EXPLAINABILITY
```

---

## 5. Recommended UI Navigation

```text
Overview
Safety / Recovery
Behavior
Adaptation
Trace / Blackbox
Domains
Settings / Tuning (future, restricted)
```

---

## 6. Data Model Mapping

### Overview

```text
D_Current_Time_MS
D_Safety_Mode
D_Safety_Active
D_Recovery_Phase
D_Recovery_Active
D_Current_Scenario
D_Global_Reason
D_Last_Trace_Text
```

### Behavior

```text
D_Score_Night
D_Score_Preheat
D_Score_VentBoost
D_Score_AccessSecure
D_Intent_Night
D_Intent_Comfort
D_Intent_VentBoost
D_Intent_AccessSecure
D_Behavior_Reason
```

### Commands

```text
D_Heating_Block
D_Vent_Stop
D_Water_Block
D_Access_Open_Active
```

### Adaptation

```text
D_Main_VentBoost_Zone
D_Main_VentBoost_Zone_Weight
D_Main_VentBoost_Zone_Confidence
D_Max_VentBoost_Zone_Weight
D_Min_VentBoost_Zone_Weight
```

### Explainability

```text
D_Behavior_Why_Active
D_Heating_Why_Blocked
D_Vent_Why_Stopped
D_Water_Why_Closed
D_Access_Why_Opened
```

---

## 7. Dashboard Modes

### 7.1 User Mode

Shows:

```text
simple system state
current mode
warnings
safe actions only
```

No raw adaptive internals.

---

### 7.2 Engineer Mode

Shows:

```text
scores
weights
confidence
trace
command states
output states
```

May include export / snapshot tools.

---

### 7.3 Service Mode

Future mode.

Can expose tuning controls, but only through a controlled configuration layer.

---

## 8. Write Safety Rules

Dashboard must never directly write to control outputs.

Allowed future actions:

```text
Reset errors → GVL_INTENT_USER.I_Reset_Errors
Open gate → GVL_INTENT_USER.I_Gate_Open_Request
Manual scenario request → future GVL_INTENT_USER or GVL_INTENT_BEHAVIOR_REQUEST
```

Forbidden:

```text
Writing GVL_IO directly
Writing GVL_COMMAND_SHADOW directly
Writing GVL_HEATING_OUTPUT / GVL_VENT_OUTPUT / GVL_WATER_OUTPUT directly
Writing adaptive weights directly from UI
```

---

## 9. Update Frequency

Recommended:

```text
Overview: 500–1000 ms
Trace table: 1000–2000 ms
Adaptation: 2000–5000 ms
Domain IO pages: 500–1000 ms
```

Do not refresh heavy trace views every PLC scan.

---

## 10. Web Dashboard Implementation Shape

Recommended backend options:

```text
PLC → OPC UA → backend/API → web UI
PLC → MQTT bridge → web UI
PLC → local gateway → REST/WebSocket
```

Recommended frontend pages:

```text
/dashboard
/safety
/behavior
/adaptation
/trace
/domains/heating
/domains/ventilation
/domains/water
/domains/access
```

Recommended frontend components:

```text
StatusCard
ScenarioScorePanel
SafetyBanner
RecoveryPanel
CommandStatePanel
AdaptationZoneTable
TraceTable
DomainOutputPanel
ExplainabilityPanel
```

---

## 11. HMI Implementation Shape

For PLC/HMI panel:

```text
Screen 1: Overview
Screen 2: Safety / Recovery
Screen 3: Behavior
Screen 4: Adaptation
Screen 5: Trace
Screen 6+: Domain pages
```

The HMI should bind mostly to `GVL_DEBUG_VIEW`.

Detailed pages may bind to raw GVLs only for drill-down.

---

## 12. What Not To Build

Do not build:

```text
second blackbox
parallel command system
dashboard-side scenario engine
dashboard-side adaptive logic
direct IO override panel
```

---

## 13. Next Implementation Step

The next practical implementation step is:

```text
Create a web/HMI read model based on GVL_DEBUG_VIEW.
```

Then optionally add:

```text
Trace table view over GVL_TRACE
Adaptation zone table over GVL_BEHAVIOR_ADAPT
Domain drill-down pages
```

---

## 14. Final Contract

```text
PLC remains source of truth.
Dashboard is read-only observability by default.
All control actions must enter through Intent.
```
