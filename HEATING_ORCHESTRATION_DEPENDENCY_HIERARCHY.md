# HEATING_ORCHESTRATION_DEPENDENCY_HIERARCHY.md

# PURPOSE

This document defines the OFFICIAL dependency hierarchy for the future heating orchestration platform.

The purpose is:
- prevent cyclic dependencies
- prevent ownership corruption
- preserve deterministic PLC execution
- preserve diagnostics isolation
- preserve OpenTherm transport ownership
- preserve cascade ownership
- preserve runtime sequencing integrity

This document is mandatory for ALL future orchestration work.

---

# PRIMARY ARCHITECTURAL RULE

Dependencies must flow ONLY downward.

Higher layers MAY depend on lower layers.

Lower layers MUST NEVER depend on higher layers.

Violations are considered architecture corruption.

---

# OFFICIAL HIERARCHY

## LEVEL 0 — FOUNDATION TYPES

Allowed contents:
- ENUM
- DUT
- constants
- contracts
- immutable runtime models

Examples:
- E_Heating_Runtime_Phase
- ST_Heating_Runtime_Context
- ST_Heating_Runtime_Phase_Event
- ST_Heating_Runtime_Event_Buffer
- ST_Heating_Runtime_Integration_Bridge

Allowed dependencies:
- NONE

Forbidden:
- FB dependencies
- GVL ownership
- runtime logic
- diagnostics logic
- OpenTherm logic

This layer MUST remain pure.

---

## LEVEL 1 — FOUNDATION SERVICES

Allowed contents:
- validation
- telemetry
- event storage
- synchronization observation
- health aggregation

Examples:
- FB_Heating_Runtime_Contract_Validator
- FB_Heating_Runtime_Event_Manager
- FB_Heating_Runtime_Synchronization_Monitor
- FB_Heating_Runtime_Health_Observer

Allowed dependencies:
- LEVEL 0 only

Forbidden:
- runtime ownership
- diagnostics ownership
- output ownership
- PRG dependencies
- cascade logic
- OpenTherm transport logic

This layer MUST remain read-only.

---

## LEVEL 2 — ORCHESTRATION SHELL

Allowed contents:
- lifecycle coordination
- sequencing coordination
- orchestration aggregation
- integration preparation

Examples:
- FB_Heating_Runtime_Coordinator
- FB_Heating_Runtime_Orchestration_Shell
- FB_Heating_Runtime_Integration_Bridge_Manager

Allowed dependencies:
- LEVEL 0
- LEVEL 1

Forbidden:
- direct heating ownership
- diagnostics ownership
- OpenTherm ownership
- cascade ownership
- safety ownership

This layer MUST remain orchestration-only.

---

## LEVEL 3 — LIVE RUNTIME

Allowed contents:
- heating runtime logic
- DHW logic
- cascade logic
- OpenTherm transport
- runtime arbitration
- output decisions

Examples:
- PRG_Heating
- FB_DHW_Manager
- FB_Heating_System_Manager
- FB_Heating_Boiler_Control
- FB_Boiler_Cascade_Manager
- FB_Boiler_OpenTherm_Interface

Allowed dependencies:
- LEVEL 0
- LIMITED LEVEL 2 observation only

Forbidden:
- dependency on orchestration supervision
- dependency on diagnostics explainability
- dependency on migration layers

This layer remains runtime-authoritative.

---

## LEVEL 4 — DIAGNOSTICS / EXPLAINABILITY

Allowed contents:
- diagnostics inference
- diagnostics projection
- explainability
- event projection
- HMI projection

Examples:
- FB_Diagnostics_RootCause
- FB_Heating_RootCause_Diagnostics
- FB_Heating_Diagnostics
- PRG_Explainability
- PRG_HMI_Dashboard

Allowed dependencies:
- LEVEL 0
- LEVEL 3 runtime observation

Forbidden:
- runtime ownership
- output ownership
- orchestration ownership
- OpenTherm transport ownership

This layer MUST remain downstream-only.

---

## LEVEL 5 — SUPERVISION / HISTORY / FUTURE BLACKBOX

Allowed contents:
- snapshots
- blackbox history
- runtime traces
- orchestration traces
- historical telemetry

Examples:
- FB_State_Snapshot_Manager
- future runtime trace pipeline
- future orchestration blackbox

Allowed dependencies:
- ALL lower levels

Forbidden:
- runtime ownership
- diagnostics ownership
- orchestration ownership

This layer MUST remain passive.

---

# FORBIDDEN DEPENDENCY PATTERNS

## Forbidden Pattern 1

Diagnostics -> Runtime ownership

Forbidden examples:
- diagnostics modifying outputs
- diagnostics modifying heating demand
- diagnostics modifying OT transport

Reason:
violates deterministic runtime ownership.

---

## Forbidden Pattern 2

Orchestration -> OpenTherm transport ownership

Forbidden examples:
- orchestration changing OT sequence
- orchestration changing OT ACK state
- orchestration changing transport timers

Reason:
breaks transport determinism.

---

## Forbidden Pattern 3

Orchestration -> Cascade ownership

Forbidden examples:
- orchestration selecting boilers
- orchestration changing cascade arbitration
- orchestration changing failover logic

Reason:
breaks thermal semantics.

---

## Forbidden Pattern 4

Runtime -> Explainability dependency

Forbidden examples:
- runtime waiting for diagnostics
- runtime waiting for HMI projection
- runtime using explainability state for execution

Reason:
breaks deterministic execution.

---

## Forbidden Pattern 5

Cross-layer cyclic dependencies

Forbidden examples:
- runtime -> orchestration -> runtime
- diagnostics -> runtime -> diagnostics
- supervision -> runtime -> supervision

Reason:
breaks PLC determinism.

---

# OFFICIAL OWNERSHIP RULES

## OpenTherm ownership

Owned ONLY by:
- FB_Boiler_OpenTherm_Interface

No other layer may:
- modify transport sequence
- modify ACK state
- modify heartbeat state

---

## Cascade ownership

Owned ONLY by:
- FB_Heating_Boiler_Control
- FB_Boiler_Cascade_Manager

No other layer may:
- select boilers
- modify cascade arbitration
- modify failover ownership

---

## Diagnostics ownership

Owned ONLY by:
- diagnostics stack

Diagnostics MUST remain:
- read-only
- downstream-only

---

## Safety ownership

Owned ONLY by:
- gas safety chain
- emergency stop chain
- freeze protection chain

No orchestration layer may bypass safety.

---

# CURRENT STATUS

Current orchestration platform status:
- isolated
- passive
- runtime-safe
- diagnostics-safe
- transport-safe
- ownership-safe

The orchestration platform is NOT connected to live runtime ownership yet.

This is intentional.

---

# FUTURE INTEGRATION RULE

Future orchestration integration is allowed ONLY if:
- dependency hierarchy remains valid
- ownership hierarchy remains valid
- runtime sequencing remains deterministic
- diagnostics remain downstream-only
- OpenTherm ownership remains isolated
- cascade ownership remains isolated
- safety ownership remains isolated

Otherwise:
- integration is forbidden.
