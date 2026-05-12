# HEATING_RUNTIME_GOVERNANCE_CLASSIFICATION

# Purpose

This document defines the governance classification for the `FB_Heating_Runtime_*` family.

The goal is to prevent:

```text
- accidental reconnect of detached orchestration layers;
- destruction of observability infrastructure;
- duplicate runtime authority paths;
- misuse of governance scaffold as runtime control;
- unsafe cleanup of passive forensic infrastructure.
```

This document formalizes the verified runtime governance model.

Current phase:

```text
GOVERNED RUNTIME MAINTENANCE
```

---

# Core architectural invariant

The invariant that must never be violated:

```text
single active runtime ownership chain
```

Verified active runtime chain:

```text
PRG_Heating
→ FB_Heating_System_Manager
    → Safety_Gate
    → Safe_State
    → Circuit_Control
    → Demand_Map
    → Policy_Priority_Bridge
    → Allocation_Filter
    → Runtime_Observability
    → Manifold_Control
    → System_Manager post-manifold safety/test finalization
    → Boiler_Control
```

`FB_Heating_Runtime_*` files are NOT allowed to create:

```text
- parallel runtime orchestration;
- alternate heating ownership;
- duplicate safety authority;
- detached control execution.
```

---

# Runtime governance model

The repository evolved toward a split architecture:

```text
ACTIVE RUNTIME OWNERSHIP
separated from
RUNTIME OBSERVABILITY / FORENSICS / GOVERNANCE
```

Meaning:

```text
Runtime_* family mostly provides:
- observability;
- diagnostics;
- governance validation;
- sequencing contracts;
- telemetry aggregation;
- anomaly analysis;
- forensic reconstruction.
```

NOT:

```text
runtime control ownership.
```

---

# Classification groups

## CLASS A — Active runtime observability participants

Definition:

```text
actively instantiated or runtime-adjacent
but not authority-owning
```

Characteristics:

```text
- projection;
- telemetry publication;
- runtime diagnostics;
- sequencing validation;
- event tracking.
```

Authority restrictions:

```text
- must not own pumps;
- must not own valves;
- must not own OpenTherm;
- must not own DHW;
- must not own safety shutdown.
```

Representative files:

```text
FB_Heating_Runtime_Observability
FB_Heating_Runtime_Event_Manager
FB_Heating_Runtime_Synchronization_Monitor
FB_Heating_Runtime_Phase_Sequencing_Validator
FB_Heating_Runtime_Contract_Validator
```

---

## CLASS B — Passive intelligence / forensic analytics

Definition:

```text
read-only analytical infrastructure
```

Characteristics:

```text
- anomaly correlation;
- drift analysis;
- predictive scoring;
- replay analysis;
- timeline reconstruction;
- telemetry aggregation;
- confidence analysis.
```

Important:

```text
These are NOT runtime controllers.
```

Allowed behavior:

```text
- read runtime state;
- aggregate telemetry;
- classify anomalies;
- reconstruct event chains;
- produce diagnostics.
```

Forbidden behavior:

```text
- output ownership;
- runtime control;
- direct heating actuation;
- emergency ownership.
```

---

## CLASS C — Governance / contract scaffold

Definition:

```text
runtime governance infrastructure
without runtime attachment authority
```

Characteristics:

```text
- sequencing contracts;
- governance validation;
- attachment locks;
- integration boundaries;
- orchestration projection;
- runtime contract verification.
```

Important:

```text
These files may contain orchestration semantics
WITHOUT being active orchestration engines.
```

Critical governance locks already verified:

```text
Governance_Locked := TRUE
Runtime_Attachment_Allowed := FALSE
Runtime_Attachment_Active := FALSE
Observation-only semantics
```

Representative files:

```text
FB_Heating_Runtime_Orchestration_Shell
FB_Heating_Runtime_Coordinator
FB_Heating_Runtime_Integration_Bridge_Manager
FB_Heating_Runtime_Contract_Validator
```

---

## CLASS D — Future reserved scaffold

Definition:

```text
future architecture placeholders
not currently connected to active runtime ownership
```

Rules:

```text
- no blind reconnect;
- no blind cleanup;
- classification required before modification.
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
No confirmed CLASS E Runtime_* files.
```

Meaning:

```text
Runtime_* family is intentional governance/observability architecture,
not dead legacy garbage.
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

Important clarification:

```text
Manifold_Control is the primary actuator helper.
System_Manager remains bounded final post-manifold finalizer.
```

---

# Runtime reconnect policy

## Forbidden

```text
- reconnect Runtime_* files blindly;
- reconnect orchestration shells directly;
- use governance scaffold as runtime controller;
- bypass active runtime ownership chain.
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
Runtime_* family is NOT primary cleanup target.
```

Cleanup allowed ONLY if ALL are proven:

```text
- no runtime participation;
- no governance role;
- no observability role;
- no forensic value;
- no future scaffold role.
```

Current audit result:

```text
No Runtime_* files currently satisfy proven-dead criteria.
```

---

# Current architectural status

Verified state:

```text
- detached orchestration runtime removed from production root;
- dangerous override path removed from production root;
- Runtime_* family remains governance/observability oriented;
- helper authority escalation not detected;
- hidden Runtime_* actuation not detected.
```

Remaining concern:

```text
future architectural drift
```

rather than:

```text
historical runtime collapse.
```

---

# Strategic conclusion

The repository evolved away from:

```text
detached orchestration runtime architecture
```

into:

```text
clean active runtime ownership
+
bounded helper execution
+
post-manifold finalization
+
passive governance / observability / forensic infrastructure
```

This split must remain explicit and preserved.
