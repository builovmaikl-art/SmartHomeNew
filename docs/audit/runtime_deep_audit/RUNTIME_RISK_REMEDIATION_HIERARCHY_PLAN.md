# RUNTIME_RISK_REMEDIATION_HIERARCHY_PLAN

## Назначение

Документ фиксирует:

- текущую иерархию runtime risks;
- фактически внедрённые remediation stages;
- remaining gaps;
- актуальный порядок дальнейших исправлений;
- правило full-file rewrite для runtime-critical файлов.

Цель:

```text
устранять root-runtime causes,
а не отдельные локальные симптомы.
```

---

# CURRENT IMPLEMENTATION STATUS

## IMPLEMENTED / INTEGRATED

```text
[done] Stage 0 — Runtime validity / authoritative runtime barrier
[done] Stage 1 — Pre-output safety barrier
[done] Stage 2 — Output freshness / output validity
[done] Stage 3 — Distributed ownership / PLC fencing foundation
[done] Stage 4 — Monotonic time / startup quarantine foundation
[done] Stage 5 — Recovery cleanup governance foundation
[done] Stage 6 — Transport freshness governance foundation
[done] Stage 7 — Safety-critical observability foundation
[done] Stage 8 — Immutable runtime snapshot isolation foundation
```

## CURRENT PRIORITY

```text
[current] Stage 9 — Distributed epoch consistency / peer reconciliation
```

---

# CURRENT AUTHORITATIVE RUNTIME TOPOLOGY

## Integrated MAIN execution chain

```text
Time_Service
→ Time_Monotonic_Governor
→ PLC_Arbitration
→ PLC_Fencing_Governor
→ IO_Read / Input_Processing
→ Safety / Mode / Policy / Command_Arbitration
→ Transport_Pipeline
→ Transport_Freshness_Governor
→ Runtime_Barrier
→ Runtime_Snapshot_Governor
→ Observability_Governor
→ Recovery_Cleanup_Governor
→ Domain_Execution
→ PreOutput_Barrier
→ Output_Freshness_Governor
→ IO_Write
→ PostActuation_Verifier / Diagnostics / HMI
```

---

## Current authority cascade

```text
Monotonic_Time failure
→ PLC_Fencing failure
→ Transport_Freshness failure
→ Runtime_Barrier invalid
→ Runtime_Snapshot invalid/frozen publication denied
→ Observability synchronization failure
→ Recovery_Governance failure
→ Output_Freshness forced decay
→ IO_Write safe projection
```

---

## Important PRG_Runtime_Barrier note

`PRG_Runtime_Barrier` intentionally does **not** directly depend on `Snapshot_Frozen`, `Snapshot_Publication_Allowed`, `Snapshot_Copy_Valid` or `Snapshot_Isolation_Valid`.

Reason:

```text
PRG_Runtime_Barrier
→ PRG_Runtime_Snapshot_Governor
```

A direct current-cycle snapshot dependency inside `PRG_Runtime_Barrier` would create a phase-cycle:

```text
Runtime_Barrier requires Snapshot
while
Snapshot requires Runtime_Barrier
```

Therefore snapshot enforcement is correctly located at publication boundaries:

```text
Runtime_Snapshot_Governor
→ Output_Freshness_Governor
→ PRG_IO_Write hard-stop gate
```

This keeps the execution graph acyclic and deterministic.

---

## Implemented authority layers

```text
GVL_TIME_MONOTONIC
PRG_Time_Monotonic_Governor

GVL_PLC_FENCING
PRG_PLC_Fencing_Governor

GVL_TRANSPORT_FRESHNESS
PRG_Transport_Freshness_Governor

GVL_RUNTIME_EPOCH
PRG_Runtime_Barrier

GVL_RUNTIME_SNAPSHOT
PRG_Runtime_Snapshot_Governor

GVL_OBSERVABILITY_AUTHORITY
PRG_Observability_Governor

GVL_RECOVERY_GOVERNANCE
PRG_Recovery_Cleanup_Governor

GVL_COMMAND_VERIFY.PreOutput_*
PRG_PreOutput_Safety_Barrier

GVL_OUTPUT_EPOCH
PRG_Output_Freshness_Governor

PRG_IO_Write authoritative hard-stop gate
```

