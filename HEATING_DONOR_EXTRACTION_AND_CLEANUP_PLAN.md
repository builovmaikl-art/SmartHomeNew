# HEATING_DONOR_EXTRACTION_AND_CLEANUP_PLAN

# Purpose

This document defines the active donor-extraction workflow for unused/disconnected `FB_Heating*.st` blocks.

The project no longer treats grey/disconnected heating FBs as automatic reconnect candidates.

The new direction is:

```text
extract useful behavior
→ merge into active runtime owners
→ verify ownership/runtime path
→ remove donor blocks
```

without creating:

```text
- second orchestration layer;
- duplicate runtime authority;
- detached parallel runtime path;
- hidden safety ownership conflicts.
```

This document continues the direction already established in:

```text
HEATING_ACTIVE_FB_CALL_GRAPH_AUDIT.md
HEATING_ALLOCATION_MIGRATION_PHASE.md
```

---

# Core engineering rule

The project now follows:

```text
DONOR EXTRACTION FIRST
RECONNECT NEVER BY DEFAULT
```

Meaning:

```text
old FBs are mined for useful bounded logic
instead of reconnecting historical orchestration pipelines.
```

Allowed:

```text
- bounded logic extraction;
- ownership-safe merge;
- observability extraction;
- policy extraction;
- diagnostics extraction;
- allocation semantics extraction.
```

Forbidden:

```text
- reconnecting obsolete orchestration shells;
- reconnecting detached authority layers;
- creating parallel runtime paths;
- restoring historical runtime wholesale.
```

---

# Current active target architecture

Current active direction:

```text
PRG_Heating
→ FB_Heating_System_Manager
    → Circuit_Control
    → Demand_Map
    → Policy_Priority_Bridge
    → Allocation_Filter
    → Runtime_Observability
    → Manifold_Control
    → Boiler_Control
```

Important rule:

```text
All extracted donor behavior must be merged
into existing active runtime owners.
```

NOT:

```text
new upper orchestration shells.
```

---

# Donor classification model

## Category A — Already extracted / obsolete donor

Definition:

```text
useful logic already absorbed into active runtime
```

Expected final action:

```text
delete donor after verification
```

---

## Category B — Useful donor remains

Definition:

```text
still contains bounded useful logic
not yet fully represented in active runtime
```

Expected action:

```text
extract incrementally
then delete donor
```

---

## Category C — Dangerous authority donor

Definition:

```text
contains hard authority logic
unsafe for direct reconnect
```

Expected action:

```text
extract concepts only
never reconnect directly
```

---

## Category D — Grey reserved scaffold

Definition:

```text
future-reserved or supervision-oriented architecture
not active runtime logic donor
```

Expected action:

```text
keep isolated
no reconnect
no blind deletion
```

---

# Current donor inventory

## 1. FB_Heating_Decision_Context

Current status:

```text
already substantially extracted
```

Useful behavior historically provided:

```text
- manifold availability filtering;
- service-state exclusion;
- pressure/current degradation exclusion;
- manifold enable decision;
- priority-ordered selection;
- thermal budget limiting.
```

Current active replacement path:

```text
FB_Heating_Allocation_Filter
```

Current direction:

```text
verify no remaining unique behavior
→ then delete donor
```

Current classification:

```text
CATEGORY A
```

---

## 2. FB_Heating_Thermal_Allocation

Current status:

```text
already substantially extracted
```

Useful behavior historically provided:

```text
- manifold base priority;
- zone priority bias;
- guest preheat priority boost;
- policy priority multiplier;
- manifold thermal weight;
- thermal budget semantics.
```

Current active replacement path:

```text
FB_Heating_Policy_Priority_Bridge
FB_Heating_Allocation_Filter
```

Current direction:

```text
verify no remaining unique behavior
→ then delete donor
```

Current classification:

```text
CATEGORY A
```

---

## 3. FB_Heating_Execution_Core

Current status:

```text
duplicate wrapper
```

Historical role:

```text
wrapper around active managers
```

Current active replacement path:

```text
PRG_Heating
→ FB_Heating_System_Manager
→ FB_DHW_Manager
```

Current direction:

```text
delete after reference verification
```

Current classification:

```text
CATEGORY A
```

---

## 4. FB_Heating_Orchestration

Current status:

```text
obsolete orchestration shell
```

Critical risk:

```text
reconnect would create second runtime authority path
```

Current direction:

```text
do not reconnect
remove after reference verification
```

Current classification:

```text
CATEGORY A
```

---

## 5. FB_Heating_Override_Layer

Current status:

```text
dangerous hard-authority donor
```

Historical authority:

```text
- pump disable;
- valve disable;
- boiler OT override;
- DHW override;
- heater override.
```

Important:

```text
contains useful authority-isolation concepts
but must never be reconnected directly.
```

Current direction:

```text
extract concepts only
then delete if fully superseded
```

Current classification:

```text
CATEGORY C
```

---

## 6. FB_FloorHeating_Freeze_Protection

Current status:

```text
logic absorbed
```

Current active owners:

```text
FB_Heating_Safety_Gate
FB_Heating_Safe_State
```

Current direction:

```text
delete after final verification
```

Current classification:

```text
CATEGORY A
```

---

## 7. FB_FloorHeating_Overheat_Protection

Current status:

```text
logic absorbed
```

Current active owner:

```text
FB_Heating_Circuit_Control
```

Current direction:

```text
delete after final verification
```

Current classification:

```text
CATEGORY A
```

---

## 8. FB_Heating_Runtime_* family

Current status:

```text
mostly supervision / telemetry / analytics scaffold
```

Important:

```text
these are NOT direct runtime-control donors.
```

Allowed extraction:

```text
- observability ideas;
- telemetry projection;
- runtime validation semantics;
- anomaly analytics;
- passive diagnostics.
```

Forbidden:

```text
wholesale reconnect
```

Current classification:

```text
CATEGORY D
```

---

# Cleanup strategy

The cleanup strategy must proceed in batches.

---

## Batch 1 — Proven obsolete wrappers

Candidates:

```text
FB_Heating_Execution_Core
FB_Heating_Orchestration
```

Condition before deletion:

```text
- no active references;
- no project registration dependency;
- no HMI/config dependency.
```

---

## Batch 2 — Extracted allocation donors

Candidates:

```text
FB_Heating_Decision_Context
FB_Heating_Thermal_Allocation
```

Condition before deletion:

```text
- active bridge/filter path verified;
- no remaining unique logic;
- compile-safe replacement confirmed.
```

---

## Batch 3 — Absorbed protection duplicates

Candidates:

```text
FB_FloorHeating_Freeze_Protection
FB_FloorHeating_Overheat_Protection
```

Condition before deletion:

```text
- freeze behavior verified in active safety path;
- overheat behavior verified in circuit control path.
```

---

## Batch 4 — Dangerous authority donor review

Candidate:

```text
FB_Heating_Override_Layer
```

Special rule:

```text
do not delete blindly
```

Reason:

```text
contains historical authority semantics
that may still be useful architecturally.
```

---

# Required verification workflow

Before any donor deletion:

```text
1. repository reference search;
2. project participation check;
3. ownership overlap verification;
4. replacement-path verification;
5. compile/runtime risk review;
6. fetch-after-verification.
```

---

# Main architectural invariant

The invariant that must never be violated:

```text
single active runtime authority path
```

Meaning:

```text
all useful donor behavior
must be merged into existing active owners
instead of restoring detached orchestration layers.
```
