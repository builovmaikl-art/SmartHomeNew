# 2026-04-29 — PRG_IO_Read Bottom-Up Audit

Mode: Analytical Verification Mode + Direct Repository Documentation Save

Runtime behavior is not confirmed here. Findings are based on repository inspection only.

---

## Scope

File inspected:

```text
PRG_IO_Read.st
```

Audit direction:

```text
Bottom-up: Physical IO -> filtering/calibration -> transport state -> diagnostics -> safety/command side effects
```

---

## Expected architecture rules

From repository guidance:

```text
Safety > Coordinator > Budget / eligibility > Priority / policy > Domain control
Fault -> Health -> State -> Policy -> Actuation
GVL_STATE is transport only, not source of truth
Logical -> Mapping -> Physical IO
```

Expected role of `PRG_IO_Read`:

```text
- read physical inputs
- debounce/filter/calibrate
- publish normalized sensor/feedback values into transport/state structures
- publish raw/derived health evidence without owning system-level decisions
```

Non-expected roles:

```text
- direct actuator/command decisions
- safety policy decisions
- direct bypass of Time Service
- becoming the source of truth for health/mode decisions
```

---

## Observed structure

`PRG_IO_Read` currently performs all of these responsibilities in one program:

```text
1. IO module watchdog processing
2. debounce of switches, motion, security, flood, smoke
3. sensor calibration for temperatures, humidity, CO2, methane, CO
4. analog processing for manifold pressure/current
5. diagnostics event publication
6. writes into GVL_STATE
7. writes into GVL_STATUS.G_Diagnostics
8. direct safety/command side effects on IO error
```

---

## Findings

| ID | Direction | Area | Finding | Severity | Status |
|---|---|---|---|---|---|
| AUD-014 | Bottom-up | Time architecture | `PRG_IO_Read` directly uses `GVL_STATUS.G_System_Time_MS` for watchdogs, debounce timers, analog filters, and diagnostic timestamps. This bypasses `GVL_TIME_SERVICE`. | Medium | Open |
| AUD-015 | Bottom-up | Safety hierarchy | On IO watchdog error, `PRG_IO_Read` directly sets `GVL_COMMAND.G_Gas_Valve_Close`, `GVL_COMMAND.G_Close_Valve_35`, `GVL_COMMAND.G_Close_Valve_36`, and forces manifold pumps false. This makes IO read layer a safety/command actor. | High | Open |
| AUD-016 | Bottom-up | Diagnostics ownership | `PRG_IO_Read` writes directly into multiple `GVL_STATUS.G_Diagnostics.*` fields and also publishes diagnostics events. This may conflict with the rule that diagnostics/health should be centralized. | Medium | Open |
| AUD-017 | Bottom-up | Transport/source-of-truth | `PRG_IO_Read` writes many calibrated values directly into `GVL_STATE`. This is acceptable only if `GVL_STATE` remains transport and no downstream logic treats it as authoritative health truth. Needs cross-check with Health/State manager. | Medium | Open |
| AUD-018 | Bottom-up | IO mapping | Door/window logic uses `GVL_CONFIG.G_Door_Map` and `GVL_CONFIG.G_Window_Map`, which is consistent with logical mapping concept. However, other sections still read fixed physical arrays directly, so mapping consistency is partial. | Low | Open |
| AUD-019 | Bottom-up | Maintainability | File contains large mixed-responsibility blocks and legacy marker `ORIGINAL SNAPSHOT (FULL)`. This increases repair risk and violates the direction toward deterministic anchored editing. | Medium | Open |

---

## Detailed notes

### AUD-014 — Direct time source usage

Observed pattern examples:

```text
VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
VI_Timestamp := GVL_STATUS.G_System_Time_MS
```

Affected logic categories:

```text
- IO watchdogs
- debounce timers
- analog filters
- diagnostic timestamps
```

Expected:

```text
GVL_TIME_SERVICE.G_Now_MS
```

Risk:

```text
simulation/time-service consistency is broken at the physical input layer.
```

Suggested remediation:

```text
Replace time inputs/timestamps with `GVL_TIME_SERVICE.G_Now_MS` after confirming `FB_Time_Service` is executed before `PRG_IO_Read`, or move time service execution earlier in the top-level order.
```

Important dependency:

