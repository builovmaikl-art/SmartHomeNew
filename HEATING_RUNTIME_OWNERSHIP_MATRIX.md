# HEATING_RUNTIME_OWNERSHIP_MATRIX

# Purpose

This document defines authoritative runtime ownership boundaries for the heating architecture.

Primary goals:

```text
- prevent duplicate writers;
- prevent detached runtime authority;
- prevent hidden authority overlap;
- prevent projection/control confusion;
- preserve deterministic phase sequencing;
- preserve explicit ownership boundaries.
```

This document is authoritative for:

```text
- runtime ownership;
- allowed write boundaries;
- observability boundaries;
- governance boundaries;
- finalization boundaries;
- safety ownership.
```

---

# Core invariant

The invariant that must never be violated:

```text
single active runtime authority path
```

Current verified orchestration:

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

Current verified subsystem ownership:

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

No detached orchestration may bypass this chain.

---

# Ownership model

## Rule 1 — Single writer principle

Every runtime authority domain must have:

```text
ONE authoritative runtime ownership chain
```

Additional layers may:

```text
- observe;
- validate sequencing;
- project telemetry;
- publish diagnostics;
- perform governance validation.
```

But may NOT:

```text
- create detached runtime ownership;
- bypass active runtime chain;
- create hidden authority overlap.
```

---

## Rule 2 — Projection ≠ control

Projection layers:

```text
- Runtime_Observability;
- observer infrastructure;
- telemetry publishers;
- diagnostics publishers.
```

must never become:

```text
runtime controllers.
```

---

## Rule 3 — Governance ≠ orchestration

Governance infrastructure may:

```text
- validate sequencing;
- validate contracts;
- validate lifecycle consistency;
- validate integration boundaries.
```

But may NOT:

```text
- own runtime execution;
- own valves;
- own pumps;
- own OpenTherm;
- own DHW.
```

---

# Authority ownership matrix

## Runtime orchestration ownership

Authoritative owner:

```text
PRG_Heating
```

Authority:

```text
- deterministic phase sequencing;
- runtime context coordination;
- bounded phase orchestration.
```

Explicit non-authority:

```text
- no detached execution ownership;
- no hidden actuation ownership;
- no alternate runtime path.
```

---

## Heating runtime ownership

Authoritative owner:

```text
FB_Heating_System_Manager
```

Authority:

```text
- heating runtime execution;
- bounded policy integration;
- allocation integration;
- manifold execution coordination;
- heating realization ownership.
```

Forbidden ownership:

```text
- detached orchestration shells;
- Runtime_* governance scaffold;
- detached override layers.
```

---

## Circuit thermal protection ownership

Authoritative owner:

```text
FB_Heating_Circuit_Control
```

Authority:

```text
- floor thermal evaluation;
- thermal shutdown;
- circuit enable state;
- bounded thermal suppression.
```

Historical absorbed donor:

```text
FB_FloorHeating_Overheat_Protection
```

---

## Freeze protection ownership

Authoritative owners:

```text
FB_Heating_Safety_Gate
FB_Heating_Safe_State
```

Authority:

```text
- freeze-safe runtime state;
- emergency-safe circulation semantics;
- freeze protection ownership.
```

Historical absorbed donor:

```text
FB_FloorHeating_Freeze_Protection
```

---

## Allocation ownership

Authoritative owner:

```text
FB_Heating_Allocation_Filter
```

Authority:

```text
- bounded allocation authorization;
- manifold admission filtering;
- degraded manifold filtering;
- availability filtering.
```

Allowed upstream influence:

```text
FB_Heating_Policy_Priority_Bridge
```

Historical absorbed donors:

```text
FB_Heating_Decision_Context
FB_Heating_Thermal_Allocation
```

---

## Priority semantics ownership

Authoritative owner:

```text
FB_Heating_Policy_Priority_Bridge
```

Authority:

```text
- effective runtime priorities;
- bounded policy multipliers;
- bounded priority reduction.
```

---

