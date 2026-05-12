# HEATING_ACTIVE_FB_CALL_GRAPH_AUDIT

# Purpose

This document serves as the canonical runtime ownership and governance audit for the heating subsystem.

Current repository phase:

```text
GOVERNED PHASE-ORIENTED RUNTIME MAINTENANCE
```

The purpose is:

```text
- document verified runtime ownership;
- document deterministic runtime phases;
- prevent detached orchestration resurrection;
- preserve bounded ownership;
- preserve compile/runtime stability.
```

---

# Verified runtime baseline

Current confirmed state:

```text
0 compile errors
single runtime ownership path verified
phase-oriented orchestration verified
```

Canonical runtime chain:

```text
PRG_Heating
 ├── Observer_Phase
 ├── DHW_Manager
 ├── Heating_Manager
 ├── Service_Gating_Phase
 ├── State_Publication_Phase
 ├── Diagnostics_Phase
 └── Output_Projection_Phase
```

Subsystem ownership chain:

```text
FB_Heating_System_Manager
    → Safety_Gate
    → Safe_State
    → Circuit_Control
    → Demand_Map
    → Policy_Priority_Bridge
    → Allocation_Filter
    → Runtime_Observability
    → Manifold_Control
    → Boiler_Control
```

Important invariants:

```text
compile participation
≠
runtime ownership
```

and:

```text
single active runtime authority path
```

---

# Runtime phase architecture

The runtime orchestration was decomposed into deterministic bounded phases.

Integrated runtime phases:

```text
FB_Heating_Runtime_Observer_Phase
FB_Heating_Runtime_Service_Gating_Phase
FB_Heating_Runtime_State_Publication_Phase
FB_Heating_Runtime_Diagnostics_Phase
FB_Heating_Runtime_Output_Projection_Phase
```

Current orchestrator role:

```text
PRG_Heating acts primarily as:
- sequencing layer;
- phase scheduler;
- runtime context coordinator.
```

---

# Verified donor cleanup result

The historical disconnected donor cleanup is considered complete.

Verified removed donor groups:

```text
- detached orchestration wrappers;
- obsolete allocation layers;
- duplicated protection layers;
- disconnected Runtime_* scaffold;
- detached diagnostics donors;
- unused governance scaffold;
- obsolete supervision scaffold.
```

Important:

```text
snapshots/history were intentionally preserved.
```

---

# Verified removed donors

## Removed orchestration donors

```text
FB_Heating_Execution_Core
FB_Heating_Orchestration
```

Status:

```text
VERIFIED REMOVED
```

---

## Removed allocation donors

```text
FB_Heating_Decision_Context
FB_Heating_Thermal_Allocation
```

Status:

```text
VERIFIED REMOVED
```

Replacement path:

```text
FB_Heating_Allocation_Filter
FB_Heating_Policy_Priority_Bridge
```

---

## Removed protection donors

```text
FB_FloorHeating_Freeze_Protection
FB_FloorHeating_Overheat_Protection
```

Status:

```text
VERIFIED REMOVED
```

---

## Removed diagnostics/snapshot donors

```text
FB_Heating_Diagnostics
FB_State_Snapshot_Manager
```

Status:

```text
VERIFIED REMOVED
```

---

# Active retained runtime blocks

## Observer path

Verified active observer chain:

```text
PRG_Heating
→ FB_Heating_Runtime_Observer_Phase
    → FB_Heating_Runtime_Observer_Authorization
    → FB_Heating_Runtime_Observer
    → GVL_Heating_Runtime_Observation
```

Verified properties:

```text
- governance-gated;
- observation-oriented;
- read-only semantics;
- isolated from runtime control ownership.
```

Status:

```text
KEEP ACTIVE
```

---

## Runtime observability

```text
FB_Heating_Runtime_Observability
```

Role:

```text
runtime explainability and allocation visibility.
```

Status:

```text
KEEP ACTIVE
```

---

## Retained utility

```text
F_Modbus_RTU_CRC16
```

Status:

```text
KEEP ACTIVE
```

Reason:

```text
deterministic standalone utility.
```

---

# Architectural anti-drift rules

Forbidden directions:

```text
- detached orchestration resurrection;
- duplicate runtime ownership;
- Runtime_* actuation resurrection;
- telemetry-driven control ownership;
- hidden publication layers;
- parallel runtime paths.
```

Required workflow:

```text
1. ownership verification;
2. governance verification;
3. write-path verification;
4. deterministic runtime validation;
5. only then bounded evolution.
```

---

# Strategic conclusion

The repository evolved from:

```text
legacy orchestration cleanup
```

into:

```text
deterministic phase-oriented runtime governance
```

Primary engineering goal:

```text
preserve explicit bounded ownership
while preventing future architectural drift.
```
