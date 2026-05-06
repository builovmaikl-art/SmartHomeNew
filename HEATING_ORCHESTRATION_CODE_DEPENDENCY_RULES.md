# HEATING_ORCHESTRATION_CODE_DEPENDENCY_RULES.md

# PURPOSE

This document defines the OFFICIAL code-level dependency rules for the heating orchestration platform.

The purpose is:
- prevent contract explosion
- prevent cyclic DUT dependencies
- prevent FB cross-coupling
- prevent hidden compile-time dependencies
- preserve deterministic PLC architecture
- preserve orchestration isolation

These rules are mandatory for ALL future orchestration work.

---

# PRIMARY CODE-LEVEL RULE

Dependencies must remain:
- single-direction
- ownership-safe
- compile-safe
- orchestration-isolated

Code-level dependency corruption is considered architecture corruption.

---

# ENUM DEPENDENCY RULES

## ENUM are ROOT objects

ENUM types:
- MUST NOT depend on DUT
- MUST NOT depend on FB
- MUST NOT depend on GVL
- MUST NOT contain runtime ownership assumptions

ENUM are pure foundation contracts.

---

## Allowed ENUM usage

ENUM may be used by:
- DUT
- FB
- PRG
- diagnostics
- orchestration
- HMI

But ENUM themselves MUST remain dependency-free.

---

## Current approved ENUM

### E_Heating_Runtime_Phase

Allowed usages:
- ST_Heating_Runtime_Context
- ST_Heating_Runtime_Phase_Event
- ST_Heating_Runtime_Integration_Bridge
- FB_Heating_Runtime_Coordinator
- orchestration observers

Forbidden future usage:
- direct runtime ownership
- OT transport ownership
- diagnostics ownership

---

# DUT DEPENDENCY RULES

## DUT may depend ONLY downward

Allowed:
- DUT -> ENUM
- DUT -> lower-level DUT

Forbidden:
- DUT -> FB
- DUT -> PRG
- DUT -> GVL ownership
- DUT -> diagnostics ownership

---

## Current approved DUT dependency graph

### ST_Heating_Runtime_Context

Allowed dependency:
- E_Heating_Runtime_Phase

Forbidden:
- bridge manager
- validator
- event manager
- diagnostics runtime

---

### ST_Heating_Runtime_Phase_Event

Allowed dependency:
- E_Heating_Runtime_Phase

Forbidden:
- runtime shell
- diagnostics engine
- OT transport

---

### ST_Heating_Runtime_Event_Buffer

Allowed dependency:
- ST_Heating_Runtime_Phase_Event

Forbidden:
- validator
- bridge manager
- synchronization monitor

---

### ST_Heating_Runtime_Integration_Bridge

Allowed dependency:
- E_Heating_Runtime_Phase

Forbidden:
- orchestration shell
- runtime manager
- diagnostics stack

---

# FB DEPENDENCY RULES

## FOUNDATION SERVICE FB

Examples:
- validator
- event manager
- synchronization monitor
- health observer

Allowed dependencies:
- ENUM
- DUT
- lower-level utility FB only

Forbidden:
- PRG_Heating
- runtime ownership
- diagnostics ownership
- OpenTherm transport
- cascade runtime

These FB MUST remain passive/read-only.

---

## ORCHESTRATION SHELL FB

Examples:
- runtime coordinator
- orchestration shell
- bridge manager

Allowed dependencies:
- foundation DUT
- foundation service FB

Forbidden:
- direct runtime outputs
- direct OT ownership
- direct cascade ownership
- direct diagnostics ownership
- direct safety ownership

These FB MUST remain orchestration-only.

---

## LIVE RUNTIME FB

Examples:
- FB_DHW_Manager
- FB_Heating_System_Manager
- FB_Heating_Boiler_Control
- FB_Boiler_Cascade_Manager
- FB_Boiler_OpenTherm_Interface

Allowed orchestration interaction:
- observation only
- synchronization only
- contract validation only

Forbidden:
- orchestration ownership
- orchestration sequencing authority
- orchestration override authority

Runtime FB remain authoritative.

---

# GVL ACCESS RULES

## Orchestration layer GVL restrictions

Orchestration foundation FB SHOULD:
- avoid direct GVL access
- avoid global ownership
- avoid global runtime manipulation

Preferred model:
- typed contracts
- typed context
- explicit interfaces

---

## Forbidden orchestration GVL patterns

Forbidden:
- orchestration modifying runtime GVL
- orchestration modifying OT state
- orchestration modifying diagnostics state
- orchestration modifying outputs directly

Reason:
creates hidden ownership corruption.

---

# CONTRACT CLUSTER RULES

## Orchestration contracts cluster

The following files now form a formal orchestration contracts cluster:

### ENUM
- E_Heating_Runtime_Phase

### DUT
- ST_Heating_Runtime_Context
- ST_Heating_Runtime_Phase_Event
- ST_Heating_Runtime_Event_Buffer
- ST_Heating_Runtime_Integration_Bridge

### Foundation service FB
- FB_Heating_Runtime_Contract_Validator
- FB_Heating_Runtime_Event_Manager
- FB_Heating_Runtime_Synchronization_Monitor
- FB_Heating_Runtime_Health_Observer

### Orchestration shell FB
- FB_Heating_Runtime_Coordinator
- FB_Heating_Runtime_Orchestration_Shell
- FB_Heating_Runtime_Integration_Bridge_Manager

---

# CONTRACT CLUSTER RULES

The orchestration contracts cluster MUST:
- remain isolated
- remain dependency-clean
- remain ownership-safe
- remain deterministic

The cluster MUST NOT:
- directly own runtime
- directly own diagnostics
- directly own OT transport
- directly own cascade
- directly own safety

---

# FORBIDDEN FUTURE PATTERNS

## Forbidden Pattern 1

FB -> reverse contract dependency

Example:
- validator depending on shell
- event manager depending on bridge manager

Reason:
creates orchestration cycles.

---

## Forbidden Pattern 2

DUT -> orchestration runtime ownership

Example:
- context storing runtime outputs
- bridge storing OT transport state

Reason:
creates ownership corruption.

---

## Forbidden Pattern 3

Diagnostics -> orchestration authority

Example:
- diagnostics controlling sequencing
- diagnostics controlling migration

Reason:
breaks deterministic execution.

---

## Forbidden Pattern 4

Orchestration -> diagnostics ownership

Example:
- orchestration publishing diagnostics
- orchestration generating explainability

Reason:
breaks diagnostics isolation.

---

## Forbidden Pattern 5

Orchestration -> output ownership

Example:
- orchestration directly driving outputs
- orchestration bypassing projection layer

Reason:
breaks runtime authority.

---

# CURRENT STATUS

Current orchestration foundation status:
- dependency-clean
- ownership-clean
- deterministic
- isolated
- runtime-safe
- diagnostics-safe
- transport-safe

No cyclic orchestration dependencies currently exist.

This state MUST be preserved.

---

# FUTURE REQUIREMENT

Before ANY orchestration integration:
- dependency graph must remain acyclic
- ownership graph must remain isolated
- diagnostics must remain downstream-only
- OpenTherm ownership must remain isolated
- cascade ownership must remain isolated
- GVL ownership violations must remain absent

Otherwise:
- orchestration integration is forbidden.