## Manifold execution ownership

Primary owner:

```text
FB_Heating_Manifold_Control
```

Authority:

```text
- manifold valve realization;
- manifold pump realization;
- manifold runtime realization;
- DHW suppression realization;
- freeze minimum realization.
```

Explicit bounded finalization owner:

```text
FB_Heating_Runtime_Service_Gating_Phase
```

Allowed finalization authority:

```text
- out-of-service suppression;
- freeze hardware suppression;
- bounded runtime masking.
```

Important:

```text
finalization remains explicit,
phase-oriented and bounded.
```

Forbidden ownership:

```text
- detached override layers;
- Runtime_* governance scaffold;
- telemetry-only layers.
```

---

## Boiler/OpenTherm ownership

Authoritative owner:

```text
FB_Heating_Boiler_Control
```

Authority:

```text
- boiler enable;
- OpenTherm interaction;
- supply target realization;
- thermal source coordination.
```

Verified helper chain:

```text
FB_Boiler_Cascade_Manager
→ FB_Boiler_OpenTherm_Interface
```

Historical dangerous donor:

```text
FB_Heating_Override_Layer
```

Forbidden ownership:

```text
- detached override semantics;
- Runtime_* governance scaffold;
- diagnostics-only layers.
```

---

## Runtime observability ownership

Authoritative owner:

```text
FB_Heating_Runtime_Observability
```

Authority:

```text
- telemetry projection;
- runtime publication;
- allocation observability;
- policy observability;
- explainability projection.
```

Explicit non-authority:

```text
- no valve ownership;
- no pump ownership;
- no boiler ownership;
- no DHW ownership;
- no safety ownership.
```

---

## Observer/diagnostics ownership

Authoritative governance/observer layers:

```text
FB_Heating_Runtime_Observer_Phase
FB_Heating_Runtime_Observer
FB_Heating_Runtime_Observer_Authorization
FB_Heating_Runtime_Diagnostics_Phase
```

Allowed authority:

```text
- diagnostics publication;
- sequencing validation;
- governance validation;
- lifecycle telemetry;
- observation publication.
```

Forbidden authority:

```text
- runtime control;
- pump control;
- valve control;
- OpenTherm control;
- DHW control;
- safety ownership.
```

Governance rules:

```text
Governance_Locked := TRUE
Observation-only semantics
No detached runtime authority
```

---

# Runtime_* family rules

## Allowed

```text
- observability;
- telemetry;
- diagnostics;
- governance;
- sequencing validation;
- forensic reconstruction.
```

---

## Forbidden

```text
- hidden runtime authority;
- detached orchestration execution;
- output ownership;
- duplicate writers;
- alternate runtime execution.
```

---

# GVL ownership policy

## Runtime control state

Must be written ONLY by authoritative runtime ownership chain.

---

## Observability state

May be written ONLY by approved observability publishers.

Examples:

```text
FB_Heating_Runtime_Observability
FB_Heating_Runtime_Observer
```

---

## Governance state

May be written ONLY by approved governance infrastructure.

Required invariant:

```text
no runtime authority attachment.
```

---

# Explicit deterministic finalization phases

Verified finalization phases:

```text
FB_Heating_Runtime_Service_Gating_Phase
FB_Heating_Runtime_State_Publication_Phase
FB_Heating_Runtime_Output_Projection_Phase
```

Required invariant:

```text
finalization must remain explicit and phase-oriented.
```

Forbidden:

```text
hidden output finalization layers.
```

---

# Explicit forbidden architectures

Forbidden:

```text
- detached orchestration runtime;
- hidden override shell;
- second detached runtime authority path;
- Runtime_* direct execution;
- telemetry-driven control ownership;
- governance-driven actuation.
```

---

# Strategic conclusion

The repository now follows:

```text
explicit deterministic runtime ownership
+
phase-oriented orchestration
+
bounded helper execution
+
explicit finalization phases
+
passive governance/observability infrastructure
```

This separation must remain explicit and continuously verified.
