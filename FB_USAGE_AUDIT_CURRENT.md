# FB_USAGE_AUDIT_CURRENT

# Status

This document reflects the current verified runtime architecture after:

```text
- runtime ownership audit;
- donor extraction audit;
- phase decomposition;
- write-boundary verification;
- governance validation;
- runtime evidence verification.
```

The audit intentionally ignores:

```text
- snapshots/;
- archives/;
- historical exports;
- disconnected harnesses.
```

Current repository phase:

```text
DETERMINISTIC PHASE-ORIENTED RUNTIME MAINTENANCE
```

---

# Repository editing rule

NO PARTIAL FILE PATCHING.

All repository modifications must:

```text
- fully rewrite affected files;
- preserve ownership consistency;
- preserve governance consistency;
- preserve runtime sequencing consistency.
```

Reason:

```text
partial edits create architectural drift.
```

---

# Current verified runtime architecture

Canonical orchestration:

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

Verified properties:

```text
- single active runtime ownership chain;
- deterministic phase sequencing;
- no detached orchestration path;
- no hidden Runtime_* actuation;
- bounded helper execution only.
```

---

# OpenTherm / boiler governance

Authoritative owner:

```text
FB_Heating_Boiler_Control
```

Bounded helper chain:

```text
FB_Boiler_Cascade_Manager
→ FB_Boiler_OpenTherm_Interface
```

Verified result:

```text
bounded helper execution only
without authority escalation.
```

---

# Diagnostics layering

## Layer 1 — Runtime semantic state

Produced by:

```text
FB_Boiler_OpenTherm_Interface
FB_Heating_Boiler_Control
```

Purpose:

```text
transport/runtime semantic diagnostics.
```

---

## Layer 2 — Inference engine

```text
FB_Diagnostics_RootCause
```

Restriction:

```text
NO runtime authority.
```

---

## Layer 3 — Runtime diagnostics phase

```text
FB_Heating_Runtime_Diagnostics_Phase
```

Purpose:

```text
bounded diagnostics orchestration
inside deterministic runtime sequencing.
```

Restriction:

```text
NO runtime control ownership.
```

---

## Layer 4 — Observer/explainability

```text
FB_Heating_Runtime_Observer_Phase
→ FB_Heating_Runtime_Observer
```

Purpose:

```text
observation/explainability projection only.
```

Restriction:

```text
NO runtime authority.
```

---

# Verified donor cleanup result

Verified removed donors:

```text
FB_Heating_Execution_Core
FB_Heating_Orchestration
FB_Heating_Thermal_Allocation
FB_Heating_Decision_Context
FB_Heating_Diagnostics
FB_State_Snapshot_Manager
FB_FloorHeating_Freeze_Protection
FB_FloorHeating_Overheat_Protection
```

Reason:

```text
their useful bounded semantics were absorbed
into active runtime ownership layers.
```

---

# Runtime governance classification

## Active runtime owners

Verified owners:

```text
FB_Heating_System_Manager
FB_Heating_Circuit_Control
FB_Heating_Manifold_Control
FB_Heating_Boiler_Control
FB_Heating_Safety_Gate
FB_Heating_Safe_State
```

---

## Runtime_* family

Verified role:

```text
passive governance / observability scaffold.
```

Allowed:

```text
- telemetry;
- diagnostics;
- sequencing validation;
- explainability;
- anomaly analysis.
```

Forbidden:

```text
runtime actuation.
```

---

## Bounded helper layers

Examples:

```text
FB_Boiler_Cascade_Manager
FB_Boiler_OpenTherm_Interface
FB_Valve_Test_Manager
```

Verified result:

```text
helper authority escalation not detected.
```

---

# Current risk model

Primary risk:

```text
future architectural drift.
```

Especially dangerous:

```text
- detached orchestration resurrection;
- Runtime_* actuation;
- duplicate writers;
- hidden publication layers;
- telemetry-driven control;
- governance-driven control.
```

---

# Architectural result

The repository now has:

```text
- explicit ownership boundaries;
- deterministic phase sequencing;
- explicit governance boundaries;
- write-boundary enforcement;
- bounded helper execution;
- bounded observability.
```

The repository evolved from:

```text
legacy cleanup
```

into:

```text
deterministic runtime governance maintenance.
```
