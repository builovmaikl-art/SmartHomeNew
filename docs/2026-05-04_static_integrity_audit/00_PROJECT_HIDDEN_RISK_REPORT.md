# 2026-05-04 — Full static integrity audit after clean compilation

## Verification mode

Mode: Analytical Verification Mode + repository file-state verification.

This report is based on repository inspection only. The user reported that compilation now passes without errors. No local CODESYS build or PLC runtime execution was performed by the assistant.

## Scope

Checked areas:

- current compile-fix impact area;
- recently changed files;
- hidden compile-stable fallbacks;
- incomplete / stub-like code;
- command-shadow ownership and stale-command risks;
- IO output ownership path;
- explainability / scenario reason chain;
- stale diagnostic artifacts.

Primary inspected files:

- `FB_Heating_System_Manager.st`
- `FB_PID_Controller.st`
- `PRG_Scenario_Engine.st`
- `GVL_BEHAVIOR_ADAPT.gvl`
- `PRG_Command_Arbitration.st`
- `GVL_COMMAND_SHADOW.gvl`
- `PRG_IO_Write.st`
- `PRG_Explainability.st`
- `PRG_System_Coordinator.st`
- `ошибки компиляции.txt`

---

## Executive summary

The repository is no longer in the broken compile-fix state caused by the accidental truncation of `FB_Heating_System_Manager.st`. The file has a full interface and full execution body again.

However, clean compilation does not mean the architecture is clean. Static audit found several hidden risks that should be handled before larger refactoring:

1. `PRG_Scenario_Engine.st` still contains a compile-stabilization fallback for behavior weights.
2. `GVL_BEHAVIOR_ADAPT.gvl` still declares `G_Behavior_Weights`, but runtime scenario selection no longer consumes it.
3. `PRG_Command_Arbitration.st` does not reset/write every field declared in `GVL_COMMAND_SHADOW.gvl`.
4. `PRG_IO_Write.st` consumes command-shadow fields that are not fully owned/reset by command arbitration.
5. `PRG_System_Coordinator.st` has `VI_Ownership_Violation := FALSE`, which is compile-safe but disables the ownership-violation signal path.
6. `ошибки компиляции.txt` in the repository is stale and still contains the old 72-error log.

---

## Finding 1 — Scenario behavior weights are disconnected

Severity: HIGH

### Evidence

`PRG_Scenario_Engine.st` now initializes behavior weights locally:

```pascal
L_Weights.W_Comfort := 1.0;
L_Weights.W_Night := 1.0;
L_Weights.W_Preheat := 1.0;
L_Weights.W_VentBoost := 1.0;
L_Weights.W_AccessSecure := 1.0;
```

The file itself labels this as a compile-stable fallback:

```pascal
// Compile-stable fallback weights. Runtime zone adaptation remains sourced from GVL_BEHAVIOR_ADAPT.
```

At the same time, `GVL_BEHAVIOR_ADAPT.gvl` still declares the intended global field:

```pascal
G_Behavior_Weights : ST_Behavior_Weights := (...)
```

### Impact

The scenario engine compiles and runs, but it no longer uses the global adaptive behavior weights. This means profile-controlled or adaptive changes to scenario weights can exist in `GVL_BEHAVIOR_ADAPT`, but they do not affect scenario scoring.

### Risk

This is not a syntax problem anymore. It is now an architectural drift:

```text
adaptive profile data exists -> scenario engine ignores it
```

### Recommendation

Create a dedicated fix pass to restore `GVL_BEHAVIOR_ADAPT.G_Behavior_Weights` usage safely.

Required approach:

1. Determine why CODESYS previously did not see `G_Behavior_Weights` as a component.
2. Check object import / GVL namespace / application tree.
3. Restore the original line only after the GVL visibility problem is understood:

```pascal
L_Weights := GVL_BEHAVIOR_ADAPT.G_Behavior_Weights;
```

Do not keep the local fallback as a permanent solution.

---

## Finding 2 — Command shadow is not fully reset or fully owned

Severity: HIGH

### Evidence

`GVL_COMMAND_SHADOW.gvl` declares more fields than `PRG_Command_Arbitration.st` writes on every path. Declared fields include:

```pascal
G_Supply_100_Req
G_Supply_80_Req
G_Vent_PV3_Boost
G_Exhaust_100_Req
G_Vent_Block
G_Heating_DHW_Block
G_Heating_Emergency_Stop
G_Heating_Gas_Safety_Stop
G_Water_Emergency_Stop
G_Close_Valve_35
G_Close_Valve_36
```

`PRG_Command_Arbitration.st` writes only a subset in its final single-point write block:

```pascal
G_Gas_Valve_Close
G_Boiler_Stop
G_Vent_Stop
G_Heating_Block
G_Water_Block
G_Lock_1_Open
G_Lock_1_Close
G_Lock_2_Open
G_Lock_2_Close
G_Gate_Open
G_Wicket_Open
```

### Impact

Fields that are declared but not reset/written by arbitration can retain stale values if another path or previous cycle set them.

### Risk

The system rule says command arbitration owns `GVL_COMMAND_SHADOW`. The current implementation only partially owns it.

This can cause hidden runtime behavior such as:

- stale emergency-stop flags;
- stale water close commands;
- stale ventilation boost/stop commands;
- IO write consuming a field that arbitration did not reset this cycle.

### Recommendation

