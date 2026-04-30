# Safety Behavior Audit

Date: 2026-04-30

## Scope

Top-down audit section covering:

- `PRG_Safety`
- interaction of safety state with downstream PRGs (domain, coordinator, IO write)

This is a static behavior audit (no runtime confirmation yet).

## Source files inspected

- `PRG_Safety.st`
- `PRG_Heating.st`
- `PRG_Ventilation.st`
- `PRG_IO_Write.st`

## Execution position

```text
PRG_IO_Read
→ PRG_Safety
→ System / Policy / Command / Domain
→ PRG_IO_Write
```

## Safety model in current implementation

Safety PRG produces state flags such as:

```text
GVL_STATE.G_Safety_Emergency_Stop
GVL_STATE.G_Safety_Gas_Latched
GVL_STATE.G_Safety_Smoke_Latched
```

These are then consumed directly by downstream PRGs.

## SAFETY-01 — safety is not the single point of actuation control

### Classification

SAFETY_BYPASS / OWNERSHIP_CONFLICT

### Status

CONFIRMED_STATIC

### Observation

`PRG_Safety` produces safety flags but does not directly enforce final actuator shutdown. Instead, domain blocks interpret safety and adjust behavior.

Example (Heating):

```text
L_Heating_Emergency_Stop := GVL_STATE.G_Safety_Emergency_Stop
```

### Expected behavior

A safety-critical system typically has a clearly defined choke point where safety can guarantee actuator shutdown.

### Potential failure behavior

If a domain block:

- forgets to apply safety logic;
- incorrectly interprets safety flags;

then a safety condition may not fully propagate to outputs.

### User-facing implication

User expects immediate and guaranteed shutdown on emergency/gas/smoke conditions.

### Engineer-facing implication

Must verify that all domain blocks consistently enforce safety flags.

### Recommended verification scenario

Trigger:

- emergency stop;
- gas alarm;
- smoke alarm;

Verify for each actuator class:

- heating pumps;
- manifold valves;
- ventilation fans;
- sockets;

that final physical outputs are forced into safe state in the same or next cycle.

## SAFETY-02 — domain-level interpretation of safety is not unified

### Classification

OWNERSHIP_CONFLICT

### Status

CONFIRMED_STATIC

### Observation

Each domain interprets safety flags independently.

Examples:

- Heating disables DHW demand and modifies gas stop logic;
- Ventilation passes smoke/gas into its manager;
- Lighting and sockets rely on alarm and command layers.

### Expected behavior

A unified safety contract:

```text
safety intent → coordinator clamp → domain behavior
```

### Potential failure behavior

Different domains respond differently to the same safety condition.

### User-facing implication

In a single emergency event, different subsystems may behave inconsistently.

### Engineer-facing implication

Commissioning requires verifying each domain separately instead of relying on a unified safety model.

### Recommended verification scenario

For each safety condition, produce a matrix:

```text
Condition × Subsystem → Expected Output State
```

and validate all combinations.

## SAFETY-03 — absence of explicit global safety clamp in IO write

### Classification

SAFETY_BYPASS

### Status

CONFIRMED_STATIC

### Observation

`PRG_IO_Write` writes outputs based on `GVL_STATE` and `GVL_COMMAND_SHADOW`, but does not implement a clearly defined global safety override section.

### Expected behavior

Either:

- all safety is resolved before IO write;
- or IO write contains a final safety clamp section.

### Potential failure behavior

If upstream layers miss a safety condition, IO write will not correct it.

### User-facing implication

Physical outputs might not reflect expected emergency behavior under edge cases.

### Engineer-facing implication

Safety validation must include IO write behavior explicitly.

### Recommended verification scenario

Force inconsistent upstream state (e.g., safety flag active but domain still requests output) and verify whether IO write enforces safe state.

## SAFETY-04 — ownership watchdog is diagnostic, not enforcing

### Classification

OBSERVABILITY_GAP / TEST_GAP

### Status

CONFIRMED_STATIC

### Observation

`FB_Ownership_Watchdog` is present in `PRG_Safety`, but acts as a diagnostic mechanism rather than a control mechanism.

### Expected behavior

Either:

- ownership conflicts are prevented structurally;
- or watchdog escalates into enforcement.

### Potential failure behavior

Ownership conflict is detected but not prevented in the same cycle.

### User-facing implication

System may behave incorrectly even though diagnostics indicate a conflict.

### Engineer-facing implication

Diagnostics must be actively monitored; they do not guarantee safe operation by themselves.

### Recommended verification scenario

Introduce an artificial ownership conflict and observe:

- watchdog diagnostics;
- actual actuator behavior.

## SAFETY-05 — safety signals propagate through multiple paths

### Classification

ORDER_DEPENDENCY / OWNERSHIP_CONFLICT

### Status

CONFIRMED_STATIC

### Observation

Safety signals are consumed:

- directly by domain blocks;
- via alarm/gateway;
- via coordinator (indirectly);

creating multiple propagation paths.

### Expected behavior

A single clear propagation chain.

### Potential failure behavior

Order of PRG execution influences which path takes precedence.

### User-facing implication

Behavior may vary subtly depending on system state combinations.

### Engineer-facing implication

Difficult to trace full safety propagation without a formal model.

### Recommended verification scenario

Trace a safety condition end-to-end and log:

- when each PRG reacts;
- which state variables change;
- final output state.

## Initial conclusion

Safety logic is present and appears functionally integrated, but:

1. it is distributed across layers;
2. enforcement is delegated to domains;
3. there is no explicit single choke point;
4. propagation paths are multiple and order-dependent.

This is acceptable for a flexible system, but requires strong documentation and validation scenarios.

## Next audit step

Proceed to:

- System layer (intent / health / scenario / gateway)
- Policy / coordinator / command layer
