# RUNTIME_RISK_REMEDIATION_HIERARCHY_PLAN

## Назначение

Документ фиксирует:

- иерархию возникновения runtime risks;
- минимальный remediation order;
- dependency graph между рисками;
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

# STAGE 0

# AUTHORITATIVE RUNTIME VALIDITY MODEL

## Назначение

Создать:

```text
- authoritative runtime epoch;
- immutable runtime snapshot semantics;
- execution phase visibility model;
- invariant enforcement;
- impossible-state rejection.
```

Без этого последующие fixes будут:

```text
patch-level
и semantically unstable.
```

---

## Primary risks addressed

```text
RISK-005
RISK-016
RISK-020
RISK-021
RISK-024
RISK-025
RISK-026
RISK-031
RISK-032
RISK-037
RISK-039
```

---

## Main runtime targets

```text
GVL_RUNTIME_EPOCH
GVL_RUNTIME_SNAPSHOT
PRG_Runtime_Barrier
PRG_Runtime_Invariant_Check
```

---

## Required properties

```text
- cycle-stable visibility;
- immutable publication epoch;
- impossible-state rejection;
- authoritative runtime validity;
- deterministic execution phases.
```

---

# STAGE 1

# PRE-OUTPUT SAFETY BARRIER

## Назначение

Устранить:

```text
unsafe physical publication
before verification.
```

Главный immediate blocker.

---

## Primary risks addressed

```text
RISK-015
RISK-037
RISK-038
RISK-040
RISK-041 (partial)
RISK-047 (partial)
```

---

## Current critical flaw

Current MAIN order:

```text
PRG_IO_Write();
PRG_Command_Verifier();
```

creates:

```text
same-cycle unsafe physical window.
```

---

## Required remediation

Target order:

```text
PRG_Command_Verifier
→ PRG_PreOutput_Safety_Barrier
→ PRG_IO_Write
```

Verifier must become:

```text
blocking authoritative safety barrier
```

instead of:

```text
diagnostic-after-fact layer.
```

---

## Main runtime targets

```text
MAIN
PRG_Command_Verifier
PRG_IO_Write
PRG_PreOutput_Safety_Barrier
```

---

# STAGE 2

# OUTPUT FRESHNESS / OUTPUT VALIDITY

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
- stale-output invalidation.
```

---

## Main runtime targets

```text
GVL_COMMAND_SHADOW
GVL_IO
PRG_IO_Write
PRG_Command_Arbitration
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

# MINIMAL EXECUTION ORDER

Recommended practical implementation order:

```text
1. Stage 1 — Pre-output safety barrier
2. Stage 0 — Runtime validity/snapshot layer
3. Stage 2 — Output freshness/decay
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
- introduce new hidden arbitration paths.
```

Prefer:

```text
single authoritative runtime barriers
with deterministic ownership.
```
