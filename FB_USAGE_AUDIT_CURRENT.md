# FB_USAGE_AUDIT_CURRENT.md

# Status

This document reflects the CURRENT verified runtime architecture after:

```text
- active runtime ownership audit;
- donor extraction audit;
- write-boundary verification;
- helper side-effect verification;
- governance classification;
- runtime evidence validation.
```

The audit intentionally ignores:

```text
- snapshots/;
- archive logs;
- export sandboxes;
- disconnected historical harnesses.
```

Current phase:

```text
GOVERNED RUNTIME MAINTENANCE
```

---

# Repository editing rule

NO PARTIAL FILE PATCHING.

All future file modifications must:

```text
- fully rewrite the file;
- preserve internal consistency;
- synchronize runtime contracts;
- synchronize ownership contracts;
- synchronize governance contracts.
```

Reason:

```text
partial edits create architectural drift.
```

---

# Verified cleanup result

The repository has already been cleaned from:

```text
- disconnected utility FBs;
- abandoned persistence branches;
- duplicated calibration paths;
- disconnected observer placeholders;
- dead test harnesses;
- detached orchestration runtime fragments;
- dangerous duplicate ownership shells.
```

Important:

```text
remaining architectural work
is governance-oriented,
not mass-cleanup-oriented.
```

---

# Verified active runtime ownership chain

Current verified runtime chain:

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
    → System_Manager post-manifold safety/test finalization
    → Boiler_Control