Create a full-file replacement of `PRG_Command_Arbitration.st` that:

1. resets every `GVL_COMMAND_SHADOW` field every cycle;
2. includes all declared fields in local deterministic buffer variables;
3. writes all fields in the final single-point write block;
4. also resets all fields in early-return branches for role conflict and inactive PLC.

This should be the next safety-relevant cleanup before any larger refactor.

---

## Finding 3 — IO write consumes command-shadow fields that arbitration does not fully own

Severity: HIGH

### Evidence

`PRG_IO_Write.st` uses these command-shadow fields:

```pascal
G_Heating_Emergency_Stop
G_Heating_Gas_Safety_Stop
G_Boiler_Stop
G_Gas_Valve_Close
G_Heating_Block
G_Vent_Stop
G_Vent_Block
G_Water_Block
G_Water_Emergency_Stop
G_Close_Valve_35
G_Close_Valve_36
```

Not all of these are written by `PRG_Command_Arbitration.st` on every cycle.

### Impact

`PRG_IO_Write` is acting correctly as the final IO projection layer, but it depends on command-shadow state being deterministic. If shadow fields are stale, IO output can be stale.

### Recommendation

Fix `PRG_Command_Arbitration.st` first, not `PRG_IO_Write.st`.

`PRG_IO_Write.st` should continue to consume command shadow and domain output GVLs. The ownership gap is upstream.

---

## Finding 4 — Ownership violation signal path is disabled

Severity: MEDIUM

### Evidence

`PRG_System_Coordinator.st` now calls the coordinator with:

```pascal
VI_Ownership_Violation := FALSE
```

This replaced the missing `GVL_TEST.G_Ownership_Violation` reference during compile stabilization.

### Impact

The coordinator can no longer receive a real ownership-violation signal.

### Risk

This is acceptable as a temporary compile fix, but not as a permanent diagnostic design.

### Recommendation

Create a real ownership violation source, for example:

```text
GVL_DIAGNOSTICS.G_Ownership_Violation
```

or another production-owned diagnostics GVL. Avoid restoring `GVL_TEST` as a runtime dependency.

---

## Finding 5 — Stale compile-log artifact remains in repository

Severity: MEDIUM

### Evidence

`ошибки компиляции.txt` still contains the old 72-error log from the broken `FB_Heating_System_Manager.st` state.

### Impact

Future audits may incorrectly assume the repository still has 72 errors.

### Recommendation

After the next confirmed clean compile, update `ошибки компиляции.txt` with the latest clean output or replace it with a short status note, for example:

```text
Compilation passed with 0 errors, 0 warnings.
Verified manually in CODESYS on YYYY-MM-DD HH:MM.
```

---

## Finding 6 — Recent file integrity check

Severity: INFO

### `FB_Heating_System_Manager.st`

Status: restored to full structure.

Confirmed present:

- `VAR_INPUT`
- `VAR_IN_OUT`
- `VAR_OUTPUT`
- local FB instances
- safety gate path
- safe-state path
- adaptive target call
- circuit control call
- demand map call
- manifold control call
- valve test manager call
- boiler control call
- final `END_FUNCTION_BLOCK`
- bulk sync anchor

### `FB_PID_Controller.st`

Status: full PID logic present.

Confirmed present:

- input/output interface
- cycle-time safe guard
- deadband handling
- reset path
- P/I/D terms
- manual mode
- anti-windup
- limiting output
- final `END_FUNCTION_BLOCK`
- bulk sync anchor

### `PRG_Explainability.st`

Status: compile-stable and structurally complete.

Confirmed:

- invalid `EVACUATION` branch removed;
- existing enum values handled;
- fallback `ELSE` path exists;
- full reason chain is still written.

### `PRG_System_Coordinator.st`

Status: compile-stable.

Risk remains: ownership-violation input is hardcoded `FALSE`.

### `PRG_Scenario_Engine.st`

Status: compile-stable.

Risk remains: global behavior weights are disconnected.

---

## No evidence found in current inspected files

During this audit, no evidence was found in the inspected runtime files of:

- truncated `END_PROGRAM` / `END_FUNCTION_BLOCK` after the heating restore;
- scenario writing physical IO;
- explainability writing control outputs;
- IO write bypassing domain output GVLs for normal heating/vent/access paths;
- remaining `GVL_TEST` dependency in active coordinator code.

This does not prove the entire repository is free of hidden problems; it means no such problem was found in the inspected scope.

---

## Recommended next work order

### Step 1 — Update compile log artifact

Update `ошибки компиляции.txt` to reflect the current clean compile.

### Step 2 — Fix command-shadow determinism

Full-file replacement of `PRG_Command_Arbitration.st` so every field in `GVL_COMMAND_SHADOW.gvl` is owned and reset every cycle.

### Step 3 — Restore behavior-weight architecture

Investigate and fix the GVL visibility problem that forced local fallback weights in `PRG_Scenario_Engine.st`.

### Step 4 — Replace ownership-violation stub

Move `VI_Ownership_Violation` from hardcoded `FALSE` to a real production diagnostics source.

---

## Final audit status

Compilation status: user-reported clean compile.

Repository file-state status: current inspected files are structurally present, but there are hidden architectural risks.

Overall status:

```text
Build-clean but not architecture-clean.
```

Recommended immediate next action:

```text
Fix PRG_Command_Arbitration full shadow reset/ownership.
```
