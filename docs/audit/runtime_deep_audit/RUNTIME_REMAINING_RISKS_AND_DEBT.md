# RUNTIME REMAINING RISKS AND DEBT

Authoritative runtime architecture consolidation document.

Date:

```text
2026-05-13
```

Scope:

```text
runtime_deep_audit
risk liquidation
runtime convergence
safe recovery
semantic progress
ownership normalization
remaining technical debt
```

---

# 1. Purpose

This document is the current authoritative runtime risk/debt view.

Historical `RUNTIME_DEEP_AUDIT_PART_*` documents remain forensic audit evidence.
This document represents the current runtime architecture baseline, remaining
active risks, remaining engineering debt and forbidden runtime patterns.

Primary goal:

```text
preserve architectural memory after runtime risk liquidation
```

Secondary goal:

```text
prevent re-introduction of hidden writers, instant recovery release,
stale authority and release-before-convergence semantics
```

---

# 2. Current runtime architecture baseline

The current runtime architecture now includes the following active foundations:

```text
- runtime authority barrier;
- immutable runtime snapshot governance;
- distributed snapshot governance;
- distributed commit governance;
- semantic progress evidence based on real runtime phase epochs;
- systemic convergence evidence;
- convergence lease acquisition;
- lease-based release semantics;
- SAFE_STOP / FREEZE_PROTECTION lease-gated exit;
- consolidated system mode ownership;
- consolidated diagnostics aggregate ownership;
- health-bridge based safety truth.
```

Current recovery model:

```text
fault / invalid runtime evidence
↓
quarantine / forced-safe decay / SAFE_STOP
↓
underlying healthy evidence restored
↓
Recovery_Stable_Cycle_Count accumulates
↓
Recovery_Stable_Time_MS accumulates
↓
Convergence_Lease_OK becomes TRUE
↓
Convergence_Release_Allowed becomes TRUE
↓
critical release paths may clear quarantine / forced-safe decay
↓
SAFE_STOP / FREEZE_PROTECTION may exit
```

This replaces the old model:

```text
fault disappeared in one scan
↓
state released immediately
```

---

# 3. Authoritative runtime invariants

## 3.1 Ownership invariants

```text
G_System_Mode has a single authoritative owner.
```

Owner path:

```text
FB_System_Health_Orchestrator
→ FB_State_Manager
→ GVL_STATE.G_System_Mode
```

Forbidden:

```text
Direct writes to GVL_STATE.G_System_Mode from policy, recovery,
persistence, diagnostics, HMI, gateway or domain logic.
```

---

```text
Safety latches are owned by FB_Safety_Manager.
```

Owner path:

```text
GVL_HEALTH_BRIDGE safety truth
→ FB_System_Health_Orchestrator
→ FB_Safety_Manager
→ GVL_STATE.G_Safety_*_Latched
```

Forbidden:

```text
Persistent boot restore or direct cross-domain writes to safety latches.
```

---

```text
Diagnostics aggregates are owned by FB_System_Health_Orchestrator.
```

Canonical aggregate fields:

```text
GVL_STATUS.G_Diagnostics.Sensor_Fault
GVL_STATUS.G_Diagnostics.IO_Offline
GVL_STATUS.G_Diagnostics.Subsystem_Degraded
```

Forbidden:

```text
Duplicate aggregate diagnostics writers.
```

---

```text
Canonical OpenTherm boiler status is owned by PRG_OpenTherm_Adapter_Status.
```

Canonical fields:

```text
GVL_STATE.G_Boiler_OT_Online[*]
GVL_STATE.G_Boiler_Flame[*]
GVL_STATE.G_Boiler_Error[*]
```

Forbidden:

```text
PRG_IO_Read or raw IO layers overwriting canonical OpenTherm status.
```

---

## 3.2 Safety truth invariants

```text
GVL_HEALTH_BRIDGE is the canonical safety truth surface for system health,
alarm aggregation, state trace visibility and safety latch inputs.
```

Forbidden:

```text
Using stale GVL_ALARM.*_Alarm_Active or GVL_STATE.G_Safety_*_Alarm
as authoritative safety truth.
```

---

## 3.3 Semantic progress invariants

```text
Semantic progress must be based on runtime phase evidence.
```

Required evidence surfaces:

```text
GVL_RUNTIME_EPOCH.Runtime_Epoch
GVL_RUNTIME_SNAPSHOT.Snapshot_Epoch
GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Epoch
GVL_OUTPUT_EPOCH.Output_Publication_Epoch
```

