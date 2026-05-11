# HEATING_RUNTIME_OWNERSHIP_MATRIX

# Purpose

This document defines authoritative runtime ownership boundaries for the heating architecture.

The goal is to prevent:

```text
- duplicate writers;
- hidden authority overlap;
- accidental orchestration resurrection;
- projection/control confusion;
- unsafe reconnects;
- runtime ownership drift.
```

This document is authoritative for:

```text
- runtime authority ownership;
- allowed write boundaries;
- projection-only layers;
- observability-only layers;
- governance-only layers;
- safety override ownership.
```

---

# Core invariant

The invariant that must never be violated:

```text
single active runtime authority path
```

Authoritative runtime path:

```text
PRG_Heating
→ FB_Heating_System_Manager
    → Circuit_Control
    → Demand_Map
    → Policy_Priority_Bridge
    → Allocation_Filter
    → Runtime_Observability
    → Manifold_Control
    → Boiler_Control
```

No additional orchestration layer may bypass this chain.

---

# Ownership model

## Rule 1 — Single writer principle

Every runtime authority domain must have:

```text
ONE authoritative writer
```

Additional blocks may:

```text
- observe;
- validate;
- project telemetry;
- publish diagnostics;
- calculate analytics.
```

But may NOT:

```text
- override ownership silently;
- duplicate control outputs;
- create secondary authority paths.
```

---

## Rule 2 — Projection ≠ control

Projection layers:

```text
- Runtime_Observability;
- telemetry aggregators;
- anomaly correlators;
- governance scaffold.
```

must never become:

```text
runtime controllers.
```

---

## Rule 3 — Governance ≠ orchestration

Governance scaffold may:

```text
- validate sequencing;
- validate contracts;
- validate phase consistency;
- validate attachment policy.
```

But may NOT:

```text
- own runtime execution;
- own pumps;
- own valves;
- own OpenTherm;
- own DHW.
```

---

# Authority ownership matrix

## Heating master runtime ownership

Authoritative owner:

```text
FB_Heating_System_Manager
```

Authority:

```text
- heating runtime sequencing;
- active heating execution chain;
- runtime coordination;
- bounded policy integration;
- allocation integration;
- manifold execution ordering.
```

Forbidden external ownership:

```text
- detached orchestration shells;
- Runtime_* governance scaffold;
- historical override layers.
```

---

## Circuit thermal protection ownership

Authoritative owner:

```text
FB_Heating_Circuit_Control
```

Authority:

```text
- floor temperature evaluation;
- overheat shutdown;
- valve thermal protection decisions;
- circuit enable state.
```

Forbidden ownership:

```text
- Runtime_* analytics;
- detached protection duplicates;
- telemetry layers.
```

Historical absorbed donors:

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
- freeze detection;
- freeze-safe operating mode;
- freeze circulation semantics;
- emergency-safe heating preservation.
```

Forbidden ownership:

```text
- Runtime_* governance scaffold;
- detached freeze protection duplicates;
- historical override layers.
```

Historical absorbed donors:

```text
FB_FloorHeating_Freeze_Protection
```

---

## Allocation authority ownership

Authoritative owner:

```text
FB_Heating_Allocation_Filter
```

Authority:

```text
- bounded thermal allocation;
- manifold admission filtering;
- manifold thermal budget decisions;
- degraded manifold exclusion;
- availability filtering.
```

Allowed upstream influence:

```text
FB_Heating_Policy_Priority_Bridge
```

Forbidden ownership:

```text
- detached allocation orchestrators;
- historical thermal allocation runtime;
- Runtime_* analytics.
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
- zone priority bias;
- manifold effective priority;
- policy priority multiplier;
- bounded priority buckets;
- neutral unset handling.
```

Forbidden ownership:

```text
- detached policy orchestrators;
- Runtime_* governance scaffold;
- telemetry-only layers.
```

---

## Manifold execution ownership

Authoritative owner:

```text
FB_Heating_Manifold_Control
```

Authority:

```text
- manifold valve execution;
- manifold runtime enable;
- manifold command realization.
```

Forbidden ownership:

```text
- Runtime_* scaffold;
- telemetry layers;
- detached override shells.
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
- supply target execution;
- thermal source coordination.
```

Forbidden ownership:

```text
- Runtime_* scaffold;
- detached override layers;
- diagnostics-only blocks.
```

Historical dangerous donor:

```text
FB_Heating_Override_Layer
```

Important:

```text
historical override semantics
must never be reintroduced
as detached authority layer.
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
- runtime state projection;
- allocation observability;
- policy observability.
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

## Governance / sequencing ownership

Authoritative governance scaffold:

```text
FB_Heating_Runtime_Orchestration_Shell
FB_Heating_Runtime_Coordinator
FB_Heating_Runtime_Integration_Bridge_Manager
FB_Heating_Runtime_Contract_Validator
```

Allowed authority:

```text
- sequencing validation;
- governance validation;
- runtime contract validation;
- attachment validation;
- integration consistency checks.
```

Forbidden authority:

```text
- runtime control;
- pump control;
- valve control;
- OpenTherm control;
- DHW control;
- emergency override ownership.
```

Governance locks:

```text
Governance_Locked := TRUE
Runtime_Attachment_Allowed := FALSE
Observation-only semantics
```

---

# Runtime_* family rules

## Allowed

```text
- observability;
- analytics;
- telemetry;
- diagnostics;
- governance;
- forensic reconstruction;
- sequencing validation.
```

---

## Forbidden

```text
- hidden runtime authority;
- detached orchestration execution;
- output ownership;
- duplicate writers;
- alternate heating runtime.
```

---

# GVL ownership policy

## Runtime control state

Must be written ONLY by authoritative runtime owners.

---

## Observability state

May be written by:

```text
FB_Heating_Runtime_Observability
```

and approved telemetry publishers.

---

## Governance state

May be written by:

```text
Runtime_* governance scaffold
```

ONLY if:

```text
- read-only semantics preserved;
- no runtime authority attached.
```

---

# Explicit forbidden architectures

The following architectures are forbidden:

```text
- detached orchestration runtime;
- hidden override shell;
- second runtime authority path;
- Runtime_* direct runtime execution;
- telemetry-driven control ownership;
- governance-driven actuation.
```

---

# Strategic conclusion

The repository architecture now follows:

```text
clean runtime authority
+
bounded policy integration
+
passive observability/governance scaffold
```

This separation must remain explicit and preserved.
