# HEATING_ACTIVE_FB_CALL_GRAPH_AUDIT.md

# Purpose

This document no longer focuses primarily on heating runtime supervision activation.

The current purpose is:

```text
Classify grey/inactive POU objects visible in the CODESYS project tree
without breaking the current 0-error compile baseline.
```

The project currently compiles successfully in the real CODESYS environment.

That compile-clean state is now considered the authoritative engineering baseline.

---

# Important baseline rule

Current confirmed state:

```text
0 compile errors
0 warnings affecting build validity
project operational baseline restored
```

This baseline must not be destabilized.

From this point:

- grey POU objects are NOT automatically considered broken;
- blue POU objects are NOT automatically considered correct architecture;
- compile participation and runtime participation are different things;
- project-tree visibility and runtime execution are different things.

---

# Current strategic correction

The audit must proceed logic-first, not reconnect-first.

Working hypothesis:

```text
Some behavior currently considered "lost" may already exist inside other grey POU
that have not yet been classified.
```

Therefore the correct order is now:

```text
1. full grey POU logic audit;
2. responsibility / behavior map;
3. duplicate and overlap detection;
4. lost-behavior identification;
5. cleanup / deletion of proven invalid root blocks;
6. only then intentional reconnect or code changes.
```

Do NOT restore historical links blindly.

Do NOT assume the 2026-05-04 pipeline should be reconnected as-is.

Do NOT assume the current runtime is complete until all grey logic is classified.

---

# What "grey POU" means in this audit

Grey POU in the CODESYS tree currently means:

```text
present in repository/project
but not participating in current compile/runtime graph
```

This does NOT automatically mean:

```text
- obsolete;
- removable;
- dead code;
- invalid architecture;
- safe to reconnect.
```

The previous mistake was assuming that compile-visible infrastructure could be safely connected without a complete dependency and project-registration audit.

This audit exists specifically to avoid repeating that mistake.

---

# Scope of this audit

Included:

```text
FB_Heating_*
FB_FloorHeating_*
FB_State_*
selected PRG_* test/simulation layers
selected runtime supervision FBs
```

Explicitly excluded:

```text
PRG_PLC_A
PRG_PLC_B
PRG_PLC_*
```

Those PRGs are outside the current grey-POU investigation scope.

---

# Current observed grey groups

## Group 1 — Heating orchestration / allocation family

Observed examples:

```text
FB_Heating_Decision_Context
FB_Heating_Diagnostics
FB_Heating_Execution_Core
FB_Heating_Orchestration
FB_Heating_Override_Layer
FB_Heating_Thermal_Allocation
```

Current interpretation:

```text
alternative heating orchestration/runtime decomposition path
partially overlaps current PRG_Heating execution ownership
```

Important correction:

```text
Decision_Context + Thermal_Allocation must NOT currently be treated
as automatically obsolete.
```

Reason:

```text
existing system behavior was reportedly corrected/improved
relative to earlier runtime behavior using these logic paths.
```

This means:

```text
these FBs may represent intended target behavior
that lost integration path visibility later,
or their behavior may now be represented in another grey/active block.
```

Completed diagnostics sub-audit:

```text
FB_Heating_Diagnostics is NOT missing heating-control behavior.
```

Role:

```text
read-only diagnostics / event projection layer
```

Implemented logic:

```text
- service / out-of-service diagnostics aggregation;
- backup pump OOS event;
- electric heater OOS event;
- manifold pump OOS events;
- DHW pump OOS events;
- freeze hardware critical event projection;
- diagnostics text/status aggregation.
```

Writes:

```text
GVL_STATUS.G_Diagnostics*
GVL_STATUS.G_Diagnostics_Events
GVL_STATUS.G_Diagnostics_Count
```

Does NOT own:

```text
- heating control;
- boiler control;
- manifold control;
- valve control;
- DHW control;
- runtime sequencing;
- output projection.
```

Current classification:

```text
FB_Heating_Diagnostics
    → KEEP_GREY_RESERVED / DIAGNOSTICS PROJECTION CANDIDATE
```

Current reconnect policy:

```text
Do not reconnect as control logic.
Only consider later as diagnostics/event projection if active diagnostics pipeline needs this exact behavior.
```

Completed orchestration/allocation sub-audit:

```text
FB_Heating_Execution_Core is NOT missing target behavior.
FB_Heating_Orchestration is NOT missing target behavior by itself.
FB_Heating_Override_Layer is dangerous direct authority.
FB_Heating_Thermal_Allocation + FB_Heating_Decision_Context are the confirmed lost-behavior candidates.
```

Execution core result:

