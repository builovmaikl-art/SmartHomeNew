# HEATING ALLOCATION MIGRATION PHASE

# Current phase status

The project has completed:

```text
- full grey POU audit;
- runtime ownership audit;
- duplicate wrapper audit;
- scaffold/runtime separation;
- obsolete floor protection cleanup;
- active runtime behavior review;
- allocation filter integration;
- first useful allocation gate activation;
- obsolete heating wrapper cleanup;
- bounded policy engine implementation;
- bounded policy activation by configured budget;
- allocation / policy observability state publication.
```

The project is now in:

```text
CONTROLLED ALLOCATION MIGRATION PHASE
```

Current sub-stage:

```text
ACTIVE AVAILABILITY / SERVICE GATE ENABLED
OBSOLETE WRAPPER CLEANUP COMPLETED
BOUNDED POLICY LAYER ENABLED BY CONFIGURED BUDGET
OBSERVABILITY PROJECTION CONNECTED
```

---

# Completed migration work

## 1. Safe allocation integration point

Created:

```text
FB_Heating_Allocation_Filter
```

Purpose:

```text
bounded runtime decision gate
between Demand_Map and Manifold_Control
```

Explicitly NOT:

```text
- orchestration layer;
- second runtime;
- boiler owner;
- pump owner;
- safety owner;
- output authority.
```

Actual ownership remains:

```text
PRG_Heating
→ FB_Heating_System_Manager
→ active subsystem owners
```

---

## 2. Runtime integration completed

Integrated chain:

```text
Circuit_Control
→ Demand_Map
→ Allocation_Filter
→ Runtime_Observability
→ Manifold_Control
→ Boiler_Control
```

Runtime observability is projection-only and does not participate in control authority.

Current runtime ownership preserved.

No legacy orchestration pipeline was reconnected.

---

## 3. Active first-stage logic enabled

`FB_Heating_Allocation_Filter` is enabled as a bounded authorization gate:

```text
VI_Enable := TRUE
```

Active base-gate logic:

```text
- manifold pressure availability gate;
- manifold pump service-state gate;
- previous-cycle predictive degradation gate;
- freeze-mode exception;
- DHW ownership preservation;
- allocation degraded publication upward.
```

Current active inputs:

```text
VI_Freeze_Mode_Active := L_Freeze_Active
VI_DHW_Heating_Demand := VI_DHW_Heating_Demand
VI_Manifold_Available := manifold pressure >= C_MIN_HEATING_MANIFOLD_PRESSURE
VI_Manifold_In_Service := GVL_CONFIG.G_Manifold_Pump_In_Service
VI_Manifold_Subsystem_Degraded := predictive pressure/current degradation flags
```

Current active output:

```text
L_Manifold_Demand_Filtered
```

This output is passed into:

```text
FB_Heating_Manifold_Control.VI_Any_Zone_Active
```

---

## 4. Bounded policy layer implemented and enabled by configuration

`FB_Heating_Allocation_Filter` contains a bounded policy layer:

```text
- priority-based manifold selection;
- thermal budget limiting;
- budget accounting;
- policy block diagnostics.
```

Activation in `FB_Heating_System_Manager`:

```text
VI_Enable_Policy_Allocation := (GVL_CONFIG.G_Max_Thermal_Budget > REAL#0.0)
```

Policy inputs are connected from active configuration:

```text
VI_Manifold_Base_Priority := GVL_CONFIG.G_Manifold_Priority
VI_Manifold_Thermal_Weight := GVL_CONFIG.G_Manifold_Thermal_Weight
VI_Max_Thermal_Budget := GVL_CONFIG.G_Max_Thermal_Budget
```

Default configuration:

```text
G_Manifold_Priority := [3, 3, 2, 2, 1]
G_Manifold_Thermal_Weight := [1.0, 1.0, 0.8, 0.8, 0.5]
G_Max_Thermal_Budget := 6.0
```

Default policy impact:

```text
sum(default weights) = 4.1
configured budget = 6.0
```

