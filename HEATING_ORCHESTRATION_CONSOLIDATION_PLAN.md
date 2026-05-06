# HEATING_ORCHESTRATION_CONSOLIDATION_PLAN.md

# PURPOSE

This document defines the controlled consolidation and integration planning stage for the heating orchestration / supervision platform.

The goal is NOT to migrate runtime authority.

The goal is to prevent the new supervision foundation from becoming a fragmented parallel system.

This document defines:
- permanent contract domains
- supervision execution topology
- runtime attachment strategy
- deployment segmentation
- integration gates
- resource policy
- consolidation sequence

---

# CURRENT STATE

The heating orchestration foundation currently includes:
- runtime phase model
- runtime context model
- contract validation
- synchronization monitoring
- health observation
- runtime observation
- phase telemetry
- execution timeline
- anomaly correlation
- causality graph
- blackbox reconstruction
- predictive supervision
- adaptive intelligence
- meta-supervision

All these layers are currently designed as passive/read-only.

This is correct.

But the platform is now deep enough that uncontrolled expansion would create operational complexity.

---

# PRIMARY CONSOLIDATION RULE

Do NOT add further supervision depth until the existing layers are consolidated into a stable topology.

Allowed work during this phase:
- documentation
- topology definition
- integration boundary definition
- deployment segmentation
- dependency verification
- runtime attachment planning

Forbidden work during this phase:
- runtime migration
- runtime ownership transfer
- output ownership transfer
- OpenTherm ownership transfer
- cascade ownership transfer
- safety ownership transfer
- uncontrolled new supervision layers

---

# PERMANENT CONTRACT DOMAINS

## Domain 1 — Runtime Lifecycle Contracts

Permanent contracts:
- E_Heating_Runtime_Phase
- ST_Heating_Runtime_Context
- ST_Heating_Runtime_Phase_Event
- ST_Heating_Runtime_Phase_Transition

Purpose:
- lifecycle phase identity
- deterministic sequencing state
- phase transition state

Allowed users:
- coordinator
- validator
- telemetry
- observation

Forbidden:
- direct output ownership
- direct OT ownership
- direct cascade ownership

---

## Domain 2 — Runtime Observation Contracts

Permanent contracts:
- ST_Heating_Runtime_Observation
- ST_Heating_Runtime_Execution_Frame
- ST_Heating_Runtime_Execution_Timeline

Purpose:
- live runtime snapshot
- execution frame history
- timeline telemetry

Allowed users:
- observers
- validators
- passive aggregators

Forbidden:
- runtime control
- command generation
- output mutation

---

## Domain 3 — Runtime Integrity / Migration Contracts

Permanent contracts:
- ST_Heating_Runtime_Integration_Bridge
- ST_Heating_Runtime_Event_Buffer

Purpose:
- integration readiness
- migration gating
- orchestration event buffering

Allowed users:
- integration bridge manager
- synchronization monitor
- contract validator

Forbidden:
- enabling migration automatically
- bypassing runtime ownership

---

## Domain 4 — Runtime Causality / Forensic Contracts

Permanent contracts:
- ST_Heating_Runtime_Anomaly
- ST_Heating_Runtime_Causality_Node
- ST_Heating_Runtime_Causality_Edge
- ST_Heating_Runtime_Causality_Graph
- ST_Heating_Runtime_Blackbox_Event
- ST_Heating_Runtime_Blackbox_Timeline

Purpose:
- anomaly state
- causality topology
- propagation analysis
- forensic reconstruction

Allowed users:
- forensic observers
- replay analyzers
- passive diagnostics viewers

Forbidden:
- runtime decisions
- failover decisions
- cascade decisions

---

## Domain 5 — Predictive / Adaptive Supervision Contracts

Permanent contracts:
- ST_Heating_Runtime_Predictive_State
- ST_Heating_Runtime_Adaptive_Intelligence
- ST_Heating_Runtime_Meta_Supervision

Purpose:
- predictive stability
- adaptive risk scoring
- meta-supervision integrity

Allowed users:
- predictive analyzers
- adaptive scoring engines
- supervision dashboard

Forbidden:
- direct process control
- autonomous recovery authority
- output ownership

---

# SUPERVISION EXECUTION TOPOLOGY

The future supervision execution chain must be downstream-only.

Required order:

1. Live runtime completes
2. Runtime state is published
3. Diagnostics/explainability publish their state
4. Runtime observation reads published state
5. Contract validation runs
6. Synchronization monitoring runs
7. Timeline / phase telemetry runs
8. Anomaly correlation runs
9. Causality graph analysis runs
10. Blackbox reconstruction runs
11. Predictive supervision runs
12. Adaptive intelligence runs
13. Meta-supervision runs
14. HMI / debug projection reads final supervision state

This order is mandatory.

No supervision layer may execute before the runtime state it depends on is published.