```text
FB_Heating_Execution_Core
    → duplicate wrapper over active FB_Heating_System_Manager + FB_DHW_Manager
```

It adds no independent heating policy, arbitration, or safety behavior beyond calling the active managers.

Current classification:

```text
FB_Heating_Execution_Core
    → OBSOLETE DUPLICATE WRAPPER CANDIDATE
```

Orchestration result:

```text
FB_Heating_Orchestration
    → wrapper over FB_Heating_Execution_Core + FB_Heating_Override_Layer
```

It should not be reconnected as a new top-level runtime path because that would create a second upper orchestration layer parallel to current PRG_Heating.

Current classification:

```text
FB_Heating_Orchestration
    → OBSOLETE / DANGEROUS DUPLICATE ORCHESTRATION CANDIDATE
```

Override layer result:

```text
FB_Heating_Override_Layer
    → hard authority layer
```

It can force-disable:

```text
- manifold pumps;
- manifold valves;
- zone valves;
- boiler OT enable;
- boiler OT setpoints;
- backup circulation pump;
- electric heater;
- DHW heating pump;
- DHW circulation pump.
```

Current classification:

```text
FB_Heating_Override_Layer
    → DO NOT CONNECT DIRECTLY
    → AUTHORITY LOGIC ONLY FOR POSSIBLE FUTURE MERGE/DESIGN REVIEW
```

Thermal allocation result:

```text
FB_Heating_Thermal_Allocation
    → confirmed policy/allocation lost-behavior candidate
```

Implemented logic:

```text
- manifold base priority;
- zone priority bias;
- guest preheat priority boost;
- zone target adjustment priority effect;
- zone self level priority effect;
- policy priority multiplier;
- manifold thermal weight;
- max thermal budget input;
- adjusted manifold priority output.
```

Decision context result:

```text
FB_Heating_Decision_Context
    → confirmed manifold enable decision helper
```

Implemented logic:

```text
- manifold allowed state from service/fault conditions;
- pressure fault exclusion;
- current fault exclusion;
- pump in-service exclusion;
- degraded flag when a manifold is disallowed;
- priority ordered selection;
- max thermal budget limiting;
- manifold enabled output.
```

Confirmed search result:

```text
thermal-budget / allocation vocabulary is not broadly present in active runtime.
It is concentrated in FB_Heating_Thermal_Allocation and historical/test harness snapshots.
```

Current classification:

```text
FB_Heating_Thermal_Allocation
    → RECONNECT_LATER / MERGE_LOGIC_INTO_ACTIVE_OWNER CANDIDATE

FB_Heating_Decision_Context
    → RECONNECT_LATER / MERGE_LOGIC_INTO_ACTIVE_OWNER CANDIDATE
```

Current reconnect policy:

```text
Do NOT reconnect old Orchestration pipeline wholesale.
Do NOT reconnect Override_Layer directly.
Do NOT reconnect Thermal_Allocation without input contract audit.
```

Required next design step for this cluster:

```text
1. identify current active owner for manifold availability / priority / budget decisions;
2. determine whether policy inputs still exist in GVL_CONFIG / HMI / scenarios;
3. define safe integration point before FB_Heating_System_Manager output authority;
4. merge only allocation decision outputs, not historical orchestration shell;
5. preserve current 0-error baseline until design is complete.
```

---

## Group 2 — Floor heating protection family

Observed examples:

```text
FB_FloorHeating_Freeze_Protection
FB_FloorHeating_Overheat_Protection
FB_FloorHeating_Controller
```

Completed overlap audit:

```text
FB_FloorHeating_Controller is NOT obsolete.
```

Reason:

```text
current active FB_Heating_Circuit_Control directly instantiates
FB_FloorHeating_Controller as active per-circuit PID/PWM runtime controller.
```

Therefore:

```text
FB_FloorHeating_Controller = ACTIVE INDIRECT RUNTIME DEPENDENCY
```

Completed safety overlap result:

```text
FB_FloorHeating_Freeze_Protection logic is absorbed.
FB_FloorHeating_Overheat_Protection logic is absorbed.
```

Freeze protection overlap:

```text
old logic:
- floor freeze detection
- outdoor freeze detection
- force circulation/pump behavior
```

Current owners:

```text
FB_Heating_Safety_Gate
FB_Heating_Safe_State
```

Current runtime now additionally includes:

```text
- freeze target supply logic;
- IO failsafe handling;
- gas safety interaction;
- backup circulation;
- electric heater integration;
- manifold-level freeze circulation.
```

Overheat overlap:

```text
old logic:
- threshold detect
- lock overheated circuits
```

