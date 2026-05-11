# HEATING_ACTIVE_WRITE_PATH_VERIFICATION

# Purpose

This document verifies actual production runtime write paths against the formal governance and ownership contracts.

The goal is to move from:

```text
architecture theory
```

to:

```text
verified runtime enforcement.
```

This document validates:

```text
- actual runtime writers;
- actual runtime authority paths;
- hidden side-effect writers;
- telemetry/control separation;
- governance/control separation;
- ownership consistency.
```

This document extends:

```text
HEATING_RUNTIME_GOVERNANCE_CLASSIFICATION.md
HEATING_RUNTIME_OWNERSHIP_MATRIX.md
HEATING_GVL_WRITE_AUDIT.md
```

into:

```text
runtime evidence verification.
```

---

# Core verification invariant

The invariant that must never be violated:

```text
single active runtime authority path
```

Verified active authority chain:

```text
PRG_Heating
→ FB_Heating_System_Manager
    → Safety_Gate
    → Safe_State
    → Circuit_Control
    → Demand_Map
    → Policy_Priority_Bridge
    → Allocation_Filter
    → Runtime_Observability
    → Manifold_Control
    → System_Manager post-manifold safety/test overrides
    → Boiler_Control
```

Verification target:

```text
all actual runtime writes
must conform to this ownership chain.
```

---

# Verification methodology

## Step 1 — Identify authoritative writer

For each runtime domain:

```text
- identify actual writer;
- identify actual write location;
- identify direct output ownership;
- identify indirect side effects.
```

---

## Step 2 — Identify hidden write paths

Search targets:

```text
- helper FB writes;
- indirect GVL mutation;
- hidden override semantics;
- Runtime_* side effects;
- detached write paths.
```

---

## Step 3 — Validate ownership consistency

Every actual runtime writer must match:

```text
HEATING_RUNTIME_OWNERSHIP_MATRIX.md
```

Any mismatch becomes:

```text
runtime governance violation.
```

---

# Verified runtime domains

## Heating runtime execution

Expected authoritative writer:

```text
FB_Heating_System_Manager
```

Verification targets:

```text
- runtime sequencing;
- manifold execution ordering;
- active heating coordination;
- runtime execution chain.
```

Verification status:

```text
VERIFIED WITH FINDINGS
```

Current findings:

```text
- System_Manager is the active heating execution owner;
- System_Manager calls safety, circuit, demand, policy, allocation, observability, manifold, and boiler blocks;
- System_Manager also performs post-manifold pressure/confidence/valve-test overrides;
- this is inside active runtime chain, not detached Runtime_* governance path.
```

Architectural note:

```text
System_Manager remains the top-level runtime owner.
Manifold_Control is the primary manifold actuator helper,
but final manifold outputs may still be modified by System_Manager
for pressure safety, confidence fallback, and valve-test override.
```

---

## Circuit thermal protection

Expected authoritative writer:

```text
FB_Heating_Circuit_Control
```

Verification targets:

```text
- overheat shutdown writes;
- thermal valve protection writes;
- circuit enable writes.
```

Verification status:

```text
VERIFIED
```

Current findings:

```text
- overheat timer logic detected;
- forced zone valve close semantics detected;
- no Runtime_* authority overlap detected.
```

---

## Freeze protection

Expected authoritative writers:

```text
FB_Heating_Safety_Gate
FB_Heating_Safe_State
```

Verification targets:

```text
- freeze-safe writes;
- freeze circulation semantics;
- emergency-safe heating state.
```

Verification status:

```text
VERIFIED
```

Current findings:

```text
- freeze detection semantics detected in Safety_Gate;
- freeze-safe projection detected in Safe_State;
- safe-state branch returns before normal runtime execution;
- no Runtime_* authority overlap detected.
```

---

## Allocation runtime authority

Expected authoritative writer:

```text
FB_Heating_Allocation_Filter
```

Verification targets:

```text
- manifold admission writes;
- thermal budget writes;
- degraded manifold exclusion writes;
- bounded allocation writes.
```

Verification status:

```text
VERIFIED
```

Current findings:

```text
- bounded allocation semantics detected;
- degraded manifold filtering detected;
- freeze and DHW bypass semantics detected;
- no detached allocation runtime detected.
```

---

## Priority runtime authority

Expected authoritative writer:

```text
FB_Heating_Policy_Priority_Bridge
```

Verification targets:

```text
- effective priority writes;
- policy multiplier writes;
- bounded priority bucket writes.
```

Verification status:

```text
VERIFIED
```

Current findings:

```text
- bounded priority semantics detected;
- neutral unset handling detected;
- no Runtime_* write authority detected.
```

---

## Manifold runtime execution

Expected primary writer:

```text
FB_Heating_Manifold_Control
```

Actual write model:

```text
primary actuator helper
+
System_Manager post-manifold finalization
```

Verification targets:

```text
- manifold valve writes;
- manifold pump writes;
- runtime realization writes;
- post-manifold override writes.
```