---

# STAGE 0 — AUTHORITATIVE RUNTIME VALIDITY MODEL

## Status

```text
implemented
runtime-integrated
```

## Implemented properties

```text
- authoritative runtime epoch;
- runtime validity publication;
- deterministic execution phases;
- runtime IO publication gating;
- monotonic-aware runtime invalidation;
- fencing-aware runtime invalidation;
- transport-aware runtime invalidation;
- recovery-aware runtime invalidation;
- observability-aware runtime invalidation.
```

## Remaining gaps

```text
- distributed runtime epoch synchronization remains incomplete;
- peer reconciliation not implemented;
- no consensus-grade semantic ownership continuity.
```

---

# STAGE 1 — PRE-OUTPUT SAFETY BARRIER

## Status

```text
implemented
runtime-integrated
```

## Implemented properties

```text
- authoritative pre-output validation;
- hard IO publication gate;
- forced safe projection;
- command/output mismatch rejection;
- blocked-publication traceability.
```

---

# STAGE 2 — OUTPUT FRESHNESS / OUTPUT VALIDITY

## Status

```text
implemented
runtime-authoritative
snapshot-aware
```

## Implemented components

```text
GVL_OUTPUT_EPOCH
PRG_Output_Freshness_Governor
PRG_IO_Write freshness-aware hard stop
```

## Implemented properties

```text
- output freshness epochs;
- output lease semantics;
- forced safe decay;
- stale-output invalidation;
- runtime/output epoch linkage;
- lease-expiration shutdown;
- immutable snapshot publication validation;
- authoritative freshness-aware IO gating.
```

## Remaining gaps

```text
- no distributed output epoch fencing;
- no peer output publication reconciliation;
- no retained-output quarantine beyond current forced decay foundation.
```

---

# STAGE 3 — DISTRIBUTED OWNERSHIP / PLC FENCING

## Status

```text
foundation implemented
runtime-integrated
```

## Implemented properties

```text
- ownership epochs;
- fencing tokens;
- semantic authority validation;
- stale-owner detection foundation;
- split-brain detection foundation;
- asymmetric partition detection foundation;
- authority lease expiration;
- fencing-aware runtime invalidation.
```

## Remaining gaps

```text
- no peer epoch negotiation;
- no distributed fencing synchronization;
- no semantic-progress watchdog;
- no external peer transaction fencing.
```

---

# STAGE 4 — MONOTONIC TIME / STARTUP QUARANTINE

## Status

```text
foundation implemented
runtime-integrated
```

## Implemented properties

```text
- monotonic epoch model;
- boot generation ID;
- rollback detection foundation;
- retained-time invalidation foundation;
- startup quarantine foundation;
- runtime invalidation on time anomaly.
```

## Remaining gaps

```text
- no reusable overflow-safe delta function block;
- no explicit retained-state scrubber;
- no persisted boot-generation reconciliation;
- no peer boot-generation comparison.
```

---

# STAGE 5 — RECOVERY CLEANUP GOVERNANCE

## Status

```text
foundation implemented
runtime-integrated
```

## Implemented properties

```text
- recovery cleanup epochs;
- recovery quarantine foundation;
- semantic residue detection foundation;
- degraded-state residual detection;
- retained-state residual detection;
- recovery-aware runtime invalidation.
```

## Remaining gaps

```text
- no deep semantic purge of all domain residues;
- no domain-specific cleanup contracts;
- no recovery-clean vs recovery-complete HMI distinction;
- no recovery blackbox snapshot.
```

---

# STAGE 6 — TRANSPORT FRESHNESS GOVERNANCE

## Status

```text
foundation implemented
runtime-integrated
```

## Implemented properties

```text
- transport freshness epochs;
- transport publication epochs;
- transport lease semantics;
- reconnect quarantine foundation;
- stale snapshot invalidation foundation;
- transport-aware runtime invalidation.
```

## Remaining gaps

