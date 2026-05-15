# SmartHomeNew — Architectural Reconstruction Roadmap

## Status

Canonical migration and reconstruction roadmap.

This document is intended to be followed during all future reconstruction, audit, migration and cleanup work.

It is not a temporary note and not a simple TODO list. It is an architectural governance document.

---

## 1. Why this roadmap exists

During the runtime reconstruction audit a systemic problem was identified:

```text
unused
was confused with
unnecessary
```

As a result, previous cleanup work risked removing or simplifying:

- inactive but architecturally valuable FBs;
- GVL semantic contracts;
- explainability layers;
- fallback semantics;
- degraded-state semantics;
- predictive diagnostics;
- future extensibility points;
- physical-to-logical mapping contracts;
- observability and forensic reconstruction layers.

The goal of this roadmap is to prevent repeated semantic collapse.

The purpose is not to restore old code blindly. The purpose is to recover, stabilize and improve the intended architecture of the project.

---

## 2. Primary audit references

The following documents and files must be treated as context before major reconstruction or cleanup work:

- `AGENTS.md`
- `ТЗ обновлен.txt`
- `docs/audit/runtime_deep_audit/RUNTIME_SEMANTIC_RECOVERY_PROVENANCE.md`
- existing reports under `docs/audit/runtime_deep_audit/`
- runtime semantic reports under `runtime_semantic_reports/`
- snapshot evidence under `snapshots/`

The most important existing audit source for reserve semantics is:

```text
docs/audit/runtime_deep_audit/RUNTIME_SEMANTIC_RECOVERY_PROVENANCE.md
```

It contains classifications for:

- heating runtime observer / explainability stack;
- physical-to-logical mapping reserve;
- flood / water-leak semantic reserve;
- water valve test and recovery reserve;
- trend/history reserve;
- device/protocol mapping reserve;
- access governance reserve;
- floor-heating reserve;
- ventilation reserve;
- scenario reserve;
- state snapshot / short-arm restore reserve;
- user rule reserve;
- outdoor lighting reserve.

The object-level design and zone/topology context should be checked against:

```text
ТЗ обновлен.txt
```

That document is important because the project is not only software topology. It describes the physical object, zones, circuits, equipment, responsibilities and domain boundaries.

---

## 3. Core architectural discovery

The project was not originally moving toward a simple PLC script collection.

Audit work revealed a mature architectural direction:

```text
observe
correlate
predict
reconstruct
explain
publish
WITHOUT runtime authority
```

This means the intended architecture includes:

- deterministic runtime execution;
- supervisory observability;
- explainability;
- predictive diagnostics;
- forensic runtime reconstruction;
- degraded-state reasoning;
- physical-to-logical configuration;
- runtime-configurable topology;
- compatibility publication surfaces;
- HMI/diagnostic visibility without hidden authority.

The most important rule:

```text
supervisory layers observe, explain and publish;
they do not directly control runtime.
```

---

## 4. Fundamental invariants

These invariants must not be violated.

Violation of any invariant is architectural regression.

### 4.1 Runtime authority separation

```text
runtime authority
≠
observability
≠
projection
≠
publication
≠
compatibility
```

### 4.2 Runtime owns execution

Runtime layers own:

- deterministic execution;
- orchestration;
- arbitration;
- command shadowing;
- output projection;
- actuator authority.

Runtime layers must not depend on HMI compatibility surfaces as semantic truth.

### 4.3 Observability owns observation

Observability layers own:

- status publication;
- diagnostics;
- explainability;
- predictive analytics;
- timeline observation;
- causality;
- forensic reconstruction;
- degraded-state visibility.

Observability layers must remain passive.

### 4.4 Projection owns semantic transfer

Projection layers are canonical boundaries between runtime execution and downstream observability.

A projection layer may publish:

- current runtime semantic state;
- selected source;
- selected confidence;
- degraded state;
- reason code/text;
- transition edges;
- lifecycle markers.

Projection layers must not become HMI compatibility surfaces or direct actuator controllers.

### 4.5 Compatibility layers are not canonical

Compatibility/HMI layers exist to preserve migration continuity.

They may mirror canonical state, but they are not canonical owners.

They must not become:

- runtime authority roots;
- predictive ingestion roots;
- supervisory aggregation roots;
- hidden control surfaces.

