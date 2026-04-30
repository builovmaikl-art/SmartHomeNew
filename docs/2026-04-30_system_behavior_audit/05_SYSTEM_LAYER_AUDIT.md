# System Layer Audit

Date: 2026-04-30

## Scope

Top-down audit section covering the current system-layer PRGs between safety and policy/domain execution.

Included PRGs:

```text
PRG_System_Intent
PRG_System_Health
PRG_System_Alarm_Gateway
PRG_System_Scenario_Rules
PRG_System_Access_Maintenance
PRG_System_BlackBox
PRG_System_History
PRG_System_Diagnostics
PRG_System_Evacuation
PRG_System_Trend
PRG_System_Runtime_Base
PRG_Presence_Manager
PRG_System_Simulation
```

`PRG_Test_Scenario_Runner` is intentionally excluded from production behavior assessment because it is a temporary test PRG.

## Source files inspected

- `MAIN.st`
- `PRG_System_Intent.st`
- `PRG_System_Health.st`
- `PRG_System_Alarm_Gateway.st`
- `PRG_System_Scenario_Rules.st`
- `PRG_System_Access_Maintenance.st`
- `PRG_System_BlackBox.st`
- `PRG_System_History.st`
- `PRG_System_Diagnostics.st`
- `PRG_System_Evacuation.st`
- `PRG_System_Trend.st`
- `PRG_System_Runtime_Base.st`
- `PRG_Presence_Manager.st`
- `PRG_System_Simulation.st`

## Execution position

```text
PRG_Safety
→ PRG_System_Intent
→ PRG_System_Health
→ PRG_System_Alarm_Gateway
→ PRG_System_Scenario_Rules
→ PRG_System_Access_Maintenance
→ PRG_System_BlackBox
→ PRG_System_History
→ PRG_System_Diagnostics
→ PRG_System_Evacuation
→ PRG_System_Trend
→ PRG_System_Runtime_Base
→ PRG_Presence_Manager
→ PRG_System_Simulation
→ PRG_Heating_Policy_Manager
```

## High-level observation

The current "system layer" is not a single architectural layer. It is a collection of services with different responsibilities:

```text
intent publication
health aggregation
alarm orchestration
gateway intent
scenario/rule arbitration
access/maintenance confirmation
blackbox snapshot
history logging
diagnostics aggregation
evacuation logic
trend logging
init/recovery/persistence/redundancy
presence state
simulation/playback
```

This is not automatically wrong, but it must be documented as a service band, not as one coherent decision layer.

## SYS-01 — system layer combines decision logic and observability

### Classification

OWNERSHIP_CONFLICT / OBSERVABILITY_GAP

### Status

CONFIRMED_STATIC

### Observation

The same band of execution contains behavior producers and observability producers:

- behavior/decision: intent, health, alarm gateway, scenario rules, access, evacuation, runtime base, presence, simulation;
- observability: blackbox, history, diagnostics, trend.

### Expected behavior

Observability should record behavior without becoming part of the behavior dependency chain unless explicitly intended.

### Potential failure behavior

If observability blocks execute before later decision blocks, logs may describe previous-cycle or partial-cycle state.

### User-facing implication

Displayed history/diagnostics may appear delayed or inconsistent with final actuator behavior in the same scan.

### Engineer-facing implication

Operator/engineer manuals must specify whether history/diagnostics represent previous-cycle snapshot, mid-cycle snapshot, or final-cycle snapshot.

### Recommended verification scenario

Trigger a mode or alarm transition and compare:

1. state before system layer;
2. history record;
3. diagnostics snapshot;
4. final state after domains and IO write.

## SYS-02 — intent ownership is distributed

### Classification

OWNERSHIP_CONFLICT

### Status

CONFIRMED_STATIC

### Observation

Intent-like state is produced in several places:

- `PRG_System_Intent` publishes system intent;
- `PRG_System_Alarm_Gateway` can publish gateway scenario intent;
- `PRG_System_Scenario_Rules` arbitrates scenario intent;
- `PRG_Security` later publishes access-related user intent;
- domain blocks may still interpret state and policy directly.

### Expected behavior

A clear model is needed:

```text
all requests → intent layer → policy/arbitration → command/domain
```

### Potential failure behavior

Requests from gateway, rules, operator, security, and system mode can be evaluated in different places with different precedence rules.

### User-facing implication

User action may be accepted in one UI/context but overridden or delayed by another layer without a clear explanation.

### Engineer-facing implication

Need a documented precedence table for all intent sources.

### Recommended verification scenario

Create an intent conflict matrix:

```text
operator scenario request
vs gateway scenario request
vs rule scenario request
vs safety mode
vs security armed state
```

Expected result: deterministic winner and user-visible reason.

## SYS-03 — health source of truth requires boundary clarification

### Classification

OWNERSHIP_CONFLICT / ENGINEER_INSTRUCTION_GAP

### Status

CONFIRMED_STATIC

### Observation

`PRG_System_Health` calls `FB_System_Health_Orchestrator`, but diagnostic flags and diagnostic events are also produced in `PRG_IO_Read`, `PRG_Heating`, and other subsystem areas.

### Expected behavior

A clear distinction is required:

```text
local diagnostics → health bridge / health aggregation → system mode/policy
```

### Potential failure behavior

A local diagnostic flag may be visible before or without corresponding health/root-cause aggregation.

### User-facing implication

User may see a subsystem diagnostic and system health mode that do not appear to match.

### Engineer-facing implication

Troubleshooting instructions must define which diagnostic source is authoritative for each question:

- raw sensor fault;
- subsystem fault;
- root cause;
- system mode.

