# ARCHIVE INTEGRATION PLAN — 2026-04-22

Purpose: compare archived design assets with the current repository state and define a sane next-wave integration queue without restoring archived blocks blindly.

Related:
- `ARCHIVE_AUDIT_2026-04-20.md`
- `docs/ROADMAP_PRIORITY_REGISTRY.md`
- `docs/architecture/orphan_analysis_roadmap.md`
- `docs/FB_INVENTORY_AUDIT.md`
- `docs/REFACTOR_PLAN_ARCH_ALIGNMENT.md`

---

## 1. Working interpretation

`archive/` is a quarantine/design-assets area.
Archived blocks are not treated as live implementation.
Any useful idea must be reintroduced through the current architecture, not by direct restore.

This document updates the archive view against the current repository state as of 2026-04-22.

---

## 2. Current baseline from repository

Already established in current repository/docs:
- archive content was already reviewed and classified in `ARCHIVE_AUDIT_2026-04-20.md`
- the current roadmap already prioritizes the sensor pipeline (`FB_Sensor_Analog_Processing`, `FB_Sensor_Calibration`, `FB_Sensor_Calibration_Processor`) as the next implementation wave
- orphan analysis already identifies snapshot/persistence, heating protection, presence playback, and zone access as future directions
- persistence architecture is already partially normalized in the live repo (`FB_Persist_Builder` + `FB_Persist_Pipeline` + `FB_NVRAM_Manager`), so old snapshot ideas must be adapted to that contour, not copied verbatim

---

## 3. Archive items vs current project state

### A. Good candidates for controlled integration

#### 1. `archive/fb_ideas/FB_Maintenance_Access.st`
Status:
- small, isolated, understandable feature block
- not safety-core
- not obviously duplicated by current core architecture

Interpretation:
- good candidate for controlled feature-layer integration
- should become explicit temporary maintenance override/access window logic, not hidden local state

Recommended path:
- integrate only through explicit intent/state/policy ownership
- define who owns activation, timeout, and visibility in HMI/state

Disposition:
- KEEP AS IDEA
- PLAN INTEGRATION

---

#### 2. `archive/fb_ideas/FB_Presence_Simulator.st`
Status:
- still useful as feature concept
- current docs classify simulation/playback as low/feature priority
- archived implementation is simplistic and should not be restored as production logic

Interpretation:
- idea remains useful, implementation should be redesigned around scenario/policy separation
- playback/simulation should not bypass system mode or safety policy

Disposition:
- KEEP AS IDEA
- REDESIGN BEFORE USE

---

#### 3. `archive/fb_ideas/FB_Pre_Departure_Heating.st`
Status:
- idea still makes product sense
- current archive audit marked it as manual review
- archived implementation is too direct/simple for the current heating architecture

Interpretation:
- preserve as a policy-level feature idea
- do not restore as a direct circuit writer
- future implementation should produce requests/targets into existing heating orchestration, not own final actuation

Disposition:
- KEEP AS IDEA
- MANUAL POLICY REDESIGN

---

#### 4. `archive/fb_ideas/FB_Zone_Access_Manager.st`
Status:
- current roadmap still treats zone-based access as not implemented and architecturally meaningful

Interpretation:
- potentially valuable security/access extension
- should be integrated only after current security intent/command separation is stabilized

Disposition:
- KEEP AS IDEA
- DEFER UNTIL SECURITY FLOW CLEANUP ADVANCES

---

### B. Useful concept, but not direct restore target

#### 5. `archive/fb_ideas/FB_Sensor_Distribution.st`
Status:
- archived version is a minimal pass-through splitter
- current roadmap calls the idea architecturally clean but not urgently required
- the live repo already has the earlier sensor pipeline building blocks in root (`FB_Sensor_Analog_Processing`, `FB_Sensor_Calibration`, `FB_Sensor_Calibration_Processor`)

Interpretation:
- the useful part is not the archived code itself, but the pipeline direction:
  raw -> processing -> calibration -> distribution -> consumers
- direct restore of the archived block adds little by itself

Disposition:
- DO NOT RESTORE DIRECTLY
- USE AS PIPELINE REFERENCE ONLY

---