```

Verified properties:

```text
- single active runtime ownership chain;
- no detached orchestration path detected;
- no hidden Runtime_* actuation detected;
- no helper authority escalation detected.
```

---

# Current heating/OpenTherm architecture status

## Boiler/OpenTherm authority

Verified authoritative owner:

```text
FB_Heating_Boiler_Control
```

Verified internal helper path:

```text
FB_Boiler_Cascade_Manager
→ FB_Boiler_OpenTherm_Interface
```

Verified result:

```text
bounded helper execution only
```

NOT:

```text
hidden authority escalation.
```

---

## OpenTherm transport observability

Implemented and verified:

```text
- stable command sequence semantics;
- adapter ACK validation;
- heartbeat telemetry;
- command age telemetry;
- semantic adapter state;
- semantic adapter error state.
```

Public state available through:

```text
GVL_STATE
```

Verified boundary:

```text
read-only observability
without control ownership expansion.
```

---

## Boiler semantic status

Implemented and verified:

```text
- OT_Online;
- OT_Command_Valid;
- OT_Transport_Degraded;
- Available;
- Selected_By_Cascade;
- Flame_Missing;
- Ignition_Timeout;
- Degraded.
```

Verified role:

```text
semantic diagnostics only
```

---

## Cascade semantic aggregate state

Implemented and verified in:

```text
GVL_STATE
```

Examples:

```text
- G_Heating_Cascade_Available;
- G_Heating_Cascade_Degraded;
- G_Heating_Cascade_No_Flame;
- G_Heating_Cascade_Transport_Degraded.
```

Verified role:

```text
aggregate diagnostics projection only
```

---

# Current diagnostics layering

## Layer 1 — Runtime semantic state

Produced by:

```text
FB_Boiler_OpenTherm_Interface
FB_Heating_Boiler_Control
```

Purpose:

```text
transport/boiler/cascade semantics
```

---

## Layer 2 — Inference engine

Block:

```text
FB_Diagnostics_RootCause
```

Purpose:

```text
hydraulic/thermal/runtime inference
```

Restriction:

```text
NO runtime authority
```

---

## Layer 3 — Explainability observer

Block:

```text
FB_Heating_RootCause_Diagnostics
```

Purpose:

```text
state collection
+
explainability publication
```

Restriction:

```text
projection only
```

---

## Layer 4 — Diagnostics event projection

Block:

```text
FB_Heating_Diagnostics
```

Verified role:

```text
read-only diagnostics/event projection
```

NOT:

```text
runtime control ownership.
```

---

## Layer 5 — Explainability / HMI

Blocks:

```text
PRG_Explainability
PRG_HMI_Dashboard
```

Purpose:

```text
operator projection only
```

---

# Verified donor extraction result

## Historical orchestration donors

Historical donor blocks:

```text
FB_Heating_Execution_Core
FB_Heating_Orchestration
```

Verified status:

```text
VERIFIED REMOVED DONORS
```

Reason:

```text
would create detached orchestration/runtime ownership path.
```

---

## Historical allocation/policy donors

Historical donor blocks:

```text
FB_Heating_Thermal_Allocation
FB_Heating_Decision_Context
```

Verified extraction:

```text
logic absorbed into:
- FB_Heating_Policy_Priority_Bridge
- FB_Heating_Allocation_Filter
```

Verified status:

```text
VERIFIED EXTRACTED DONORS
```

---

## Historical protection donors

Historical donor blocks:

```text
FB_FloorHeating_Freeze_Protection
FB_FloorHeating_Overheat_Protection
```

Verified absorption:

```text
absorbed into:
- FB_Heating_Safety_Gate
- FB_Heating_Safe_State
- FB_Heating_Circuit_Control
```

Verified status:

```text
VERIFIED ABSORBED DONORS
```

---

## Historical dangerous authority donor

Block:

```text
FB_Heating_Override_Layer
```

Verified role:

```text
historical detached authority shell
```

Capabilities:

```text
- valve suppression;
- manifold suppression;
- OpenTherm suppression;
- DHW suppression.
```

Verified policy:

```text
DO NOT CONNECT DIRECTLY
```

Allowed future role:

```text
conceptual extraction review only
```

---

# Runtime governance classification

## Active runtime owners

Verified runtime owners:

```text
FB_Heating_System_Manager
FB_Heating_Circuit_Control
FB_Heating_Manifold_Control
FB_Heating_Boiler_Control
FB_Heating_Safety_Gate
FB_Heating_Safe_State
```

---

## Runtime_* family

Verified role:

```text
passive governance / observability / forensic scaffold
```

Allowed:

```text
- telemetry;
- diagnostics;
- governance validation;
- sequencing validation;
- anomaly analysis;
- forensic reconstruction.
```

Forbidden:

```text
runtime actuation.
```

---

## Bounded helper execution layers

Verified helper examples:

```text
FB_Boiler_Cascade_Manager
FB_Boiler_OpenTherm_Interface
FB_Valve_Test_Manager
```

Verified result:

```text
helper authority escalation not detected.
```

---

# Verified ownership nuances

## Manifold ownership model

Verified result:

```text
FB_Heating_Manifold_Control
=
primary manifold actuator helper
```

while:

```text
FB_Heating_System_Manager
=
bounded post-manifold safety/test finalizer
```

Verified post-manifold responsibilities:

```text
- low-pressure suppression;
- confidence-fallback suppression;
- valve-test override finalization.
```

Important:

```text
this is NOT detached second authority path.
```

---

# Snapshot / blackbox prototype

Block:

```text
FB_State_Snapshot_Manager
```

Verified role:

```text
dormant architectural prototype
```

Status:

```text
KEEP VISIBLE
KEEP ISOLATED
```

Reason:

```text
future architectural review candidate.
```

---

# Current verified risk model

The primary risk is no longer:

```text
compile collapse
```

The primary risk is now:

```text
future architectural drift.
```

Especially dangerous:

```text
- detached orchestration resurrection;
- Runtime_* actuation;
- hidden helper escalation;
- duplicate writers;
- hidden finalization layers;
- telemetry-driven control;
- governance-driven control.
```

---

# Current architectural result

The heating repository now has:

```text
- explicit ownership boundaries;
- explicit governance boundaries;
- explicit write-boundary enforcement;
- runtime evidence verification;
- anti-pattern enforcement;
- bounded helper execution;
- explicit post-manifold finalization.
```

The repository evolved from:

```text
legacy runtime cleanup
```

into:

```text
governed runtime architecture maintenance.
```

---

# Remaining future review targets

Remaining future review items:

```text
- FB_Heating_Override_Layer conceptual extraction review;
- compile/runtime verification after latest integrations;
- possible future extraction of bounded manifold finalization helper;
- future architectural drift prevention.
```