### 4.6 Physical IO is not semantic topology

A foundational design goal of the project is:

```text
physical IO wiring
≠
logical topology
```

Sensors and actuators may be wired to IO controllers in arbitrary order. Their meaning must be configured through mapping/topology layers without recompilation.

This applies to:

- heating circuits;
- room/floor sensors;
- flood sensors;
- water valves;
- ventilation units;
- lighting circuits;
- security zones;
- access control;
- scenario effects.

### 4.7 Object topology is not installation topology

The object has real zones, rooms, hydraulic branches, heating loops, manifolds, equipment groups and responsibility domains.

Software must model these as semantic topology, not as hardcoded IO indexes.

Object topology should be derived from configuration and documented against `ТЗ обновлен.txt`.

---

## 5. Canonical domain topology

Each domain should evolve toward the following layered model:

```text
physical IO
→ raw input read
→ input normalization
→ signal quality
→ logical sensor / logical actuator mapping
→ domain semantic projection
→ governance / policy
→ arbitration
→ output projection
→ physical output
→ observability
→ explainability
→ supervisory publication
→ compatibility/HMI mirrors
```

Not every domain needs all layers immediately, but the topology direction must stay consistent.

---

## 6. Cleanup and migration rules

### 6.1 Never delete only because something is unused

Forbidden cleanup logic:

```text
not called
→ delete
```

Correct cleanup logic:

```text
not called
→ classify semantic role
→ classify architectural role
→ classify safety role
→ classify observability role
→ classify extensibility role
→ decide after domain review
```

### 6.2 Classify before modifying

Before modifying or deleting a DUT, FB, GVL or PRG, classify it as one or more of:

- active runtime;
- active configuration;
- compatibility mirror;
- semantic reserve;
- architectural reserve;
- observability reserve;
- safety reserve;
- physical-to-logical mapping reserve;
- predictive reserve;
- forensic reserve;
- replaced presentation summary;
- cleanup candidate after review.

### 6.3 Preserve explainability

Removing any of the following without replacement is semantic regression:

- confidence;
- degraded reason;
- reason text;
- reason code;
- causality;
- status publication;
- timeline edge;
- recovery state;
- fallback semantics.

### 6.4 New advanced layers start observe-only

Any new advanced layer must start as:

```text
observe-only
publish-only
no runtime authority
```

Runtime influence can only be discussed after:

- observation period;
- false-positive analysis;
- stability review;
- safety boundary review;
- authority design review.

### 6.5 Full-file replacement rule

When editing repository files, prefer full-file replacement rather than partial patching, because previous edits have caused truncated files.

For large files:

- fetch current file;
- build full replacement;
- preserve anchors;
- avoid parallel writes to the same path;
- verify SHA before update.

---

## 7. Target platform vision

The long-term goal is not simply a smart home script.

The target is:

```text
runtime-configurable deterministic building governance platform
```

Key properties:

- physical IO can be wired arbitrarily;
- semantic topology is configured, not hardcoded;
- runtime authority is deterministic;
- observability is rich but passive;
- degraded operation is explainable;
- recovery workflows are governed;
- safety boundaries are explicit;
- future extensions preserve semantic intent.

---

## 8. Phase roadmap

---

# Phase 0 — Governance and documentation baseline

## Goal

Establish the architectural rules and evidence base before further domain reconstruction.

## Required work

1. Treat this roadmap as migration governance.
2. Keep `RUNTIME_SEMANTIC_RECOVERY_PROVENANCE.md` as audit evidence.
3. Use `ТЗ обновлен.txt` for object topology and domain responsibility boundaries.
4. Preserve `AGENTS.md` repository rules.
5. Do not perform destructive cleanup without classification.

## Exit criteria

- roadmap exists and is followed;
- core invariants are known;
- future work references the roadmap;
- cleanup no longer uses `unused -> delete`.

---

# Phase 1 — Heating branch stabilization

## Current status

Mostly stabilized.

Recovered or introduced:

- passive input quality layer;
- confidence-aware heating source fallback;
- fallback explainability;
- runtime transition edges;
- canonical runtime projection;
- explainability adapter;
- source stability observer;
- predictive source instability contract;
- supervisory enrichment;
- canonical supervisory publication;
- `PRG_Heating_Supervisory_Publication` orchestration;
- compatibility demotion for circuit explainability.