#### 6. `archive/fb_ideas/FB_State_Snapshot_NVRAM.st`
Status:
- archived implementation writes to a hardcoded file path and reflects an older persistence model
- live repo persistence has already moved toward `FB_Persist_Builder` / `FB_Persist_Pipeline` / `FB_NVRAM_Manager`
- orphan roadmap still says snapshot/persistence idea is only partially realized

Interpretation:
- the idea (event-driven snapshots / state checkpointing) is still valid
- the archived implementation shape is obsolete for the current persistence contour

Disposition:
- DO NOT RESTORE DIRECTLY
- EXTRACT IDEA ONLY
- REINTRODUCE LATER AS PERSISTENCE EXTENSION

---

### C. Do not restore directly from archive

#### 7. `archive/fb_unintegrated_controllers/*`
Includes:
- `FB_Exhaust_Ventilation_Controller.st`
- `FB_Gas_Valve_Controller.st`
- `FB_Manifold_Pump_Controller.st`
- `FB_Outdoor_Lighting_Controller.st`
- `FB_Supply_Ventilation_Controller.st`
- `FB_Water_Valve_Controller.st`

Status:
- archive audit already classified them as unintegrated controllers
- current target architecture requires explicit separation of detector / health / state / policy / actuation
- at least some archived controller shapes still embed local policy shortcuts

Interpretation:
- do not resurrect controller blocks into root as-is
- use only as reference material during future actuator/policy decomposition

Disposition:
- REFERENCE ONLY
- NO DIRECT RESTORE

---

## 4. Recommended next-wave implementation queue

### Wave 1 — document-guided integration targets
1. Maintenance access
2. Pre-departure heating
3. Zone-based access

Reason:
- these have product value
- they can be integrated as explicit feature/policy additions
- they do not require restoring legacy controller shape from archive

### Wave 2 — architectural ideas, not direct code reuse
4. Sensor distribution stage
5. Snapshot/event-checkpoint extension
6. Presence playback/simulation redesign

Reason:
- valid ideas remain
- archived implementations are too thin or outdated
- they should follow after current core cleanup/priorities

### Wave 3 — reference-only archive assets
7. Archived controller FBs

Reason:
- use as design reference only during later controlled refactors
- do not reintroduce as standalone live blocks

---

## 5. Proposed deterministic step queue

These are planning steps, not yet executed changes.

### Step A — archive idea inventory alignment
Target:
- align `archive/` planning with current docs and live architecture

Proposed step path:
- `steps/2026-04-22_archive_integration_plan/01_align_archive_plan.py`

Expected result:
- no code changes
- documentation checkpoint only

---

### Step B — maintenance access integration design
Target:
- define ownership and insertion points for maintenance-access logic

Questions to resolve:
- intent source
- state exposure
- timeout owner
- policy impact

Proposed step path:
- `steps/2026-04-22_archive_maintenance_access/01_plan_maintenance_access.py`

Expected result:
- design-level docs and insertion plan before code

---

### Step C — pre-departure heating redesign
Target:
- convert archive concept into policy/request layer design compatible with current heating architecture

Rules:
- no direct final actuation from feature block
- outputs should become requests/setpoint intents

Proposed step path:
- `steps/2026-04-22_archive_predeparture_heating/01_plan_predeparture_heating.py`

Expected result:
- feature contract, not implementation copy

---

### Step D — zone access concept extraction
Target:
- decide whether zone access belongs in access control, security policy, or separate authorization layer

Proposed step path:
- `steps/2026-04-22_archive_zone_access/01_plan_zone_access.py`

Expected result:
- architecture decision before code

---

### Step E — snapshot extension concept
Target:
- extract useful snapshot semantics without reviving obsolete file-path persistence code

Proposed step path:
- `steps/2026-04-22_archive_snapshot_extension/01_plan_snapshot_extension.py`

Expected result:
- bridge document from archive idea to current persist pipeline

---

## 6. Immediate recommendation

Do next:
1. keep archive as reference/quarantine
2. do not restore archived controllers into root
3. use archive only as idea source
4. start with `FB_Maintenance_Access` and `FB_Pre_Departure_Heating` as the healthiest feature candidates

---

## 7. Explicit non-goals

This document does not claim:
- archived code is compile-ready for current architecture
- archived code should be restored as-is
- archive assets are equivalent to verified live implementation

---

End of plan.
