# FB INVENTORY AUDIT — STEP-BY-STEP REGISTER

Status: Baseline audit register
Purpose: Persistent project memory for full `FB_*` review before code refactor
Related:
- `AGENTS.md`
- `docs/MASTER_GUIDE.md`
- `docs/WORKFLOW.md`
- `docs/REFACTOR_PLAN_ARCH_ALIGNMENT.md`

---

## 1. Mandatory usage rule

This document is the required Stage 0 working register for the project refactor.

Before any architecture-changing code step:
- every `FB_*` block must be reviewed against actual repository code
- each reviewed block must be recorded here
- the disposition must be explicit
- deletion candidates must be justified here before removal planning

This document is project memory, not proof of implementation.

---

## 2. Review method

For every `FB_*` block:
1. open actual code
2. identify real responsibilities
3. compare against target architecture
4. assign one primary role
5. mark violations
6. assign disposition
7. note required follow-up step

Allowed primary roles:
- Detector
- Health
- State
- Policy
- Actuator
- Service / Infrastructure
- Persistence / Diagnostics / History
- Candidate for deletion

Allowed dispositions:
- Keep
- Keep with constraints
- Split
- Rewrite
- Delete candidate
- Needs deeper audit

---

## 3. Review status legend

- `NOT_REVIEWED`
- `REVIEWED`
- `CONFIRMED_VIOLATION`
- `CONFIRMED_OK`
- `DELETE_CANDIDATE`
- `MIGRATION_TARGET_DEFINED`

---

## 4. Inventory register

| FB | Review Status | Primary Role | Current Reality | Architecture Violations | Disposition | Required Follow-up |
|---|---|---|---|---|---|---|
| FB_AccessCode_Manager | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Access_Control | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Alarm_Manager | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Analog_Validator | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Astro_Timer | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_BlackBox_Recorder | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_CO_Detector | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_CRC32_Calculator | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Calibration_Manager | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Command_Deduplication | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_DHW_Manager | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Debug_Logger | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Device_Predictive_Diag | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Emergency_Valve_Open | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Exhaust_Ventilation_Controller | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_FloorHeating_Controller | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_FloorHeating_Freeze_Protection | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_FloorHeating_Overheat_Protection | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Gas_Methane_Detector | REVIEWED | Detector | Sensor threshold block also emits direct valve-close command | Direct actuation from detector; local global alarm ownership; bypass of Health/Policy | Rewrite | Remove actuator output and route through Health |
| FB_Gas_Smoke_Manager | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Gas_Valve_Controller | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Gateway_Interface | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_HMAC_SHA1 | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Heating_System_Manager | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_History_Manager | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_IO_Module_Watchdog | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Lifetime_Predictor | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Lighting_Blinds_Manager | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Maintenance_Access | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Manifold_Pump_Controller | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Manual_Valve_Control | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_NVRAM_Manager | REVIEWED | Persistence / Diagnostics / History | Low-level NVRAM/RETAIN writer with validation and explicit no-read guard; now write-only by design | Historical interface ambiguity around READ resolved; no current policy-layer mixing after cleanup | Keep with constraints | Keep low-level only; do not reintroduce read-path or throttling policy here without separate design |
| FB_Persist_Builder | REVIEWED | Persistence / Diagnostics / History | Builds `ST_Persist` from runtime state and mirrors it into `GVL_PERSISTENT` | Still coupled to `GVL_STATE` directly, but responsibility is now narrow and explicit | Keep with constraints | Keep as persistence builder only; consider future interface decoupling after wider architecture audit |
| FB_Persist_Pipeline | REVIEWED | Persistence / Diagnostics / History | Serializes persist struct, applies single throttling policy, and triggers controlled NVRAM write | No critical current violation after `Apply_Settings` and throttling fixes | Keep | Preserve as the only persistence write-policy layer |
| FB_Outdoor_Lighting_Controller | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_PID_Controller | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_PLC_Heartbeat | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Pre_Departure_Heating | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Presence_Playback | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Presence_Simulator | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Random_Generator | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Redundancy_Manager | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Rule_Engine | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_SHA1 | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Scenario_Manager | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Scenario_Transition_Controller | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Security_Alarm | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Security_System_Manager | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Sensor_Analog_Processing | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Sensor_Calibration | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Sensor_Calibration_Processor | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Sensor_Distribution | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Simulation_Manager | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Smoke_Detector | REVIEWED | Detector | Smoke detector includes delay-based fire alarm qualification | Local alarm qualification outside Health | Split / Rewrite | Keep sensor signal role only and move qualification to Health |
| FB_Socket_Manager | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_State_Manager | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_State_Replication | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_State_Snapshot_Manager | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_State_Snapshot_NVRAM | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Supply_Ventilation_Controller | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_System_Timer | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_System_Timer_TOF | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Trend_Analyzer | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Trend_Logger | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_TwoFactor_Auth | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Valve_Test | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Valve_Test_Manager | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Ventilation_System_Manager | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Water_Leakage_Manager | REVIEWED | Mixed legacy block | Water leak block contains detection, warning/alarm timing, valve mapping, and direct valve close outputs | Detector+Health+Policy+Actuation merged in one block | Split / Rewrite | Extract detector signals, move qualification to Health, remove direct valve commands |
| FB_Water_Valve_Controller | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |
| FB_Zone_Access_Manager | NOT_REVIEWED | TBD | TBD | TBD | Needs deeper audit | Open code and classify |

---

## 5. Persistence checkpoint note

As of the current repository state:
- persistence compile checkpoint is achieved
- `FB_Persist_Builder`, `FB_Persist_Pipeline`, and `FB_NVRAM_Manager` have been brought into a consistent write-path architecture
- `GVL_PERSISTENT` remains the primary recovery source
- NVRAM remains a secondary mirror layer

---

## 5. Initial priority review queue

The next blocks to review first:

1. `FB_CO_Detector`
2. `FB_Gas_Smoke_Manager`
3. `FB_Water_Valve_Controller`
4. `FB_Gas_Valve_Controller`
5. `FB_State_Manager`
6. `FB_Rule_Engine`
7. `FB_Scenario_Manager`
8. `FB_Security_System_Manager`
9. `FB_Heating_System_Manager`
10. `FB_Ventilation_System_Manager`

---

## 6. Deletion candidate rules

A block can be moved to `Delete candidate` only if at least one applies:
- duplicated responsibility already covered elsewhere
- legacy shortcut bypassing Detector→Health→State→Policy→Actuation
- not required by current integrated architecture
- fully replaced by a cleaner split architecture

Deletion still requires:
- reference review
- integration review
- deterministic repair step

---

## 7. Completion criteria for Stage 0

Stage 0 is complete only when:
- every `FB_*` row is updated from `NOT_REVIEWED`
- each block has a primary role
- each block has a disposition
- deletion candidates are explicitly justified
- migration order is clear

---

End of register.
