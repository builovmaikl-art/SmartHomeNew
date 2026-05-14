# Runtime Semantic Recovery Provenance

## Purpose

This document records architectural reserve structures that look like dead semantic material in `runtime_dead_semantic_audit.py`, but may actually represent incomplete or lost runtime work.

The goal is to recover useful integration paths before deleting DUT fields or entire DUT families.

## Current conclusion

The suspicious runtime DUT families are not random residue. They form coherent observation, explainability, diagnostics, trend/history, maintenance, safety-policy, access-governance and physical-to-logical mapping models around existing runtime and diagnostics pipelines.

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

## Physical-to-logical mapping semantic reserve

### Architectural hypothesis

Several reserve DUT families appear to describe a common architecture:

`physical installation -> configurable mapping -> logical zones -> runtime behaviour without recompilation`.

This is not a single-domain DTO idea. It is a cross-domain configuration pattern intended to decouple physical wiring and actuator/sensor placement from program recompilation.

### Evidence

- `ST_FloorHeating_Circuit_Config` contains `zone`, `manifold_id`, `sensor_id`, `valve_id`, `control_type`, `design_temp`, `min_temp`, `max_temp`, `pid_kp` and `pwm_period_s`.
- `ST_FloorHeating_Manifold_Config` groups circuits under a manifold with location, nominal flow and pump enable policy.
- `ST_Flood_Config` and `ST_Flood_Global_Config` contain `sensor_to_valve_map` mappings.
- `ST_Operator_Zone_Rights` contains `zone_masks`.
- `ST_Gas_Valve_Configuration` contains generic actuator fields such as `valve_id` and `valve_type`, despite being unsafe/misleading as a gas-specific config.

### Working hypothesis

The original design intent likely allowed installation first and configuration later:

- sensors and actuators could be physically connected without hardcoding final logical meaning;
- logical zones could be mapped to sensors, valves, manifolds and circuits through configuration;
- floor-heating circuits could be associated with room zones, floor/air sensors and valve outputs;
- water/flood recovery could map leak sensors to shutoff valves;
- operator permissions could be scoped to zone masks;
- generic valve actuator type could support normally-open and normally-closed devices in water/heating/service contexts.

### Gas-specific safety boundary

`valve_type` may be valid in a generic actuator mapping layer, but not as an unrestricted gas safety policy. Gas runtime must enforce fail-safe assumptions such as normally-closed gas valves and must not allow generic emergency opening without a strict service interlock design.

### Classification

- `PHYSICAL_TO_LOGICAL_MAPPING_RESERVE`
- `CONFIGURABLE_INSTALLATION_MAPPING_RESERVE`
- `RECOVER_LATER_WITH_DOMAIN_SAFETY_BOUNDARIES`

Do not delete these structures simply because individual fields are not currently read. Their value is architectural: they preserve the design direction toward configurable installation without recompilation.

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

It likely represents one of three related unfinished ideas:

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

3. **Zone sensor health and fallback support**
   - detect noisy, missing or implausible zone sensors;
   - compare current values against historical zone trends;
   - use last-good or fallback values when a sensor is unreliable;
   - mark the affected component for maintenance without breaking heating/scenario logic.

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
- optionally `FB_Zone_Sensor_Health_Analyzer`

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
- HMI/history visibility;
- last-good/fallback sensor confidence hints.

## Flood / water-leak semantic reserve

### Active signal conditioning

`ST_Flood_Global_Config` is not dead. It is actively used by `FB_Water_Leakage_Manager`.

Current active behaviour:

- `min_duration_ms` acts as anti-splash / debounce / short-spike suppression;
- `warning_duration_ms` creates a pre-alarm warning window before leak latch;
- `sensor_to_valve_map` maps leak sensors to water valves;
- `valve_types` preserves water-valve policy metadata.

Classification:

- `ACTIVE_SIGNAL_CONDITIONING_CONFIG`

Do not remove or downgrade this structure.

### Policy reserve

`ST_Flood_Config` appears to be an older or richer reserve policy DTO rather than active runtime configuration.

Observed fields:

- `Emergency_Two_Stage_Enabled`;
- `Valve_Test_Period_Days`;
- `Current_Threshold_MA`;
- wider `sensor_to_valve_map` policy.

Working hypothesis:

- two-stage emergency handling;
- valve exercise/test scheduling;
- valve current diagnostics;
- selective water shutoff / recovery policy;
- extended sensor-to-valve localization.

Classification:

