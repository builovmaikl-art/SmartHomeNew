# SAFETY SHUTDOWN PIPELINE — 2026-04-30

## 1. Purpose

This document records the introduction of the unified Safety Shutdown Pipeline.

The goal is to keep emergency behavior centralized, deterministic and independent from individual domain programs.

---

## 2. Final Architecture

Current safety/control flow:

```text
Sensors / Health
→ PRG_Safety
→ GVL_INTENT_SAFETY
→ PRG_Safety_Shutdown
→ GVL_SAFETY_SHUTDOWN
→ PRG_Command_Arbitration
→ GVL_COMMAND_SHADOW
→ Domain PRGs
→ Domain Output GVLs
→ PRG_IO_Write
→ Physical IO
```

---

## 3. New Components

### 3.1 GVL_SAFETY_SHUTDOWN

Introduced global shutdown state:

```text
G_Safety_Mode
G_Safety_Active
```

`G_Safety_Mode` is based on `E_Safety_Mode`:

```text
NORMAL
FIRE
GAS
WATER_LEAK
GLOBAL_STOP
EVACUATION
```

---

### 3.2 PRG_Safety_Shutdown

This PRG converts raw safety intents into one selected global safety mode.

Current priority:

```text
FIRE > GAS > WATER_LEAK > GLOBAL_STOP > NORMAL
```

The purpose is to prevent emergency behavior from being scattered across domain programs.

---

### 3.3 PRG_Command_Arbitration

Command arbitration now consumes `GVL_SAFETY_SHUTDOWN.G_Safety_Mode` instead of spreading direct safety-condition handling throughout the command layer.

It translates a safety mode into domain commands.

Examples:

```text
FIRE:
- stop/block Heating
- stop Ventilation
- block Water / close main valves
- open evacuation locks

GAS:
- block Heating
- stop Ventilation

WATER_LEAK:
- block Water
- close water valves

GLOBAL_STOP:
- block major domains

EVACUATION:
- open evacuation access outputs
```

---

## 4. Domain Impact

### Heating

Heating remains a command-driven executor.

It does not decide emergency behavior directly.

### Ventilation

Ventilation receives stop/block commands from command arbitration.

### Water

Water is controlled through command arbitration and output projection.

### Access

Access receives command-layer open/close outputs and projects them to IO.

---

## 5. Invariants

The following rules must be preserved:

```text
1. Domain PRGs must not interpret raw safety intents directly.
2. Domain PRGs must consume commands or local execution inputs only.
3. Safety mode selection must remain centralized in PRG_Safety_Shutdown.
4. Physical IO authority remains in PRG_IO_Write.
5. Domain output GVLs remain projection contracts, not decision owners.
```

---

## 6. What Was Improved

Before:

```text
Safety behavior was distributed across PRG_Command_Arbitration and domain logic.
```

After:

```text
Safety event → one safety mode → one command scenario → deterministic domain behavior.
```

Benefits:

- clearer emergency priorities;
- easier scenario testing;
- cleaner command layer;
- reduced domain coupling;
- easier future expansion.

---

## 7. Current Limitations

### 7.1 Instant mode switching

Current implementation selects mode immediately each scan.

There is no explicit transition model yet.

Example future need:

```text
FIRE → EVACUATION → RECOVERY → NORMAL
```

---

### 7.2 Limited mode diagnostics

The system currently stores the selected mode but does not store a detailed reason/source record.

Possible future fields:

```text
G_Last_Trigger_Source
G_Last_Trigger_Time_MS
G_Mode_Reason_Text
G_Mode_Confidence
```

---

### 7.3 Recovery is not modeled

There is no dedicated recovery pipeline yet.

Recovery should eventually be explicit and controlled, not just a return to `NORMAL` when input flags drop.

---

### 7.4 Access scenarios are still simple

Access currently has evacuation-style opening, but no full access policy states.

Possible future modes:

```text
ACCESS_EVACUATION
ACCESS_LOCKDOWN
ACCESS_BLOCK_CLOSE
ACCESS_BLOCK_OPEN
```

---

## 8. Recommended Next Improvements

### High Priority

#### 8.1 Recovery Pipeline

Introduce controlled recovery from emergency modes.

Target:

```text
ACTIVE_EMERGENCY
→ STABILIZING
→ MANUAL_CONFIRM_REQUIRED
→ RECOVERY
→ NORMAL
```

Why:

Emergency outputs should not automatically return to normal just because a sensor signal clears.

---

#### 8.2 Safety Mode Reason Logging

Add structured reason tracking.

Minimum:

```text
G_Safety_Mode
G_Safety_Active
G_Safety_Reason_Code
G_Safety_Reason_Text
G_Safety_Mode_Start_MS
```

Why:

Users and engineers must know why the house entered a safety mode.

---

### Medium Priority

#### 8.3 Conflict Diagnostics

Detect impossible or suspicious command combinations.

Examples:

```text
Lock_Open AND Lock_Close
Vent_Stop AND Vent_Boost
Heating_Block AND Freeze_Protection_Required
```

---

#### 8.4 Extract IO authority layer

`PRG_IO_Write` currently contains final clamp logic directly.

Possible improvement:

```text
FB_IO_Authority
```

Responsibilities:

- command clamp;
- domain projection validation;
- final physical output safety.

---

### Low Priority

#### 8.5 Replace plain enum with richer state object

Current mode enum is enough for now.

Later the shutdown state may become a structured object:

```text
Mode
Phase
Reason
StartedAt
RequiresManualReset
AffectedDomains
```

---

## 9. Not Recommended Now

Do not immediately spread safety logic back into domains.

Do not create per-domain emergency handling unless it is a local execution detail.

Do not remove `GVL_INTENT_SAFETY`; it remains the raw safety intent layer.

---

## 10. Status

Safety Shutdown Pipeline is implemented as a first complete architecture layer.

Current status:

```text
IMPLEMENTED / NEEDS RECOVERY MODEL NEXT
```

---

## 11. Next Logical Step

The most logical next engineering step is:

```text
Recovery Pipeline + manual reset model
```

This should be implemented before adding complex new safety modes.
