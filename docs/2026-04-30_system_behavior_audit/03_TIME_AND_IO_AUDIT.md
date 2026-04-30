# Time and IO Read Audit

Date: 2026-04-30

## Scope

Top-down audit section covering:

1. `PRG_Time_Service`
2. `PRG_IO_Read`

This document records behavioral and architectural observations only. The project is known to compile successfully.

## Source files inspected

- `MAIN.st`
- `PRG_Time_Service.st`
- `PRG_IO_Read.st`
- `PRG_Heating_Policy_Manager.st` for cross-check of time-service reuse

## Execution position

Current top-level order:

```text
01 PRG_Time_Service
02 PRG_IO_Read
03 PRG_Safety
```

This order is structurally correct: time is produced first, then raw IO is read and normalized, then safety consumes normalized state.

## PRG_Time_Service — observed behavior

`PRG_Time_Service` runs:

```text
FB_System_Timebase
FB_Time_Service
```

Then it bridges canonical time into legacy status fields:

```text
GVL_STATUS.G_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS
GVL_STATUS.G_Current_TOD := GVL_TIME_SERVICE.G_Current_TOD
GVL_STATUS.G_Current_Day := TO_UINT(GVL_TIME_SERVICE.G_Day_Of_Week)
```

## TIME-01 — canonical time exists, but legacy bridge remains active

### Classification

ORDER_DEPENDENCY / OBSERVABILITY_GAP

### Status

CONFIRMED_STATIC

### Observation

The system has a canonical time object via `GVL_TIME_SERVICE`, but also maintains legacy compatibility fields in `GVL_STATUS`.

### Expected behavior

All runtime logic should eventually depend on one canonical source:

```text
GVL_TIME_SERVICE.G_Now_MS
```

### Potential failure behavior

If some PRGs consume `GVL_TIME_SERVICE` while others consume `GVL_STATUS.G_System_Time_MS`, future edits can accidentally reintroduce time drift or mixed-cycle assumptions.

### User-facing implication

Time-based automations may appear inconsistent if different subsystems evaluate time differently.

### Engineer-facing implication

Commissioning and debugging must treat `GVL_TIME_SERVICE` as canonical and `GVL_STATUS` time fields as compatibility mirrors unless proven otherwise.

### Recommended verification scenario

Create a scenario panel check that displays:

- `GVL_TIME_SERVICE.G_Now_MS`
- `GVL_STATUS.G_System_Time_MS`
- `GVL_TIME_SERVICE.G_Current_TOD`
- `GVL_STATUS.G_Current_TOD`

Expected result: values remain equivalent every cycle.

## TIME-02 — secondary `FB_Time_Service` call in heating policy manager

### Classification

OWNERSHIP_CONFLICT / ORDER_DEPENDENCY

### Status

CONFIRMED_STATIC

### Observation

`PRG_Heating_Policy_Manager` contains its own local `FB_Time_Service` instance and calls it inside the heating policy layer.

### Expected behavior

Time service should be produced once at the beginning of the cycle by `PRG_Time_Service`.

### Potential failure behavior

If the local time-service call updates shared time state or relies on internal state, then heating policy may observe a time base updated later than other subsystems in the same cycle.

### User-facing implication

Heating schedule/preheat behavior may appear to trigger one cycle or one timing step differently from other time-based behavior.

### Engineer-facing implication

Review whether `FB_Time_Service` is pure/idempotent or whether it mutates global time state. If it mutates global state, remove the local call and consume `GVL_TIME_SERVICE` only.

### Recommended verification scenario

Run a heating schedule/preheat scenario and record:

- value before `PRG_Heating_Policy_Manager`;
- value after `PRG_Heating_Policy_Manager`;
- schedule decision timestamp.

Expected result: no secondary mutation of canonical time.

## PRG_IO_Read — observed behavior

`PRG_IO_Read` performs multiple responsibilities:

```text
raw digital read
raw analog read
watchdog monitoring
input debounce
sensor calibration
analog processing/filtering
diagnostics projection
diagnostics event generation
state publication into GVL_STATE / GVL_STATUS
```

Main FB groups used:

