# RUNTIME INVARIANTS

Authoritative runtime invariant registry.

Date:

```text
2026-05-13
```

Scope:

```text
runtime governance
ownership invariants
recovery invariants
convergence invariants
semantic invariants
forbidden runtime patterns
```

Purpose:

```text
Preserve deterministic runtime architecture invariants and
prevent regression into hidden writers, stale authority,
instant recovery release and unsafe convergence semantics.
```

---

# 1. Runtime governance model

The runtime architecture is governed by the following deterministic model:

```text
detection
→ quarantine / SAFE_STOP
→ sustained healthy evidence
→ convergence lease acquisition
→ controlled release
```

The following patterns are forbidden:

```text
fault disappears in one scan
→ immediate release
```

or:

```text
policy/persistence/HMI layer mutates authoritative runtime state directly
```

---

# 2. Ownership invariants

## 2.1 System mode ownership

Invariant:

```text
GVL_STATE.G_System_Mode has a single authoritative owner.
```

Canonical ownership path:

```text
FB_System_Health_Orchestrator
→ FB_State_Manager
→ GVL_STATE.G_System_Mode
```

Allowed mutation authority:

```text
FB_State_Manager only
```

Forbidden:

```text
- PRG_Policy writing G_System_Mode
- PRG_Recovery writing G_System_Mode
- persistence restore writing G_System_Mode
- HMI/gateway/direct IO writing G_System_Mode
- diagnostics layers writing G_System_Mode
```

Verification target:

```text
Search for:
G_System_Mode :=
```

Only canonical owner path is allowed.

---

## 2.2 Safety latch ownership

Invariant:

```text
Safety latches are owned by FB_Safety_Manager.
```

Canonical ownership path:

```text
GVL_HEALTH_BRIDGE safety truth
→ FB_System_Health_Orchestrator
→ FB_Safety_Manager
→ GVL_STATE.G_Safety_*_Latched
```

Forbidden:

```text
- persistence restore writing safety latches
- policy logic writing safety latches
- diagnostics layers writing safety latches
- IO layers writing safety latches
- distributed layers writing safety latches
```

Verification target:

```text
Search for:
G_Safety_.*_Latched :=
```

Only canonical owner path is allowed.

---

## 2.3 Diagnostics aggregate ownership

Invariant:

```text
Diagnostics aggregates have single authoritative owners.
```

Canonical aggregate owner:

```text
FB_System_Health_Orchestrator
```

Protected aggregate fields:

```text
GVL_STATUS.G_Diagnostics.Sensor_Fault
GVL_STATUS.G_Diagnostics.IO_Offline
GVL_STATUS.G_Diagnostics.Subsystem_Degraded
```

Forbidden:

```text
Duplicate aggregate diagnostics writers.
```

Verification target:

```text
Search for:
Sensor_Fault :=
IO_Offline :=
Subsystem_Degraded :=
```

Only canonical aggregate owner is allowed.

---

## 2.4 OpenTherm canonical ownership

Invariant:

```text
Canonical OpenTherm boiler status is owned by PRG_OpenTherm_Adapter_Status.
```

Protected fields:

```text
GVL_STATE.G_Boiler_OT_Online[*]
GVL_STATE.G_Boiler_Flame[*]
GVL_STATE.G_Boiler_Error[*]
```

Forbidden:

```text
PRG_IO_Read or raw IO layers overriding protocol-derived state.
```

Verification target:

```text
Search for:
G_Boiler_OT_Online :=
G_Boiler_Flame :=
G_Boiler_Error :=
```

Only canonical protocol owner is allowed.

---

# 3. Safety truth invariants

## 3.1 Canonical safety truth

Invariant:

```text
GVL_HEALTH_BRIDGE is the canonical runtime safety truth surface.
```

Consumers:

```text
FB_System_Health_Orchestrator
FB_System_Alarm_Orchestrator
PRG_System_Diagnostics
FB_Safety_Manager
```

Forbidden:

```text
Using stale alarm projections as authoritative runtime safety truth.
```

Examples:

```text
GVL_ALARM.G_Fire_Alarm_Active
GVL_ALARM.G_Gas_Alarm_Active
GVL_STATE.G_Safety_*_Alarm
```

must not replace canonical health-bridge truth.

---

# 4. Semantic progress invariants

## 4.1 Runtime phase evidence

Invariant:

```text
Semantic progress must use runtime phase evidence.
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

Required semantic protections:

```text
- replay detection
- regression detection
- stall detection
- semantic continuity validation
```

---

# 5. Convergence invariants

## 5.1 Convergence independence

Invariant:

```text
Convergence proof must not depend on quarantine flags
that are themselves released by convergence.
```

Required convergence evidence:

```text
Recovery_Stable_Cycle_Count
Recovery_Stable_Time_MS
```

Required outputs:

```text
GVL_CONVERGENCE.Convergence_Lease_OK
GVL_CONVERGENCE.Convergence_Release_Allowed
```

Forbidden:

```text
Circular convergence logic.
```

Example forbidden pattern:

```text
lease requires quarantine clear
while quarantine clear requires lease
```

---

## 5.2 Lease acquisition semantics

Invariant:

```text
Convergence lease acquisition requires sustained healthy evidence.
```

Forbidden:

```text
One-cycle healthy recovery.
```

Forbidden pattern:

```text
IF valid THEN clear
```

without:

```text
GVL_CONVERGENCE.Convergence_Release_Allowed
```

---

# 6. Recovery release invariants

## 6.1 Output release

Invariant:

```text
Output release requires convergence lease.
```

Protected release surfaces:

```text
Output_Stale_Detected
Output_Forced_Safe_Decay
```

Canonical authority:

```text
PRG_Output_Freshness_Governor
```

Required gate:

```text
GVL_CONVERGENCE.Convergence_Release_Allowed
```

---

## 6.2 Distributed snapshot release

Invariant:

```text
Distributed snapshot quarantine release requires convergence lease.
```

Protected surface:

```text
Distributed_Snapshot_Quarantine_Active
```

Canonical authority:

```text
PRG_Distributed_Snapshot_Governor
```

Required gate:

```text
GVL_CONVERGENCE.Convergence_Release_Allowed
```

---

## 6.3 Distributed commit release

Invariant:

```text
Distributed commit quarantine release requires convergence lease.
```

Protected surface:

```text
Distributed_Commit_Quarantine_Active
```

Canonical authority:

```text
PRG_Distributed_Commit_Governor
```

Required gate:

```text
GVL_CONVERGENCE.Convergence_Release_Allowed
```

---

## 6.4 Recovery cleanup completion

Invariant:

```text
Recovery cleanup completion requires convergence lease.
```

Protected surfaces:

```text
Recovery_Cleanup_Completed
Recovery_Cleanup_Verified
Recovery_Quarantine_Active
```

Canonical authority:

```text
PRG_Recovery_Cleanup_Governor
```

Required gate:

```text
GVL_CONVERGENCE.Convergence_Release_Allowed
```

---

## 6.5 SAFE_STOP exit semantics

Invariant:

```text
SAFE_STOP / FREEZE_PROTECTION exit requires convergence lease.
```

Canonical authority:

```text
FB_State_Manager
```

Required gate:

```text
GVL_CONVERGENCE.Convergence_Lease_OK
```

Forbidden:

```text
One-cycle SAFE_STOP exit.
```

Forbidden pattern:

```text
critical fault disappears
→ mode restored immediately
```

---

# 7. Persistence invariants

## 7.1 No authoritative runtime resurrection

Invariant:

```text
Persistent storage must not restore authoritative runtime state.
```

Protected surfaces:

```text
G_System_Mode
G_Safety_*_Latched
```

Forbidden:

```text
Boot-time stale runtime resurrection.
```

Allowed:

```text
bootstrap markers
non-authoritative diagnostics history
statistics
telemetry
```

---

# 8. Forbidden runtime patterns

The following runtime patterns are forbidden:

```text
- hidden writers
- duplicate aggregate ownership
- direct persistent authority restore
- diagnostics-derived safety truth
- stale alarm truth used as runtime authority
- release-before-convergence
- one-cycle recovery release
- one-cycle SAFE_STOP exit
- self-counter-only semantic validation
- circular convergence proof
- raw IO overriding canonical protocol state
- policy/HMI/direct IO mutating authoritative runtime mode
- persistence restoring runtime authority
- hidden cross-domain resets
```

---

# 9. Verification workflow

## 9.1 Ownership verification

Required searches:

```text
G_System_Mode :=
G_Safety_.*_Latched :=
Sensor_Fault :=
IO_Offline :=
Subsystem_Degraded :=
G_Boiler_OT_Online :=
G_Boiler_Flame :=
G_Boiler_Error :=
```

Goal:

```text
Detect hidden writers and duplicate ownership.
```

---

## 9.2 Recovery verification

Required searches:

```text
IF .*Valid THEN
.*Quarantine_Active := FALSE
.*Forced_Safe.* := FALSE
.*Cleanup_Completed := TRUE
```

Goal:

```text
Detect release-before-convergence patterns.
```

Required gate:

```text
GVL_CONVERGENCE.Convergence_Release_Allowed
```

---

## 9.3 SAFE_STOP verification

Required proof:

```text
critical severity disappears
→ SAFE_STOP remains active
until convergence lease acquired
```

---

## 9.4 Semantic verification

Required proof:

```text
semantic progress uses runtime phase evidence
```

Forbidden:

```text
semantic progress derived only from self-generated counters
```

---

# 10. Runtime governance conclusion

The runtime architecture is now governed by deterministic convergence semantics.

Canonical runtime model:

```text
detection
→ quarantine / SAFE_STOP
→ sustained healthy evidence
→ convergence lease acquisition
→ controlled release
```

Future remediation and feature work must preserve these invariants.
