# RUNTIME_RISK_REMEDIATION_HIERARCHY_PLAN

## Назначение

Документ фиксирует:

- иерархию возникновения runtime risks;
- минимальный remediation order;
- dependency graph между рисками;
- текущий implementation status;
- runtime authority architecture status;
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
→ TIME GOVERNANCE
→ RECOVERY GOVERNANCE
→ TRANSPORT
→ OBSERVABILITY
```

а не по numerical order risk-файлов.

---

# CURRENT IMPLEMENTATION STATUS

## IMPLEMENTED

```text
[done] Stage 0 — Runtime validity barrier foundation
[done] Stage 1 — Pre-output safety barrier
[done] Stage 2 — Output freshness / output validity
[done] Stage 3 — Distributed ownership / PLC fencing foundation
```

## CURRENT PRIORITY

```text
[current] Stage 4 — Monotonic time / startup quarantine
```

## NOT STARTED

```text
[pending] Stage 5 — Recovery cleanup governance
[pending] Stage 6 — Transport freshness governance
[pending] Stage 7 — Safety-critical observability
```

---

# CURRENT AUTHORITATIVE RUNTIME CHAIN

## Integrated execution order

```text
PLC_Arbitration
→ PLC_Fencing_Governor
→ Runtime_Barrier
→ Domain_Execution
→ PreOutput_Barrier
→ Output_Freshness_Governor
→ IO_Write
→ PostActuation_Verifier
```

---

## Current authority cascade

```text
PLC fencing failure
→ Runtime invalidation
→ Output freshness decay
→ Forced safe IO projection
```

---

## Current implemented authority layers

```text
GVL_RUNTIME_EPOCH
PRG_Runtime_Barrier

GVL_COMMAND_VERIFY.PreOutput_*
PRG_PreOutput_Safety_Barrier

GVL_OUTPUT_EPOCH
PRG_Output_Freshness_Governor

GVL_PLC_FENCING
PRG_PLC_Fencing_Governor
```

---

# STAGE 0

# AUTHORITATIVE RUNTIME VALIDITY MODEL

## Status

```text
foundation implemented
partially integrated
```

---

## Implemented runtime properties

```text
- authoritative runtime epoch;
- runtime validity publication;
- deterministic execution phases;
- impossible-state rejection foundation;
- runtime authority publication;
- runtime IO publication gating;
- fencing-aware runtime invalidation.
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
- no distributed runtime epoch synchronization;
- no monotonic epoch linkage;
- no reboot-generation invalidation.
```

---

# STAGE 1

# PRE-OUTPUT SAFETY BARRIER

## Status

```text
implemented
runtime-integrated
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
- verifier still post-actuation only;
- no immutable runtime snapshot freeze;
- no pre-actuation HMI publication.
```

---

# STAGE 2

# OUTPUT FRESHNESS / OUTPUT VALIDITY

## Status

```text
implemented
runtime-authoritative
```

---

## Implemented runtime components

```text
GVL_OUTPUT_EPOCH
PRG_Output_Freshness_Governor
PRG_IO_Write freshness-aware hard stop
```

---

## Implemented properties

```text
- output freshness epochs;
- output lease semantics;
- forced safe decay;
- stale-output invalidation;
- runtime/output epoch linkage;
- lease-expiration shutdown;
- authoritative freshness-aware IO gating.
```

---

## Risks addressed

### substantially mitigated

```text
RISK-040
RISK-047
```

### partially mitigated

```text
RISK-044
RISK-045
RISK-046
```

---

## Remaining gaps

```text
- no monotonic lease timebase;
- no reboot-safe freshness invalidation;
- no distributed output epoch fencing;
- no retained-output quarantine.
```

---

# STAGE 3

# DISTRIBUTED OWNERSHIP / PLC FENCING

## Status

```text
foundation implemented
runtime-integrated
```

---

## Implemented runtime components

```text
GVL_PLC_FENCING
PRG_PLC_Fencing_Governor
Runtime_Barrier fencing integration
```

---

## Implemented properties

```text
- ownership epochs;
- fencing tokens;
- semantic authority validation;
- stale-owner detection foundation;
- split-brain detection foundation;
- asymmetric partition detection foundation;
- fencing-aware runtime invalidation;
- authority lease expiration.
```

---

## Risks addressed

### substantially mitigated

```text
RISK-044
RISK-045
```

### partially mitigated

```text
RISK-046
RISK-047
```

---

## Remaining gaps

```text
- no distributed fencing synchronization;
- no peer epoch negotiation;
- no semantic-progress watchdog;
- no monotonic lease authority;
- no reboot-safe ownership invalidation.
```

---

# STAGE 4

# MONOTONIC TIME + STARTUP QUARANTINE

## Status

```text
highest remaining architectural priority
not started
```

---

## Architectural rationale

Current system authority now depends on:

```text
- runtime epochs;
- output freshness leases;
- PLC fencing leases;
- runtime publication timestamps.
```

Without monotonic governance:

```text
all authority chains remain vulnerable
to rollback/reboot resurrection.
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
- reboot generation IDs;
- overflow-safe delta wrappers;
- retained-state quarantine;
- startup quarantine windows;
- reboot-safe lease invalidation.
```

---

## Required implementation order

```text
1. Isolated monotonic layer
2. Startup quarantine foundation
3. Monotonic authority publication
4. Runtime/output/fencing integration
```

---

## Main runtime targets

```text
GVL_TIME_MONOTONIC
PRG_Time_Monotonic_Governor
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

# STAGE 6

# TRANSPORT FRESHNESS GOVERNANCE

## Primary risks addressed

```text
RISK-007
RISK-027
RISK-028
RISK-029
RISK-038
```

---

# STAGE 7

# SAFETY-CRITICAL OBSERVABILITY

## Primary risks addressed

```text
RISK-023
RISK-041
```

---

# UPDATED MINIMAL EXECUTION ORDER

Recommended practical implementation order:

```text
1. Stage 1 — Pre-output safety barrier [implemented]
2. Stage 0 — Runtime validity/snapshot layer [implemented foundation]
3. Stage 2 — Output freshness/decay [implemented]
4. Stage 3 — PLC ownership/fencing [implemented foundation]
5. Stage 4 — Monotonic time/startup quarantine [current priority]
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
- perform partial file rewrites for runtime-critical files;
- integrate lease semantics without monotonic time governance.
```

Prefer:

```text
single authoritative runtime barriers
with deterministic ownership.
```
