# RUNTIME_RISK_REMEDIATION_HIERARCHY_PLAN

## Назначение

Документ фиксирует:

- иерархию возникновения runtime risks;
- минимальный remediation order;
- dependency graph между рисками;
- текущий implementation status;
- порядок исправлений с минимальным количеством runtime/code passes.

Цель:

```text
устранять root-runtime causes,
а не отдельные локальные симптомы.
```

---

# GLOBAL PRINCIPLE

Runtime remediation должна идти:

```text
ROOT AUTHORITY
→ EXECUTION BARRIERS
→ OUTPUT VALIDITY
→ DISTRIBUTED OWNERSHIP
→ TIME/RECOVERY
→ TRANSPORT
→ OBSERVABILITY
```

а не по numerical order risk-файлов.

---

# CURRENT IMPLEMENTATION STATUS

## IMPLEMENTED

```text
[done] Stage 1 — Pre-output safety barrier
[done] Stage 0 — Runtime validity barrier foundation
```

## IN PROGRESS

```text
[in-progress] Stage 2 — Output freshness / output validity
```

## NOT STARTED

```text
[pending] Stage 3 — Distributed ownership / PLC fencing
[pending] Stage 4 — Monotonic time / startup quarantine
[pending] Stage 5 — Recovery cleanup governance
[pending] Stage 6 — Transport freshness governance
[pending] Stage 7 — Safety-critical observability
```

---

# STAGE 0

# AUTHORITATIVE RUNTIME VALIDITY MODEL

## Status

```text
foundation implemented
```

---

## Implemented runtime components

```text
GVL_RUNTIME_EPOCH
PRG_Runtime_Barrier
```

---

## Integrated execution order

```text
Command_Arbitration
→ Runtime_Barrier
→ Domain_Execution
→ PreOutput_Barrier
→ IO_Write
→ Verification
```

---

## Implemented runtime properties

```text
- authoritative runtime epoch;
- runtime validity publication;
- deterministic execution phases;
- impossible-state rejection foundation;
- runtime authority publication;
- runtime barrier state;
- runtime IO publication gating.
```

---

## Risks addressed

### substantially mitigated

```text
RISK-024
RISK-025
RISK-026
RISK-032
RISK-037
```

### partially mitigated

```text
RISK-005
RISK-016
RISK-020
RISK-021
RISK-031
RISK-039
```

---

## Remaining gaps

```text
- immutable runtime snapshots still incomplete;
- no snapshot copy isolation;
- no publication freeze barrier;
- no distributed runtime epochs;
- no stale snapshot invalidation;
- no runtime lease semantics.
```

---

# STAGE 1

# PRE-OUTPUT SAFETY BARRIER

## Status

```text
implemented
```

---

## Implemented runtime components

```text
PRG_PreOutput_Safety_Barrier
GVL_COMMAND_VERIFY.PreOutput_*
PRG_IO_Write authoritative block gate
```

---

## Implemented execution order

Current MAIN order:

```text
Runtime_Barrier
→ Domain_Execution
→ PreOutput_Barrier
→ IO_Write
→ Command_Verifier
```

---

## Implemented properties

```text
- authoritative pre-output validation;
- hard IO publication gate;
- forced safe projection;
- command/output mismatch rejection;
- impossible-state rejection before IO publication;
- blocked-publication traceability.
```

---

## Risks addressed

### substantially mitigated

```text
RISK-037
RISK-038
RISK-040
```

### partially mitigated

```text
RISK-015
RISK-041
RISK-047
```

---

## Remaining gaps

```text
- no output freshness epochs;
- no stale-output lease invalidation;
- no retained output decay semantics;
- verifier still post-actuation only;
- no authoritative snapshot freeze before IO.
```

---

# STAGE 2

# OUTPUT FRESHNESS / OUTPUT VALIDITY

## Status

```text
next critical implementation target
```

---

## Назначение

Устранить:

```text
stale-output survivability.
```

---

## Primary risks addressed

```text
RISK-040
RISK-044
RISK-045
RISK-046
RISK-047
```

---

## Required remediation

Introduce:

```text
- output freshness epoch;
- authority-bound outputs;
- output lease timeout;
- forced safe decay;
- stale-output invalidation;
- runtime epoch linkage to outputs.
```

---

## Main runtime targets

