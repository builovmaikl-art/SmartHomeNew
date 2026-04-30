# Global Risk Register

Date: 2026-04-30

## Purpose

Consolidated list of all risks identified during full top-down audit.

This document is the bridge between analysis and future architectural fixes.

---

# 🔴 CRITICAL RISKS

## CRIT-01 — No single decision owner

### Description
Decision-making is distributed across Policy, Arbitration, Coordinator, Security and Domains.

### Impact
- unpredictable behavior under combined conditions
- difficult debugging

### Source
POL-01, SYS-02

---

## CRIT-02 — No single actuator owner

### Description
Multiple layers influence actuator state (Domain, IO_Read fail-safe, Command Shadow).

### Impact
- last-writer-wins behavior
- hidden conflicts

### Source
DOM-03

---

## CRIT-03 — No hard safety enforcement point

### Description
No guaranteed safety clamp at IO_Write level.

### Impact
- unsafe output possible if upstream fails

### Source
SAFETY-01, IO-OUT-02

---

## CRIT-04 — Shadow vs Legacy command system

### Description
Two parallel command paths exist.

### Impact
- mismatch
- inconsistent outputs

### Source
POL-03

---

## CRIT-05 — Order-dependent behavior

### Description
Execution order defines final behavior.

### Impact
- fragile system evolution
- hidden bugs

### Source
Multiple layers

---

# 🟠 MAJOR RISKS

## MAJ-01 — Distributed intent ownership

### Description
Intent generated in multiple subsystems.

### Impact
- conflicting actions

---

## MAJ-02 — Distributed safety interpretation

### Description
Domains interpret safety independently.

### Impact
- inconsistent shutdown

---

## MAJ-03 — System layer not clearly defined

### Description
System layer mixes multiple responsibilities.

### Impact
- hard to maintain

---

## MAJ-04 — Heating complexity hotspot

### Description
Heating combines policy, control, diagnostics.

### Impact
- difficult auditing

---

## MAJ-05 — Security timing issue

### Description
Security executes after arbitration.

### Impact
- delayed reaction

---

## MAJ-06 — Simulation inside runtime path

### Description
Simulation can affect runtime behavior.

### Impact
- unintended behavior in production

---

# 🟡 MINOR RISKS

## MIN-01 — Time service duplication risk

### Description
Multiple FB_Time_Service usage.

---

## MIN-02 — IO layer responsibility mixing

### Description
IO handles diagnostics + normalization.

---

## MIN-03 — Observability timing ambiguity

### Description
History/diagnostics not final-cycle.

---

## MIN-04 — Verifier is passive

### Description
Detects mismatch but does not enforce.

---

# Target PRG Role Chain

## Purpose

The system can be normalized without introducing new architectural layers.

Existing PRGs must be assigned strict roles and connected into a logical control chain.

Target chain:

```text
PRG_Time_Service
→ PRG_IO_Read
→ PRG_Safety
→ System Intent / Health / Scenario service band
→ Mode / Coordinator / Policy
→ PRG_Command_Arbitration
→ PRG_Command_Verifier
→ PRG_Security
→ Domain PRGs
→ PRG_IO_Write
```

This is a role discipline over existing code, not a rewrite.

## PRG role ownership table