- `FLOOD_POLICY_RESERVE`
- `PARTIALLY_REPLACED_BY_ST_Flood_Global_Config_AND_FB_Water_Leakage_Manager`

Do not delete during cleanup. Do not wire into control without a dedicated design pass for water-valve diagnostics, selective recovery and safety authority boundaries.

### Lost / incomplete water valve test and recovery workflow

The current project contains `ST_Valve_Test_Config`, which preserves a water/service valve testing contract:

- `valve_id`;
- `test_interval_days`;
- `Nominal_Current`;
- `nominal_close_time_sec`;
- `enabled`.

This confirms that the intended valve workflow was not only leak detection, but also actuator verification.

Working hypothesis from recovered design intent:

- water inlet and riser shutoff valves should be configurable;
- valve close/open operation should have bounded confirmation windows;
- close confirmation should be validated against end-switch / limit-switch feedback;
- valve current should be checked against nominal current or threshold;
- valves should support scheduled exercise/test cycles;
- after leak detection and repair, an operator should be able to request a short controlled test opening for visual confirmation that the leak is gone;
- every test opening must be time-limited and must automatically return the valve to a safe closed state if conditions are not explicitly cleared.

Current state:

- leak signal conditioning is active;
- complete valve actuator confirmation / end-switch workflow is not clearly present in active runtime;
- test-opening / post-leak visual confirmation workflow appears lost or incomplete;
- `ST_Valve_Test_Config` should be kept as the stronger semantic anchor for recovering this workflow.

Classification:

- `WATER_VALVE_TEST_AND_RECOVERY_RESERVE`
- `LOST_OR_INCOMPLETE_RUNTIME_WORKFLOW`

Do not delete `ST_Valve_Test_Config`. Future recovery should focus on water valve actuator diagnostics, close/open confirmation, test intervals, safe short test opening and operator-governed post-leak recovery.

### `ST_Gas_Valve_Configuration` safety review

`ST_Gas_Valve_Configuration` contains:

- `valve_id`;
- `valve_type`;
- `close_time_seconds`;
- `open_time_seconds`;
- `emergency_open_allowed`.

Despite the name, this structure does not represent gas sensor thresholds. It is an actuator/service valve policy DTO.

Important safety conclusion:

- a real gas valve should be normally closed by design;
- gas close action should be immediate/fail-safe, not governed by a configurable slow-close policy;
- automatic or emergency opening of a gas valve is unsafe unless protected by a strict service interlock and explicit safety design;
- `valve_type`, `open_time_seconds` and `emergency_open_allowed` are suspicious in a gas-specific DTO.

This structure may be a misnamed older generic valve configuration, overlapping with `ST_Valve_Test_Config` and/or the lost water-valve workflow.

Classification:

- `MISNAMED_GENERIC_VALVE_TEST_CONFIG`
- `SAFETY_REVIEW_REQUIRED`
- `REMOVE_LATER_CANDIDATE_AFTER_WATER_VALVE_RECOVERY_REVIEW`

Do not integrate `ST_Gas_Valve_Configuration` into gas runtime. Keep temporarily only as provenance evidence until water/service valve recovery is reviewed.

## Access governance semantic reserve

Candidate DUTs:

- `ST_Operator_Zone_Rights`
- `ST_Maintenance_Access_Config`
- parts of `ST_Security_Global_Config`
- parts of `ST_Security_Zone_State`

Working hypothesis:

This family is a planned operator/maintenance access-governance layer:

- operator identity;
- global access level;
- zone-scoped access masks;
- last-modified audit metadata;
- maintenance enable window;
- maximum maintenance duration;
- two-person rule;
- minimum required access level;
- security-zone trigger history.

Classification:

- `ACCESS_GOVERNANCE_RESERVE`

Do not delete during mechanical cleanup. Future recovery should likely be a passive/authoritative policy layer such as `FB_Access_Governance`, but it must be designed carefully because it may gate configuration, maintenance and dangerous actions.

## Floor-heating semantic reserve

Candidate DUTs:

- `ST_FloorHeating_Global_Config`
- `ST_FloorHeating_Manifold_Config`
- `ST_FloorHeating_Circuit_Config`

Working hypothesis:

This family is a lost or incomplete floor-heating control/configuration layer. It is also part of the broader physical-to-logical mapping architecture.

Observed intent:

- enable/disable floor heating;
- anti-freeze and overheat thresholds;
- weather compensation flag;
- manifold-level location, nominal flow and pump enable policy;
- circuit-level zone mapping;
- circuit-to-manifold mapping;
- circuit-to-sensor mapping;
- circuit-to-valve mapping;
- control by floor temperature or air temperature;
- design/min/max temperature limits;
- simple control gain through `pid_kp`;
- PWM valve/actuator period through `pwm_period_s`.

Current evidence:

Fields such as `pid_kp`, `pwm_period_s`, `design_temp`, `control_type`, `sensor_id` and `valve_id` are weak or absent in active runtime but recur across multiple snapshots. This suggests incomplete recovery rather than a fully migrated layer.

Classification:

- `FLOOR_HEATING_CONTROL_CONFIG_RESERVE`
- `PHYSICAL_TO_LOGICAL_MAPPING_RESERVE`
- `LOST_OR_INCOMPLETE_RUNTIME_LAYER`

Do not delete during cleanup. Do not wire into the heating control path without a dedicated design pass, because it may affect actuator authority, zoning, heating comfort and safety limits.

## Zone sensor semantic reserve

### Candidate DUT

- `ST_Zone_Sensors`

Observed fields:

- `Temp_Room`;
- `Temp_Floor`;
- `Motion_Active`;
- `Switch_Physical`;
- `Light_State`;
- `Maintenance : ST_Component_Maintenance`.

Working hypothesis:

This structure is a lost or incomplete zone-centric sensor aggregate. It combines climate, presence, manual input, lighting state and maintenance/fallback metadata into one logical-zone DTO.

This fits the broader architecture:

- physical sensors and actuators are mapped into logical zones;
- scenario scoring and effects can reason over zones;
- heating can use room/floor temperatures by zone;
- lighting can use motion/manual switch/light state by zone;
- maintenance can isolate faulty sensors without breaking zone-level logic;
- trend/history can provide last-good/fallback or confidence hints for unreliable temperature sensors.

Recovered design intent:

- if a zone sensor becomes noisy, missing or implausible, compare it with historical zone trends;
- use last-good or configured fallback values when necessary;
- mark the affected component as faulty or in maintenance;
- continue operating heating/scenarios from a degraded-but-safe zone model;
- avoid letting one faulty sensor collapse the entire room-control path.

Classification:

- `ZONE_CENTRIC_SENSOR_AGGREGATE_RESERVE`
- `ZONE_SENSOR_HEALTH_AND_FALLBACK_RESERVE`
- `PHYSICAL_TO_LOGICAL_MAPPING_RESERVE`
- `RECOVER_LATER_WITH_TREND_AND_MAINTENANCE_LINKS`

Do not delete during cleanup. Future recovery should align this model with active input GVLs, trend/history collection, heating zones, lighting zones and maintenance diagnostics.

## Ventilation semantic reserve

### Active ventilation policy

`ST_Ventilation_Global_Config` and `ST_Ventilation_Scenario_Mode` are active or near-active ventilation policy structures used by `FB_Ventilation_System_Manager`.

Observed active concepts:

- enable ventilation;
- total unit count;
- default supply/exhaust speed;
- degraded exhaust limit;
- scenario modes;
- wet-zone to exhaust fan mapping;
- PV3 index;
- fire/gas/smoke scenario fields;
- base fan speed;
- target temperature.

Classification:

- `ACTIVE_VENTILATION_POLICY_CONFIG`
- `ACTIVE_SCENARIO_VENTILATION_POLICY`

Do not remove or downgrade these structures.

### Per-unit ventilation reserve

`ST_Ventilation_Config`, `ST_Ventilation_Unit_Config` and `ST_Ventilation_Unit` appear to preserve an older or parallel per-unit ventilation model.

Observed intent:

- global CO2 and humidity thresholds;
- night mode start/end;
- unit id;
- unit type;
- unit location;
- min/max speed;
- humidity threshold per unit;
- smoke detector presence per unit;
- enabled/speed/filter dirty/error/mode state.

Working hypothesis:

The current manager controls arrays of supply/exhaust fans and heaters, while these reserve structures describe ventilation equipment as configurable units with their own location, thresholds and diagnostics. This suggests a partially lost equipment-object model rather than random residue.

Classification:

- `VENTILATION_UNIT_CONFIG_RESERVE`
- `PER_UNIT_VENTILATION_DIAGNOSTICS_RESERVE`
- `RECOVER_LATER_AS_EQUIPMENT_MODEL`

Do not delete during cleanup. Future recovery should align this model with the active `FB_Ventilation_System_Manager` and should stay explicit about safety overrides for fire, gas, smoke and degraded modes.