## Canonical model

```text
PRG_Heating
→ GVL_Heating_Runtime_Projection
→ FB_Heating_Circuit_Explainability_Adapter
→ FB_Heating_Source_Stability_Observer
→ FB_Heating_Runtime_Supervisory_Enrichment
→ FB_Heating_Runtime_Supervisory_Publication_Adapter
→ GVL_Heating_Runtime_Supervisory_Publication
```

## Remaining work

1. Compile-risk audit.
2. Verify all newly introduced GVL/FB/PRG names are included in the build/project import flow.
3. Verify `PRG_Heating_Supervisory_Publication` is called after `PRG_Heating` and before output write.
4. Verify no supervisory layer mutates runtime outputs.
5. Reduce remaining duplicated status mirrors.
6. Keep legacy explainability GVLs compatibility-only.
7. Document any remaining direct topology coupling.

## Exit criteria

- Heating runtime remains deterministic;
- supervisory pipeline is passive;
- projection is canonical;
- compatibility surfaces are not semantic roots;
- no hidden control feedback from predictive/explainability layers.

---

# Phase 2 — Water / Flood branch reconstruction

## Goal

Recover Water/Flood as topology-aware hydraulic governance, not simple leak-to-global-close logic.

## Current active simplification

Current active path is approximately:

```text
FB_Water_Leakage_Manager
→ leak/warning latch
→ GVL_HEALTH_BRIDGE
→ PRG_Safety
→ PRG_Safety_Shutdown
→ WATER_LEAK mode
→ PRG_Command_Arbitration
→ close valve 35 and 36
→ PRG_Water
→ FB_Water_Output_Projection
```

This is functional but semantically collapsed.

## Known surviving semantic reserves

From audit evidence:

- `ST_Flood_Global_Config`
  - active debounce / anti-splash duration;
  - warning window;
  - `sensor_to_valve_map`;
  - `valve_types` / NO-NC semantics.

- `ST_Flood_Config`
  - two-stage emergency policy;
  - valve test period;
  - current threshold;
  - richer sensor-to-valve policy.

- `ST_Valve_Test_Config`
  - valve id;
  - test interval;
  - nominal current;
  - nominal close time;
  - enabled flag.

- valve diagnostics reserve described in audit:
  - current deviation;
  - travel-time deviation;
  - stall;
  - limit-switch failure;
  - aborted test.

## Target architecture

Water/Flood must evolve toward:

```text
physical leak input
→ input normalization
→ signal quality
→ logical leak sensor
→ hydraulic zone / segment mapping
→ leak classification
→ isolation intent
→ safety arbitration
→ valve governance
→ valve confirmation
→ output projection
→ observability
→ explainability
→ recovery governance
```

## Critical principles

1. Physical sensor index is not zone identity.
2. Sensor-to-valve map is only an early primitive of a richer topology model.
3. Hydraulic domain must become explicit.
4. Selective isolation should be recovered before more aggressive automation.
5. Valve confirmation must be separated from valve command authority.
6. Recovery opening must be governed, time-limited and operator-visible.
7. No diagnostics layer may directly reopen valves.

## Required reconstruction stages

### 2.1 Audit active runtime

Inspect and classify:

- `PRG_Water.st`
- `FB_Water_Leakage_Manager.st`
- `FB_Water_Output_Projection.st`
- `PRG_Safety.st`
- `PRG_Safety_Shutdown.st`
- `PRG_Command_Arbitration.st`
- `GVL_INTENT_SAFETY.gvl`
- `GVL_COMMAND_SHADOW.gvl`
- water/flood config GVLs;
- water/flood output GVLs;
- health bridge / state latch paths.

### 2.2 Restore semantic projection first

Create or reuse canonical Water runtime projection.

It should publish, at minimum:

- logical leak sensor visibility;
- physical sensor id;
- mapped hydraulic zone/segment;
- mapped valve/isolation target;
- warning active;
- leak confirmed;
- duration;
- confidence;
- degraded state;
- reason code/text;
- event edges:
  - warning started;
  - leak confirmed;
  - leak cleared/requested reset;
  - isolation requested;
  - mapping missing;
  - degraded sensor/mapping.

Initial integration must be observe-only.

### 2.3 Recover localization and mapping

