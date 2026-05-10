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
- obsolete heating wrapper cleanup.
```

The project is now in:

```text
CONTROLLED ALLOCATION MIGRATION PHASE
```

Current sub-stage:

```text
ACTIVE AVAILABILITY / SERVICE GATE ENABLED
OBSOLETE WRAPPER CLEANUP COMPLETED
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
→ Manifold_Control
→ Boiler_Control
```

Current runtime ownership preserved.

No legacy orchestration pipeline was reconnected.

---

## 3. Active first-stage logic enabled

`FB_Heating_Allocation_Filter` is now enabled as a bounded authorization gate:

```text
VI_Enable := TRUE
VI_Enable_Policy_Allocation := FALSE
```

Currently active logic:

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

# Policy / thermal budget state

Policy allocation remains intentionally disabled:

```text
VI_Enable_Policy_Allocation := FALSE
```

Not active yet:

```text
- thermal budget limiting;
- comfort priority weighting;
- guest preheat priority;
- dynamic thermal shedding.
```

Reason:

```text
runtime must first stabilize around explicit availability/service authorization semantics.
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
```

Reference check result:

```text
No active production reference remains in root runtime path.
Historical copies remain in snapshots/docs/logs.
```

---

# Remaining source/reference blocks

Kept for now:

```text
FB_Heating_Thermal_Allocation.st
FB_Heating_Decision_Context.st
```

Reason:

```text
these are still historical source/reference blocks for future policy-layer work.
```

Do not reconnect them directly.

Do not delete them until thermal-budget / priority policy is either:

```text
- fully migrated into FB_Heating_Allocation_Filter;
- or explicitly rejected as not required.
```

---

# Next technical checks

Required next checks:

```text
1. CODESYS compile check;
2. verify FB_Heating_Allocation_Filter is visible as a project POU;
3. verify no missing interface arguments in FB_Heating_System_Manager;
4. verify service/pressure gate does not conflict with freeze behavior;
5. verify predictive degradation one-cycle delay is acceptable;
6. only then continue policy-layer design.
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
