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

This document formalizes the results of the runtime governance audit.

---

# Core architectural invariant

The invariant that must never be violated:

```text
single active runtime authority path
```

Active runtime authority remains:

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
ACTIVE RUNTIME AUTHORITY
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

Representative files:

```text
FB_Heating_Runtime_Anomaly_Correlator
FB_Heating_Runtime_RootCause_Correlator
FB_Heating_Runtime_Fault_Replay_Analyzer
FB_Heating_Runtime_Degradation_Timeline_Rebuilder
FB_Heating_Runtime_Adaptive_Drift_Detector
FB_Heating_Runtime_Cascade_Collapse_Predictor
FB_Heating_Runtime_Confidence_Decay_Analyzer
FB_Heating_Runtime_Observation_Aggregator
FB_Heating_Runtime_Phase_Telemetry_Aggregator
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

Critical governance locks already detected:

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

Characteristics:

```text
- partial integration;
- governance preparation;
- future analytics expansion;
- future diagnostics infrastructure.
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

Status:

```text
No confirmed CLASS E Runtime_* files yet.
```

Meaning:

```text
Runtime_* family is currently treated as
intentional governance/observability architecture
instead of dead legacy garbage.
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

# Strategic conclusion

The repository already evolved away from:

```text
detached orchestration runtime architecture
```

toward:

```text
clean active runtime authority
+
passive governance / observability / forensic infrastructure
```

This split must be preserved.