Move from:

```text
sensor index -> valve id
```

toward:

```text
physical input
→ logical leak sensor
→ zone
→ hydraulic segment
→ isolation group
→ valve group
```

Do not hardcode object topology if configuration exists or can be recovered.

### 2.4 Restore selective isolation semantics

Use existing intent fields such as:

```text
I_Water_Zone_Close_Required[]
```

but only after projection and explainability are in place.

Expected result:

```text
localized leak
→ localized isolation intent
```

Fallback rule:

```text
mapping invalid / unknown / multi-zone risk
→ global isolation
```

### 2.5 Valve governance and confirmation

Recover valve subsystem gradually.

Target semantics:

- commanded state;
- projected output state;
- confirmed state;
- confirmation timeout;
- current deviation;
- travel-time deviation;
- limit-switch failure;
- stall detection;
- valve type semantics;
- diagnostic degraded state;
- maintenance required.

This must be separate from leak detection.

### 2.6 Valve exercise / test workflow

Recover scheduled test semantics from reserve structures.

Rules:

- test must be explicit;
- test must be bounded in time;
- test must not override active leak/gas/fire safety;
- test result must be published;
- failed test must degrade valve confidence but must not silently alter runtime authority.

### 2.7 Post-leak recovery governance

Recover controlled recovery workflow:

```text
incident isolated
→ operator acknowledgement
→ controlled short test opening
→ observation window
→ no renewed leak
→ restore allowed
```

Safety rules:

- never auto-reopen after leak without configured recovery policy;
- recovery must be time-limited;
- recovery must automatically return to safe closed state if leak reappears;
- recovery must be blocked by fire/gas/global stop.

### 2.8 Water/Flood explainability

Publish:

- why a valve was selected;
- why global isolation was chosen;
- which sensor caused isolation;
- which mapping was used;
- whether the valve confirmed closed;
- whether operation is degraded;
- what operator action is required.

### 2.9 Water/Flood supervisory publication

After projection and explainability are stable, create or reuse canonical Water supervisory publication.

It should aggregate:

- active leak state;
- affected zones/segments;
- isolation state;
- valve confirmation state;
- recovery state;
- degraded diagnostics;
- status code/text.

## Exit criteria

- leak semantics are no longer flattened to global close only;
- mapping semantics are visible;
- selective isolation exists or is explicitly explained as unavailable;
- valve authority is separate from valve diagnostics;
- recovery is governed;
- all new advanced layers start observe-only;
- safety fallback remains conservative.

---

# Phase 3 — Ventilation reconstruction

## Goal

Recover ventilation as equipment/topology-aware air governance, not only fan-speed control.

## Audit evidence

See `RUNTIME_SEMANTIC_RECOVERY_PROVENANCE.md` section on Ventilation.

Existing semantic reserve indicates:

- global ventilation policy;
- scenario ventilation policy;
- per-unit configuration reserve;
- CO2/humidity thresholds;
- night mode;
- unit location;
- smoke detector presence;
- dirty filter/error/mode state.

## Target architecture

```text
physical sensors
→ air quality normalization
→ logical zone/room air model
→ ventilation unit mapping
→ policy/scenario intent
→ safety override
→ fan/heater governance
→ output projection
→ observability/explainability
```

## Required stages

1. Audit active `FB_Ventilation_System_Manager` and related PRGs/GVLs.
2. Classify per-unit reserve vs active global policy.
3. Preserve fire/gas/smoke safety authority boundaries.
4. Recover per-unit observability before runtime authority.
5. Add topology-aware publication if needed.
6. Avoid hidden balancing control until measurement/feedback semantics are clear.

## Exit criteria

- active ventilation logic classified;
- reserve unit model preserved;
- safety paths remain authoritative;
- observability does not mutate airflow authority.

---

# Phase 4 — Security / Access / Scenario reconstruction

## Goal

Recover governance layers around security, access rights, scenario effects and state restore.

## Audit evidence

See provenance sections:

- Access governance semantic reserve;
- Scenario semantic reserve;
- User rule semantic reserve;
- State snapshot and short-arm restore reserve.

## Key recovered intents

- operator identity;
- access level;
- zone masks;
- maintenance access windows;
- two-person rule;
- scenario effects;
- transition guards;
- scenario statistics;
- short-arm state capture/restore;
- CRC-protected state snapshot.

