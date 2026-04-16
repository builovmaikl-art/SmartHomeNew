# REFACTOR PLAN — ARCHITECTURE ALIGNMENT

Status: Draft plan for controlled repository refactor
Scope: Whole project, with safety-first execution
Priority: Bring implementation in line with `docs/MASTER_GUIDE.md`, `docs/WORKFLOW.md`, and `AGENTS.md`

---

## 1. Objective

Bring the repository from the current mixed legacy architecture to the required target architecture:

`Fault → FB_System_Health → FB_State_Manager → Policy → Actuation`

This plan is intended as project memory and execution roadmap.

---

## 2. Confirmed systemic issues

Observed during repository audit:

- safety detectors contain local alarm logic
- some subsystem FBs directly issue actuator commands
- warning/alarm qualification is distributed instead of centralized
- policy is not explicitly separated from subsystem logic
- `FB_System_Health` is not present as a visible dedicated block
- `*_Manager` blocks are likely carrying mixed responsibilities
- project documentation is ahead of implementation

---

## 3. Target architecture rules

### 3.1 Detector blocks
Detector blocks may:
- read raw inputs
- perform minimal signal normalization if strictly required
- output raw/qualified event signals

Detector blocks must not:
- decide system mode
- directly close/open valves
- own global alarm state
- own global warning state

### 3.2 FB_System_Health
Must become the single source of truth for:
- fault aggregation
- warning/alarm qualification
- root cause classification
- latching and reset
- severity input for state calculation

### 3.3 FB_State_Manager
Must:
- consume health outputs only
- compute system mode only
- remain the only authority for operational mode

### 3.4 Policy layer
Must:
- convert system mode into allowed behavior
- decide actuator permissions and demanded actions
- avoid raw diagnostic evaluation

### 3.5 Actuation blocks
Actuation blocks may:
- execute commands
- validate feedback
- report execution fault / feedback fault

Actuation blocks must not:
- make policy decisions
- infer global alarm state

---

## 4. Classification model for every block

Each FB must be classified into exactly one primary role:

- Detector
- Health
- State
- Policy
- Actuator
- Service / Infrastructure
- Persistence / History / Diagnostics
- Candidate for deletion

If a block spans more than one role, it is a refactor candidate.

---

## 5. Execution stages

## Stage 0 — Repository baseline and inventory
Purpose: Freeze understanding before refactor.

Steps:
1. inspect current `git diff`
2. inspect execution errors/logs
3. confirm repo consistency
4. build full FB inventory table
5. classify every FB by role and risk
6. mark blocks as keep / split / rewrite / delete

Deliverables:
- full FB audit table
- conflict list against target architecture
- candidate deletion list

Exit criteria:
- all FB_* reviewed
- each FB assigned a disposition

---

## Stage 1 — Safety domain audit closure
Purpose: Close the highest-risk architecture violations first.

In scope:
- water leakage
- gas / methane
- smoke / fire
- CO
- gas/smoke aggregation
- emergency valve logic

Steps:
1. identify all direct sensor→actuator paths
2. identify all local alarm/warning calculations
3. identify all latch/debounce logic outside health
4. identify all direct safety actuation shortcuts
5. document required decomposition for each block

Expected outcomes:
- list of safety FBs to split
- list of obsolete emergency shortcuts
- first candidate deletion set

Exit criteria:
- no unresolved ambiguity on safety architecture migration

---

## Stage 2 — Introduce `FB_System_Health`
Purpose: Create the missing architectural core.

Required capabilities:
- accept normalized fault/event inputs from subsystems
- produce centralized warnings/alarms
- classify root cause and source
- provide latched state and reset logic
- output health summary for `FB_State_Manager`

Steps:
1. define health input contract
2. define root cause enums / source fields if missing
3. define health outputs consumed by `FB_State_Manager`
4. implement empty/stub health block skeleton
5. integrate one safety path first
6. verify health is source of truth

Exit criteria:
- `FB_System_Health` exists
- at least one subsystem uses it as the only alarm authority

