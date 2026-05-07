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

## Group 1 — Legacy heating orchestration family

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
that lost integration path visibility later.
```

Important engineering implication:

```text
grey-state alone is NOT sufficient proof
that the logic is obsolete or incorrect.
```

Current risk:

```text
unsafe reconnect could duplicate ownership and execution paths
inside active heating runtime.
```

Current status:

```text
DO NOT CONNECT YET
reconstruct historical integration first
```

Required next investigation:

```text
1. compare historical snapshot PRG_Heating versions;
2. determine original integration points;
3. determine why the path became grey;
4. determine which behavior corrections were intended;
5. determine which active runtime sections replaced the logic;
6. identify safe reconnect boundaries.
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
3. unfinished decomposition attempt.
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
- test infrastructure.
```

Action:

```text
classify before reconnecting or deleting
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
5. no retained HMI/config dependency.
```

Important:

```text
compile absence alone is NOT sufficient deletion proof
```

---

# Main engineering rule

From this point onward:

```text
NO reconnect first
NO delete first
classification first
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

## Step 2 — Determine architectural role

Possible outcomes:

```text
- active dependency hidden by tree state;
- future-reserved scaffold;
- obsolete duplicate;
- safety-isolated helper;
- simulation/test only;
- historical artifact.
```

---

## Step 3 — Decide safe action

Allowed actions:

```text
KEEP_ACTIVE
KEEP_GREY_RESERVED
MOVE_TO_ARCHIVE
MOVE_TO_TEST_SCOPE
RECONNECT_LATER
DELETE_ONLY_AFTER_FULL_AUDIT
```

---

# Current risk statement

The current risk is no longer compile failure.

The real risk is:

```text
incorrect reconnect of detached architecture fragments
```

Especially dangerous:

```text
- safety FB reconnect;
- orchestration reconnect;
- duplicate ownership paths;
- predictive runtime authority;
- reconnecting supervision scaffold as live runtime.
```

---

# Current engineering recommendation

Current recommendation is intentionally conservative:

```text
1. keep current 0-error baseline stable;
2. classify all grey POU first;
3. reconnect nothing automatically;
4. delete nothing automatically;
5. identify true obsolete duplicates;
6. identify true future-reserved architecture;
7. reconnect only after dependency proof.
```

---

# Current audit focus

Immediate focus:

```text
Grey POU Classification Table
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
Test/Simulation Only
Likely Role
Replacement Exists
Reconnect Risk
Recommended Action
Notes
```

This classification table is now the primary engineering task.