## Scenario semantic reserve

### Active scenario scoring engine

`PRG_Scenario_Engine` is active. It currently performs scoring and intent generation for:

- night mode;
- comfort/preheat;
- ventilation boost;
- access secure mode;
- adaptive behaviour weights;
- best ventilation boost zone;
- reason text and trace publication.

This confirms that the scenario subsystem is not abandoned.

### Lost / incomplete scenario effects and transition layer

Candidate DUTs:

- `ST_Scenario_Config`
- `ST_Scenario_Transition_Config`
- `ST_Scenario_Stats`

Observed intent:

`ST_Scenario_Config` describes cross-domain scenario effects:

- base lighting level;
- accent lighting level;
- floor-heating adjustment;
- ventilation speed;
- socket enable state;
- blinds position;
- presence simulation.

`ST_Scenario_Transition_Config` describes transition guards:

- current scenario;
- target scenario;
- minimum duration;
- transition allowed flag.

`ST_Scenario_Stats` describes scenario telemetry and adaptation feedback:

- activations;
- success count;
- failure count;
- success rate;
- average result value;
- stability counter;
- last activation.

Working hypothesis:

The active `PRG_Scenario_Engine` selects and scores scenario intents, but the reserve DUTs preserve a missing layer that should apply scenario effects across lighting, heating, ventilation, sockets and blinds, guard unsafe or too-frequent transitions, and feed scenario success/failure statistics back into adaptation.

Classification:

- `SCENARIO_EFFECTS_AND_TRANSITION_RESERVE`
- `SCENARIO_TELEMETRY_RESERVE`
- `PARTIALLY_REPLACED_BY_PRG_Scenario_Engine`
- `RECOVER_LATER_WITH_ORCHESTRATION_GUARDS`

Do not delete during cleanup. Future recovery should not directly mutate outputs from a hidden path; it should publish intents/effects through explicit command or intent layers with clear priority and safety boundaries.

## State snapshot and short-arm restore reserve

### Candidate DUTs

- `ST_State_Snapshot`
- `ST_System_State_Summary`

### `ST_State_Snapshot`

`ST_State_Snapshot` is not merely an HMI summary. It likely preserves the lost short-arm state capture / restore workflow.

Observed fields:

- `timestamp_ms`;
- `operator_id`;
- `scenario_id`;
- `lighting_levels`;
- `floor_heating_setpoints`;
- `alarm_active`;
- `crc32`.

Recovered design intent:

- when the house is put into short-term armed mode, selected runtime state should be captured;
- on return / disarm, the previous comfort state should be restored;
- lighting levels and floor-heating setpoints should return to the pre-arm state;
- scenario id and operator id provide context for the restore operation;
- `crc32` protects against restoring a corrupted or stale snapshot;
- `alarm_active` prevents unsafe or inappropriate restore after an alarm path.

Classification:

- `SHORT_ARM_STATE_SNAPSHOT_AND_RESTORE_RESERVE`
- `LOST_OR_INCOMPLETE_RUNTIME_WORKFLOW`

Do not delete during cleanup. Future recovery should integrate with security/arming logic and must avoid restoring unsafe states after alarm, leak, fire, gas or degraded conditions.

### `ST_System_State_Summary`

`ST_System_State_Summary` looks like a whole-house state summary for HMI, diagnostics, snapshots or publication surfaces.

Observed fields:

- outdoor temperature;
- indoor temperatures;
- floor temperatures;
- humidity;
- CO2;
- gas/flood/fire/security alarms;
- security armed state.

Classification:

- `WHOLE_HOUSE_STATE_SUMMARY_RESERVE`
- `HMI_DIAGNOSTICS_OR_SNAPSHOT_PUBLICATION_RESERVE`

Do not delete until current publication surfaces and HMI/debug views are reviewed. This may later become a compact global state publication DTO.

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

All major domain-contract families have now been classified at least once. Remaining audit findings should be treated as one of:

- active publication/config surfaces;
- documented reserve contracts;
- replaced presentation summaries;
- explicit cleanup candidates after domain review.

## Cleanup guardrail

Do not remove systematic runtime observability, diagnostics, history, trend, scenario, safety-policy, signal-conditioning, access-governance, physical-to-logical mapping, actuator configuration, zone aggregation or state-restore structures simply because the current code does not read their fields. For these families, lack of member access is a signal for integration review, not an automatic deletion decision.
