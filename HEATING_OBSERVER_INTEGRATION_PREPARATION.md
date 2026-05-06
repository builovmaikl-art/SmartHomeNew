# HEATING_OBSERVER_INTEGRATION_PREPARATION.md

# PURPOSE

This document defines the exact preparation steps required before the first live observer-only runtime attachment is enabled.

The goal is:
- preserve deterministic runtime execution
- preserve ownership isolation
- preserve runtime publication integrity
- preserve OT timing stability
- preserve cascade arbitration stability
- preserve scan-time stability

This preparation phase intentionally avoids:
- runtime migration
- runtime delegation
- orchestration authority
- predictive deployment
- adaptive deployment
- replay deployment

---

# CURRENT TARGET

The current target is ONLY:
- first passive observer attachment

The attachment target is:
- FB_Heating_Runtime_Observer

No additional analytics layers are enabled during this phase.

---

# PRIMARY INTEGRATION RULE

The observer must attach ONLY:
- after finalized runtime publication
- after finalized diagnostics publication
- before HMI projection only

The observer must NEVER:
- participate in runtime execution
- participate in runtime ownership
- participate in OT arbitration
- participate in cascade arbitration
- participate in safety logic

---

# REQUIRED INTEGRATION PREPARATION

Before first attachment the project must validate:
- exact call placement
- finalized snapshot boundaries
- publication ordering
- dependency ordering
- ownership ordering
- deterministic execution ordering

---

# INTEGRATION FILE TARGET

## Primary runtime integration target

Expected integration topology:

PRG_Heating
→ runtime finalized
→ runtime publication
→ PRG_Explainability
→ explainability finalized
→ FB_Heating_Runtime_Observer
→ optional telemetry projection
→ HMI projection

The observer must remain:
- removable
- isolated
- downstream-only

---

# REQUIRED CALL PLACEMENT RULES

The observer call must:
- execute once per scan
- execute after finalized publication
- execute after diagnostics publication
- avoid runtime feedback
- avoid synchronization waits

The observer call must NEVER:
- execute before runtime outputs finalize
- execute inside runtime arbitration
- execute inside OT transport
- execute inside cascade ownership
- execute inside safety chains

---

# SNAPSHOT PUBLICATION BOUNDARIES

## Allowed finalized publication state

Observer may consume ONLY:
- finalized runtime context
- finalized diagnostics context
- finalized OT publication state
- finalized cascade publication state

---

## Forbidden snapshot sources

Observer must NEVER consume:
- intermediate runtime variables
- temporary arbitration variables
- partially computed outputs
- synchronization-internal temporary values
- runtime-private ownership structures

Reason:
avoid unstable observation coupling.

---

# FIRST LIVE OBSERVATION SCOPE

## Allowed observation domains

Allowed:
- runtime ready state
- runtime fault state
- runtime phase state
- DHW visibility
- heating visibility
- OT visibility
- cascade visibility
- sequencing visibility
- ownership visibility
- synchronization visibility

---

## Forbidden observation domains

Forbidden:
- internal OT timing internals
- boiler arbitration internals
- runtime-internal temporary buffers
- safety-internal transitions
- synchronization intermediate states

---

# EXECUTION SAFETY RULES

The observer implementation must:
- remain bounded
- remain deterministic
- remain single-pass
- avoid recursion
- avoid graph traversal
- avoid replay traversal
- avoid adaptive traversal

Allowed:
- bounded aggregation
- bounded loops
- bounded projection

Forbidden:
- dynamic allocations
- recursive analytics
- deep dependency traversal
- unbounded telemetry

---

# FAILURE ISOLATION PREPARATION

If observer execution fails:
- runtime execution must continue
- OT transport must continue
- cascade arbitration must continue
- diagnostics publication must continue
- outputs must continue

Observer failure must degrade to:
- observation unavailable only

Runtime must NEVER:
- depend on observer execution
- wait for observer completion
- synchronize with observer state

---

# HMI / EXPORT PREPARATION

All exports remain:
- read-only
- projection-only
- observational-only

Forbidden:
- writable dashboard bindings
- writable OPC bindings
- replay activation controls
- migration controls
- operator authority escalation

---

# GOVERNANCE LOCK PREPARATION

The observer layer remains governance-locked.

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

# PRE-ATTACHMENT VALIDATION

## Compile validation

Validate:
- clean compile
- dependency stability
- no cyclic dependencies
- no hidden ownership writes

---

## Deterministic validation

Validate:
- scan-time stability
- OT timing stability
- cascade timing stability
- sequencing stability
- publication stability

---

## Governance validation

Validate:
- read-only exports
- no writable bindings
- no authority semantics
- no replay authority
- no migration authority

---

# FIRST LIVE ENABLEMENT STRATEGY

## Stage A

Observer compiled but disabled.

---

## Stage B

Observer enabled without telemetry export.

---

## Stage C

Observer export visibility enabled.

---

## Stage D

Stability review performed.

---

# FIRST LIVE ENABLEMENT SUCCESS CRITERIA

The first observer enablement is successful only if:
- runtime behavior remains unchanged
- outputs remain unchanged
- DHW priority remains unchanged
- OT timing remains unchanged
- cascade arbitration remains unchanged
- scan-time impact remains negligible
- supervision remains removable
- supervision remains read-only
- governance isolation remains intact

---

# CURRENT DECISION

The project is now ready for:
- first compile-safe observer attachment preparation
- finalized-state runtime observation preparation
- passive deterministic telemetry preparation

The project is NOT ready for:
- orchestration migration
- runtime delegation
- predictive operational deployment
- adaptive operational deployment
- writable supervision authority
- autonomous runtime governance
