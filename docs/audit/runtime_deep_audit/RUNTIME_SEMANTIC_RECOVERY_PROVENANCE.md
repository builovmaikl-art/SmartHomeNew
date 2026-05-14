# Runtime Semantic Recovery Provenance

## Purpose

This document records architectural reserve structures that look like dead semantic material in `runtime_dead_semantic_audit.py`, but may actually represent incomplete or lost runtime work.

The goal is to recover useful integration paths before deleting DUT fields or entire DUT families.

## Current conclusion

The suspicious runtime DUT families are not random residue. They form coherent observation, explainability, diagnostics, trend/history and maintenance-related models around existing runtime and diagnostics pipelines.

Active code already contains working observer/diagnostics paths, and several reserve DUT families have now been recovered through passive publication surfaces instead of mechanical deletion.

## Recovered reserve families

### Heating runtime observer / explainability stack

Recovered or partially recovered through passive publication:

- `ST_Heating_Runtime_Meta_Supervision`
- `ST_Heating_Runtime_Phase_Event`
- `ST_Heating_Runtime_Anomaly`
- `ST_Heating_Runtime_Blackbox_Event`
- `ST_Heating_Runtime_Blackbox_Timeline`
- `ST_Heating_Runtime_Event_Buffer`
- `ST_Heating_Runtime_Adaptive_Intelligence`
- `ST_Heating_Runtime_Causality_Graph`
- `ST_Heating_Runtime_Causality_Node`
- `ST_Heating_Runtime_Causality_Edge`
- `ST_Heating_Runtime_Integration_Bridge`
- `ST_Heating_Runtime_Predictive_State`
- `ST_Heating_Runtime_Execution_Timeline`
- `ST_Heating_Runtime_Execution_Frame`
- `ST_Heating_Runtime_Phase_Transition`

Current surfaces/publishers:

- `GVL_Heating_Runtime_Meta.gvl`
- `GVL_Heating_Runtime_Explainability.gvl`
- `FB_Heating_Runtime_Meta_Supervision_Publisher.st`
- `FB_Heating_Runtime_Explainability_Publisher.st`
- `PRG_Heating.st`

All recovered structures must remain observation-only. They must not introduce command authority, output authority, runtime mutation authority or hidden control feedback.

### System diagnostics stack

Recovered through passive diagnostics publication:

- `ST_System_Diagnostics`

Current surfaces/publishers:

- `GVL_System_Diagnostics_Publication.gvl`
- `FB_System_Diagnostics_Publisher.st`
- `PRG_System_Diagnostics.st`

This layer is HMI/engineering diagnostics only. It must not become a command or output authority surface.

## Existing observer evidence

`FB_Heating_Runtime_Observer.st` is an active minimal read-only observer. It publishes `VO_Observation : ST_Heating_Runtime_Observation`, plus `VO_Status_Code` and `VO_Status_Text`.

It already sets status values such as:

- observer disabled;
- diagnostics publication invalid;
- observer nominal;
- runtime fault detected.

This confirms that `Status_Code` / `Status_Text` are not inherently garbage. They are an existing status-publication idiom.

`FB_Heating_Runtime_Observer_Phase.st` owns governed observer authorization and finalized-state observer publication. It writes lifecycle/status fields into `GVL_Heating_Runtime_Observation` and uses `FB_Heating_Runtime_Observer` as the finalized observer.

## Trend/history semantic reserve

### Candidate DUTs

- `E_Trend_Parameter_Type`
- `ST_Trend_Header`
- `ST_Trend_History_Record`

### Observed structure

`E_Trend_Parameter_Type` covers:

- air temperature;
- floor temperature;
- pressure;
- pump current;
- methane;
- CO.

`ST_Trend_Header` contains:

- parameter type;
- zone id;
- record count;
- average value;
- min value;
- max value.

`ST_Trend_History_Record` contains:

- timestamp;
- value.

### Working hypothesis

This family should not be treated as ordinary dead code.

It likely represents one of two related unfinished ideas:

1. **Heating trend analytics**
   - historical room/floor temperature behaviour;
   - heating response analysis;
   - adaptive heating decisions;
   - thermal inertia / comfort trend calculation;
   - predictive heating support.

2. **Equipment maintenance / lifetime analytics**
   - pump current trend;
   - pressure trend;
   - equipment degradation detection;
   - service interval calculation;
   - maintenance cycle estimation.

The enum scope is wider than heating setpoints alone and includes pump current, pressure and gas sensors. That suggests a generic time-series analytics substrate rather than a single heating FB DTO.

### Current evidence

The trend types exist in multiple snapshots from April and May, but active runtime references are weak or absent. This suggests a planned generic trend/history layer that was carried across snapshots but not fully integrated.

### Recommended classification

`RECOVER_LATER_AS_GENERIC_TREND_ENGINE`

Do not delete during mechanical cleanup.

### Recommended future recovery path

A future recovery should introduce a passive trend publication/collector layer, for example:

- `GVL_Trend_Publication`
- `FB_Trend_Collector`
- optionally `FB_Trend_Maintenance_Analyzer`
- optionally `FB_Heating_Trend_Analyzer`

The first integration should stay read-only and should only publish aggregated trend/history data. It must not directly control heating, maintenance decisions or safety actions.

Suggested initial signals:

- room temperature;
- floor temperature;
- manifold pressure;
- manifold pump current;
- methane level;
- CO level.

Suggested derived outputs:

- average/min/max by parameter and zone;
- trend record count;
- simple degradation indicator for maintenance review;
- HMI/history visibility.

## Replaced / lower-priority reserve families

### `ST_Astro_Time`

Likely replaced by working time/astro blocks or time-service logic.

Classification:

- `REMOVE_LATER / REPLACED`

Do not prioritize recovery unless a specific missing sunrise/sunset contract is found.

### `ST_Calibration_Family_Summary` / `ST_Calibration_Sensor_Summary`

Likely replaced by runtime calibration workflow. These appear to be old HMI/reporting summaries rather than core calibration logic.

Classification:

- `REPLACED_BY_RUNTIME_CALIBRATION`

Do not delete until current calibration blocks are reviewed, but do not prioritize recovery.

## Remaining domain-contract families

The following are not classified as garbage, but require domain-specific review before recovery or removal:

- `ST_Ventilation_*`
- `ST_Security_*`
- `ST_Flood_*`
- `ST_FloorHeating_*`
- `ST_Gas_Valve_Configuration`
- `ST_Operator_Zone_Rights`
- `ST_Maintenance_Access_Config`
- `ST_State_Snapshot`
- `ST_System_State_Summary`

These may represent old HMI/config surfaces, domain DTOs, or structures replaced by current GVL/FB runtime implementations.

## Cleanup guardrail

Do not remove systematic runtime observability, diagnostics, history or trend structures simply because the current code does not read their fields. For these families, lack of member access is a signal for integration review, not an automatic deletion decision.