### Recommended verification scenario

Inject one sensor fault and one actuator feedback fault, then trace:

1. local diagnostic flag;
2. diagnostics event;
3. health bridge/root-cause;
4. system mode;
5. user-visible message.

## SYS-04 — alarm gateway is both observer and intent producer

### Classification

OWNERSHIP_CONFLICT / ORDER_DEPENDENCY

### Status

CONFIRMED_STATIC

### Observation

`PRG_System_Alarm_Gateway` runs alarm orchestration and gateway intent execution.

It observes system health and can publish scenario-related user intent through gateway handling.

### Expected behavior

Alarm gateway responsibility must be split conceptually:

```text
alarm observer / notifier
vs
gateway command/intent ingress
```

### Potential failure behavior

Gateway request behavior may be influenced by alarm state in a way that is hard to explain unless precedence and blocking rules are explicit.

### User-facing implication

Remote/gateway command may be ignored, delayed, or changed without a clear user instruction.

### Engineer-facing implication

Gateway commissioning must test both normal mode and alarm/degraded modes.

### Recommended verification scenario

Send gateway scenario request under:

- normal mode;
- operator action blocked;
- dangerous action pending;
- alarm active;
- degraded mode.

Expected result: deterministic accept/reject behavior and diagnostics.

## SYS-05 — scenario/rule arbitration is a major behavior owner

### Classification

OWNERSHIP_CONFLICT / USER_INSTRUCTION_GAP

### Status

CONFIRMED_STATIC

### Observation

`PRG_System_Scenario_Rules` uses `FB_Rule_Engine` and `FB_System_Scenario_Arbitration`. It evaluates operator, gateway, and rule sources.

### Expected behavior

Scenario selection must be documented as a formal arbitration model.

### Potential failure behavior

Rules can appear to override operator/gateway behavior or vice versa if precedence is not explicit.

### User-facing implication

User may not understand why an expected scenario did or did not activate.

### Engineer-facing implication

Scenario troubleshooting requires tracing all three sources:

```text
operator
gateway
rule engine
```

### Recommended verification scenario

Create scenario arbitration table and validate each priority combination.

## SYS-06 — access/maintenance confirmation modifies configuration inside runtime band

### Classification

ORDER_DEPENDENCY / ENGINEER_INSTRUCTION_GAP

### Status

CONFIRMED_STATIC

### Observation

`PRG_System_Access_Maintenance` handles dangerous-action confirmation and can apply maintenance intent into configuration flags.

### Expected behavior

Maintenance writes must have clear operator confirmation, timeout, and post-write behavior documentation.

### Potential failure behavior

Configuration changes may happen mid-cycle and be consumed by later PRGs in the same scan.

### User-facing implication

An operator confirmation may have immediate effect before the operator sees a final confirmation state.

### Engineer-facing implication

Commissioning instructions must specify which maintenance changes are immediate and which require cycle/restart/revalidation.

### Recommended verification scenario

Confirm a maintenance change and observe:

1. log event;
2. configuration flag;
3. downstream domain effect in same cycle and next cycle;
4. user-visible confirmation message.

## SYS-07 — runtime base executes after several behavior/observability services

### Classification

ORDER_DEPENDENCY

### Status

CONFIRMED_STATIC

### Observation

`PRG_System_Runtime_Base` includes init, recovery, persist, and redundancy orchestration, but executes after blackbox/history/diagnostics/evacuation/trend and before presence/simulation/policy.

### Expected behavior

Init/recovery/redundancy semantics should be clearly defined relative to behavior execution.

### Potential failure behavior

A recovery or redundancy state update may occur after some services already observed older state.

### User-facing implication

After recovery/redundancy transition, some displayed state may lag one cycle or show pre-recovery values.

### Engineer-facing implication

Recovery documentation must describe cycle timing.

### Recommended verification scenario

Trigger recovery/redundancy change and trace state through:

- history;
- diagnostics;
- runtime base;
- policy;
- domains;
- IO write.

## SYS-08 — simulation is present in runtime path and needs a strict boundary

### Classification

SAFETY_BYPASS / TEST_GAP / USER_INSTRUCTION_GAP

### Status

CONFIRMED_STATIC

### Observation

`PRG_System_Simulation` runs in the main pipeline and calls simulation/playback FBs.

### Expected behavior

Simulation must be explicitly bounded:

- allowed only under simulation mode;
- must not override real safety;
- must not write physical output-driving state unless intentionally gated.

### Potential failure behavior

Simulation/playback state can influence real domain decisions if gating is incomplete.

### User-facing implication

User must know whether simulation mode is active and whether it can affect lighting/presence/scenario behavior.

### Engineer-facing implication

Commissioning must include a simulation-off validation that proves no simulation state affects production behavior.

### Recommended verification scenario

Run with simulation disabled and enabled:

1. compare presence/simulation-related state;
2. verify physical outputs do not change unexpectedly;
3. verify user-visible simulation status.

## Initial conclusion

The system layer is best described as a service band, not a single decision layer.

Main risks:

1. distributed intent ownership;
2. health/diagnostics boundary ambiguity;
3. observability timing ambiguity;
4. runtime base timing ambiguity;
5. simulation boundary risk.

## Next audit step

Proceed to:

- `06_POLICY_COMMAND_AUDIT.md`

Covering:

```text
PRG_Heating_Policy_Manager
PRG_Heating_Policy_Observer
PRG_Mode_Manager
PRG_System_Coordinator
PRG_Policy
PRG_Command_Arbitration
PRG_Command_Verifier
PRG_Security
```
