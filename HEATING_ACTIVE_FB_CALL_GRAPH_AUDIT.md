# HEATING_ACTIVE_FB_CALL_GRAPH_AUDIT.md

# Purpose

This document audits heating-related FB/POU activity by runtime participation, not by compile success.

Clean compilation means only that a POU is syntactically/type valid and accepted by the project. It does not prove that the POU:
- has an instance;
- is called from an active PRG;
- receives live inputs;
- publishes consumed outputs;
- participates in physical IO projection.

The goal of this audit is to separate:
- active runtime code;
- indirectly active code;
- observer-only active code;
- compile-only code;
- future-reserved prototypes;
- delete candidates.

---

# Audit status

Status: initial classification audit.

This file intentionally does not claim that all listed FBs are fully verified. It records the current architectural concern and establishes the review categories.

---

# Important conclusion

A large part of the previously created heating runtime / supervision FB family appears to be compile-visible but not necessarily runtime-active.

This is not the same as a compile failure.

It means the project may contain many valid POUs that are not connected to the active execution graph.

---

# Why this happened

Some FBs were created as staged architecture scaffolding during large supervision/orchestration planning:
- runtime observer preparation;
- blackbox/event reconstruction planning;
- predictive supervision planning;
- adaptive supervision planning;
- meta-supervision planning;
- orchestration planning.

That approach is acceptable only if those FBs are explicitly marked as future-reserved and excluded from the active runtime expectation.

It becomes a problem if they are assumed to be live functionality.

---

# Current active-call categories

## Category A — Active runtime FB

Definition:
- has an instance in an active PRG/FB;
- is called every relevant scan;
- receives live runtime inputs;
- its outputs are consumed by active runtime logic or final state publication.

Known examples to verify/keep:
- `FB_Heating_System_Manager`
- `FB_DHW_Manager`
- `FB_Heating_Output_Projection`
- `FB_Heating_RootCause_Diagnostics`

---

## Category B — Indirect active runtime FB

Definition:
- not called directly from top-level PRG;
- instantiated/called inside an active runtime FB;
- participates in runtime behavior through that parent FB.

Likely examples through `FB_Heating_System_Manager`:
- `FB_Heating_Safety_Gate`
- `FB_Heating_Adaptive_Target`
- `FB_Heating_Circuit_Control`
- `FB_Heating_Demand_Map`
- `FB_Heating_Manifold_Control`
- `FB_Heating_Boiler_Control`

Required check:
- confirm each instance exists in `FB_Heating_System_Manager`;
- confirm each call is active in implementation body;
- confirm outputs are consumed.

---

## Category C — Observer-only active FB

Definition:
- active only as passive observer/supervision attachment;
- does not control runtime;
- may publish observation/diagnostic state.

Known examples:
- `FB_Heating_Runtime_Observer`
- `FB_Heating_Runtime_Observer_Authorization`

Required check:
- confirm call in `PRG_Heating`;
- confirm gated activation path;
- confirm read-only publication path.

---

## Category D — Compile-only / not proven active

Definition:
- file exists;
- compiles;
- no confirmed active instance/call path yet.

Likely examples:
- `FB_Heating_Runtime_Contract_Validator`
- `FB_Heating_Runtime_Event_Manager`
- `FB_Heating_Runtime_Synchronization_Monitor`
- `FB_Heating_Runtime_Health_Observer`
- `FB_Heating_Runtime_Coordinator`
- `FB_Heating_Runtime_Orchestration_Shell`
- `FB_Heating_Runtime_Integration_Bridge_Manager`
- `FB_Heating_Runtime_Observation_Validator`
- `FB_Heating_Runtime_Observation_Aggregator`

Required decision:
- either connect intentionally;
- or mark future-reserved;
- or remove from active root once safely archived/documented.

---

## Category E — Future-reserved supervision prototypes

Definition:
- intentionally not active today;
- represents planned analytics/supervision capabilities;
- must not be mistaken for deployed behavior.