## Target architecture

```text
operator/security state
→ access governance
→ scenario intent
→ transition guard
→ state snapshot / restore governance
→ domain intents
→ arbitration
→ observability/explainability
```

## Special safety requirements

State restore must not restore unsafe state after:

- alarm;
- leak;
- fire;
- gas;
- smoke;
- degraded runtime;
- invalid CRC;
- stale snapshot;
- insufficient operator rights.

## Exit criteria

- scenario effects do not bypass command arbitration;
- access governance is explicit;
- restore is governed and explainable;
- user rules are typed and priority-aware;
- primitive rule DTOs are not used as new canonical contracts.

---

# Phase 5 — Lighting reconstruction

## Goal

Recover lighting as zone/scenario/topology-aware domain, not only output toggles.

## Audit evidence

See provenance sections:

- outdoor lighting semantic reserve;
- zone sensor semantic reserve;
- scenario semantic reserve;
- state snapshot restore reserve.

## Target architecture

```text
physical switches/motion/light sensors
→ logical zone state
→ scenario / presence / security policy
→ lighting intent
→ arbitration
→ output projection
→ observability/explainability
```

## Expected reserves

- outdoor lighting zones;
- astro/daylight policy;
- party/security/economy/manual modes;
- scenario lighting levels;
- state snapshot restore;
- presence simulation.

## Exit criteria

- lighting effects are not hidden output writes;
- scenario lighting goes through explicit intent/arbitration;
- zone mapping is configurable;
- compatibility HMI surfaces are not semantic roots.

---

# Phase 6 — Global topology and configuration model

## Goal

Recover the cross-domain physical-to-logical configuration model.

## Key principle

```text
install first
configure later
without recompilation
```

## Required global model

The project should eventually support:

- physical IO sources;
- logical sensors;
- logical actuators;
- zones;
- hydraulic segments;
- heating circuits;
- manifolds;
- ventilation units;
- lighting circuits;
- security zones;
- access zones;
- valve groups;
- scenario domains.

## Required stages

1. Audit existing config structures for mapping semantics.
2. Identify canonical mapping contracts.
3. Avoid per-domain hardcoded IO indexes.
4. Preserve object topology from `ТЗ обновлен.txt`.
5. Introduce mapping projection/validation before runtime authority.
6. Publish mapping explainability.

## Exit criteria

- physical wiring is decoupled from semantic topology;
- mapping can be inspected and explained;
- invalid mapping degrades safely;
- runtime does not hardcode object topology unnecessarily.

---

# Phase 7 — Generic trend/history/maintenance recovery

## Goal

Recover trend/history and maintenance analytics as passive observability first.

## Audit evidence

See provenance sections:

- Trend/history semantic reserve;
- Equipment lifetime tracking reserve;
- Zone sensor semantic reserve;
- Valve diagnostics reserve.

## Target architecture

```text
runtime measurements
→ passive trend collector
→ aggregates
→ degradation hints
→ HMI/diagnostics publication
```

## Rules

- trend collector must be passive;
- trend analytics must not control runtime directly;
- derived maintenance hints must be explainable;
- future runtime influence requires separate authority review.

## Initial signals

- room temperature;
- floor temperature;
- manifold pressure;
- pump current;
- methane;
- CO;
- valve current/travel time;
- fan runtime/lifetime.

## Exit criteria

- trend reserve is no longer treated as garbage;
- passive collection exists or is documented;
- no hidden adaptive control is introduced.

---

# Phase 8 — Global supervisory fabric

## Goal

Unify observability, explainability, predictive analytics and forensic reconstruction across domains.

## Target architecture

```text
domain projections
→ domain supervisory enrichment
→ domain publication
→ global supervisory correlation
→ HMI / diagnostics / history / blackbox
```

## Required capabilities

- domain status aggregation;
- degraded-state aggregation;
- causality graph across domains;
- runtime event timeline;
- predictive risk correlation;
- explainability publication;
- blackbox reconstruction.

## Rules

- global supervisory fabric is passive;
- it does not control outputs;
- it may publish operator attention;
- it may classify risk;
- it may not silently override runtime.

## Exit criteria

- observability is coherent across domains;
- domain publication surfaces are canonical;
- compatibility mirrors are clearly marked;
- global dashboard reads canonical publication where possible.