| PRG / group | Target role | Allowed ownership | Forbidden ownership |
|---|---|---|---|
| `PRG_Time_Service` | canonical time producer | `GVL_TIME_SERVICE`, compatibility time mirrors | domain logic, policy decisions |
| `PRG_IO_Read` | input acquisition + normalization | raw-to-logical state, debounce, first-stage sensor diagnostics | final actuator decisions, policy decisions |
| `PRG_Safety` | safety fact and safety intent producer | safety alarms, latches, safety intent | comfort decisions, domain-specific optimization |
| `PRG_System_Intent` | system intent publication | system intent from validated system conditions | direct actuator commands |
| `PRG_System_Health` | health aggregation | system severity, root cause, first fault | direct actuator commands |
| `PRG_System_Alarm_Gateway` | alarm/gateway service ingress | gateway request intake, alarm status/service translation | final decision precedence unless routed to arbitration |
| `PRG_System_Scenario_Rules` | scenario request arbitration service | rule/operator/gateway scenario candidates | physical output decisions |
| `PRG_System_Access_Maintenance` | access and maintenance confirmation | confirmation windows, maintenance permission flags | direct runtime actuator control |
| `PRG_System_BlackBox` / `PRG_System_History` / `PRG_System_Diagnostics` / `PRG_System_Trend` | observability services | snapshots, history, diagnostics, trend records | behavior ownership, command mutation |
| `PRG_System_Evacuation` | evacuation service producer | evacuation guidance/state | direct physical output writes outside domain/IO path |
| `PRG_System_Runtime_Base` | runtime support | init, recovery, persist, redundancy support | policy or domain decisions |
| `PRG_Presence_Manager` | presence state producer | occupancy/presence facts | lighting/heating final decisions |
| `PRG_System_Simulation` | bounded simulation service | simulation/playback state under explicit gating | production output control when simulation disabled |
| `PRG_Heating_Policy_Manager` | heating policy producer | heating policy outputs, constraints, target adjustment | direct physical output writes |
| `PRG_Heating_Policy_Observer` | occupancy-based heating policy observer | zone policy class, priority bias, target adjustment | direct heating actuation |
| `PRG_Mode_Manager` | behavior mode producer | behavior mode and mode timestamp | actuator commands |
| `PRG_System_Coordinator` | global constraint/gate producer | subsystem block flags, degraded coordination | actuator commands outside command/domain chain |
| `PRG_Policy` | scenario/system policy resolver | scenario intent and policy-level requests | physical output commands |
| `PRG_Command_Arbitration` | single command decision owner | final command shadow from all intents and constraints | raw IO, diagnostics, domain control algorithms |
| `PRG_Command_Verifier` | transition verifier | mismatch detection between old/new command paths | final control correction unless explicitly upgraded |
| `PRG_Security` | security/access fact and request producer | security armed/alarm state, access requests | direct physical output writes |
| `PRG_Heating` | heating domain executor | heating actuator state from accepted commands/policies | global policy ownership, safety reinterpretation beyond contract |
| `PRG_Ventilation` | ventilation domain executor | ventilation actuator state from accepted commands/policies | global policy ownership, safety reinterpretation beyond contract |
| `PRG_Lighting` | lighting/socket/blinds domain executor | lighting/socket/blinds actuator state from accepted commands/policies | global policy ownership, safety reinterpretation beyond contract |
| `PRG_IO_Write` | physical output projector + final safety clamp | final write to `GVL_IO`, last-resort safety forcing | policy decisions, optimization |

## Target ownership rules

### Rule 1 — Safety always wins

`PRG_Safety` owns safety facts and safety intents.

Downstream blocks may consume safety, but they must not weaken it.

### Rule 2 — Coordinator produces constraints, not actuation

`PRG_System_Coordinator` should answer:

```text
what must be blocked or degraded?
```

It should not own physical outputs directly.

### Rule 3 — Policy produces desired behavior, not outputs

Policy blocks may decide desired scenarios, target adjustments, priorities, and eligibility.

They must not become actuator owners.

### Rule 4 — Command Arbitration is the single command decision owner

All safety, system, user, security, policy, and coordinator requests must be resolved into a single command view by `PRG_Command_Arbitration`.

Target output:

```text
GVL_COMMAND_SHADOW
```

During transition, `GVL_COMMAND_SHADOW` is treated as the preferred command path.

### Rule 5 — Domains execute, they do not arbitrate globally

Domain PRGs own domain algorithms and actuator state preparation only after higher-level constraints are resolved.

They must not create a parallel global policy or safety arbitration layer.

### Rule 6 — IO_Write is final projection and last-resort clamp

`PRG_IO_Write` owns physical writes.

It should contain a clearly named final safety clamp section so final outputs cannot violate active safety conditions even if upstream state is inconsistent.

### Rule 7 — Observability is read-only for behavior

History, blackbox, trend, and diagnostics services must not mutate behavior-driving state unless explicitly documented as a diagnostic fault producer.

## Minimal normalization path using existing layers

### Step A — Codify PRG roles

Use this table as the working contract for all future changes.

### Step B — Strengthen `PRG_Command_Arbitration`

Make it the only place where cross-layer command precedence is resolved.

### Step C — Add explicit final safety clamp in `PRG_IO_Write`

No new layer required.

### Step D — Migrate legacy command paths behind shadow command path

Do not delete immediately.

First make shadow authoritative, legacy observable.

### Step E — Reduce domain reinterpretation over time

Domains may still consume safety and coordinator state during transition, but target state is:

```text
higher layers decide
Domains execute
IO_Write projects safely
```

---

# 🧠 PRIORITY ACTIONS

## Phase 1 (Critical)

1. Define single decision owner
2. Define actuator ownership model
3. Add safety clamp at IO_Write

## Phase 2 (Structural)

4. Separate policy vs arbitration
5. Remove shadow/legacy duplication
6. Formalize intent layer

## Phase 3 (Stabilization)

7. Normalize system layer
8. Isolate simulation
9. Document IO semantics

---

# FINAL NOTE

System is functionally working but architecturally distributed.

Main task:

```text
move from distributed control
→ to controlled hierarchy
```

The preferred path is not to add new layers first.

The preferred path is to assign strict ownership roles to existing PRGs and enforce the logical chain through small, verified changes.