Verification status:

```text
VERIFIED WITH FINDINGS
```

Current findings:

```text
- Manifold_Control writes VO_Manifold_Pumps and VO_Manifold_Valves;
- Manifold_Control owns PID valve realization;
- Manifold_Control owns DHW suppression at manifold level;
- Manifold_Control owns freeze pump/valve minimum behavior;
- System_Manager may overwrite pumps after Manifold_Control for low-pressure safety;
- System_Manager may overwrite all manifold pumps for low-pressure confidence reason code 3;
- System_Manager may overwrite a selected valve/pump during Valve_Test_Manager active test.
```

Important ownership finding:

```text
Manifold_Control is not the only final manifold writer.
System_Manager currently performs final post-manifold safety/test output finalization.
```

Refinement candidate:

```text
future refactor could move post-manifold finalization
into a dedicated bounded finalization helper,
but no runtime change is made by this audit.
```

---

## Boiler/OpenTherm authority

Expected authoritative writer:

```text
FB_Heating_Boiler_Control
```

Verification targets:

```text
- boiler enable writes;
- OpenTherm writes;
- supply target writes;
- thermal source coordination writes.
```

Verification status:

```text
VERIFIED
```

Current findings:

```text
- Boiler_Control is the actual OT/boiler writer;
- OT authority flows through Boiler_Cascade_Manager and Boiler_OpenTherm_Interface;
- no Runtime_* OT authority detected;
- no detached Override_Layer path detected;
- Boiler_Control writes cascade semantic GVL_STATE fields, but these are status/diagnostics oriented rather than direct actuation authority.
```

Critical historical risk:

```text
FB_Heating_Override_Layer
```

Verification result:

```text
detached override semantics not detected in production root actuation path.
```

---

## Runtime observability

Expected authoritative writer:

```text
FB_Heating_Runtime_Observability
```

Verification targets:

```text
- telemetry projection writes;
- diagnostics publication writes;
- runtime observability writes.
```

Critical verification:

```text
ensure observability remains read-only
relative to runtime authority.
```

Verification status:

```text
PARTIALLY VERIFIED
```

Current findings:

```text
no direct actuation ownership detected yet.
```

---

## Governance scaffold

Governance targets:

```text
FB_Heating_Runtime_Orchestration_Shell
FB_Heating_Runtime_Coordinator
FB_Heating_Runtime_Integration_Bridge_Manager
FB_Heating_Runtime_Contract_Validator
```

Verification targets:

```text
- governance-only writes;
- sequencing validation writes;
- contract validation writes;
- attachment validation writes.
```

Critical verification:

```text
ensure governance scaffold
cannot perform runtime actuation.
```

Verification status:

```text
VERIFIED FOR HIGH-RISK SCAFFOLD
```

Current findings:

```text
- Governance_Locked detected;
- Runtime_Attachment_Allowed := FALSE detected;
- observation-only semantics detected;
- no direct runtime actuation detected in audited governance scaffold.
```

---

# High-risk verification targets

The following domains require continuous verification:

```text
- OpenTherm write ownership;
- manifold valve ownership;
- System_Manager post-manifold output finalization;
- hidden helper side effects;
- indirect GVL mutation;
- detached override semantics;
- Runtime_* write escalation.
```

---

# Forbidden runtime findings

The following findings would be considered architectural violations:

```text
- Runtime_* direct actuation;
- hidden valve writers outside active System_Manager chain;
- hidden boiler writers outside Boiler_Control;
- governance-driven runtime execution;
- telemetry-driven actuation;
- detached override ownership;
- second runtime authority path.
```

---

# Current audit result

Current evidence indicates:

```text
runtime authority is mostly aligned with formal ownership/governance contracts,
but manifold output ownership is more nuanced than originally documented.
```

Current verified findings:

```text
- dangerous historical orchestration path removed;
- dangerous override path removed from production root;
- Runtime_* family appears governance/observability-oriented;
- no confirmed hidden Runtime_* actuation detected;
- Boiler_Control is the actual OT/boiler writer;
- Manifold_Control is the primary manifold actuator helper;
- System_Manager currently performs final post-manifold pressure/confidence/valve-test overrides.
```

---

# Documentation synchronization required

The following documents should be synchronized with this finding:

```text
HEATING_RUNTIME_OWNERSHIP_MATRIX.md
HEATING_GVL_WRITE_AUDIT.md
```

Required change:

```text
Manifold_Control should be described as primary manifold actuator helper,
while System_Manager remains final post-manifold safety/test finalizer.
```

---

# Strategic conclusion

The repository now has:

```text
formal governance contracts
+
formal ownership contracts
+
formal write-boundary contracts
+
runtime evidence verification
```

Future runtime modifications must preserve all four layers simultaneously.

Immediate next refinement target:

```text
System_Manager post-manifold output finalization boundary
```

Potential future refactor:

```text
extract pressure/confidence/valve-test finalization
into a bounded helper
without changing runtime behavior.
```
