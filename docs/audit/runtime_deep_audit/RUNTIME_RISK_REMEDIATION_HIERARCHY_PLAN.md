# RUNTIME_RISK_REMEDIATION_HIERARCHY_PLAN

## Назначение

Документ фиксирует:

- текущую иерархию runtime risks;
- фактически внедрённые remediation stages;
- removed / dormant speculative layers;
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
[done] Stage 9H — Semantic continuity downstream publication enforcement
[done] Stage 9I foundation — Semantic publication commit coherence state/governor foundation
[done] Semantic cleanup — Removed ineffective passive semantic observability fanout
```

## DORMANT / NOT RUNTIME-ACTIVE

```text
[dormant] GVL_SEMANTIC_COMMIT
[dormant] PRG_Semantic_Commit_Governor
```

Reason:

```text
Semantic commit coherence requires real peer checkpoint/ack feed.
Without that feed it is structurally pessimistic and produces artificial quarantine noise.
```

## REMOVED AS SPECULATIVE / INEFFECTIVE

```text
[removed] PRG_Semantic_Progress_Observability
[removed] PRG_Semantic_Commit_Observability
[removed] PRG_Semantic_Commit_Stabilization_Observability
[removed] PRG_Semantic_Commit_Telemetry_Observability
[removed] PRG_Semantic_Telemetry_Diagnostics
[removed] PRG_Semantic_Telemetry_Blackbox
```

Reason:

```text
These passive layers wrote transient observability flags that were reset by PRG_Observability_Governor.
They created misleading topology without authoritative runtime effect.
```

## CURRENT PRIORITY

```text
[current] Runtime validation, compile validation and authority simplification
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
→ Observability_Governor
→ Recovery_Cleanup_Governor
→ Domain_Execution
→ PreOutput_Barrier
→ Output_Freshness_Governor
→ IO_Write
→ PostActuation_Verifier / Diagnostics / HMI
```

---

# CURRENT SEMANTIC POSITION

## Active semantic runtime layer

```text
Semantic_Progress_Governor
```

This layer is currently active because it is:

```text
local
self-contained
non-peer-dependent
publication-authoritative downstream only
```

## Dormant semantic commit foundation

```text
GVL_SEMANTIC_COMMIT
PRG_Semantic_Commit_Governor
```

This foundation remains in source but is not called from `MAIN`.

It must not be reactivated until:

```text
- peer semantic checkpoint epoch feed exists;
- peer semantic commit epoch feed exists;
- semantic checkpoint acknowledgement feed exists;
- rollback/replay fencing semantics are validated;
- default-pass/default-fail behavior is proven safe.
```

---

# WHY SEMANTIC CLEANUP WAS REQUIRED

## Problem discovered

Passive semantic observability PRG programs wrote:

```text
GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required
GVL_OBSERVABILITY_AUTHORITY.Unsafe_State_Published
```

but `PRG_Observability_Governor` resets these flags at the start of its cycle.

Therefore those layers were:

```text
ineffective
misleading
non-authoritative
```

## Architectural correction

Do not place passive pre-observability writers before a governor that owns and resets the same authority fields.

Observability must be either:

```text
single authoritative source
```

or explicitly designed with:

```text
owned input latches
clear ownership rules
post-reset integration semantics
```

No current semantic evidence justifies that expansion.

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

## Semantic expansion freeze

Further semantic layers are prohibited until real runtime evidence exists.

Required evidence:

```text
- real runtime traces;
- real peer instability;
- real replay storms;
- real checkpoint drift distributions;
- operational proof that another semantic layer is necessary.
```

Forbidden speculative expansions:

```text
- speculative stabilization projections;
- speculative telemetry collectors;
- speculative blackbox projections;
- speculative diagnostics projections;
- speculative semantic correction layers;
- speculative replay suppression layers;
- speculative semantic health scoring.
```

---

# FORBIDDEN RECURSIVE PATTERNS

Forbidden:

```text
Telemetry
→ Stabilization
→ Telemetry
```

Forbidden:

```text
Diagnostics
→ Adaptive semantic governance
```

Forbidden:

```text
Blackbox
→ Semantic correction
```

Forbidden:

```text
Semantic visibility
→ Runtime invalidation
```

Forbidden:

```text
Peer semantic jitter
→ Local runtime collapse
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

