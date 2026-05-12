# HEATING_ALLOCATION_MIGRATION_PHASE

# Purpose

This document records the finalized result of the heating allocation migration.

The migration phase itself is considered complete.

The repository is now in:

```text
DETERMINISTIC PHASE-ORIENTED RUNTIME MAINTENANCE
```

---

# Final architectural result

Allocation semantics were integrated into the active runtime ownership chain.

Canonical runtime flow:

```text
Circuit_Control
→ Demand_Map
→ Policy_Priority_Bridge
→ Allocation_Filter
→ Runtime_Observability
→ Manifold_Control
→ Boiler_Control
```

Important invariant:

```text
allocation logic remains bounded
and does not own physical outputs.
```

Runtime ownership remains:

```text
PRG_Heating
→ FB_Heating_System_Manager
→ active subsystem owners
```

---

# Verified integrated components

## Allocation filter

```text
FB_Heating_Allocation_Filter
```

Role:

```text
bounded runtime authorization gate
between Demand_Map and Manifold_Control.
```

Responsibilities:

```text
- manifold availability filtering;
- service-state filtering;
- degradation filtering;
- bounded policy allocation;
- freeze/DHW bypass preservation;
- allocation diagnostics.
```

Explicitly NOT:

```text
- orchestration owner;
- boiler owner;
- valve owner;
- output authority.
```

---

## Policy priority bridge

```text
FB_Heating_Policy_Priority_Bridge
```

Role:

```text
bounded advisory priority influence.
```

Important:

```text
policy influence can only reduce or reprioritize
already existing demand.
```

Policy layer cannot:

```text
- create demand;
- write outputs;
- bypass safety/runtime ownership.
```

---

## Runtime observability

```text
FB_Heating_Runtime_Observability
```

Role:

```text
projection/explainability layer only.
```

Publishes:

```text
- allocation diagnostics;
- policy activity;
- freeze/DHW bypass visibility;
- effective allocation priority.
```

Important:

```text
observability remains read-only.
```

---

# Verified removals

Removed obsolete donors:

```text
FB_Heating_Decision_Context
FB_Heating_Thermal_Allocation
FB_Heating_Execution_Core
FB_Heating_Orchestration
FB_Heating_Override_Layer
FB_FloorHeating_Freeze_Protection
FB_FloorHeating_Overheat_Protection
```

Reason:

```text
their useful bounded semantics were absorbed
into active runtime ownership layers.
```

---

# Final runtime model

The runtime is now phase-oriented.

Canonical orchestration:

```text
PRG_Heating
 ├── Observer_Phase
 ├── DHW_Manager
 ├── Heating_Manager
 ├── Service_Gating_Phase
 ├── State_Publication_Phase
 ├── Diagnostics_Phase
 └── Output_Projection_Phase
```

Allocation/policy logic exists inside this bounded runtime model.

---

# Strategic conclusion

The allocation migration initiative is considered complete.

Future work should focus on:

```text
- bounded policy refinement;
- diagnostics quality;
- runtime explainability;
- deterministic verification;
- safety validation.
```

NOT on restoring detached historical orchestration.
