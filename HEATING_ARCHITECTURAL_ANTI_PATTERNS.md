# HEATING_ARCHITECTURAL_ANTI_PATTERNS

# Purpose

This document formalizes architectural anti-patterns and governance violations for the heating runtime.

Primary goals:

```text
- prevent architectural drift;
- prevent detached runtime resurrection;
- prevent hidden authority growth;
- prevent duplicate runtime writers;
- prevent helper escalation;
- prevent telemetry/control coupling;
- preserve deterministic phase sequencing.
```

This document converts accumulated runtime audits into:

```text
long-term architectural protection rules.
```

---

# Core invariant

The invariant that must never be violated:

```text
single active runtime ownership chain
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

Any architecture bypassing this chain is a governance violation.

---

# Forbidden architectural patterns

## AP-001 — Detached orchestration runtime

Forbidden:

```text
creating runtime orchestration
outside the active ownership chain
```

Examples:

```text
- parallel orchestration shells;
- detached execution coordinators;
- alternate heating runtime paths;
- hidden runtime supervisors.
```

Reason:

```text
creates second authority path
```

Historical context:

```text
historical orchestration donors were removed.
```

---

## AP-002 — Hidden runtime writers

Forbidden:

```text
runtime actuation writes
not explicitly documented as ownership
```

Examples:

```text
- hidden valve writers;
- hidden pump writers;
- hidden OpenTherm writers;
- hidden manifold suppressors.
```

Reason:

```text
creates invisible authority overlap
```

---

## AP-003 — Runtime_* actuation

Forbidden:

```text
Runtime_* family directly controlling runtime outputs
```

Allowed:

```text
- observability;
- diagnostics;
- telemetry;
- sequencing validation;
- governance validation;
- forensic reconstruction.
```

Reason:

```text
Runtime_* family is governance/observability infrastructure,
not runtime authority.
```

---

## AP-004 — Telemetry-driven control

Forbidden:

```text
telemetry or analytics layers
performing direct runtime actuation
```

Allowed:

```text
telemetry publication
without actuation ownership.
```

---

## AP-005 — Governance-driven actuation

Forbidden:

```text
governance scaffold
performing runtime execution
```

Required governance locks:

```text
Governance_Locked := TRUE
Observation-only semantics
```

---

## AP-006 — Helper authority escalation

Forbidden:

```text
bounded helpers silently becoming runtime owners
```

Allowed:

```text
bounded helper semantics
inside explicit ownership boundaries.
```

Verified acceptable examples:

```text
FB_Boiler_Cascade_Manager
FB_Boiler_OpenTherm_Interface
FB_Valve_Test_Manager
```

---

## AP-007 — Detached override resurrection

Forbidden:

```text
reintroducing detached override semantics
```

Historical reference:

```text
FB_Heating_Override_Layer
```

---

## AP-008 — Mixed projection/control layers

Forbidden:

```text
projection and runtime authority
inside the same logical layer
```

Required separation:

```text
projection
≠
control
```

---

## AP-009 — Implicit safety ownership

Forbidden:

```text
safety semantics spread implicitly
across unrelated helpers
```

Required explicit owners:

```text
FB_Heating_Safety_Gate
FB_Heating_Safe_State
```

---

## AP-010 — Undocumented finalization layers

Forbidden:

```text
runtime output finalization
without explicit documentation
```

Reason:

```text
creates ownership ambiguity
```

Current verified finalization layers:

```text
Service_Gating_Phase
State_Publication_Phase
Output_Projection_Phase
```

---

# Required architectural patterns

## RP-001 — Single active ownership chain

Required:

```text
all runtime actuation
must remain inside
single active runtime chain.
```

---

## RP-002 — Explicit helper boundaries

Required:

```text
helper semantics must remain bounded and explicit.
```

Helpers may:

```text
- realize execution;
- transport commands;
- perform bounded arbitration;
- support maintenance/testing.
```

Helpers may NOT:

```text
- become detached authority centers;
- mutate unrelated runtime domains.
```

---

## RP-003 — Explicit override modes

Required:

```text
all override semantics
must be explicit and discoverable.
```

---

## RP-004 — Explicit finalization ownership

Required:

```text
all finalization layers
must remain explicit and documented.
```

---

## RP-005 — Observability-only Runtime_* scaffold

Required:

```text
Runtime_* family
must remain governance/observability oriented.
```

Forbidden:

```text
runtime actuation.
```

---

## RP-006 — Evidence-based ownership verification

Required:

```text
ownership claims must be validated
against actual write paths.
```

---

# Mandatory governance review triggers

The following changes REQUIRE governance review:

```text
- new runtime writer;
- helper begins mutating outputs;
- new GVL mutation path;
- Runtime_* write expansion;
- new override semantics;
- new finalization layer;
- new OpenTherm arbitration;
- new manifold suppression logic;
- new safety bypass path.
```

---

# Mandatory verification workflow

Before approving runtime ownership changes:

```text
1. verify ownership consistency;
2. verify write-boundary consistency;
3. verify governance consistency;
4. verify no detached authority path;
5. verify no Runtime_* actuation;
6. verify no helper escalation;
7. verify evidence-level write paths.
```

---

# Current architectural status

Current evidence indicates:

```text
- detached orchestration runtime removed;
- detached override runtime removed;
- Runtime_* family remains observability-oriented;
- helper authority escalation not detected;
- deterministic phase sequencing established;
- active runtime ownership chain remains bounded.
```

Primary remaining risk:

```text
future architectural drift.
```

---

# Strategic conclusion

The repository evolved from:

```text
legacy orchestration cleanup
```

into:

```text
deterministic runtime governance maintenance.
```

Primary engineering goal:

```text
prevent future architectural drift
while preserving bounded ownership and runtime clarity.
```