---

## Stage 3 — Normalize detector layer
Purpose: Reduce detector FBs to their proper role.

Candidates:
- `FB_Gas_Methane_Detector`
- `FB_Smoke_Detector`
- `FB_CO_Detector`
- water leak detector logic currently embedded in `FB_Water_Leakage_Manager`

Steps:
1. remove actuator outputs from detector FBs
2. remove global alarm/warning ownership from detector FBs
3. move delay/debounce/latch decisions to health where appropriate
4. keep only signal-level outputs in detector blocks
5. rename blocks where names no longer match responsibility

Exit criteria:
- detector blocks no longer command valves
- detector blocks no longer define global alarm state

---

## Stage 4 — Separate policy from subsystem managers
Purpose: Eliminate mixed-responsibility `*_Manager` blocks.

Candidates:
- `FB_Water_Leakage_Manager`
- `FB_Gas_Smoke_Manager`
- `FB_Heating_System_Manager`
- `FB_Ventilation_System_Manager`
- `FB_Security_System_Manager`
- other `*_Manager` blocks after audit

Steps:
1. inspect each manager for mixed logic
2. extract detector responsibilities out
3. extract policy decisions into dedicated policy blocks
4. retain only orchestration where justified
5. delete manager blocks that become redundant

Possible target blocks:
- `FB_Policy_Safety`
- `FB_Policy_Heating`
- `FB_Policy_Ventilation`
- `FB_Policy_Security`

Exit criteria:
- no subsystem manager directly owns full detector+alarm+actuation chain

---

## Stage 5 — Restrict actuator blocks to execution only
Purpose: Make actuator FBs dumb and verifiable.

Candidates:
- `FB_Water_Valve_Controller`
- `FB_Gas_Valve_Controller`
- pump and ventilation actuators
- any block issuing OPEN/CLOSE commands

Steps:
1. inspect command inputs
2. inspect whether local policy exists
3. remove self-decided emergency behavior
4. retain feedback validation and execution fault detection only
5. route execution faults back to health

Exit criteria:
- actuators execute commands only
- execution/feedback faults are reported, not self-governed globally

---

## Stage 6 — Enforce mode-driven behavior across controllers
Purpose: Ensure all control FBs obey system mode.

Candidates:
- `FB_PID_Controller`
- `FB_FloorHeating_Controller`
- `FB_Supply_Ventilation_Controller`
- `FB_Exhaust_Ventilation_Controller`
- `FB_Outdoor_Lighting_Controller`
- any other autonomous controller

Steps:
1. inspect current autonomous behavior
2. add explicit system mode input if missing
3. define behavior per mode
4. ensure `SAFE_STOP` and `FREEZE_PROTECTION` are respected
5. verify no controller runs outside allowed modes

Exit criteria:
- every active controller is mode-gated

---

## Stage 7 — Clean state ownership and persistence boundaries
Purpose: Remove duplicated state authority.

Candidates:
- `FB_State_Manager`
- `FB_State_Replication`
- `FB_State_Snapshot_Manager`
- `FB_State_Snapshot_NVRAM`
- `GVL_STATE`

Steps:
1. identify which block computes state
2. identify which blocks only transport/store state
3. remove any secondary state inference
4. enforce `GVL_STATE` as transport only
5. verify persistence layers are passive

Exit criteria:
- `FB_State_Manager` is the only state authority
- storage blocks do not compute logic

---

## Stage 8 — Rule/Scenario governance cleanup
Purpose: Prevent architecture bypass through automation logic.

Candidates:
- `FB_Rule_Engine`
- `FB_Scenario_Manager`
- `FB_Scenario_Transition_Controller`
- `FB_Lighting_Blinds_Manager`
- any scheduler/simulator blocks

Steps:
1. inspect direct output control paths
2. forbid raw diagnostic interpretation in rule/scenario blocks
3. make rule/scenario blocks influence policy inputs, not direct safety actions
4. isolate simulation-only logic from production control paths
5. verify no scenario bypasses system mode

