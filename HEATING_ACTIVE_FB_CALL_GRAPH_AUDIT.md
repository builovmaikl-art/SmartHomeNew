# HEATING_ACTIVE_FB_CALL_GRAPH_AUDIT

# Purpose

This document now serves as a verified runtime ownership and donor-extraction audit.

The repository is no longer in:

```text
reconnect-first investigation phase
```

Current phase:

```text
GOVERNED RUNTIME MAINTENANCE
```

The current purpose is:

```text
- document verified active runtime ownership;
- classify historical donor FBs;
- document absorbed logic paths;
- prevent detached runtime resurrection;
- preserve compile/runtime stability.
```

---

# Verified runtime baseline

Current confirmed state:

```text
0 compile errors
0 runtime authority conflicts detected during audit
active runtime ownership chain verified
```

Verified active runtime chain:

```text
PRG_Heating
→ FB_Heating_System_Manager
    → Safety_Gate
    → Safe_State
    → Circuit_Control
    → Demand_Map
    → Policy_Priority_Bridge
    → Allocation_Filter
    → Runtime_Observability
    → Manifold_Control
    → System_Manager post-manifold safety/test finalization
    → Boiler_Control
```

Important:

```text
compile participation
≠
runtime ownership
```

and:

```text
grey POU
≠
automatically dead code.
```

---

# Strategic correction

The previous investigation focused on:

```text
reconnect of historical orchestration fragments
```

The verified conclusion is now:

```text
historical detached orchestration/runtime layers
must NOT be reconnected.
```

The repository evolved toward:

```text
clean active runtime ownership
+
bounded helper execution
+
post-manifold finalization
+
passive governance/observability scaffold
```

---

# Group 1 — Heating orchestration/allocation donor family

Historical donor examples:

```text
FB_Heating_Decision_Context
FB_Heating_Diagnostics
FB_Heating_Execution_Core
FB_Heating_Orchestration
FB_Heating_Override_Layer
FB_Heating_Thermal_Allocation
```

---

## FB_Heating_Diagnostics

Verified classification:

```text
DIAGNOSTICS / EVENT PROJECTION LAYER
```

Role:

```text
read-only diagnostics projection
```

Important:

```text
NOT runtime authority.
```

Writes:

```text
GVL_STATUS.G_Diagnostics*
```

Does NOT own:

```text
- heating control;
- boiler control;
- manifold control;
- valve control;
- DHW control.
```

Current status:

```text
KEEP_GREY_RESERVED
```

---

## FB_Heating_Execution_Core

Verified result:

```text
historical duplicate wrapper
```

Verified status:

```text
VERIFIED REMOVED DONOR
```

Reason:

```text
active ownership already exists in:
FB_Heating_System_Manager
+
FB_DHW_Manager
```

Important:

```text
must NOT be reconnected
as alternate orchestration layer.
```

---

## FB_Heating_Orchestration

Verified result:

```text
historical detached orchestration shell
```

Verified status:

```text
VERIFIED REMOVED DONOR
```

Reason:

```text
would create second orchestration path
parallel to active runtime ownership chain.
```

Reconnect policy:

```text
FORBIDDEN
```

---

## FB_Heating_Override_Layer

Verified result:

```text
historical dangerous authority layer
```

Capabilities:

```text
- manifold suppression;
- valve suppression;
- OpenTherm suppression;
- DHW suppression;
- emergency runtime override.
```

Verified status:

```text
DO NOT CONNECT DIRECTLY
```

Current role:

```text
historical authority donor only
```

Future work:

```text
possible future conceptual extraction review only
```

---

## FB_Heating_Thermal_Allocation

Verified result:

```text
policy/allocation donor
```

Verified extraction:

```text
logic absorbed into:
- FB_Heating_Policy_Priority_Bridge
- FB_Heating_Allocation_Filter
```

Verified status:

```text
VERIFIED EXTRACTED DONOR
```

Important:

```text
historical orchestration shell
must NOT be restored.
```

---

## FB_Heating_Decision_Context

Verified result:

```text
manifold decision/allocation donor
```

Verified extraction:

```text
logic absorbed into:
FB_Heating_Allocation_Filter
```

Verified status:

```text
VERIFIED EXTRACTED DONOR
```

---

# Group 2 — Floor heating protection donor family

Historical donor examples:

```text
FB_FloorHeating_Freeze_Protection
FB_FloorHeating_Overheat_Protection
FB_FloorHeating_Controller
```

---

## FB_FloorHeating_Controller

Verified result:

```text
ACTIVE INDIRECT RUNTIME DEPENDENCY
```

Current owner:

```text
FB_Heating_Circuit_Control
```

Status:

```text
KEEP_ACTIVE
```

---

## FB_FloorHeating_Freeze_Protection

Verified result:

```text
freeze protection donor
```

Verified absorption:

```text
absorbed into:
FB_Heating_Safety_Gate
FB_Heating_Safe_State
```

Status:

```text
VERIFIED ABSORBED DONOR
```

---

## FB_FloorHeating_Overheat_Protection

Verified result:

```text
overheat protection donor
```

Verified absorption:

```text
absorbed into:
FB_Heating_Circuit_Control
```

Status:

```text
VERIFIED ABSORBED DONOR
```

---

# Group 3 — Runtime supervision / governance scaffold family

Representative examples:

```text
FB_Heating_Runtime_Coordinator
FB_Heating_Runtime_Event_Manager
FB_Heating_Runtime_Observation_Aggregator
FB_Heating_Runtime_Observation_Validator
FB_Heating_Runtime_Orchestration_Shell
FB_Heating_Runtime_Stability_Model
FB_Heating_Runtime_Timeline_Observer
FB_Heating_Runtime_Adaptive_*
FB_Heating_Runtime_Anomaly_*
FB_Heating_Runtime_Predictive_*
```

Verified active exceptions:

```text
FB_Heating_Runtime_Observer
FB_Heating_Runtime_Observer_Authorization
```

Deep audit conclusion:

```text
this family does NOT contain missing production runtime authority.
```

Verified role:

```text
passive governance / observability / forensic scaffold
```

NOT:

```text
lost heating runtime controller.
```

Verified properties:

```text
- governance-gated;
- observation-oriented;
- telemetry-oriented;
- sequencing validation oriented;
- anomaly/risk aggregation oriented;
- intentionally isolated from control ownership.
```

Verified active observer path:

```text
PRG_Heating
→ FB_Heating_Runtime_Observer_Authorization
→ FB_Heating_Runtime_Observer
→ GVL_Heating_Runtime_Observation
```

Confirmed governance locks:

```text
Governance_Locked := TRUE
Runtime_Attachment_Allowed := FALSE
Observation-only semantics
```

Verified status:

```text
KEEP_GREY_RESERVED
```

Reconnect policy:

```text
DO NOT CONNECT WHOLE FAMILY
```

Allowed future direction:

```text
bounded read-only extensions only
```

---

# Group 4 — Snapshot/test/simulation family

Examples:

```text
FB_State_Snapshot_Manager
PRG_Config_Simulation
PRG_Scenario_Test_Harness
```

Verified role:

```text
test/support infrastructure
```

Current recommendation:

```text
keep isolated from production runtime ownership chain
```

---

# Updated classification model

## Category A — Active production runtime

Definition:

```text
actively participates in verified production ownership chain
```

Examples:

```text
FB_Heating_System_Manager
FB_Heating_Safety_Gate
FB_Heating_Circuit_Control
FB_Heating_Manifold_Control
FB_Heating_Boiler_Control
```

---

## Category B — Bounded helper execution layers

Definition:

```text
active helper execution
inside runtime ownership chain
```

Examples:

```text
FB_Boiler_Cascade_Manager
FB_Boiler_OpenTherm_Interface
FB_Valve_Test_Manager
```

Important:

```text
helper authority escalation not detected.
```

---

## Category C — Passive runtime observability/governance

Definition:

```text
active or reserved read-only runtime scaffold
```

Examples:

```text
FB_Heating_Runtime_Observer
FB_Heating_Runtime_Observer_Authorization
FB_Heating_Runtime_Contract_Validator
FB_Heating_Runtime_Event_Manager
```

---

## Category D — Verified donor blocks

Definition:

```text
historical runtime decomposition
already absorbed or superseded
```

Examples:

```text
FB_Heating_Execution_Core
FB_Heating_Orchestration
FB_Heating_Thermal_Allocation
FB_Heating_Decision_Context
FB_FloorHeating_Freeze_Protection
FB_FloorHeating_Overheat_Protection
```

---

## Category E — Historical dangerous authority donors

Definition:

```text
historical detached authority layers
unsafe to reconnect directly
```

Examples:

```text
FB_Heating_Override_Layer
```

---

# Main engineering rule

From this point onward:

```text
NO detached reconnect
NO reconnect-first engineering
NO hidden authority expansion
```

Required workflow:

```text
1. governance verification;
2. ownership verification;
3. write-path verification;
4. evidence-level runtime validation;
5. only then bounded runtime evolution.
```

---

# Current verified risk model

The primary risk is no longer:

```text
compile collapse
```

The primary risk is now:

```text
future architectural drift
```

Especially dangerous:

```text
- detached orchestration resurrection;
- Runtime_* actuation;
- helper authority escalation;
- duplicate writers;
- hidden finalization layers;
- telemetry-driven control;
- governance-driven control.
```

---

# Strategic conclusion

The repository evolved from:

```text
legacy orchestration cleanup
```

into:

```text
governed runtime architecture maintenance
```

The primary goal now is:

```text
prevent future architectural drift
while preserving explicit bounded ownership.
```