Forbidden:

```text
Self-counter-only semantic progress validation.
```

---

## 3.4 Convergence invariants

```text
Convergence lease must be derived from underlying healthy evidence,
not from quarantine flags that are themselves released by the lease.
```

Required:

```text
GVL_CONVERGENCE.Convergence_Lease_OK
GVL_CONVERGENCE.Convergence_Release_Allowed
Recovery_Stable_Cycle_Count
Recovery_Stable_Time_MS
```

Forbidden:

```text
Circular dependency: release required to prove convergence.
```

---

## 3.5 Recovery release invariants

```text
Output release requires convergence lease.
```

Critical path:

```text
PRG_Output_Freshness_Governor
→ GVL_CONVERGENCE.Convergence_Release_Allowed
→ clear Output_Stale_Detected / Output_Forced_Safe_Decay
```

---

```text
Distributed snapshot quarantine release requires convergence lease.
```

Critical path:

```text
PRG_Distributed_Snapshot_Governor
→ GVL_CONVERGENCE.Convergence_Release_Allowed
→ clear Distributed_Snapshot_Quarantine_Active
```

---

```text
Distributed commit quarantine release requires convergence lease.
```

Critical path:

```text
PRG_Distributed_Commit_Governor
→ GVL_CONVERGENCE.Convergence_Release_Allowed
→ clear Distributed_Commit_Quarantine_Active
```

---

```text
SAFE_STOP / FREEZE_PROTECTION exit requires convergence lease.
```

Critical path:

```text
FB_State_Manager
→ hold previous safe mode until GVL_CONVERGENCE.Convergence_Lease_OK
```

Forbidden:

```text
One-scan SAFE_STOP exit after critical severity disappears.
```

---

# 4. Forbidden runtime patterns

The following patterns are forbidden in runtime code:

```text
- hidden writers;
- direct persistent authority restore;
- duplicate aggregate ownership;
- diagnostics-derived safety truth;
- stale alarm authority as runtime truth;
- one-cycle recovery release;
- release-before-convergence;
- convergence depending on quarantine flags released by convergence;
- direct G_System_Mode writes outside FB_State_Manager path;
- direct safety latch writes outside FB_Safety_Manager path;
- raw IO overriding canonical protocol-derived state;
- self-counter-only semantic progress validation;
- policy or HMI layers mutating authoritative runtime mode;
- boot-time stale runtime resurrection.
```

---

# 5. Fully mitigated findings

## 5.1 Hidden OpenTherm online reset

Status:

```text
FULLY MITIGATED
```

Mitigation:

```text
Removed hidden G_Boiler_OT_Online[*] := FALSE reset from PRG_IO_Read.
```

Impact:

```text
Canonical OpenTherm online state no longer has stale hidden reset path.
```

---

## 5.2 Boiler flame/error mixed ownership

Status:

```text
FULLY MITIGATED
```

Mitigation:

```text
Removed duplicate G_Boiler_Flame[*] and G_Boiler_Error[*] writers from PRG_IO_Read.
```

Current owner:

```text
PRG_OpenTherm_Adapter_Status
```

---

## 5.3 Persistent boot-time authority resurrection

Status:

```text
FULLY MITIGATED FOR SYSTEM MODE AND SAFETY LATCHES
```

Mitigation:

```text
FB_System_Recovery no longer restores GVL_STATE.G_Safety_*_Latched
or GVL_STATE.G_System_Mode from persistent state.
```

---

## 5.4 Duplicate diagnostics aggregate writer

Status:

```text
FULLY MITIGATED
```

Mitigation:

```text
Removed FB_System_Diagnostics call from active PRG_System_Diagnostics.
Aggregated diagnostics ownership consolidated in FB_System_Health_Orchestrator.
```

---

## 5.5 Duplicate direct system mode writer in policy

Status:

```text
FULLY MITIGATED
```

Mitigation:

```text
Removed direct GVL_STATE.G_System_Mode := MODE_DEGRADED write from PRG_Policy.
```

Current owner:

```text
FB_System_Health_Orchestrator / FB_State_Manager
```

---

## 5.6 One-cycle SAFE_STOP exit

Status:

```text
FULLY MITIGATED AT STATE MANAGER LEVEL
```

Mitigation:

```text
FB_State_Manager now holds SAFE_STOP / FREEZE_PROTECTION until
GVL_CONVERGENCE.Convergence_Lease_OK is TRUE.
```