Likely examples:
- `FB_Heating_Runtime_Anomaly_Aggregator`
- `FB_Heating_Runtime_Anomaly_Correlator`
- `FB_Heating_Runtime_Anomaly_Severity_Classifier`
- `FB_Heating_Runtime_Anomaly_Weighting_Engine`
- `FB_Heating_Runtime_Causality_Propagation_Analyzer`
- `FB_Heating_Runtime_Degradation_Timeline_Rebuilder`
- `FB_Heating_Runtime_Degradation_Trend_Analyzer`
- `FB_Heating_Runtime_Event_Reconstruction_Engine`
- `FB_Heating_Runtime_Confidence_Decay_Analyzer`
- `FB_Heating_Runtime_Supervision_Confidence_Analyzer`
- `FB_Heating_Runtime_Supervision_Integrity_Validator`
- `FB_Heating_Runtime_Predictive_Correlation_Weighting_Engine`
- `FB_Heating_Runtime_OT_Instability_Predictor`
- `FB_Heating_Runtime_Cascade_Collapse_Predictor`
- `FB_Heating_Runtime_Intelligence_Consistency_Analyzer`
- `FB_Heating_Runtime_Stability_Model`
- `FB_Heating_Runtime_Latency_Validator`
- `FB_Heating_Runtime_Jitter_Detector`
- `FB_Heating_Runtime_Timeline_Observer`
- `FB_Heating_Runtime_Phase_Transition_Observer`
- `FB_Heating_Runtime_Phase_Sequencing_Validator`
- `FB_Heating_Runtime_OT_Cascade_Correlator`
- `FB_Heating_Runtime_Adaptive_Drift_Detector`

Policy:
- do not delete automatically;
- do not claim active runtime behavior;
- either move to documented future-reserved area or connect through a bounded passive extension plan.

---

## Category F — Modbus helper functions / protocol builders

Definition:
- functions/FBs may be valid protocol helpers;
- they are active only if called by an active Modbus backend or device manager.

Relevant examples:
- `F_Modbus_RTU_CRC16`
- `FB_Modbus_RTU_TX_Builder`
- `FB_Modbus_RTU_RX_Parser`

Required check:
- confirm whether active Modbus backend calls TX builder/RX parser;
- confirm whether CRC function is still called or only legacy compatibility;
- remove or mark legacy if unused.

Current known note:
- TX/RX currently use inline CRC in active file versions;
- `F_Modbus_RTU_CRC16` may be legacy compatibility only.

---

## Category G — State snapshot family

Definition:
- snapshot structures/managers are only active if called by a live snapshot PRG/manager and if produced snapshots are consumed.

Relevant examples:
- `ST_System_State_Snapshot`
- `FB_State_Snapshot_*`

Required check:
- confirm active snapshot manager instance;
- confirm snapshot capture call;
- confirm snapshot consumers;
- classify as active telemetry, compile-only, or future-reserved.

---

# Why not simply delete all compile-only FBs?

Deleting everything compile-only is not automatically correct.

There are three different cases:

1. Prototype that should be removed because it is misleading.
2. Future-reserved building block that should be moved/documented, not deleted.
3. Required helper that appears unused only because the call graph audit is incomplete.

Therefore deletion must follow classification.

---

# Required next steps

## Step 1 — Build real call graph

For every `FB_Heating*`, `FB_FloorHeating*`, `FB_State_Snapshot*`, and `F_Modbus*`:
- find declaration;
- find instance declarations;
- find call sites;
- find output consumers.

## Step 2 — Fill classification table

Columns:
- POU name;
- file exists;
- instance exists;
- call site exists;
- active inputs;
- active outputs;
- classification;
- action.

## Step 3 — Decide action

Allowed actions:
- keep active;
- connect intentionally;
- move to future-reserved docs/snapshots;
- delete if obsolete;
- leave as protocol helper with explicit legacy marker.

---

# Initial risk statement

The main risk is not current compilation.

The main risk is false confidence:
- a large FB family exists;
- names suggest advanced runtime capability;
- but the active runtime may only call a small subset.

This must be made explicit before further expansion.

---

# Current recommendation

Do not add more heating supervision FBs until this call graph audit is completed.

The next engineering action should be:
- verify active call graph;
- mark inactive scaffolding;
- remove or archive misleading prototypes;
- keep only active or explicitly future-reserved code in the root active project.
