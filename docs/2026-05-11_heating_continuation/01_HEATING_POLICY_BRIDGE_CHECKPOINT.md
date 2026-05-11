# 01 — Heating Policy Bridge Checkpoint

Дата: 2026-05-11

## Режим

Direct Repository Modification Mode.
Verification: repository file-state verification only.
Runtime/build/PLC verification is not claimed.

## Pre-change repository reading

Read from current `main` before this checkpoint:

- `docs/2026-04-27_repository_rebaseline/05_HEATING_POLICY_INTEGRATION_PLAN.md`
- `docs/2026-04-27_repository_rebaseline/06_HP1_PRIORITY_BIAS_CHANGESET_PLAN.md`
- `HEATING_ALLOCATION_MIGRATION_PHASE.md`
- `PRG_Heating.st`
- `FB_Heating_System_Manager.st`
- `FB_Heating_Policy_Priority_Bridge.st`
- `FB_Heating_Runtime_Observability.st`
- `GVL_HEATING_POLICY.gvl`
- `GVL_STATE.gvl`

## Main finding

The older HP-1 plan is not the newest effective heating checkpoint.

The active continuation point is `HEATING_ALLOCATION_MIGRATION_PHASE.md`, which records:

- bounded policy layer enabled by configured budget;
- bounded target bridge connected;
- bounded priority bridge connected;
- priority bridge observability connected;
- priority semantics documented;
- unset priority policy handled as neutral.

## Current active runtime chain

Current active chain in `FB_Heating_System_Manager.st`:

```text
Circuit_Control
→ Demand_Map
→ Policy_Priority_Bridge
→ Allocation_Filter
→ Runtime_Observability
→ Manifold_Control
→ diagnostics/confidence
→ Valve_Test_Manager
→ Boiler_Control
```

## Analytical verification result

Checked analytically from repository files:

- `FB_Heating_Policy_Priority_Bridge.st` exists and is connected from `FB_Heating_System_Manager.st`.
- Bridge output is passed into `FB_Heating_Allocation_Filter` as effective manifold priority.
- `FB_Heating_Runtime_Observability.st` receives priority bridge state.
- Required allocation/policy observability fields exist in `GVL_STATE.gvl`.
- `PRG_Heating.st` still calls `FB_Heating_System_Manager` as the heating execution owner.
- No runtime source file was modified by this checkpoint.

## Important scope decision

Do not blindly re-apply the older HP-1 plan to `PRG_Heating.st`.
The repository already contains the newer active bridge stack.

The correct next step is verification of the current bridge stack, not a duplicate HP-1 implementation.

## Runtime files left unchanged

- `MAIN.st`
- `PRG_IO_Read.st`
- `PRG_Safety.st`
- `PRG_Heating.st`
- `FB_Heating_System_Manager.st`
- `FB_Heating_Policy_Priority_Bridge.st`
- `FB_Heating_Runtime_Observability.st`
- `GVL_HEATING_POLICY.gvl`
- `GVL_STATE.gvl`

## Required next validation

Minimum next checks:

1. `FB_Heating_Policy_Priority_Bridge` compile/interface check.
2. `FB_Heating_System_Manager` interface check.
3. `FB_Heating_Runtime_Observability` interface check.
4. `GVL_STATE` field visibility check.
5. Default policy state remains neutral.
6. Configured budget path does not unexpectedly suppress normal demand.
7. Freeze/DHW/service-gate behavior remains owned by existing runtime blocks.

## Recommendation

Next work item:

```text
Create focused heating bridge verification package/report before further runtime changes.
```