```text
- no Modbus/OpenTherm transaction ID fencing yet;
- no per-frame stale RX rejection at driver boundary;
- no staged transport snapshot publication;
- reconnect stabilization is governance-level only;
- transport quarantine is not yet exposed to HMI/diagnostics.
```

---

# STAGE 7 — SAFETY-CRITICAL OBSERVABILITY

## Status

```text
foundation implemented
runtime-integrated
```

## Implemented properties

```text
- observability authority state;
- emergency visibility foundation;
- pre-actuation visibility readiness;
- diagnostics/explainability synchronization foundation;
- visibility flags for runtime/output/transport/recovery/fencing/monotonic failures;
- observability-aware runtime invalidation.
```

## Remaining gaps

```text
- HMI/diagnostics/blackbox consumers still need snapshot-bound rendering;
- post-actuation verifier still needs authority snapshot linkage;
- emergency visibility is governed but not yet domain-specific in UI.
```

---

# STAGE 8 — IMMUTABLE RUNTIME SNAPSHOT ISOLATION

## Status

```text
foundation implemented
publication-integrated
```

## Implemented components

```text
GVL_RUNTIME_SNAPSHOT
PRG_Runtime_Snapshot_Governor
PRG_Output_Freshness_Governor snapshot validation
PRG_IO_Write immutable snapshot hard-stop gate
```

## Implemented properties

```text
- immutable snapshot epoch foundation;
- snapshot freeze foundation;
- snapshot publication allowed flag;
- snapshot copy validity foundation;
- snapshot isolation validity foundation;
- snapshot mutation detection foundation;
- output freshness validation against snapshot authority;
- final physical IO hard-stop on snapshot failure.
```

## PRG_Runtime_Barrier decision

`PRG_Runtime_Barrier` remains upstream and does not directly validate current-cycle snapshot freeze flags.
This is intentional to avoid cyclic dependency.
Snapshot authority is enforced downstream at publication boundaries.

## Remaining gaps

```text
- no deep copy of all domain/runtime state yet;
- no struct-level immutable snapshot schema;
- no snapshot-bound HMI/blackbox rendering yet;
- no distributed immutable snapshot reconciliation.
```

---

# STAGE 9 — DISTRIBUTED EPOCH CONSISTENCY / PEER RECONCILIATION

## Status

```text
current priority
not started
```

## Назначение

Устранить remaining distributed gap:

```text
local deterministic authority exists,
but peer epoch consistency is not authoritative yet.
```

## Required remediation

```text
- distributed epoch negotiation;
- cross-PLC fencing reconciliation;
- peer boot-generation comparison;
- distributed snapshot epoch exchange;
- peer transport transaction fencing;
- authoritative distributed publication reconciliation;
- semantic-progress watchdog.
```

## Main runtime targets

```text
PRG_PLC_Arbitration
PRG_PLC_Fencing_Governor
GVL_PLC_FENCING
GVL_RUNTIME_EPOCH
GVL_RUNTIME_SNAPSHOT
GVL_TRANSPORT_FRESHNESS
GVL_TIME_MONOTONIC
```

---

# UPDATED MINIMAL EXECUTION ORDER

Recommended practical implementation order:

```text
1. Stage 1 — Pre-output safety barrier [implemented]
2. Stage 0 — Runtime validity/snapshot layer [implemented]
3. Stage 2 — Output freshness/decay [implemented]
4. Stage 3 — PLC ownership/fencing [foundation implemented]
5. Stage 4 — Monotonic time/startup quarantine [foundation implemented]
6. Stage 5 — Recovery cleanup governance [foundation implemented]
7. Stage 6 — Transport freshness governance [foundation implemented]
8. Stage 7 — Safety-critical observability [foundation implemented]
9. Stage 8 — Immutable runtime snapshot isolation [publication-integrated]
10. Stage 9 — Distributed epoch consistency [current priority]
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
- integrate lease semantics without monotonic time governance;
- expose post-fact diagnostics as safety truth;
- create upstream/downstream phase cycles.
```

Prefer:

```text
single authoritative runtime barriers
with deterministic ownership,
acyclic phase ordering,
pre-actuation observability,
and publication-bound immutable snapshots.
```
