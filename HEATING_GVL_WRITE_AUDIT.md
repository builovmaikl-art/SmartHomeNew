# HEATING_GVL_WRITE_AUDIT

# Purpose

This document formalizes runtime write-boundary enforcement for the heating architecture.

Primary goals:

```text
- prevent duplicate writers;
- prevent hidden side-effect writers;
- prevent detached runtime authority;
- prevent telemetry/control coupling;
- prevent governance/control coupling;
- preserve deterministic phase sequencing;
- preserve explicit ownership boundaries.
```

This document extends:

```text
HEATING_RUNTIME_GOVERNANCE_CLASSIFICATION.md
HEATING_RUNTIME_OWNERSHIP_MATRIX.md
```

into:

```text
practical runtime write-boundary enforcement.
```

---

# Core invariant

The invariant that must never be violated:

```text
single authoritative runtime ownership chain per authority domain
```

Meaning:

```text
runtime write authority
must remain inside
explicit active runtime ownership chain.
```

Detached writers are forbidden.

---

# Current canonical runtime architecture

Verified orchestration:

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

Verified subsystem ownership:

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

---

# Write-boundary model

## Runtime orchestrator layer

Authoritative role:

```text
PRG_Heating
```

Allowed responsibilities:

```text
- deterministic phase sequencing;
- runtime context coordination;
- bounded phase invocation ordering.
```

Forbidden responsibilities:

```text
- detached actuation ownership;
- hidden output mutation;
- parallel runtime execution paths.
```

---

## Heating runtime execution state

Authoritative writer:

```text
FB_Heating_System_Manager
```

Allowed writes:

```text
- runtime execution state;
- manifold execution coordination;
- bounded runtime coordination;
- heating realization state.
```

Forbidden writers:

```text
- Runtime_* governance scaffold;
- telemetry aggregators;
- detached orchestration layers;
- observer infrastructure.
```

---

## Circuit thermal protection state

Authoritative writer:

```text
FB_Heating_Circuit_Control
```

Allowed writes:

```text
- circuit enable state;
- thermal protection state;
- bounded thermal suppression.
```

Forbidden writers:

```text
- Runtime_* observability scaffold;
- detached diagnostics layers;
- governance infrastructure.
```

---

## Freeze protection state

Authoritative writers:

```text
FB_Heating_Safety_Gate
FB_Heating_Safe_State
```

Allowed writes:

```text
- freeze-safe runtime state;
- emergency-safe circulation state;
- safety shutdown state.
```

Forbidden writers:

```text
- Runtime_* scaffold;
- telemetry-only layers;
- detached override semantics.
```

---

## Allocation runtime state

Authoritative writer:

```text
FB_Heating_Allocation_Filter
```

Allowed writes:

```text
- manifold admission decisions;
- bounded allocation authorization;
- degraded manifold filtering;
- allocation enable decisions.
```

Allowed upstream influence:

```text
FB_Heating_Policy_Priority_Bridge
```

Forbidden writers:

```text
- Runtime_* governance scaffold;
- analytics-only infrastructure;
- detached allocation layers.
```

---

## Priority runtime state

Authoritative writer:

```text
FB_Heating_Policy_Priority_Bridge
```

Allowed writes:

```text
- effective runtime priority values;
- bounded policy multipliers;
- bounded priority reductions.
```

Forbidden writers:

```text
- Runtime_* analytics;
- detached policy orchestrators;
- governance-only infrastructure.
```

---

## Manifold execution state

Primary writer:

```text
FB_Heating_Manifold_Control
```

Allowed writes:

```text
- manifold valve realization;
- manifold pump realization;
- DHW suppression realization;
- freeze minimum realization.
```

Allowed bounded finalization:

```text
FB_Heating_Runtime_Service_Gating_Phase
```

Allowed finalization writes:

```text
- out-of-service suppression;
- freeze hardware suppression;
- bounded runtime masking.
```