---

# 6. Substantially mitigated findings

## 6.1 Semantic brownout survivability

Status:

```text
SUBSTANTIALLY MITIGATED
```

Mitigation:

```text
GVL_SEMANTIC_PROGRESS now stores real runtime phase evidence.
PRG_Semantic_Progress_Governor validates runtime/snapshot/distributed/output epochs.
Replay/regression and phase stall detection are present.
```

Remaining debt:

```text
- add explicit tests for delayed phase execution;
- add tests for partial runtime freeze;
- add epoch regression tests;
- add phase starvation simulation.
```

---

## 6.2 Output stale resurrection / unsafe output recovery

Status:

```text
SUBSTANTIALLY MITIGATED
```

Mitigation:

```text
PRG_Output_Freshness_Governor releases Output_Stale_Detected and
Output_Forced_Safe_Decay only after Convergence_Release_Allowed.
```

Remaining debt:

```text
- add tests proving forced-safe decay persists before convergence lease;
- add tests proving output release happens after convergence lease.
```

---

## 6.3 Distributed snapshot one-cycle recovery

Status:

```text
SUBSTANTIALLY MITIGATED
```

Mitigation:

```text
PRG_Distributed_Snapshot_Governor clears Distributed_Snapshot_Quarantine_Active
only after Convergence_Release_Allowed.
```

Remaining debt:

```text
- add distributed snapshot quarantine persistence tests;
- add peer divergence/recovery simulations.
```

---

## 6.4 Distributed commit one-cycle recovery

Status:

```text
SUBSTANTIALLY MITIGATED
```

Mitigation:

```text
PRG_Distributed_Commit_Governor clears Distributed_Commit_Quarantine_Active
only after Convergence_Release_Allowed.
```

Remaining debt:

```text
- add distributed commit quarantine persistence tests;
- add peer commit replay/lease expiry recovery tests.
```

---

## 6.5 Stale safety truth and latch input divergence

Status:

```text
SUBSTANTIALLY MITIGATED
```

Mitigation:

```text
Alarm aggregation, state trace and safety latch inputs use GVL_HEALTH_BRIDGE truth.
```

Remaining debt:

```text
- add tests proving detected safety truth reaches latch manager;
- add tests for CO/gas/fire/flood truth propagation.
```

---

# 7. Partially mitigated findings

## 7.1 Recovery cleanup release semantics

Status:

```text
PARTIALLY MITIGATED
```

Current issue:

```text
PRG_Recovery_Cleanup_Governor still has immediate cleanup release semantics:
Recovery_Quarantine_Active := FALSE
Recovery_Cleanup_Completed := TRUE
Recovery_Cleanup_Verified := TRUE
when L_Recovery_Valid is TRUE.
```

Required follow-up:

```text
Convert recovery cleanup completion/release to convergence-lease semantics.
```

Target invariant:

```text
Recovery cleanup completion requires convergence lease.
```

---

## 7.2 Degraded subsystem convergence harmonization

Status:

```text
PARTIALLY MITIGATED
```

Current issue:

```text
Degraded subsystem signals are partly aggregated and partly advisory.
Not all degraded paths are proven to have sustained convergence release semantics.
```

Required follow-up:

```text
Review all subsystem degraded writers and clears.
Normalize degraded release through convergence or explicit source evidence.
```

---

## 7.3 PLC fencing and asymmetric partition resilience

Status:

```text
PARTIALLY MITIGATED BY DOWNSTREAM CONVERGENCE FOUNDATIONS
```

Current issue:

```text
Convergence/epoch/distributed quarantine foundations reduce stale release risk,
but asymmetric heartbeat partition and ownership fencing require dedicated tests
and possible further fencing-token hardening.
```

Required follow-up:

```text
Add asymmetric partition simulation and stale-owner resurrection tests.
```

---

# 8. Remaining active risks

The remaining active risk surface is now narrower and mostly test/proof or
follow-up governance work.

## 8.1 Recovery cleanup immediate release

Risk:

```text
Recovery cleanup may still mark cleanup complete after one valid scan.
```

Owner:

```text
PRG_Recovery_Cleanup_Governor
```

Next action:

```text
Migrate cleanup release to Convergence_Release_Allowed.
```

---

## 8.2 Missing formal invariant verification suite

Risk:

```text
Architecture invariants exist in code but are not yet protected by tests.
```

Required tests:

```text
- no direct G_System_Mode writers outside owner path;
- no direct safety latch writers outside FB_Safety_Manager path;
- no output release before convergence lease;
- no distributed quarantine release before convergence lease;
- no SAFE_STOP exit before convergence lease;
- no semantic progress self-counter-only validation regression.
```

---

## 8.3 Missing convergence invalidation tests

Risk:

```text
Convergence lease invalidation after evidence regression must be proven.
```

Required tests:

```text
- runtime barrier invalidation resets lease;
- snapshot mutation resets lease;
- distributed commit invalidation resets lease;
- semantic replay resets lease;
- output invalidation resets lease.
```

---

## 8.4 Missing distributed partition/failover simulations

Risk:

```text
Asymmetric heartbeat visibility and stale owner resurrection are not yet fully proven.
```

Required tests:

```text
- asymmetric packet loss;
- delayed heartbeat replay;
- peer snapshot divergence;
- peer commit replay;
- failover under partial partition;
- reconnect oscillation.
```

---

# 9. Remaining technical debt

Current technical debt list:

```text
1. Convert PRG_Recovery_Cleanup_Governor cleanup release to convergence lease.
2. Add convergence lease acquisition/invalidation tests.
3. Add SAFE_STOP exit blocked-before-lease tests.
4. Add output forced-safe decay persistence tests.
5. Add distributed snapshot/commit quarantine persistence tests.
6. Add invariant verification suite for ownership and forbidden patterns.
7. Review degraded subsystem convergence paths.
8. Add asymmetric partition and failover simulation suite.
9. Add semantic progress phase starvation tests.
10. Update RUNTIME_DEEP_AUDIT_PART_10 after proof/test pass.
```

---

# 10. Historical audit mapping

## RISK-040

Current status:

```text
PARTIALLY MITIGATED
```

Reason:

```text
Output freshness and convergence hardening reduce unsafe output recovery,
but PRG_Command_Verifier still executes after PRG_IO_Write. Pre-output verifier
ordering remains a separate open issue.
```

---

## RISK-041

Current status:

```text
SUBSTANTIALLY MITIGATED
```

Reason:

```text
Diagnostics truth cleanup, health-bridge safety truth, semantic progress evidence
and convergence visibility reduce stale-safe observability windows.
```

Remaining:

```text
Physical IO/verification timing proof remains open.
```

---

## RISK-043

Current status:

```text
SUBSTANTIALLY MITIGATED
```

Reason:

```text
Boot-time stale resurrection removed; convergence lease foundation and lease-based
release semantics added.
```

Remaining:

```text
PRG_Recovery_Cleanup_Governor still requires lease-based cleanup release.
```

---

## RISK-044

Current status:

```text
PARTIALLY MITIGATED
```

Reason:

```text
Distributed snapshot/commit quarantine and convergence release reduce stale release,
but explicit fencing-token / ownership-epoch proof remains open.
```

---

## RISK-045

Current status:

```text
PARTIALLY MITIGATED
```

Reason:

```text
Convergence and distributed quarantine reduce unsafe release under divergence,
but asymmetric heartbeat partition still requires dedicated simulation/proof.
```

---

## RISK-046

Current status:

```text
SUBSTANTIALLY MITIGATED
```

Reason:

```text
Semantic progress is now phase-evidence based and convergence lease semantics
separate liveness from semantic validity.
```

Remaining:

```text
Formal semantic starvation / freeze / regression tests are still required.
```

---

# 11. Operational rule for future remediation

Future remediation must preserve these rules:

```text
1. Do not introduce direct writes to authoritative state from policy/HMI/recovery layers.
2. Do not clear quarantine/forced-safe state without convergence release.
3. Do not restore runtime authority from persistent state.
4. Do not use diagnostics projections as safety truth.
5. Do not replace phase-evidence semantic progress with self-counter-only progress.
6. Do not allow SAFE_STOP exit without convergence lease.
7. Do not create duplicate aggregate diagnostics writers.
8. Do not hide cross-domain resets in IO read/write layers.
```

---

# 12. Current conclusion

The runtime architecture has moved from forensic cleanup to managed deterministic
runtime governance.

Current model:

```text
detection
→ quarantine / SAFE_STOP
→ sustained evidence
→ convergence lease
→ controlled release
```

The primary remaining work is now:

```text
- recovery cleanup lease migration;
- formal invariant tests;
- convergence invalidation tests;
- distributed partition/failover simulations;
- degraded convergence harmonization.
```