GVL_SEMANTIC_COMMIT
PRG_Semantic_Commit_Governor [dormant]

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

# STAGE 9 — DISTRIBUTED / SEMANTIC PUBLICATION CONTINUITY

## Current status

```text
distributed publication continuity active
semantic progress continuity active
semantic commit coherence dormant
semantic passive fanout removed
```

## Implemented active properties

```text
- distributed epoch reconciliation foundation;
- distributed immutable snapshot reconciliation foundation;
- distributed publication freeze validation;
- deterministic peer publication commit foundation;
- distributed commit observability projection;
- publication-bound output decay on distributed commit failure;
- semantic progress continuity foundation;
- publication-bound output decay on semantic continuity failure.
```

## Dormant semantic commit properties

```text
- semantic publication checkpoint epochs;
- semantic commit epochs;
- semantic checkpoint acknowledgement foundation;
- semantic rollback/replay fencing foundation;
- semantic commit lease foundation.
```

Dormant means:

```text
source retained
not called from MAIN
not publication-enforcing
not runtime-authoritative
```

---

# CURRENT RISKS AFTER CLEANUP

## R1 — Compile/runtime consistency validation pending

Need to verify:

```text
- all called PRG_* exist;
- all referenced GVL fields exist;
- no deleted PRG is still referenced;
- no stale semantic observability symbol remains in MAIN or active programs.
```

## R2 — Distributed commit may still be too strict

`PRG_Distributed_Commit_Governor` should be reviewed for the same class of issue found in semantic commit:

```text
peer ack/feed required
but default peer feed may be absent
```

## R3 — Distributed commit output decay may be too eager

`PRG_Output_Freshness_Governor` currently enforces distributed commit validity.

Need to verify that distributed commit has real peer data before it can force output decay.

## R4 — Observability centralization is incomplete

`PRG_Observability_Governor` remains the single active owner of observability authority fields.

Any future visibility input must use explicit owned input latches, not direct pre-governor writes to reset-owned fields.

## R5 — Semantic commit dormant state may become stale

If retained, dormant semantic commit files must be documented as inactive foundation.

If not used after distributed peer feeds are designed, remove them later.

---

# UPDATED MINIMAL EXECUTION ORDER

Recommended next steps:

```text
1. Compile/reference validation of MAIN and active PRG/GVL usage.
2. Confirm no deleted semantic observability PRG is referenced anywhere.
3. Review PRG_Distributed_Commit_Governor for default-fail behavior.
4. Review PRG_Output_Freshness_Governor distributed commit enforcement gates.
5. Keep semantic commit dormant until real peer checkpoint/ack feed exists.
6. Do not add new semantic layers without runtime evidence.
```

---

# IMPORTANT ENGINEERING PRINCIPLE

Do NOT:

```text
- patch isolated risks independently;
- add scattered local fixes;
- duplicate authority layers;
- introduce hidden semantic arbitration;
- create semantic observability sprawl;
- mutate execution order without full runtime review;
- perform partial file rewrites for runtime-critical files;
- integrate speculative stabilization logic;
- expose speculative telemetry as runtime truth;
- create upstream/downstream phase cycles;
- make semantic visibility runtime-authoritative;
- wire semantic stalls into local runtime invalidation;
- make semantic continuity an execution ownership authority;
- call peer-dependent governors before real peer feeds exist.
```

Prefer:

```text
single authoritative runtime barriers
with deterministic ownership,
acyclic phase ordering,
publication-bound immutable snapshots,
downstream-only semantic continuity,
centralized observability ownership,
and runtime-driven evidence before semantic expansion.
```