Important:

```text
this is an explicit deterministic finalization phase,
not a detached second runtime authority.
```

Forbidden writers:

```text
- Runtime_* governance scaffold;
- analytics-only layers;
- detached override layers.
```

---

## Boiler/OpenTherm runtime state

Authoritative writer:

```text
FB_Heating_Boiler_Control
```

Allowed writes:

```text
- boiler enable state;
- OpenTherm command realization;
- supply target realization;
- thermal source coordination.
```

Verified bounded helper chain:

```text
FB_Boiler_Cascade_Manager
→ FB_Boiler_OpenTherm_Interface
```

Forbidden writers:

```text
- Runtime_* governance scaffold;
- detached override semantics;
- telemetry-only infrastructure.
```

Historical risk reference:

```text
FB_Heating_Override_Layer
```

---

## Runtime observability state

Authoritative writer:

```text
FB_Heating_Runtime_Observability
```

Allowed writes:

```text
- telemetry publication;
- explainability projection;
- allocation observability;
- diagnostics publication.
```

Forbidden writes:

```text
- valve execution;
- pump execution;
- boiler execution;
- safety actuation.
```

---

## Observer/governance state

Allowed observer/governance writers:

```text
FB_Heating_Runtime_Observer_Phase
FB_Heating_Runtime_Observer
FB_Heating_Runtime_Observer_Authorization
FB_Heating_Runtime_Diagnostics_Phase
```

Allowed writes:

```text
- observation publication;
- sequencing validation;
- diagnostics publication;
- governance validation;
- lifecycle telemetry.
```

Forbidden writes:

```text
- runtime outputs;
- boiler commands;
- manifold commands;
- safety commands;
- physical actuation.
```

Mandatory governance rules:

```text
Governance_Locked := TRUE
Observation-only semantics
No detached runtime authority
```

---

# Runtime_* family enforcement policy

## Allowed Runtime_* domains

```text
- observability;
- diagnostics;
- telemetry;
- governance validation;
- sequencing validation;
- forensic reconstruction metadata.
```

---

## Forbidden Runtime_* domains

```text
- heating actuation;
- valve outputs;
- pump outputs;
- OpenTherm outputs;
- DHW actuation;
- emergency override ownership.
```

---

# Explicit deterministic finalization layers

Verified explicit finalization phases:

```text
FB_Heating_Runtime_Service_Gating_Phase
FB_Heating_Runtime_State_Publication_Phase
FB_Heating_Runtime_Output_Projection_Phase
```

Required invariant:

```text
finalization must remain explicit,
bounded and phase-oriented.
```

Forbidden:

```text
hidden finalization layers
or detached output suppression.
```

---

# Forbidden write patterns

Forbidden:

```text
- telemetry-driven runtime actuation;
- governance-driven control execution;
- hidden side-effect writers;
- detached override writers;
- duplicate boiler writers;
- duplicate manifold writers;
- Runtime_* authority escalation;
- hidden publication layers.
```

---

# Verification workflow

Before adding ANY runtime writer:

```text
1. identify authoritative owner;
2. verify no detached writer overlap;
3. verify ownership matrix consistency;
4. verify governance consistency;
5. verify no Runtime_* authority drift;
6. verify deterministic phase consistency;
7. verify evidence-level write paths.
```

---

# Current runtime audit result

Current verified result:

```text
- no detached Runtime_* authority detected;
- deterministic phase sequencing established;
- explicit finalization phases established;
- helper authority escalation not detected;
- write-boundary governance remains bounded.
```

Primary remaining risk:

```text
future architectural drift.
```

---

# Strategic conclusion

The repository now follows:

```text
single deterministic runtime ownership chain
+
explicit phase-oriented orchestration
+
bounded policy integration
+
explicit finalization phases
+
passive observability/governance infrastructure
+
explicit write-boundary enforcement
```

This separation must remain explicit and continuously verified.
