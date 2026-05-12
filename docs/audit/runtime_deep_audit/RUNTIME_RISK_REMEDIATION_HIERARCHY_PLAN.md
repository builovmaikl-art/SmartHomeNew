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
```

## CURRENT PRIORITY

```text
[current] Stage 7 — Safety-critical observability
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
→ Recovery_Governance failure
→ Runtime_Barrier invalid
→ Output_Freshness forced decay
→ IO_Write safe projection
```

---

## Implemented authority layers

```text
GVL_TIME_MONOTONIC
PRG_Time_Monotonic_Governor

GVL_PLC_FENCING
PRG_PLC_Fencing_Governor

GVL_TRANSPORT_FRESHNESS
PRG_Transport_Freshness_Governor

GVL_RECOVERY_GOVERNANCE
PRG_Recovery_Cleanup_Governor

GVL_RUNTIME_EPOCH
PRG_Runtime_Barrier

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
- recovery-aware runtime invalidation.
```

## Risks addressed

```text
substantially mitigated:
RISK-024
RISK-025
RISK-026
RISK-032
RISK-037

partially mitigated:
RISK-005
RISK-016
RISK-020
RISK-021
RISK-031
RISK-039
```

## Remaining gaps

```text
- immutable runtime snapshot copy isolation still incomplete;
- no full publication freeze barrier;
- no distributed runtime epoch synchronization;
- no authoritative HMI snapshot layer.
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

## Risks addressed

```text
substantially mitigated:
RISK-037
RISK-038
RISK-040

partially mitigated:
RISK-015
RISK-041
RISK-047
```

## Remaining gaps

```text
- verifier remains post-actuation;
- no pre-actuation HMI/diagnostics publication.
```

---

# STAGE 2 — OUTPUT FRESHNESS / OUTPUT VALIDITY

## Status

```text
implemented
runtime-authoritative
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
- authoritative freshness-aware IO gating.
```

## Risks addressed

```text
substantially mitigated:
RISK-040
RISK-047

partially mitigated:
RISK-044
RISK-045
RISK-046
```

## Remaining gaps

```text
- no distributed output epoch fencing;
- no retained-output quarantine beyond current forced decay foundation;
- no HMI-facing output validity snapshot.
```

---

# STAGE 3 — DISTRIBUTED OWNERSHIP / PLC FENCING

## Status

```text
foundation implemented
runtime-integrated
```

## Implemented components

```text
GVL_PLC_FENCING
PRG_PLC_Fencing_Governor
Runtime_Barrier fencing integration
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

## Risks addressed

```text
substantially mitigated:
RISK-044
RISK-045

partially mitigated:
RISK-046
RISK-047
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

## Implemented components

```text
GVL_TIME_MONOTONIC
PRG_Time_Monotonic_Governor
Runtime_Barrier monotonic integration
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

## Risks addressed

```text
substantially mitigated:
RISK-048
RISK-049

partially mitigated:
RISK-009
RISK-017
RISK-030
```

## Remaining gaps

```text
- no reusable overflow-safe delta function block;
- no explicit retained-state scrubber;
- no persisted boot-generation reconciliation;
- no HMI-visible startup quarantine diagnostics.
```

---

# STAGE 5 — RECOVERY CLEANUP GOVERNANCE

## Status

```text
foundation implemented
runtime-integrated
```

## Implemented components

```text
GVL_RECOVERY_GOVERNANCE
PRG_Recovery_Cleanup_Governor
Runtime_Barrier recovery integration
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

## Risks addressed

```text
substantially mitigated:
RISK-031
RISK-035
RISK-043

partially mitigated:
RISK-008
RISK-010
RISK-011
RISK-012
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

## Implemented components

```text
GVL_TRANSPORT_FRESHNESS
PRG_Transport_Freshness_Governor
Runtime_Barrier transport integration
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

## Risks addressed

```text
substantially mitigated:
RISK-027
RISK-028
RISK-029

partially mitigated:
RISK-007
RISK-038
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
current remaining priority
not started
```

## Назначение

Устранить:

```text
false-safe observability windows.
```

## Primary risks addressed

```text
RISK-023
RISK-041
```

## Required remediation

```text
- pre-actuation unsafe-state publication;
- authoritative runtime/HMI snapshots;
- emergency visibility barrier;
- diagnostics synchronized with authority chain;
- blackbox linkage to runtime/fencing/output/transport/recovery failures;
- explainability synchronized before and after IO publication.
```

## Main runtime targets

```text
PRG_System_Diagnostics
PRG_System_BlackBox
PRG_HMI_Dashboard
PRG_Debug_View
GVL_DEBUG_VIEW
GVL_EXPLAINABILITY
GVL_RUNTIME_EPOCH
GVL_COMMAND_VERIFY
GVL_OUTPUT_EPOCH
GVL_TRANSPORT_FRESHNESS
GVL_RECOVERY_GOVERNANCE
GVL_PLC_FENCING
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
8. Stage 7 — Safety-critical observability [current priority]
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
- expose post-fact diagnostics as safety truth.
```

Prefer:

```text
single authoritative runtime barriers
with deterministic ownership
and pre-actuation observability.
```