Exit criteria:
- rules/scenarios cannot bypass policy and mode

---

## Stage 9 — IO mapping enforcement
Purpose: Align implementation with `docs/IO_MAPPING_CONCEPT.md`.

Steps:
1. inspect for direct physical IO coupling
2. inventory every direct hardware dependency
3. move logical addressing to mapping layer
4. ensure HMI remapping is feasible without logic edits
5. document all exceptions if any remain

Exit criteria:
- logic no longer depends on fixed physical PLC channel assumptions

---

## Stage 10 — Candidate deletion and consolidation
Purpose: Remove obsolete and duplicate logic.

Initial candidates for review:
- `FB_Emergency_Valve_Open`
- `FB_Manual_Valve_Control`
- duplicate presence/simulation helpers if overlapping
- any manager block fully replaced by policy + actuator split
- any detector block made obsolete by normalized replacements

Deletion criteria:
- responsibility duplicated elsewhere
- violates target architecture and is superseded
- not referenced in current integrated architecture
- only exists as legacy shortcut

Exit criteria:
- deletion list approved
- obsolete blocks removed through deterministic steps

---

## Stage 11 — Documentation alignment
Purpose: Keep project memory synchronized with implementation.

Steps:
1. update architecture notes after each major refactor milestone
2. update work changelog with accepted decisions
3. document deleted blocks and rationale
4. document new contracts between Detector / Health / State / Policy / Actuator
5. keep docs aligned with actual repo code

Exit criteria:
- docs reflect implemented reality, not aspiration only

---

## Stage 12 — Final stabilization and freeze
Purpose: End refactor in controlled state.

Steps:
1. run final repository consistency review
2. inspect resulting `git diff`
3. inspect execution logs/errors
4. verify no direct safety shortcuts remain
5. verify fail-safe behavior still preserved
6. freeze architecture baseline for next stage

Exit criteria:
- repo consistent
- docs aligned
- architecture enforced in code

---

## 6. Mandatory per-step execution template

For every actual change step:

1. inspect current `git diff`
2. inspect logs/errors
3. confirm consistency
4. define one target problem only
5. create exactly one deterministic repair step in `steps/<date>_<context>/`
6. execute repair
7. inspect resulting `git diff`
8. verify no side effects
9. document the accepted result if the change is retained

---

## 7. First execution queue (recommended order)

1. complete full FB inventory and disposition table
2. implement `FB_System_Health` contract and skeleton
3. refactor methane detector to signal-only
4. refactor smoke detector to signal-only
5. split `FB_Water_Leakage_Manager`
6. review and constrain valve controllers
7. extract `FB_Policy_Safety`
8. connect safety path through Health → State → Policy
9. audit controllers for mode compliance
10. review deletion candidates

---

## 8. Initial deletion review queue

Blocks to review first as likely legacy or architecture-bypass candidates:

- `FB_Emergency_Valve_Open`
- `FB_Manual_Valve_Control`
- `FB_Water_Leakage_Manager` in current form
- `FB_Gas_Smoke_Manager` in current form
- detector blocks exposing global alarm or actuator outputs

These are not auto-delete items. They must be reviewed against actual references and integrated behavior.

---

## 9. Success criteria for the project

The project reaches acceptable alignment when:

- every safety event flows through `FB_System_Health`
- `FB_State_Manager` consumes health only
- policy exists as explicit layer
- actuators do not make system decisions
- detector blocks do not own global alarms
- mode-driven behavior is enforced everywhere
- `GVL_STATE` remains transport only
- obsolete legacy shortcuts are removed
- docs describe implemented reality

---

## 10. Notes for future sessions

For any next assistant session:

- read `AGENTS.md`
- read `docs/MASTER_GUIDE.md`
- read `docs/WORKFLOW.md`
- use this document as project-memory roadmap
- verify every conclusion against the actual repository state
- do not treat this plan as proof of implementation

---

End of plan.
