# HEATING ALLOCATION MIGRATION PHASE

# Current phase status

The project has completed:

```text
- full grey POU audit;
- runtime ownership audit;
- duplicate wrapper audit;
- scaffold/runtime separation;
- obsolete floor protection cleanup;
- allocation policy extraction start.
```

The project is now officially in:

```text
CONTROLLED ALLOCATION MIGRATION PHASE
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
bounded allocation/policy filter
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

## 3. Extracted useful logic

Useful bounded logic extracted from:

```text
FB_Heating_Thermal_Allocation
FB_Heating_Decision_Context
```

Already migrated:

```text
- availability filtering;
- degraded detection;
- priority allocation scaffold;
- thermal budget scaffold;
- manifold weighting scaffold.
```

---

# Important current runtime state

Current behavior remains intentionally unchanged.

Current state:

```text
VI_Enable := FALSE
VI_Enable_Policy_Allocation := FALSE
```

Therefore:

```text
Allocation_Filter currently works in transparent passthrough mode.
```

Meaning:

```text
input demand == output demand
```

This preserves:

```text
- current heating behavior;
- current ownership model;
- compile-clean baseline;
- existing safety architecture.
```

---

# Explicitly rejected architecture

The following architecture is now considered invalid for reconnect:

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

# Current cleanup status

Already removed:

```text
FB_FloorHeating_Freeze_Protection
FB_FloorHeating_Overheat_Protection
```

Reason:

```text
logic fully absorbed by active runtime owners.
```

---

# Remaining migration candidates

Still under controlled migration review:

```text
FB_Heating_Execution_Core
FB_Heating_Orchestration
FB_Heating_Override_Layer
```

Current interpretation:

```text
Execution_Core
    → obsolete wrapper candidate

Orchestration
    → obsolete orchestration shell candidate

Override_Layer
    → dangerous hard-authority layer
```

---

# Next activation phase

Before enabling allocation policy:

```text
1. define real manifold priorities;
2. define thermal budget source;
3. define configuration ownership;
4. validate runtime behavior impact;
5. validate starvation risks;
6. validate degraded-mode interactions.
```

Only after that:

```text
VI_Enable := TRUE
```

and later:

```text
VI_Enable_Policy_Allocation := TRUE
```

---

# Final architectural direction

The project direction is now officially:

```text
extract useful policy logic
from legacy detached architecture
and integrate it into the active runtime
without creating a second orchestration layer.
```
