# HEATING_OBSERVER_ONLY_ATTACHMENT_PROTOTYPE_PLAN.md

# PURPOSE

This document defines the first real observer-only runtime attachment prototype for the heating supervision platform.

This prototype is intentionally minimal.

The goal is:
- validate deterministic runtime attachment
- validate observation-only execution
- validate governance isolation
- validate negligible scan-time impact
- validate no runtime ownership coupling

This prototype is NOT:
- orchestration migration
- runtime delegation
- predictive supervision deployment
- forensic deployment
- adaptive analytics deployment

---

# PRIMARY ENGINEERING RULE

The first live attachment must:
- observe runtime only
- publish no writable control state
- remain fully downstream from runtime authority
- remain removable without runtime changes

The supervision layer must behave as:
- passive instrumentation
- passive telemetry
- passive observation

---

# FIRST LIVE ATTACHMENT SCOPE

## Included

The prototype includes ONLY:
- FB_Heating_Runtime_Observer
- minimal runtime observation snapshot
- minimal sequencing observation
- minimal ownership observation
- minimal synchronization observation

---

## Excluded

The prototype explicitly excludes:
- predictive analytics
- adaptive analytics
- meta analytics
- causality graph
- forensic timeline
- replay systems
- anomaly correlation
- dashboard authority
- writable exports

Reason:
minimal deterministic integration risk.

---

# ATTACHMENT LOCATION

## Approved attachment point

The first observer attachment must execute:

PRG_Heating
→ runtime publication complete
→ PRG_Explainability complete
→ FB_Heating_Runtime_Observer
→ optional telemetry projection
→ HMI projection

---

# FORBIDDEN LOCATIONS

Attachment remains forbidden:
- inside OT transport
- inside cascade arbitration
- inside DHW prioritization
- inside safety logic
- before runtime publication
- before output calculation

---

# FIRST PROTOTYPE EXECUTION MODEL

## Step 1 — Runtime completes

Runtime remains fully authoritative.

No supervision execution occurs before runtime completion.

---

## Step 2 — Runtime publishes finalized state

Only finalized state may be observed.

Observer must NEVER read:
- intermediate runtime values
- partially computed outputs
- transitional arbitration state

---

## Step 3 — Observer executes

Observer reads:
- finalized runtime state
- finalized diagnostics state
- finalized OT state
- finalized cascade state

Observer writes ONLY:
- local observation contract

Observer writes NEVER:
- runtime state
- OT state
- cascade state
- output state
- diagnostics ownership state

---

## Step 4 — Projection executes

Projection may only:
- display observation
- export observation
- archive observation

Projection may NEVER:
- modify runtime
- modify observer state
- activate replay
- activate migration

---

# FIRST ATTACHMENT CONTRACTS

## Runtime publication contracts

Allowed:
- ST_Heating_Runtime_Context
- ST_Heating_Runtime_Observation

Forbidden:
- direct runtime FB ownership
- runtime internal state mutation

---

## Observation contracts

Allowed:
- read-only observation
- bounded telemetry
- bounded phase state

Forbidden:
- writable authority semantics
- activation semantics
- migration semantics

---

# DETERMINISTIC EXECUTION REQUIREMENTS

The prototype must:
- remain single-pass
- remain bounded
- avoid recursion
- avoid dynamic allocation
- avoid graph traversal
- avoid nested traversal across runtime domains

Allowed complexity:
- bounded O(N)

Forbidden complexity:
- unbounded traversal
- recursive analytics
- dynamic dependency analysis

---

# RESOURCE REQUIREMENTS

## Allowed

Allowed:
- bounded observation structs
- bounded arrays
- bounded timeline buffers
- fixed-size telemetry

---

## Forbidden

Forbidden:
- dynamic replay storage
- dynamically growing telemetry
- unlimited event history
- deep analytics traversal

---

# SCAN-TIME POLICY

The observer prototype must:
- have negligible scan-time impact
- avoid runtime blocking
- avoid additional runtime passes
- avoid synchronization waits

Observer execution must remain:
- deterministic
- bounded
- removable

---

# FAILURE ISOLATION

If observer fails:
- runtime continues
- outputs continue
- OT continues
- cascade continues
- diagnostics continue

Observation failure must degrade to:
- observation unavailable only

The runtime must never depend on observer state.

---

# EXPORT / HMI POLICY

All exports remain:
- read-only
- projection-only
- observational-only

Forbidden:
- writable HMI bindings
- writable OPC bindings
- writable replay controls
- writable migration controls
- writable dashboard authority

---

# GOVERNANCE LOCK

The prototype remains governance-locked.

Observer:
- may observe
- may export
- may archive

Observer may NOT:
- decide
- override
- request
- activate
- authorize
- arbitrate

---

# INITIAL DEPLOYMENT STRATEGY

## Phase A — Offline validation

Verify:
- compile stability
- dependency stability
- no ownership violations
- no writable exports

---

## Phase B — Passive runtime attachment

Enable:
- observer only
- observation contracts only

Disable:
- all heavy analytics

---

## Phase C — Telemetry validation

Validate:
- phase visibility
- sequencing visibility
- ownership visibility
- synchronization visibility

---

## Phase D — Stability review

Review:
- scan-time impact
- runtime stability
- OT timing stability
- cascade stability
- sequencing stability

---

# SUCCESS CRITERIA

The prototype is successful only if:
- runtime behavior remains unchanged
- outputs remain unchanged
- DHW priority remains unchanged
- OT timing remains unchanged
- cascade arbitration remains unchanged
- compile remains clean
- scan-time impact is negligible
- supervision remains removable
- supervision remains read-only
- governance isolation remains intact

---

# CURRENT DECISION

The project is now ready for:
- minimal observer-only prototype attachment
- passive observation deployment
- bounded deterministic observation telemetry

The project is NOT ready for:
- runtime migration
- orchestration delegation
- writable supervision authority
- predictive operational analytics deployment
- autonomous runtime governance
