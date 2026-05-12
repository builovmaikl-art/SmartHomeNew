# HEATING_RUNTIME_GOVERNANCE_CLASSIFICATION

# Purpose

This document defines governance classification and authority boundaries for the `FB_Heating_Runtime_*` family.

Primary goals:

```text
- prevent detached runtime resurrection;
- prevent duplicate authority paths;
- prevent Runtime_* actuation drift;
- preserve bounded governance semantics;
- preserve deterministic phase sequencing;
- preserve explicit ownership boundaries.
```

Current repository phase:

```text
DETERMINISTIC PHASE-ORIENTED RUNTIME MAINTENANCE
```

---

# Core architectural invariant

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

Runtime_* infrastructure is NOT allowed to create:

```text
- parallel orchestration;
- detached authority paths;
- duplicate safety ownership;
- hidden runtime execution.
```

---

# Runtime governance model

The repository evolved toward explicit separation:

```text
ACTIVE RUNTIME OWNERSHIP
≠
RUNTIME GOVERNANCE / OBSERVABILITY
```

Meaning:

```text
Runtime_* family primarily provides:
- observability;
- diagnostics;
- sequencing validation;
- governance validation;
- telemetry aggregation;
- explainability;
- forensic reconstruction.
```

NOT:

```text
runtime actuation ownership.
```

---

# Classification groups

## CLASS A — Active observability participants

Definition:

```text
runtime-adjacent infrastructure
without runtime authority ownership
```

Characteristics:

```text
- telemetry publication;
- runtime diagnostics;
- sequencing validation;
- event tracking;
- explainability projection.
```

Authority restrictions:

```text
- no pump ownership;
- no valve ownership;
- no OpenTherm ownership;
- no DHW ownership;
- no safety ownership.
```

Representative files:

```text
FB_Heating_Runtime_Observability
FB_Heating_Runtime_Observer
FB_Heating_Runtime_Observer_Phase
FB_Heating_Runtime_Diagnostics_Phase
```

---

## CLASS B — Passive forensic/analytics infrastructure

Definition:

```text
read-only analytical infrastructure
```

Characteristics:

```text
- anomaly correlation;
- replay analysis;
- timeline reconstruction;
- telemetry aggregation;
- confidence analysis;
- diagnostics analytics.
```

Allowed behavior:

```text
- read runtime state;
- aggregate telemetry;
- classify anomalies;
- publish diagnostics.
```

Forbidden behavior:

```text
- runtime control;
- output ownership;
- safety actuation;
- detached execution.
```

---

## CLASS C — Governance/validation scaffold

Definition:

```text
runtime governance infrastructure
without runtime attachment authority
```

Characteristics:

```text
- sequencing validation;
- governance validation;
- runtime contract validation;
- lifecycle validation;
- integration boundary verification.
```

Important:

```text
these layers may contain orchestration semantics
WITHOUT becoming orchestration engines.
```

Mandatory governance rules:

```text
Governance_Locked := TRUE
Observation-only semantics
No detached runtime authority
```

Representative files:

```text
FB_Heating_Runtime_Observer_Authorization
FB_Heating_Runtime_Contract_Validator
FB_Heating_Runtime_Phase_Sequencing_Validator
```

---

## CLASS D — Reserved scaffold

Definition:

```text
future or partially integrated scaffold
without active runtime ownership
```

Rules:

```text
- no blind reconnect;
- no blind cleanup;
- governance classification required before modification.
```

---

## CLASS E — True dead files

Definition:

```text
files with:
- no runtime participation;
- no governance role;
- no observability role;
- no forensic value;
- no future scaffold value.
```

Current verified status:

```text
No confirmed active Runtime_* CLASS E files.
```

---

# Explicit non-authority rules

The following MUST remain outside Runtime_* ownership:

```text
- pump authority;
- valve authority;
- OpenTherm authority;
- DHW authority;
- safety shutdown authority;
- safe-state ownership;
- boiler enable ownership.
```

These remain owned by:

```text
FB_Heating_System_Manager
FB_Heating_Circuit_Control
FB_Heating_Manifold_Control
FB_Heating_Boiler_Control
FB_Heating_Safety_Gate
FB_Heating_Safe_State
```

---

# Runtime reconnect policy

## Forbidden

```text
- reconnect Runtime_* blindly;
- use governance scaffold as runtime controller;
- bypass deterministic phase chain;
- bypass active ownership hierarchy.
```

---

## Allowed

```text
- observability integration;
- diagnostics integration;
- telemetry publication;
- forensic analysis;
- governance validation;
- sequencing verification.
```

---

# Cleanup policy

Current policy:

```text
Runtime_* family is NOT blanket cleanup target.
```

Cleanup allowed ONLY if ALL are proven:

```text
- no runtime participation;
- no governance role;
- no observability role;
- no forensic value;
- no future scaffold role.
```

---

# Current architectural status

Verified state:

```text
- detached orchestration runtime removed;
- detached override runtime removed;
- deterministic phase sequencing established;
- Runtime_* family remains governance-oriented;
- hidden Runtime_* actuation not detected;
- helper authority escalation not detected.
```

Primary remaining risk:

```text
future architectural drift.
```

---

# Strategic conclusion

The repository evolved from:

```text
legacy detached orchestration
```

into:

```text
explicit deterministic runtime ownership
+
phase-oriented orchestration
+
bounded helper execution
+
passive governance/observability infrastructure
```

This separation must remain explicit and continuously verified.
