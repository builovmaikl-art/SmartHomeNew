# RUNTIME_RISK_REMEDIATION_HIERARCHY_PLAN

## Назначение

Документ фиксирует:

- текущую иерархию runtime risks;
- фактически внедрённые remediation stages;
- remaining gaps;
- актуальный порядок дальнейших исправлений;
- правило full-file rewrite для runtime-critical файлов;
- запрет upstream/downstream phase cycles.

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
[done] Stage 9A — Distributed epoch reconciliation foundation
[done] Stage 9B — Distributed reconciliation visibility
[done] Stage 9C — Distributed downstream publication quarantine
[done] Stage 9D — Distributed immutable snapshot reconciliation foundation
[done] Stage 9E — Distributed immutable publication freeze enforcement
[done] Stage 9F — Deterministic peer publication handshake foundation
[done] Stage 9F.1 — Distributed commit observability projection
[done] Stage 9F.2 — Distributed commit downstream publication decay enforcement
[done] Stage 9G — Semantic progress continuity foundation
[done] Stage 9G.1 — Semantic progress observability projection
[done] Stage 9H — Semantic continuity downstream publication enforcement
```

## CURRENT PRIORITY

```text
[current] Stage 9I — Deterministic semantic publication commit coherence
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
→ Distributed_Epoch_Governor
→ Distributed_Snapshot_Governor
→ Distributed_Commit_Governor
→ Distributed_Commit_Observability
→ Semantic_Progress_Governor
→ Semantic_Progress_Observability
→ Observability_Governor
→ Recovery_Cleanup_Governor
→ Domain_Execution
→ PreOutput_Barrier
→ Output_Freshness_Governor
→ IO_Write
→ PostActuation_Verifier / Diagnostics / HMI
```

---

## Current local authority cascade

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

## Current downstream distributed / semantic publication cascade

```text
Distributed_Epoch divergence
→ Distributed_Reconciliation quarantine
→ Observability distributed visibility
→ Output_Freshness forced decay
→ IO_Write safe projection
```

```text
Distributed_Immutable_Snapshot divergence
→ Distributed_Publication_Freeze invalid
→ Observability distributed immutable visibility
→ Output_Freshness forced decay
→ IO_Write safe projection
```

```text
Distributed_Commit failure
→ Commit observability projection
→ Output_Freshness forced decay
→ IO_Write safe projection
```

```text
Semantic_Progress failure
→ Semantic observability projection
→ Output_Freshness forced decay
→ IO_Write safe projection
```

---

# CRITICAL ARCHITECTURAL BOUNDARIES

## Distributed and semantic layers are downstream-only

Distributed reconciliation, distributed commit and semantic progress are intentionally:

```text
publication-authoritative only
```

They must NOT become:

```text
runtime-authoritative
ownership-authoritative
snapshot-authoritative upstream
```

Reason:

```text
peer packet jitter,
delayed reconciliation,
commit acknowledgement latency,
or semantic execution stalls
must not recursively collapse local runtime authority.
```

---

## PRG_Runtime_Barrier snapshot decision

`PRG_Runtime_Barrier` intentionally does **not** directly depend on current-cycle snapshot flags:

```text
Snapshot_Frozen
Snapshot_Publication_Allowed
Snapshot_Copy_Valid
Snapshot_Isolation_Valid
```

Reason:

```text
PRG_Runtime_Barrier
→ PRG_Runtime_Snapshot_Governor
```

A direct dependency would create:

```text
Runtime_Barrier requires Snapshot
while
Snapshot requires Runtime_Barrier
```

Therefore snapshot enforcement is located at publication boundaries:

```text
Runtime_Snapshot_Governor
→ Output_Freshness_Governor
→ PRG_IO_Write hard-stop gate
```

---

# IMPLEMENTED AUTHORITY / GOVERNANCE LAYERS

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

GVL_DISTRIBUTED_EPOCH
PRG_Distributed_Epoch_Governor

GVL_DISTRIBUTED_SNAPSHOT
PRG_Distributed_Snapshot_Governor

GVL_DISTRIBUTED_COMMIT
PRG_Distributed_Commit_Governor
PRG_Distributed_Commit_Observability

GVL_SEMANTIC_PROGRESS
PRG_Semantic_Progress_Governor
PRG_Semantic_Progress_Observability

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
- no consensus-grade semantic ownership continuity;
- no semantic publication checkpoint coherence;
- no deterministic semantic rollback fencing.
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
distributed-publication-aware
commit-aware
semantic-continuity-aware
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
- distributed epoch quarantine validation;
- distributed immutable publication freeze validation;
- distributed commit quarantine validation;
- semantic progress continuity validation;
- authoritative freshness-aware IO gating.
```

## Remaining gaps

```text
- no deterministic semantic publication checkpointing;
- no semantic publication rollback fencing;
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
- no ownership consensus;
- no semantic-progress ownership arbitration by design;
- no transport-level transaction ID fencing.
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
- no peer boot-generation commit handshake.
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
distributed-aware
semantic-aware
```

