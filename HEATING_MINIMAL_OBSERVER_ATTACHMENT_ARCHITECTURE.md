# HEATING_MINIMAL_OBSERVER_ATTACHMENT_ARCHITECTURE.md

# PURPOSE

This document defines the first safe runtime attachment strategy for the heating orchestration supervision platform.

The attachment is:
- observation-only
- downstream-only
- passive
- deterministic-safe
- governance-locked

The attachment:
- MUST NOT change runtime sequencing
- MUST NOT change runtime ownership
- MUST NOT change output ownership
- MUST NOT change OpenTherm ownership
- MUST NOT change cascade ownership
- MUST NOT introduce writable supervision paths

This is NOT orchestration migration.

This is ONLY minimal runtime observation attachment.

---

# CURRENT ARCHITECTURE STATE

The project currently already contains:
- runtime phase model
- runtime context contracts
- observation contracts
- timeline telemetry
- causality analytics
- forensic analytics
- predictive analytics
- adaptive analytics
- meta analytics
- governance isolation
- semantic isolation

The platform is therefore ready for:
- minimal passive runtime attachment

The platform is NOT ready for:
- runtime migration
- orchestration authority
- runtime control delegation
- autonomous supervision

---

# PRIMARY ATTACHMENT PRINCIPLE

The supervision platform must observe already-published runtime state.

It must NEVER:
- participate in runtime execution
- participate in runtime decisions
- influence runtime outputs
- influence runtime sequencing
- influence runtime timing

Supervision runs strictly after runtime publication.

---

# REQUIRED EXECUTION ORDER

The required execution order is:

1. PRG_Heating runtime executes
2. Runtime outputs are computed
3. Runtime ownership completes
4. Runtime state is published
5. Diagnostics/explainability complete
6. Observation attachment executes
7. Timeline telemetry executes
8. Analytics layers execute
9. HMI/export projection executes

This order is mandatory.

---

# SAFE ATTACHMENT LOCATION

## Primary attachment point

The first attachment point must be:
- after runtime publication
- after diagnostics publication
- before HMI projection only

Recommended topology:

PRG_Heating
→ PRG_Explainability
→ FB_Heating_Runtime_Observer
→ supervision pipeline
→ HMI projection

Reason:
- runtime already completed
- sequencing already fixed
- supervision cannot affect outputs anymore

---

# FORBIDDEN ATTACHMENT LOCATIONS

Attachment is forbidden:
- inside boiler arbitration
- inside OpenTherm transport
- inside cascade manager
- inside DHW prioritization
- before runtime publication
- inside safety chains
- inside output projection ownership

Reason:
those locations are runtime-authoritative.

---

# MINIMAL ATTACHMENT SCOPE

The first attachment phase must include ONLY:
- runtime observer
- contract validator
- synchronization observer
- timeline observer

Forbidden during first attachment:
- forensic replay
- predictive analytics
- adaptive analytics
- meta analytics
- graph traversal
- heavy telemetry export

Reason:
minimal deterministic footprint.

---

# FIRST ATTACHMENT PIPELINE

## Stage 1 — Runtime observation

Allowed:
- snapshot observation
- phase observation
- ownership observation
- synchronization observation

Forbidden:
- runtime modification
- runtime requests
- runtime feedback

---

## Stage 2 — Contract validation

Allowed:
- sequencing validation
- ownership validation
- publication validation

Forbidden:
- validation-based blocking
- validation-based override
- validation-based runtime control

---

## Stage 3 — Timeline telemetry

Allowed:
- frame capture
- bounded telemetry history
- bounded timing observation

Forbidden:
- replay execution
- replay authority
- timeline-driven runtime actions

---

# RUNTIME SNAPSHOT POLICY

The observer must consume only:
- already-published runtime state
- already-published diagnostics state
- already-published OT state
- already-published cascade state

The observer must NEVER:
- read intermediate execution state
- read partially computed state
- read unstable sequencing state

---

# SNAPSHOT STABILITY REQUIREMENTS

All snapshot reads must be:
- single-pass
- bounded
- deterministic
- non-blocking

Forbidden:
- waiting
- retry loops
- dynamic allocations
- recursive traversal

---

# RESOURCE POLICY

## Allowed always-on resources

Allowed:
- bounded structs
- bounded arrays
- fixed-size telemetry
- fixed-size timelines

Forbidden:
- dynamic buffers
- dynamic replay history
- unbounded event accumulation

---

# TIMING POLICY

The attachment layer must:
- complete inside deterministic scan budget
- avoid nested loops over runtime domains
- avoid graph traversal in always-on mode

Allowed:
- O(N) bounded loops

Forbidden:
- unbounded traversal
- recursive analytics
- dynamic dependency walks

---

# HMI / EXPORT POLICY

All supervision exports are:
- read-only
- projection-only
- observational-only

Forbidden:
- writable HMI bindings
- writable OPC bindings
- writable dashboard controls
- replay activation controls
- migration controls

---

# GOVERNANCE LOCK REQUIREMENTS

The attachment layer must remain governance-locked.

Required:
- no runtime authority
- no OT authority
- no cascade authority
- no sequencing authority
- no output authority

Supervision may observe.

Supervision may NOT decide.

---

# FAILURE POLICY

If supervision fails:
- runtime must continue normally
- outputs must continue normally
- OT must continue normally
- cascade must continue normally

Supervision failure must degrade to:
- invisible observation loss only

Runtime must remain authoritative.

---

# FIRST LIVE ATTACHMENT TARGET

The first real runtime attachment target is:
- FB_Heating_Runtime_Observer

Only after observer stability is proven:
- timeline observer may attach
- validation layer may attach

All other analytics remain offline initially.

---

# FIRST ATTACHMENT SUCCESS CRITERIA

The first attachment phase is considered successful only if:
- compile remains clean
- scan-time impact is negligible
- runtime sequencing is unchanged
- DHW priority is unchanged
- OT timing is unchanged
- cascade arbitration is unchanged
- outputs are unchanged
- supervision remains read-only
- no writable export surfaces appear

---

# FUTURE ATTACHMENT SEQUENCE

## Phase A

Minimal observer-only attachment.

Status:
- NEXT

---

## Phase B

Validation + synchronization attachment.

Status:
- AFTER PHASE A STABILITY

---

## Phase C

Timeline telemetry attachment.

Status:
- AFTER PHASE B STABILITY

---

## Phase D

Optional engineering analytics.

Status:
- ENGINEERING ONLY

---

## Phase E

Offline forensic analytics.

Status:
- NOT ALWAYS-ON

---

## Phase F

Predictive/adaptive analytics.

Status:
- ONLY AFTER RESOURCE REVIEW

---

# CURRENT DECISION

The project is now ready for:
- minimal observer-only runtime attachment design
- observer-only integration prototype
- bounded deterministic telemetry attachment

The project is NOT ready for:
- orchestration migration
- runtime delegation
- autonomous supervision
- writable orchestration surfaces
- predictive operational authority