Current owner:

```text
FB_Heating_Circuit_Control
```

Current runtime now additionally includes:

```text
- validated sensor inputs;
- 60s debounce timer;
- room/floor fallback selection;
- rule-action arbitration.
```

Current classification:

```text
FB_FloorHeating_Controller
    → KEEP_ACTIVE

FB_FloorHeating_Freeze_Protection
    → OBSOLETE DUPLICATE CANDIDATE

FB_FloorHeating_Overheat_Protection
    → OBSOLETE DUPLICATE CANDIDATE
```

Current deletion status:

```text
not deleted yet
awaiting full-system audit completion
```

---

## Group 3 — Runtime supervision scaffold family

Observed examples:

```text
FB_Heating_Runtime_Coordinator
FB_Heating_Runtime_Event_Manager
FB_Heating_Runtime_Observation_Aggregator
FB_Heating_Runtime_Observation_Validator
FB_Heating_Runtime_Orchestration_Shell
FB_Heating_Runtime_Stability_Model
FB_Heating_Runtime_Timeline_Observer
FB_Heating_Runtime_Jitter_Detector
FB_Heating_Runtime_Latency_Validator
FB_Heating_Runtime_Adaptive_*
FB_Heating_Runtime_Anomaly_*
FB_Heating_Runtime_Predictive_*
```

Currently active exceptions:

```text
FB_Heating_Runtime_Observer
FB_Heating_Runtime_Observer_Authorization
```

Deep audit result:

```text
this family does NOT contain missing heating-control runtime logic.
```

Main architectural role:

```text
read-only runtime supervision / telemetry / validation scaffold
```

Confirmed properties:

```text
- governance-gated;
- observation-oriented;
- ownership validation oriented;
- sequencing validation oriented;
- anomaly/risk aggregation oriented;
- runtime-health projection oriented;
- intentionally isolated from control authority.
```

Verified active path:

```text
PRG_Heating
→ FB_Heating_Runtime_Observer_Authorization
→ FB_Heating_Runtime_Observer
→ GVL_Heating_Runtime_Observation
```

Confirmed status:

```text
bounded passive observer path only
```

Important confirmed conclusion:

```text
Coordinator / Orchestration_Shell are NOT missing production runtime.
```

They are:

```text
future-reserved orchestration/supervision shell layers
```

NOT:

```text
lost heating runtime authority.
```

Confirmed reconnect risk:

```text
wholesale reconnect would create parallel orchestration/runtime authority illusion
without restoring actual heating behavior.
```

Confirmed current role examples:

```text
FB_Heating_Runtime_Contract_Validator
    → sequencing/isolation validator

FB_Heating_Runtime_Event_Manager
    → bounded telemetry/event buffer

FB_Heating_Runtime_Observation_Validator
    → passive observation integrity validator

FB_Heating_Runtime_Observation_Aggregator
    → runtime health aggregation

FB_Heating_Runtime_Adaptive_*
FB_Heating_Runtime_Anomaly_*
FB_Heating_Runtime_Predictive_*
    → supervision/risk/anomaly analytics scaffold
```

Current classification:

```text
FB_Heating_Runtime_Observer
    → KEEP_ACTIVE

FB_Heating_Runtime_Observer_Authorization
    → KEEP_ACTIVE

remaining FB_Heating_Runtime_*
    → KEEP_GREY_RESERVED
```

Current deletion policy:

```text
DO NOT DELETE YET
```

Reason:

```text
they are architecturally coherent supervision scaffolding,
not random garbage or broken duplicates.
```

Current connection policy:

```text
DO NOT CONNECT WHOLE FAMILY
```

Allowed future direction:

```text
bounded read-only extensions only
through existing observer authorization path.
```

---

## Group 4 — Snapshot/test/simulation family

Observed examples:

```text
FB_State_Snapshot_Manager
PRG_Config_Simulation
PRG_Scenario_Test_Harness
```

Interpretation:

```text
test/support infrastructure
not production runtime path
```

Current recommendation:

```text
keep isolated from production runtime execution graph
```

---

# New classification model

The previous classification model was too runtime-centric.

The new model focuses on safe engineering decisions.

---

## Category A — Active production runtime

Definition:

```text
actively participates in current production execution graph
```

Examples:

```text
FB_Heating_System_Manager
FB_DHW_Manager
FB_Heating_Output_Projection
FB_Heating_RootCause_Diagnostics
```

Action:

```text
protect
verify carefully before modification
```

---

## Category B — Indirect active runtime

Definition:

```text
called from active runtime FBs
```

Examples:

```text
FB_Heating_Safety_Gate
FB_Heating_Circuit_Control
FB_Heating_Manifold_Control
FB_Heating_Boiler_Control
FB_FloorHeating_Controller
```

Action:

```text
trace ownership before touching
```

---

## Category C — Passive observer runtime

Definition:

```text
active but read-only/passive
```

Examples:

```text
FB_Heating_Runtime_Observer
FB_Heating_Runtime_Observer_Authorization
```

Action:

```text
bounded extension only
```

---

## Category D — Grey inactive project objects

Definition:

```text
present in project tree
not participating in current compile/runtime graph
```

This is now the MAIN investigation category.

Possible meanings:

```text
- legacy decomposition;
- future-reserved architecture;
- disabled experiments;
- detached scaffolding;
- archived runtime concepts;
- test infrastructure;
- missing target behavior waiting for safe integration.
```

Action:

```text
classify by logic and ownership before reconnecting or deleting
```

---

## Category E — Future-reserved architecture

Definition:

```text
intentionally inactive
but architecturally valuable
```

Action:

```text
keep documented
keep isolated
do not claim active behavior
```

---

## Category F — Obsolete duplicate candidates

Definition:

```text
older implementation replaced by current active architecture
```

Requirements before deletion:

```text
1. ownership verified;
2. no active references;
3. no hidden project dependencies;
4. no retained safety behavior;
5. no retained HMI/config dependency;
6. snapshot or audit trail exists.
```

Important:

```text
compile absence alone is NOT sufficient deletion proof
```

If a root block is proven invalid in the current architecture:

```text
delete without preserving root clutter
but only after audit evidence is recorded
```

---

# Main engineering rule

From this point onward:

```text
NO reconnect first
NO delete first unless proven invalid
classification first
logic-first audit before lost-behavior claims
```

The previous failure happened because connection work started before:

```text
- dependency audit;
- project registration audit;
- ownership audit;
- compile graph audit;
- rollback chain verification.
```

This document changes the workflow.

---

# Required investigation workflow

## Step 1 — Determine project participation

For every grey POU:

```text
- exists in repository?
- exists in project tree?
- excluded from build?
- instantiated anywhere?
- referenced by active runtime?
- referenced by HMI/config/safety?
```

---

## Step 2 — Determine logic responsibility

For every grey POU:

```text
- what behavior does it implement?
- is that behavior present in current active runtime?
- is that behavior present in another grey POU?
- does it own control authority?
- does it only compute diagnostics/observation?
- does it write GVL_STATE / GVL_STATUS / GVL_OUTPUT?
- does it touch safety, boiler, manifold, DHW, or IO authority?
```

---

## Step 3 — Determine architectural role

Possible outcomes:

```text
- active dependency hidden by tree state;
- future-reserved scaffold;
- obsolete duplicate;
- safety-isolated helper;
- simulation/test only;
- historical artifact;
- target behavior waiting for safe integration;
- duplicate authority that must be deleted or redesigned.
```

---

## Step 4 — Decide safe action

Allowed actions:

```text
KEEP_ACTIVE
KEEP_GREY_RESERVED
MOVE_TO_ARCHIVE
MOVE_TO_TEST_SCOPE
RECONNECT_LATER
DELETE_AFTER_FULL_AUDIT
MERGE_LOGIC_INTO_ACTIVE_OWNER
```

---

# Current risk statement

The current risk is no longer compile failure.

The real risk is:

```text
incorrect reconnect of detached architecture fragments
or premature deletion of behavior that exists only in grey POU
```

Especially dangerous:

```text
- safety FB reconnect;
- orchestration reconnect;
- duplicate ownership paths;
- predictive runtime authority;
- reconnecting supervision scaffold as live runtime;
- deleting allocation/policy logic before confirming replacement.
```

---

# Current engineering recommendation

Current recommendation is intentionally conservative:

```text
1. keep current 0-error baseline stable;
2. complete full grey POU logic audit;
3. reconnect nothing automatically;
4. delete only blocks proven invalid in current architecture;
5. identify true obsolete duplicates;
6. identify true future-reserved architecture;
7. identify behavior implemented only in grey POU;
8. reconnect or merge only after dependency proof.
```

---

# Current audit focus

Immediate focus:

```text
Grey POU Logic Classification Table
```

Columns:

```text
POU Name
POU Type
Grey/Blue State
Repository File Exists
Project Present
Compile Participant
Runtime Participant
Safety Related
Writes State/Outputs
Test/Simulation Only
Implemented Logic
Replacement Exists
Overlap With Active Runtime
Reconnect Risk
Recommended Action
Notes
```

This classification table is now the primary engineering task.