---

# 9. Domain audit template

Every domain reconstruction should follow this template.

## 9.1 Active runtime inventory

Find:

- PRGs;
- FBs;
- GVLs;
- DUTs;
- command paths;
- output paths;
- safety paths.

## 9.2 Reserve inventory

Find:

- unused structures;
- snapshots;
- old richer FBs;
- semantic reports;
- audit notes.

## 9.3 Semantic comparison

Compare:

```text
active runtime
vs
reserve intent
vs
object topology
```

## 9.4 Collapse detection

Look for:

- rich state collapsed to BOOL;
- confidence lost;
- reason lost;
- mapping ignored;
- fallback simplified;
- selective behavior replaced by global behavior;
- diagnostics separated from runtime without publication;
- recovery workflow deleted;
- actuator confirmation missing.

## 9.5 Recovery order

Use this order:

1. classify;
2. observe;
3. project;
4. publish;
5. explain;
6. aggregate;
7. only then consider authority integration.

---

# 10. Forbidden regression patterns

The following patterns are forbidden unless explicitly reviewed and documented.

## 10.1 Unused-to-delete cleanup

```text
unused field / FB / DUT
→ delete
```

## 10.2 Observability controlling runtime

```text
predictive risk
→ directly close valve / stop boiler / override output
```

## 10.3 Runtime depending on HMI mirrors

```text
runtime
→ reads compatibility GVL
```

## 10.4 Semantic flattening

```text
confidence + reason + degraded state
→ BOOL
```

## 10.5 Hardcoded topology where mapping exists

```text
sensor index 3 means bathroom forever
```

## 10.6 Hidden recovery authority

```text
reset button
→ reopen valve / restore state
```

without governed recovery state machine.

## 10.7 Partial unsafe rewrites

Large files must not be patched fragment-by-fragment if that risks truncation or semantic corruption.

---

# 11. Canonical ownership model

## Runtime owns

- execution;
- arbitration;
- output projection;
- actuator authority;
- runtime state transitions.

## Projection owns

- semantic transfer;
- selected sources;
- mapped targets;
- degraded state;
- transition edges.

## Governance owns

- policy decisions;
- safety mode classification;
- recovery permission;
- access validation.

## Supervisory owns

- observation;
- diagnostics;
- predictability;
- explainability;
- causality;
- reconstruction.

## Publication owns

- canonical visibility;
- HMI/diagnostics surfaces;
- compatibility mirrors.

---

# 12. Safety and recovery rules

## Water/Flood

- leak isolation must fail safe;
- unknown mapping must fall back to conservative isolation;
- recovery opening must be governed and time-limited;
- valve diagnostics must not directly reopen valves;
- operator acknowledgement must be explicit for recovery.

## Gas

- gas valve semantics require separate safety review;
- generic valve config must not be reused for gas opening authority;
- gas fail-safe assumptions must be preserved.

## Fire/Smoke

- evacuation and lock-opening semantics must remain explicit;
- fire paths must not be blocked by scenario/user logic.

## Heating

- supervisory heating analytics must not override valves or boiler commands;
- predictive instability remains attention/diagnostics unless authority is explicitly designed.

---

# 13. Documentation expectations

For each major migration step, update or create audit notes that describe:

- what was found;
- what was active;
- what was reserve;
- what was restored;
- what was intentionally not connected;
- what remains compatibility-only;
- what safety boundary was preserved.

Recommended location:

```text
docs/audit/runtime_deep_audit/
```

---

# 14. Current next recommended work

The next major domain should be:

```text
Water / Flood
```

Recommended immediate sequence:

1. Complete Water/Flood active runtime inventory.
2. Create Water/Flood semantic gap report.
3. Define canonical Water runtime projection contract.
4. Add observe-only Water/Flood projection publication.
5. Add explainability/compatibility adapter.
6. Restore selective isolation intent after projection is visible.
7. Add valve governance and confirmation later.
8. Add recovery/test workflow only after authority boundaries are explicit.

Do not jump directly from leak detection to new valve authority.

---

# 15. Final rule

The project should always prefer:

```text
architectural memory
over local simplification
```

and:

```text
explicit semantic contracts
over hidden assumptions
```

This roadmap exists to make that rule operational.
