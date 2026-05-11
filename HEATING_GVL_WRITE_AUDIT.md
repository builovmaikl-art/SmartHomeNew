# HEATING_GVL_WRITE_AUDIT

# Purpose

This document formalizes runtime write-boundary enforcement for the heating architecture.

The goal is to prevent:

```text
- duplicate writers;
- hidden side-effect writers;
- telemetry-to-control drift;
- governance-to-control drift;
- projection/control confusion;
- accidental runtime authority bypass.
```

This document extends:

```text
HEATING_RUNTIME_GOVERNANCE_CLASSIFICATION.md
HEATING_RUNTIME_OWNERSHIP_MATRIX.md
```

into:

```text
practical runtime write enforcement.
```

---

# Core enforcement invariant

The invariant that must never be violated:

```text
single authoritative writer per runtime authority domain
```

Meaning:

```text
runtime ownership
must match
runtime write authority.
```

---

# Write-boundary model

## Authoritative writer

Definition:

```text
single runtime owner
allowed to mutate authoritative control state
```

---

## Observers

Allowed:

```text
- read runtime state;
- aggregate telemetry;
- publish diagnostics;
- project analytics;
- validate sequencing.
```

Forbidden:

```text
- mutate runtime control state;
- alter heating execution;
- alter boiler ownership;
- alter valve ownership;
- alter safety authority.
```

---

## Governance scaffold

Allowed:

```text
- validate contracts;
- validate sequencing;
- validate attachment policy;
- validate integration consistency.
```

Forbidden:

```text
- runtime actuation;
- control ownership;
- hidden side-effect writes.
```

---

# Runtime authority write matrix

## Heating runtime execution state

Authoritative writer:

```text
FB_Heating_System_Manager
```

Allowed writes:

```text
- runtime sequencing state;
- active heating execution state;
- manifold execution coordination;
- bounded runtime coordination.
```

Forbidden writers:

```text
- Runtime_* governance scaffold;
- telemetry aggregators;
- anomaly analyzers;
- detached orchestration shells.
```

---

## Circuit thermal protection state

Authoritative writer:

```text
FB_Heating_Circuit_Control
```

Allowed writes:

```text
- overheat shutdown state;
- circuit enable state;
- thermal protection valve state.
```

Forbidden writers:

```text
- Runtime_* analytics;
- telemetry-only layers;
- governance scaffold.
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
- freeze-safe state;
- freeze circulation requests;
- emergency-safe heating state.
```

Forbidden writers:

```text
- Runtime_* scaffold;
- telemetry-only layers;
- detached override logic.
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
- bounded thermal allocation;
- degraded manifold exclusion;
- allocation enable decisions.
```

Allowed upstream influence:

```text
FB_Heating_Policy_Priority_Bridge
```

Forbidden writers:

```text
- Runtime_* governance scaffold;
- anomaly analytics;
- detached allocation logic.
```

---

## Priority runtime state

Authoritative writer:

```text
FB_Heating_Policy_Priority_Bridge
```

Allowed writes:

```text
- effective priority values;
- bounded priority buckets;
- policy multipliers;
- neutral priority fallback semantics.
```

Forbidden writers:

```text
- Runtime_* analytics;
- telemetry aggregators;
- detached policy orchestrators.
```

---

## Manifold execution state

Authoritative writer:

```text
FB_Heating_Manifold_Control
```

Allowed writes:

```text
- manifold valve commands;
- manifold enable execution;
- manifold runtime realization.
```

Forbidden writers:

```text
- Runtime_* governance scaffold;
- telemetry-only layers;
- analytics layers.
```

---

## Boiler/OpenTherm runtime state

Authoritative writer:

```text
FB_Heating_Boiler_Control
```

Allowed writes:

```text
- boiler enable;
- OpenTherm command state;
- supply target execution;
- thermal source coordination.
```

Forbidden writers:

```text
- Runtime_* scaffold;
- governance-only layers;
- detached override semantics.
```

Critical historical risk:

```text
FB_Heating_Override_Layer
```

Important:

```text
override semantics must never reappear
as detached write authority.
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
- runtime observability projection;
- allocation observability state;
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

## Governance state

Allowed governance writers:

```text
FB_Heating_Runtime_Orchestration_Shell
FB_Heating_Runtime_Coordinator
FB_Heating_Runtime_Integration_Bridge_Manager
FB_Heating_Runtime_Contract_Validator
```

Allowed writes:

```text
- governance validation state;
- sequencing validation state;
- attachment policy state;
- runtime consistency state.
```

Forbidden writes:

```text
- runtime outputs;
- control actuation;
- valve commands;
- boiler commands;
- safety commands.
```

Mandatory governance locks:

```text
Governance_Locked := TRUE
Runtime_Attachment_Allowed := FALSE
Observation-only semantics
```

---

# Runtime_* family enforcement policy

## Allowed Runtime_* write domains

```text
- observability;
- diagnostics;
- telemetry;
- governance validation;
- sequencing validation;
- forensic reconstruction metadata.
```

---

## Forbidden Runtime_* write domains

```text
- heating actuation;
- valve outputs;
- pump outputs;
- OpenTherm outputs;
- DHW actuation;
- emergency override ownership.
```

---

# Forbidden write patterns

The following write patterns are forbidden:

```text
- telemetry-driven runtime actuation;
- governance-driven control execution;
- analytics-driven valve ownership;
- hidden side-effect writers;
- detached override writers;
- duplicate boiler writers;
- duplicate manifold writers.
```

---

# Verification workflow

Before adding ANY new runtime writer:

```text
1. identify authoritative owner;
2. verify no existing writer overlap;
3. verify ownership matrix consistency;
4. verify governance classification consistency;
5. verify no Runtime_* authority drift;
6. verify no second runtime authority path.
```

---

# Runtime audit status

Current audit result:

```text
No verified Runtime_* hidden authority writers detected.
```

Current architecture state:

```text
runtime authority appears separated from
observability/governance infrastructure.
```

---

# Strategic conclusion

The heating repository now follows:

```text
single-writer runtime ownership
+
bounded policy integration
+
passive observability/governance infrastructure
+
explicit write-boundary enforcement
```

This separation must remain explicit and continuously verified.