Therefore default policy activation should not shed normal all-manifold demand.

The layer can only reduce already authorized demand.
It cannot create new demand and cannot write physical outputs.

---

## 5. Runtime observability projection connected

Created:

```text
FB_Heating_Runtime_Observability
```

Purpose:

```text
projection / publication layer only
```

Explicitly NOT:

```text
- runtime owner;
- output authority;
- demand modifier;
- arbitration layer;
- safety owner.
```

Connected in `FB_Heating_System_Manager` after `FB_Heating_Allocation_Filter`.

Publishes to `GVL_STATE`:

```text
G_Allocation_Policy_Active
G_Allocation_Freeze_Bypass_Active
G_Allocation_DHW_Bypass_Active
G_Allocation_Budget_Max
G_Allocation_Budget_Used
G_Allocation_Requested
G_Allocation_Allowed
G_Allocation_Filtered
G_Allocation_Block_Reason
G_Allocation_Effective_Priority
```

Block reason semantics:

```text
0 = no block
1 = availability / pressure block
2 = service-state block
3 = predictive degradation block
4 = policy budget shed
```

---

# Preserved behavior

The following behavior remains owned by existing active runtime blocks:

```text
freeze protection
    → FB_Heating_Safety_Gate / FB_Heating_Safe_State / FB_Heating_Manifold_Control

DHW priority
    → FB_DHW_Manager / FB_Heating_Manifold_Control / FB_Heating_Boiler_Control

pump and valve authority
    → FB_Heating_Manifold_Control

boiler cascade and OpenTherm authority
    → FB_Heating_Boiler_Control

output projection
    → FB_Heating_Output_Projection
```

---

# Explicitly rejected architecture

The following architecture is invalid for reconnect:

```text
Thermal_Allocation
→ Orchestration
→ Execution_Core
→ Override_Layer
→ Runtime
```

Reason:

```text
would create duplicate runtime authority
and parallel orchestration ownership.
```

---

# Completed cleanup

Removed from repository root:

```text
FB_FloorHeating_Freeze_Protection.st
FB_FloorHeating_Overheat_Protection.st
FB_Heating_Execution_Core.st
FB_Heating_Orchestration.st
FB_Heating_Override_Layer.st
FB_Heating_Decision_Context.st
FB_Heating_Thermal_Allocation.st
```

Reasons:

```text
FB_FloorHeating_Freeze_Protection
FB_FloorHeating_Overheat_Protection
    → logic fully absorbed by active runtime owners

FB_Heating_Execution_Core
    → obsolete duplicate wrapper over active managers

FB_Heating_Orchestration
    → obsolete shell around Execution_Core + Override_Layer

FB_Heating_Override_Layer
    → dangerous hard-authority output override layer

FB_Heating_Decision_Context
    → bounded useful behavior absorbed into Allocation_Filter

FB_Heating_Thermal_Allocation
    → detached legacy allocation scaffold; dynamic inputs had no active sources
```

Reference check result:

```text
No active production reference remains in root runtime path.
Historical copies remain in snapshots/docs/logs.
```

---

# Current technical verification status

Static checks completed:

```text
- GVL_STATE allocation observability fields exist;
- FB_Heating_Runtime_Observability writes only those fields;
- FB_Heating_System_Manager contains projection-only instance;
- projection call is placed after Allocation_Filter;
- projection call is placed before Manifold_Control;
- runtime ownership path is unchanged.
```

Required next check:

```text
CODESYS compile check after observability integration.
```

Runtime checks after compile:

```text
1. default budget does not shed all-manifold demand;
2. freeze mode bypasses policy throttling;
3. DHW ownership remains with existing active owners;
4. service/pressure gate works under policy layer;
5. G_Allocation_* fields match expected runtime state.
```

---

# Final architectural direction

The project direction remains:

```text
extract useful bounded policy logic
from legacy detached architecture
and integrate it into the active runtime
without creating a second orchestration layer.
```
