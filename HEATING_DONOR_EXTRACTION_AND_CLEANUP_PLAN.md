# HEATING_DONOR_EXTRACTION_AND_CLEANUP_PLAN

# Purpose

This document records the finalized donor-cleanup and runtime decomposition direction for the heating subsystem.

The project no longer treats disconnected `FB_Heating*.st` blocks as reconnect candidates.

Canonical engineering direction:

```text
extract bounded useful semantics
→ integrate into active runtime owners
→ verify ownership/runtime path
→ remove donor blocks
```

without introducing:

```text
- duplicate orchestration layers;
- parallel runtime authority;
- detached execution paths;
- hidden ownership conflicts.
```

---

# Final architectural result

The heating runtime is now phase-oriented.

Canonical runtime orchestration:

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

Important invariant:

```text
single active runtime authority path
```

Meaning:

```text
all donor behavior must be merged
into active runtime ownership layers
instead of reconnecting historical orchestration.
```

---

# Final donor cleanup result

The disconnected heating donor cleanup is considered complete.

Verified removed groups include:

```text
- orchestration wrappers;
- detached execution shells;
- obsolete allocation layers;
- duplicated protection layers;
- disconnected Runtime_* experimental scaffold;
- detached diagnostics donors;
- disconnected supervision scaffold;
- unused runtime analytics scaffold.
```

Important:

```text
snapshots/history were intentionally preserved.
```

---

# Verified completed donor removals

## Removed orchestration donors

```text
FB_Heating_Execution_Core
FB_Heating_Orchestration
```

Status:

```text
VERIFIED REMOVED
```

---

## Removed allocation donors

```text
FB_Heating_Decision_Context
FB_Heating_Thermal_Allocation
```

Status:

```text
VERIFIED REMOVED
```

Replacement path:

```text
FB_Heating_Allocation_Filter
FB_Heating_Policy_Priority_Bridge
```

---

## Removed duplicated protection donors

```text
FB_FloorHeating_Freeze_Protection
FB_FloorHeating_Overheat_Protection
```

Status:

```text
VERIFIED REMOVED
```

Replacement path:

```text
FB_Heating_Safety_Gate
FB_Heating_Safe_State
FB_Heating_Circuit_Control
```

---

## Removed diagnostics/supervision donors

```text
FB_Heating_Diagnostics
FB_State_Snapshot_Manager
```

Status:

```text
VERIFIED REMOVED
```

Reason:

```text
their remaining useful semantics were either integrated
or deemed architecturally unjustified.
```

---

## Retained utility

```text
F_Modbus_RTU_CRC16
```

Status:

```text
KEEP ACTIVE
```

Reason:

```text
deterministic standalone utility function.
```

---

# Runtime decomposition result

The previous monolithic procedural runtime orchestration was decomposed into explicit deterministic phases.

Integrated runtime phases:

```text
FB_Heating_Runtime_Observer_Phase
FB_Heating_Runtime_Service_Gating_Phase
FB_Heating_Runtime_State_Publication_Phase
FB_Heating_Runtime_Diagnostics_Phase
FB_Heating_Runtime_Output_Projection_Phase
```

Result:

```text
PRG_Heating now acts primarily as:
- sequencing layer;
- runtime context coordinator;
- deterministic phase scheduler.
```

---

# Strategic conclusion

The heating donor cleanup and runtime decomposition initiative is considered complete.

Future work should focus on:

```text
- bounded subsystem evolution;
- policy refinement;
- observability improvements;
- diagnostics quality;
- runtime explainability;
- safety verification.
```

NOT on restoring historical orchestration layers.