## Implemented properties

```text
- observability authority state;
- emergency visibility foundation;
- pre-actuation visibility readiness;
- diagnostics/explainability synchronization foundation;
- visibility flags for runtime/output/transport/recovery/fencing/monotonic failures;
- distributed epoch divergence visibility;
- distributed immutable publication visibility;
- distributed commit observability projection;
- semantic progress observability projection;
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

## Remaining gaps

```text
- no deep copy of all domain/runtime state yet;
- no struct-level immutable snapshot schema;
- no snapshot-bound HMI/blackbox rendering yet.
```

---

# STAGE 9 — DISTRIBUTED / SEMANTIC PUBLICATION CONTINUITY

## Status

```text
foundation implemented
publication-integrated downstream
current continuation: Stage 9I
```

## Implemented components

```text
GVL_DISTRIBUTED_EPOCH
PRG_Distributed_Epoch_Governor

GVL_DISTRIBUTED_SNAPSHOT
PRG_Distributed_Snapshot_Governor

GVL_DISTRIBUTED_COMMIT
PRG_Distributed_Commit_Governor
PRG_Distributed_Commit_Observability

GVL_SEMANTIC_PROGRESS
PRG_Semantic_Progress_Governor
PRG_Semantic_Progress_Observability

GVL_OBSERVABILITY_AUTHORITY distributed/semantic visibility fields
PRG_Observability_Governor distributed visibility integration
PRG_Output_Freshness_Governor distributed/commit/semantic publication enforcement
```

## Implemented properties

```text
- distributed epoch reconciliation foundation;
- peer runtime epoch projection;
- peer snapshot epoch projection;
- peer boot generation projection;
- peer fencing token projection;
- peer semantic continuity loss detection;
- downstream distributed quarantine visibility;
- downstream distributed publication quarantine;
- distributed immutable snapshot reconciliation foundation;
- distributed publication freeze validation;
- distributed immutable snapshot consistency validation;
- peer publication divergence detection;
- peer publication reconciliation loss detection;
- deterministic peer publication commit foundation;
- peer commit acknowledgement validation;
- peer commit mismatch detection;
- peer commit replay detection foundation;
- commit lease expiration detection;
- distributed commit observability projection;
- publication-bound output decay on distributed commit failure;
- semantic progress continuity foundation;
- semantic replay/stagnation/livelock/deadlock suspicion foundation;
- semantic progress observability projection;
- publication-bound output decay on semantic continuity failure.
```

## Explicit boundary

```text
Distributed and semantic continuity are downstream/publication-authoritative only.
They must not be wired into Runtime_Barrier, PLC_Fencing_Governor,
or Runtime_Snapshot_Governor as upstream authority sources.
```

## Remaining gaps

```text
- no deterministic semantic publication checkpointing;
- no semantic publication commit coherence;
- no semantic publication rollback fencing;
- no semantic progression commit acknowledgement;
- no transport-level transaction ID fencing;
- no HMI/blackbox snapshot-bound semantic rendering.
```

---

# STAGE 9I — DETERMINISTIC SEMANTIC PUBLICATION COMMIT COHERENCE

## Status

```text
current priority
not started
```

## Назначение

Устранить remaining semantic publication gap:

```text
semantic continuity exists,
commit continuity exists,
publication decay exists,
but semantic commit coherence is not deterministic yet.
```

## Required remediation

```text
- semantic publication checkpoint epoch;
- semantic commit epoch;
- semantic checkpoint acknowledgement;
- semantic checkpoint mismatch detection;
- semantic rollback/replay fencing;
- semantic progression commit acknowledgement;
- downstream-only publication quarantine on semantic commit failure.
```

## Main runtime targets

```text
GVL_SEMANTIC_COMMIT
PRG_Semantic_Commit_Governor
PRG_Semantic_Commit_Observability
GVL_SEMANTIC_PROGRESS
GVL_DISTRIBUTED_COMMIT
PRG_Output_Freshness_Governor
```

## Required integration boundary

```text
Semantic commit must remain downstream-only:
Semantic_Progress
→ Semantic_Commit
→ Semantic_Commit_Observability
→ Observability
→ Output_Freshness
→ IO_Write
```

Do not wire semantic commit upstream into:

```text
Runtime_Barrier
PLC_Fencing_Governor
Runtime_Snapshot_Governor
Distributed ownership arbitration
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
10. Stage 9A-H — Distributed/semantic publication continuity [publication-integrated downstream]
11. Stage 9I — Deterministic semantic publication commit coherence [current priority]
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
- create upstream/downstream phase cycles;
- make distributed reconciliation ownership-authoritative;
- wire peer jitter into local runtime invalidation;
- wire semantic stalls into local runtime invalidation;
- make semantic continuity an execution ownership authority.
```

Prefer:

```text
single authoritative runtime barriers
with deterministic ownership,
acyclic phase ordering,
pre-actuation observability,
publication-bound immutable snapshots,
downstream-only distributed publication governance,
and downstream-only semantic publication continuity.
```
