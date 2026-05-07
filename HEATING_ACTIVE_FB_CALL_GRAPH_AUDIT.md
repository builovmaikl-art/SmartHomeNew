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

Current status:

```text
DO NOT CONNECT YET
complete full grey POU logic audit first
```

---

## Group 2 — Floor heating protection family

Observed examples:

```text
FB_FloorHeating_Freeze_Protection
FB_FloorHeating_Overheat_Protection
```

Possible interpretations:

```text
1. legacy standalone protection layer;
2. partially absorbed into Safety_Gate/System_Manager logic;
3. unfinished decomposition attempt;
4. still-needed behavior currently absent from active runtime.
```

Current status:

```text
unknown ownership
requires safety-path verification before any reconnect
```

Special rule:

```text
No automatic reconnect of safety-related FBs.
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

Current interpretation:

```text
large supervision/planning scaffold
mostly compile-visible prototypes
not proven runtime-active
```

Important rule:

```text
Do NOT convert this family into active orchestration runtime.
```

Allowed future usage:

```text
bounded read-only supervision only
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