```text
Current MAIN order calls PRG_IO_Read before PRG_System. Since PRG_System currently calls fbTime(), PRG_IO_Read cannot safely depend on GVL_TIME_SERVICE unless time service is moved earlier or called before IO read.
```

This is a cross-cutting orchestration issue, not just a local replacement.

---

### AUD-015 — IO read layer performs command/safety side effects

Observed behavior:

```text
IF L_IO_Error_Active THEN
    GVL_COMMAND.G_Gas_Valve_Close := TRUE;
    GVL_COMMAND.G_Close_Valve_35 := TRUE;
    GVL_COMMAND.G_Close_Valve_36 := TRUE;
    GVL_STATE.G_Manifold_Pumps[...] := FALSE;
END_IF;
```

Mismatch:

```text
IO read should publish evidence/faults, not directly command valves or pumps.
```

Risk:

```text
- bypasses Safety/Coordinator/Policy hierarchy
- creates hidden actuator ownership
- may conflict with command arbitration/shadow command model
- complicates active/standby PLC failover behavior
```

Suggested remediation:

```text
Convert this into an IO fault intent/health signal, then let Safety/Coordinator/Command Arbitration produce the final command/shadow command.
```

Verification required:

```text
Full Verification Mode with scenario tests for IO module failure and fail-safe outputs.
```

---

### AUD-016 — Diagnostics ownership is mixed

Observed behavior:

```text
PRG_IO_Read writes GVL_STATUS.G_Diagnostics fields directly
PRG_IO_Read also calls FB_Diagnostics_Event_Manager
```

Expected:

```text
IO layer should publish raw fault evidence; Health/Diagnostics layer should aggregate, classify, latch, and decide severity/root cause.
```

Risk:

```text
- duplicate or inconsistent diagnostic state
- unclear source of truth
- false escalation or missed escalation
```

Suggested remediation:

```text
Define ownership split:
1. IO evidence fields
2. Health aggregation fields
3. Diagnostics event log projection
```

---

### AUD-017 — GVL_STATE transport risk

Observed behavior:

```text
GVL_STATE.G_Room_Temps[...] := calibrated value
GVL_STATE.G_Water_Sensors[...] := debounced input
GVL_STATE.G_Manifold_Pressures[...] := processed analog value
```

This can be acceptable if `GVL_STATE` is only normalized transport.

Risk appears if downstream programs treat `GVL_STATE` as health source of truth rather than input evidence.

Suggested next audit:

```text
Trace who reads these GVL_STATE fields and whether they flow through Health/State/Policy before actuation.
```

---

### AUD-018 — Mapping is partial

Positive observation:

```text
Door/window mapping uses GVL_CONFIG.G_Door_Map / GVL_CONFIG.G_Window_Map.
```

Concern:

```text
Several other IO categories still read hard-coded physical arrays directly.
```

Suggested remediation:

```text
Do not refactor immediately. First create an IO mapping ownership table: physical input -> logical signal -> consumer.
```

---

### AUD-019 — Large mixed-responsibility file

Observed:

```text
single PRG combines watchdog, debounce, calibration, analog processing, diagnostics, and safety side effects.
```

Suggested decomposition direction:

```text
PRG_IO_Read
  -> FB_IO_Heartbeat_Collector
  -> FB_Input_Debounce_Projector
  -> FB_Sensor_Calibration_Projector
  -> FB_IO_Diagnostics_Projector
```

Do not split until ownership and orchestration are clarified.

---

## New cross-cutting question opened

Because `MAIN.st` currently calls:

```text
PRG_IO_Read();
PRG_Safety();
PRG_System();
```

and `FB_Time_Service` is currently called inside `PRG_System`, any move of `PRG_IO_Read` to `GVL_TIME_SERVICE.G_Now_MS` requires one of these architecture decisions:

```text
A. Move/call time service before PRG_IO_Read in MAIN
B. Create a dedicated PRG_Time_Service before PRG_IO_Read
C. Keep low-level IO on raw time and explicitly document it as allowed exception
```

Recommendation: option B is the cleanest long-term direction.

---

## Recommended next audit step

Proceed to:

```text
PRG_System / FB_System_Health / state manager chain
```

Reason:

```text
We need to determine where IO fault evidence should flow before proposing any repair of PRG_IO_Read side effects.
```
