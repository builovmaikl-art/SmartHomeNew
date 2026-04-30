# HEATING — Final Architecture & Next System Step

Date: 2026-04-30

---

# 1. Current architecture

`PRG_Heating` is now a thin domain pipeline assembled from FBs.

Current execution chain:

```text
FB_Heating_Local_Context
→ FB_Heating_Thermal_Allocation
→ FB_Heating_Orchestration
   → FB_Heating_Execution_Core
   → FB_Heating_Override_Layer
→ FB_Heating_Diagnostics
→ FB_Heating_Maintenance_Gating
→ FB_Heating_Freeze_Hardware
→ FB_Heating_Adapter_CopyOut
→ FB_Heating_RootCause_Diagnostics
```

---

# 2. Responsibility split

## Context

`FB_Heating_Local_Context`

Owns:

- boiler modulation adaptation;
- target temperature calculation;
- mode hold memory;
- local DHW demand preparation from previous-cycle DHW feedback.

Does not own:

- final safety authority;
- global command decision;
- IO write.

## Decision / allocation

`FB_Heating_Thermal_Allocation`

Owns:

- policy-influenced priority calculation;
- thermal budget decision through `FB_Heating_Decision_Context`;
- manifold enabled/allowed result.

Does not own:

- pumps;
- valves;
- physical IO;
- safety clamp.

## Execution core

`FB_Heating_Execution_Core`

Owns:

- `FB_Heating_System_Manager` call;
- `FB_DHW_Manager` call;
- raw actuator proposal from heating/DHW managers.

Does not own:

- global block;
- allocation override;
- command precedence.

## Override layer

`FB_Heating_Override_Layer`

Owns:

- applying `G_Heating_Block`;
- applying manifold enabled/disabled result;
- forcing blocked manifold outputs to safe local proposal state.

Does not own:

- manager logic;
- policy;
- diagnostics;
- final physical IO.

## Post-processing

```text
FB_Heating_Diagnostics
FB_Heating_Maintenance_Gating
FB_Heating_Freeze_Hardware
FB_Heating_Adapter_CopyOut
FB_Heating_RootCause_Diagnostics
```

---

# 3. Command architecture

Current command flow:

```text
Safety/System/User Intent
→ PRG_Command_Arbitration
→ GVL_COMMAND_SHADOW
→ PRG_Heating
→ GVL_STATE actuator proposal
→ PRG_IO_Write
→ GVL_IO physical outputs
```

Heating command fields currently used:

```text
G_Heating_Block
G_Heating_DHW_Block
G_Heating_Emergency_Stop
G_Heating_Gas_Safety_Stop
```

---

# 4. Preserved behavior

## DHW previous-cycle feedback

`FB_Heating_Local_Context` reads:

```text
GVL_STATE.G_DHW_Heating_Pump
```

before `FB_Heating_Execution_Core` updates DHW state later in the same scan.

This preserves the original previous-cycle feedback behavior.

---

# 5. Completed cleanup

Done:

- `PRG_Heating` decomposed into FB pipeline.
- DHW block moved to command layer.
- Heating safety authority moved to command layer.
- S2 split into execution core and override layer.
- Fragmentary decomposition documents `09`–`12` removed.

Remaining by design:

- `GVL_STATE` is still the actuator proposal bus.
- `PRG_IO_Write` still projects most Heating outputs from state.
- Final physical safety clamp is not yet explicit for Heating outputs.

---

# 6. Logical next step

## NEXT — IO Write command-aware final projection

Reason:

`PRG_Heating` now produces a cleaner actuator proposal, but `PRG_IO_Write` is still the final physical output owner.

Target:

```text
COMMAND > STATE > IO
```

Minimum required behavior:

1. `PRG_IO_Write` remains final physical output projector.
2. Heating command gates from `GVL_COMMAND_SHADOW` override `GVL_STATE` before physical outputs.
3. Emergency/blocked Heating state forces safe physical outputs even if upstream state is inconsistent.
4. Gas-safety behavior must not accidentally disable anti-freeze backup hardware unless full heating block/emergency is active.

Suggested first IO change:

```text
IF GVL_COMMAND_SHADOW.G_Heating_Block
   OR GVL_COMMAND_SHADOW.G_Heating_Emergency_Stop THEN

   force manifold pumps OFF
   force manifold valves CLOSED
   force zone valves OFF
   force DHW heating pump OFF
   force DHW circ pump OFF
   force backup circulation pump OFF
   force electric heater OFF
END_IF
```

Important distinction:

```text
G_Heating_Gas_Safety_Stop
```

should stop gas/boiler behavior through command/heating manager logic, but must not automatically kill backup/electric anti-freeze outputs at IO level unless full heating block/emergency is active.

---

# 7. Not now

Do not start yet:

- test matrix;
- full GVL removal;
- large IO refactor beyond command-aware safety projection;
- user-facing documentation.

---

# Final note

Heating architecture is structurally ready.

The next system-level hardening point is `PRG_IO_Write`, because it is the final physical output owner.
