# Runtime Semantic Recovery Provenance

## Purpose

This document records the first pass over architectural reserve structures that look like dead semantic material in `runtime_dead_semantic_audit.py`, but may actually represent incomplete or lost runtime work.

The goal is to recover useful integration paths before deleting DUT fields or entire DUT families.

## Current conclusion

The suspicious runtime DUT families are not random residue. They form a coherent observation / explainability / diagnostics model around the existing heating runtime observer pipeline.

Active code already contains a working observer path:

- `FB_Heating_Runtime_Observer.st`
- `FB_Heating_Runtime_Observer_Phase.st`
- `GVL_Heating_Runtime_Observation.gvl`
- `PRG_Heating.st`

The reserve DUTs appear to be adjacent, not-yet-integrated layers around this observer path.

## Evidence found

### Existing observer pipeline

`FB_Heating_Runtime_Observer.st` is an active minimal read-only observer. It publishes `VO_Observation : ST_Heating_Runtime_Observation`, plus `VO_Status_Code` and `VO_Status_Text`.

It already sets status values such as:

- observer disabled;
- diagnostics publication invalid;
- observer nominal;
- runtime fault detected.

This confirms that `Status_Code` / `Status_Text` are not inherently garbage. They are an existing status-publication idiom.

`FB_Heating_Runtime_Observer_Phase.st` owns governed observer authorization and finalized-state observer publication. It writes lifecycle/status fields into `GVL_Heating_Runtime_Observation` and uses `FB_Heating_Runtime_Observer` as the finalized observer.

Therefore the recovery question is not whether status fields are useful. They are. The question is which reserve DUT families should be wired into this observer pipeline.

## Reserve DUT family mapping

### 1. Meta supervision

Candidate:

- `ST_Heating_Runtime_Meta_Supervision.dut`

Observed structure:

- meta analytics visibility;
- supervision integrity observation;
- adaptive supervision drift observation;
- predictive confidence observation;
- analytics consistency observation;
- sequencing / ownership / synchronization meta observation;
- `Status_Code` / `Status_Text`.

Likely intended role:

- passive governance analytics over runtime observer outputs;
- integrity layer over sequencing / ownership / synchronization invariants;
- HMI / diagnostics surface for runtime health beyond simple observer valid/fault flags.

Likely owner candidate:

- new or existing `FB_Heating_Runtime_Observer_*` extension;
- probably after `FB_Heating_Runtime_Observer_Phase` finalization;
- no command or output authority.

Recommended decision:

- `ARCHITECTURAL_RESERVE`;
- do not delete;
- candidate for minimal integration as `GVL_Heating_Runtime_Observation.G_Runtime_Meta_Supervision` or a separate `GVL_Heating_Runtime_Meta` surface.

### 2. Adaptive intelligence

Candidate:

- `ST_Heating_Runtime_Adaptive_Intelligence.dut`

Observed structure:

- adaptive analytics visibility;
- adaptive analytics degraded / attention;
- supervision confidence observation;
- runtime stability observation;
- anomaly observation weights;
- predictive correlation observation;
- sequencing / ownership / synchronization confidence observation;
- `Status_Code` / `Status_Text`.

Likely intended role:

- passive adaptive analytics layer;
- confidence/scoring layer over runtime anomalies and predictive correlation;
- no adaptive control authority.

Important wording in DUT:

- “Passive analytics only.”
- “No adaptive authority exists.”

This is a strong guardrail: the design was not to make adaptive decisions, but to observe and explain.

Likely owner candidate:

- future `FB_Heating_Runtime_Adaptive_Observer` or extension of observer phase;
- may consume `ST_Heating_Runtime_Observation`, anomaly status and predictive/cascade/OpenTherm diagnostics.

Recommended decision:

- `ARCHITECTURAL_RESERVE`;
- do not delete;
- integrate only as read-only / passive analytics after observer output exists.

### 3. Causality graph

Candidates:

- `ST_Heating_Runtime_Causality_Graph.dut`
- `ST_Heating_Runtime_Causality_Node.dut`
- `ST_Heating_Runtime_Causality_Edge.dut`

Observed structure:

- graph nodes;
- graph edges;
- node / edge counts;
- active / degraded / critical graph state;
- sequencing / ownership / synchronization validity;
- `Status_Code` / `Status_Text`.

Likely intended role:

- post-event reconstruction;
- explainability chain;
- blackbox/debug graph of runtime causes and propagated effects.

Likely owner candidate:

- not the control pipeline;
- a diagnostics/explainability publisher after runtime observation and blackbox event generation;
- possible HMI/engineering debug consumer.

Recommended decision:

- `ARCHITECTURAL_RESERVE`;
- do not delete;
- integrate only if there is a concrete blackbox/explainability output path.

### 4. Runtime anomaly / blackbox / phase event family

Candidates:

- `ST_Heating_Runtime_Anomaly.dut`
- `ST_Heating_Runtime_Blackbox_Event.dut`
- `ST_Heating_Runtime_Phase_Event.dut`
- related timeline DUTs.

Likely intended role:

- convert observer state into event records;
- preserve start/end/duration/status;
- publish phase and anomaly state for blackbox or HMI diagnostics.

Likely owner candidate:

- `FB_Heating_Runtime_Observer_Phase` extension;
- dedicated `FB_Heating_Runtime_Event_Recorder`;
- blackbox publisher after finalized runtime phase.

Recommended decision:

- `ARCHITECTURAL_RESERVE`;
- compare snapshots before deleting fields;
- strongest minimal integration target after meta-supervision.

## Snapshot evidence

Search results show that key reserve DUTs exist both in active tree and in recent snapshots, including:

- `snapshots/2026-05-07/ST_Heating_Runtime_Meta_Supervision.dut`
- `snapshots/2026-05-12/ST_Heating_Runtime_Meta_Supervision.dut`
- `snapshots/2026-05-07/ST_Heating_Runtime_Adaptive_Intelligence.dut`
- `snapshots/2026-05-12/ST_Heating_Runtime_Adaptive_Intelligence.dut`

This suggests they were part of recent runtime work, not ancient leftovers.

## Important correction to cleanup strategy

`Status_Code` and `Status_Text` must not be treated as automatic cleanup targets.

They are already actively used by the observer pipeline, just not necessarily in every reserve DUT family. A field can be unused in one DUT while still representing a valid project-wide pattern.

## Minimal recovery path

The safest first recovery candidate is **Meta Supervision**, because it is passive, governance-oriented and close to the existing observer status model.

Recommended first implementation target:

1. Add a small published meta-supervision surface.
2. Populate it from existing observer validity/status/lifecycle fields.
3. Keep all authority flags passive/read-only.
4. Avoid feeding it back into control, command, arbitration or outputs.

Possible shape:

- `GVL_Heating_Runtime_Observation.G_Runtime_Meta_Supervision : ST_Heating_Runtime_Meta_Supervision`

or, if we want stricter separation:

- `GVL_Heating_Runtime_Meta.G_Runtime_Meta_Supervision : ST_Heating_Runtime_Meta_Supervision`

## Next recommended action

Do not resume large DUT cleanup yet.

Next work should be:

1. Inspect `ST_Heating_Runtime_Observation.dut` and current observer GVL.
2. Decide whether meta-supervision belongs inside existing observation GVL or separate GVL.
3. Implement one minimal passive publisher.
4. Re-run audit.
5. Check whether related unused DUT fields become real references and whether semantic debt decreases naturally.

## Guardrail

All recovered structures must remain observation-only. They must not introduce command authority, output authority, runtime mutation authority or hidden control feedback.