---

# RUNTIME ATTACHMENT STRATEGY

## Allowed attachment points

Allowed future attach points:
- after PRG_Heating state publication
- after FB_Heating_RootCause_Diagnostics publication
- after PRG_Explainability publication
- after PRG_HMI_Dashboard projection, if observation is HMI-only

Preferred first attach point:
- after PRG_Heating state publication and before HMI-only projection

Reason:
- live runtime has already completed
- semantic state is available
- outputs are not controlled by supervision

---

## Forbidden attachment points

Forbidden:
- inside FB_Boiler_OpenTherm_Interface
- inside FB_Boiler_Cascade_Manager
- inside FB_Heating_Boiler_Control arbitration logic
- before DHW demand generation
- before heating manager execution
- inside safety shutdown chains
- inside output projection ownership

Reason:
these points are runtime-authoritative.

---

# DEPLOYMENT SEGMENTATION

## Always-on minimal layer

Allowed always-on components:
- runtime observer
- observation validator
- contract validator
- synchronization monitor
- health observer

Purpose:
- low-cost runtime supervision
- safety of integration boundary
- operator confidence

---

## Conditional engineering layer

Enabled only when diagnostics depth is needed:
- phase transition observer
- timeline observer
- jitter detector
- latency validator
- anomaly correlator
- OT/cascade correlator
- anomaly severity classifier

Purpose:
- deeper engineering visibility
- runtime degradation analysis

---

## Forensic / debug-only layer

Enabled only during commissioning, incident analysis, or engineering review:
- causality graph
- event reconstruction engine
- fault replay analyzer
- degradation timeline rebuilder

Purpose:
- post-analysis
- blackbox reconstruction
- fault replay

---

## Predictive / adaptive layer

Enabled only after observation layer has proven stable:
- stability model
- degradation trend analyzer
- cascade collapse predictor
- OT instability predictor
- adaptive risk scorer
- anomaly weighting engine
- supervision confidence analyzer
- predictive correlation weighting engine
- meta-supervision analyzers

Purpose:
- predictive supervision
- adaptive confidence analytics
- future operator advisory systems

Forbidden:
- automatic control authority
- automatic recovery action
- automatic runtime migration

---

# INTEGRATION GATES

## Gate 1 — Compile gate

Before any integration:
- all new DUT and FB must compile
- no missing enum references
- no invalid array/scalar assignments
- no GVL field assumptions without verification

Status:
- REQUIRED BEFORE RUNTIME ATTACHMENT

---

## Gate 2 — Dependency gate

Before any integration:
- dependency graph must remain acyclic
- no lower layer may depend on upper layer
- no runtime FB may depend on forensic/adaptive layers
- no diagnostics FB may own orchestration authority

Status:
- REQUIRED BEFORE RUNTIME ATTACHMENT

---

## Gate 3 — Read-only gate

Before any integration:
- supervision must not write runtime outputs
- supervision must not write OT state
- supervision must not write cascade state
- supervision must not write safety state

Status:
- REQUIRED BEFORE RUNTIME ATTACHMENT

---

## Gate 4 — Resource gate

Before enabling deep layers:
- scan-time impact must be estimated
- memory impact must be estimated
- buffer sizes must be reviewed
- forensic buffers must be optional or bounded

Status:
- REQUIRED BEFORE ALWAYS-ON DEPLOYMENT

---

## Gate 5 — Runtime equivalence gate

Before any orchestration migration:
- live runtime output behavior must remain equivalent
- DHW-first sequencing must remain unchanged
- diagnostics-after-publication must remain unchanged
- output-projection-last must remain unchanged

Status:
- REQUIRED BEFORE MIGRATION

---

# CONSOLIDATION SEQUENCE

## Step 1 — Current step

Create consolidation plan and topology.

Status:
- IN PROGRESS

---

## Step 2 — Code dependency audit

Verify newly created files against:
- enum dependencies
- DUT dependencies
- FB dependencies
- GVL access
- runtime ownership

Status:
- NEXT

---

## Step 3 — Compile-risk audit

Check for likely IEC/ST compile risks:
- scalar/array mismatch
- missing GVL fields
- invalid SEL usage
- invalid arithmetic types
- missing enum imports
- oversized strings

Status:
- NEXT

---

## Step 4 — Consolidation map update

Update audit documentation with:
- permanent domains
- optional layers
- debug-only layers
- forbidden integration points

Status:
- AFTER STEP 2/3

---

## Step 5 — Minimal observation integration design

Only after gates pass:
- design minimal observer-only integration point
- no runtime migration
- no output effect

Status:
- NOT STARTED

---

# CURRENT DECISION

The project is NOT ready for runtime migration.

The project IS ready for:
- dependency audit
- compile-risk audit
- consolidation mapping
- observation-only integration design

This is intentional and correct.