```text
FB_System_Timer[]
FB_IO_Module_Watchdog
FB_Diagnostics_Event_Manager
FB_Sensor_Calibration_Processor[]
FB_Sensor_Analog_Processing[]
```

## IO-01 — IO read layer mixes acquisition, normalization, and diagnostics

### Classification

OWNERSHIP_CONFLICT / ENGINEER_INSTRUCTION_GAP

### Status

CONFIRMED_STATIC

### Observation

`PRG_IO_Read` is not only an IO adapter. It also performs diagnostics and emits diagnostic events.

### Expected behavior

A clean architecture would distinguish:

```text
Physical IO read
  -> logical mapping
    -> normalization/filtering
      -> diagnostics/health interpretation
```

### Potential failure behavior

A future engineer may treat `PRG_IO_Read` as a passive adapter and accidentally duplicate or bypass diagnostic logic elsewhere.

### User-facing implication

Some sensor faults may appear as system diagnostics before higher-level health/safety logic runs.

### Engineer-facing implication

Documentation must explicitly state that `PRG_IO_Read` currently owns first-stage sensor normalization and some first-stage diagnostic event generation.

### Recommended verification scenario

Create a scenario/test panel for a manifold pressure/current fault:

1. inject raw invalid pressure/current;
2. observe calibrated state;
3. observe diagnostics flags;
4. observe diagnostics event count.

Expected result: sensor normalization and diagnostics event behavior is deterministic and documented.

## IO-02 — debounce and timer semantics require explicit documentation

### Classification

USER_INSTRUCTION_GAP / ENGINEER_INSTRUCTION_GAP / TEST_GAP

### Status

CONFIRMED_STATIC

### Observation

`PRG_IO_Read` uses arrays of `FB_System_Timer` for switch, motion, security, flood, smoke, and group inputs.

### Expected behavior

Every safety-relevant input must have documented semantics:

- raw signal;
- debounced logical signal;
- latched state if applicable;
- reset condition;
- minimum pulse visibility.

### Potential failure behavior

A short pulse may be filtered, delayed, or interpreted differently depending on where the downstream logic reads from.

### User-facing implication

A user may report that an alarm or action did not trigger from a short physical event if debounce behavior is not explained.

### Engineer-facing implication

Commissioning instructions must specify minimum sensor activation duration for validation.

### Recommended verification scenario

For each safety-relevant input class:

- flood;
- smoke;
- methane/CO;
- door/window;
- motion;

run short-pulse and sustained-pulse tests and record first visible state in `GVL_STATE` and downstream alarm behavior.

## IO-03 — IO module watchdog can directly mitigate state

### Classification

SAFETY_BYPASS / OWNERSHIP_CONFLICT

### Status

CONFIRMED_STATIC

### Observation

When IO module error is active, `PRG_IO_Read` forces manifold pump state false:

```text
GVL_STATE.G_Manifold_Pumps[i] := FALSE
```

### Expected behavior

Fail-safe mitigation is valid, but ownership must be explicit:

- either IO layer is allowed to apply immediate fail-safe clamps;
- or all clamps should flow through safety/coordinator/domain contracts.

### Potential failure behavior

Multiple layers may write or clamp the same output-intent state, making it unclear which layer owns final pump stop behavior.

### User-facing implication

Heating may stop due to IO module health before a clear higher-level heating fault is visible.

### Engineer-facing implication

This must be documented as immediate IO-level fail-safe behavior, or moved/duplicated into a named safety/coordinator clamp with explicit ownership.

### Recommended verification scenario

Simulate IO module watchdog failure and verify:

1. module online flags;
2. diagnostics event;
3. manifold pump state;
4. final physical pump output after `PRG_IO_Write`;
5. user-visible alarm/status.

## Initial conclusion

The top of the system is structurally reasonable:

```text
Time -> IO Read -> Safety
```

But there are three important documentation and architecture risks:

1. time service must remain single-source;
2. `PRG_IO_Read` must be documented as normalization + first-stage diagnostics, not just input read;
3. immediate IO-level fail-safe clamps must have explicit ownership.

## Follow-up documents

- `04_SAFETY_BEHAVIOR_AUDIT.md`
- future bottom-up actuator ownership audit
