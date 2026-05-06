# HEATING_EXACT_RUNTIME_INTEGRATION_INSERTION_DESIGN.md

# PURPOSE

This document defines the exact runtime integration insertion design for the first observer-only live attachment.

The goal is:
- preserve deterministic runtime execution
- preserve runtime ownership isolation
- preserve finalized publication ordering
- preserve OT timing stability
- preserve cascade stability
- preserve rollback-safe integration
- preserve governance isolation

This insertion design intentionally excludes:
- orchestration migration
- runtime delegation
- predictive deployment
- adaptive deployment
- replay deployment
- writable supervision authority

---

# PRIMARY INSERTION PRINCIPLE

The observer insertion must remain:
- downstream-only
- finalized-state-only
- removable
- compile-safe
- governance-locked

The observer insertion must NEVER:
- modify runtime execution
- modify runtime ownership
- modify runtime sequencing
- modify runtime timing
- modify output ownership
- modify OT arbitration
- modify cascade arbitration

---

# EXACT INSERTION TARGET

## Primary runtime integration file

The first observer insertion target is:
- PRG_Heating

The observer insertion must occur ONLY:
- after finalized runtime publication
- after finalized diagnostics publication
- before HMI projection

---

# EXACT INSERTION ORDER

The mandatory execution order is:

1. PRG_Heating runtime logic executes
2. Runtime outputs finalize
3. Runtime ownership finalizes
4. Runtime publication finalizes
5. PRG_Explainability executes
6. Diagnostics publication finalizes
7. Observer enable condition evaluates
8. FB_Heating_Runtime_Observer executes
9. Observation contracts publish
10. Optional telemetry projection executes
11. HMI projection executes

This ordering is mandatory.

---

# EXACT INSERTION SECTION

## Required insertion location

The observer insertion must be placed:
- after all runtime publication blocks
- after explainability publication
- before HMI/export projection

The observer insertion must NEVER be placed:
- inside runtime arbitration
- inside OT transport
- inside cascade arbitration
- inside DHW priority logic
- inside synchronization ownership
- inside safety ownership

Reason:
those sections are runtime-authoritative.

---

# EXACT ENABLE CONDITION DESIGN

## Initial observer enablement

The observer enable condition must:
- default to disabled
- remain explicit
- remain removable
- remain compile-safe

Recommended topology:

IF GVL_RUNTIME.G_Enable_Runtime_Observer THEN
    FB_Heating_Runtime_Observer(...);
END_IF;

---

# ENABLE CONDITION RULES

The observer enable condition must NEVER:
- depend on runtime sequencing
- depend on runtime outputs
- depend on OT arbitration
- depend on cascade arbitration
- depend on synchronization waits

Reason:
avoid hidden runtime coupling.

---

# OBSERVER CALL STRUCTURE

## Required observer call model

The observer call must:
- execute once per scan
- execute after finalized publication
- remain bounded
- remain deterministic
- remain removable

Allowed:
- finalized snapshot observation
- bounded aggregation
- bounded telemetry projection

Forbidden:
- recursive traversal
- graph traversal
- replay execution
- adaptive execution
- predictive execution
- synchronization waits

---

# EXACT SNAPSHOT BOUNDARIES

Observer may consume ONLY:
- finalized runtime context
- finalized diagnostics context
- finalized OT publication state
- finalized cascade publication state

Observer must NEVER consume:
- temporary runtime values
- runtime-private ownership structures
- transitional synchronization state
- partial output state
- arbitration-intermediate state

Reason:
avoid unstable observation coupling.

---

# OBSERVATION CONTRACT INSERTION RULES

## Observation publication topology

Runtime
→ finalized publication
→ observer
→ observation contract
→ telemetry projection
→ HMI projection

Never the reverse.

---

# OBSERVATION CONTRACT RULES

Observation contracts remain:
- read-only
- projection-only
- governance-safe
- removable

Forbidden semantics:
- activation semantics
- migration semantics
- replay authority
- advisory authority
- runtime control authority

---

# FAILURE ISOLATION INSERTION RULES

If observer execution fails:
- runtime continues
- outputs continue
- OT continues
- cascade continues
- diagnostics continue

Observer failure degrades to:
- observation unavailable only

Runtime must NEVER:
- depend on observer execution
- wait for observer execution
- synchronize with observer state

---

# EXPORT / HMI INSERTION RULES

All observer exports remain:
- read-only
- projection-only
- observational-only

Allowed:
- runtime visibility
- telemetry visibility
- sequencing visibility
- ownership visibility

Forbidden:
- writable exports
- writable dashboards
- replay controls
- migration controls
- runtime overrides
- operator authority escalation

---

# GOVERNANCE LOCK INSERTION RULES

The observer insertion remains governance-locked.

Observer may:
- observe
- export
- archive

Observer may NOT:
- decide
- authorize
- activate
- arbitrate
- override runtime

---

# COMPILE-SAFE INSERTION STRATEGY

## Step A — Observer compiled but disabled

Observer:
- linked
- compiled
- inactive

No runtime behavior changes.

---

## Step B — Observer insertion added

Insert ONLY:
- observer enable condition
- observer call

No telemetry exports yet.

---

## Step C — Internal visibility validation

Validate:
- runtime visibility
- sequencing visibility
- ownership visibility
- synchronization visibility

---

## Step D — Read-only projection enablement

Enable:
- read-only telemetry projection
- read-only HMI visibility

Still forbidden:
- writable exports
- writable dashboards
- replay controls
- migration controls

---

## Step E — Stability validation

Validate:
- scan-time stability
- runtime sequencing stability
- OT timing stability
- cascade stability
- DHW priority stability

---

# ROLLBACK STRATEGY

Rollback action:
- disable observer enable condition only

Runtime continues unchanged.

Rollback must NOT require:
- runtime modification
- output modification
- OT modification
- cascade modification

---

# FIRST LIVE INSERTION SUCCESS CRITERIA

The first observer insertion is successful only if:
- compile remains clean
- runtime behavior remains unchanged
- outputs remain unchanged
- runtime sequencing remains unchanged
- DHW priority remains unchanged
- OT timing remains unchanged
- cascade arbitration remains unchanged
- scan-time impact remains negligible
- observer remains removable
- observer remains read-only
- governance isolation remains intact

---

# CURRENT DECISION

The project is now ready for:
- exact observer insertion preparation
- compile-safe observer insertion
- rollback-safe finalized-state observation insertion

The project is NOT ready for:
- orchestration migration
- runtime delegation
- predictive operational deployment
- adaptive operational deployment
- writable supervision authority
- autonomous runtime governance