```text
GVL_RUNTIME_EPOCH
GVL_COMMAND_SHADOW
GVL_IO
PRG_IO_Write
PRG_Command_Arbitration
```

---

## Priority rationale

This stage became highest remaining priority because:

```text
- runtime authority chain already exists;
- pre-output barrier already exists;
- IO blocking already exists;
- stale physical survivability is now the dominant unresolved safety gap.
```

---

# STAGE 3

# DISTRIBUTED OWNERSHIP / PLC FENCING

## Назначение

Устранить:

```text
split-brain
and stale authority resurrection.
```

---

## Primary risks addressed

```text
RISK-044
RISK-045
RISK-046
RISK-047
```

---

## Required remediation

Introduce:

```text
- ownership epochs;
- fencing tokens;
- stale-owner invalidation;
- semantic-progress watchdog;
- asymmetric partition detection.
```

---

## Main runtime targets

```text
PRG_PLC_Arbitration
GVL_PLC
heartbeat ownership semantics
```

---

# STAGE 4

# MONOTONIC TIME + STARTUP QUARANTINE

## Назначение

Устранить:

```text
rollback/reboot semantic corruption.
```

---

## Primary risks addressed

```text
RISK-009
RISK-017
RISK-030
RISK-048
RISK-049
```

---

## Required remediation

Introduce:

```text
- monotonic epoch model;
- rollback detection;
- overflow-safe delta wrappers;
- retained-state quarantine;
- cold-start epoch.
```

---

## Main runtime targets

```text
PRG_Time_Service
GVL_TIME_SERVICE
startup/reboot path
retained state handling
```

---

# STAGE 5

# RECOVERY CLEANUP GOVERNANCE

## Назначение

Устранить:

```text
semantic residue accumulation.
```

---

## Primary risks addressed

```text
RISK-008
RISK-010
RISK-011
RISK-012
RISK-031
RISK-035
RISK-043
```

---

## Required remediation

Introduce:

```text
- cleanup epochs;
- degraded residue invalidation;
- authority reset during recovery;
- recovery-clean vs recovery-complete separation;
- semantic cleanup diagnostics.
```

---

## Main runtime targets

```text
PRG_Safety_Recovery
GVL_RECOVERY
GVL_DEGRADED
```

---

# STAGE 6

# TRANSPORT FRESHNESS GOVERNANCE

## Назначение

Устранить:

```text
stale transport semantics.
```

---

## Primary risks addressed

```text
RISK-007
RISK-027
RISK-028
RISK-029
RISK-038
```

---

## Required remediation

Introduce:

```text
- transaction matching;
- freshness epochs;
- reconnect stabilization phases;
- staged transport snapshots;
- transport acceptance barriers.
```

---

## Main runtime targets

```text
transport layer
fieldbus synchronization
transport publication path
```

---

# STAGE 7

# SAFETY-CRITICAL OBSERVABILITY

## Назначение

Устранить:

```text
false-safe observability windows.
```

---

## Primary risks addressed

```text
RISK-023
RISK-041
```

---

## Required remediation

Introduce:

```text
- pre-actuation unsafe-state publication;
- safety-critical diagnostics path;
- authoritative runtime snapshots for HMI;
- emergency visibility barrier.
```

---

## Main runtime targets

```text
PRG_System_Diagnostics
PRG_System_BlackBox
PRG_HMI_Dashboard
GVL_DEBUG_VIEW
GVL_EXPLAINABILITY
```

---

# UPDATED MINIMAL EXECUTION ORDER

Recommended practical implementation order:

```text
1. Stage 1 — Pre-output safety barrier [implemented]
2. Stage 0 — Runtime validity/snapshot layer [foundation implemented]
3. Stage 2 — Output freshness/decay [current priority]
4. Stage 3 — PLC ownership/fencing
5. Stage 4 — Monotonic time/startup quarantine
6. Stage 5 — Recovery cleanup governance
7. Stage 6 — Transport freshness governance
8. Stage 7 — Safety-critical observability
```

---

# IMPORTANT ENGINEERING PRINCIPLE

Do NOT:

```text
- patch isolated risks independently;
- add scattered local fixes;
- duplicate authority layers;
- introduce new hidden arbitration paths;
- mutate execution order without full runtime review;
- perform partial file rewrites for runtime-critical files.
```

Prefer:

```text
single authoritative runtime barriers
with deterministic ownership.
```
