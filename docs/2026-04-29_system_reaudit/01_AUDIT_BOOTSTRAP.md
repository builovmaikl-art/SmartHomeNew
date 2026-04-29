# 2026-04-29 — Full System Re-Audit Bootstrap

Mode: Analytical Verification Mode + Direct Repository Documentation Save

This document starts a new full-system audit from two directions:

1. Top-down: MAIN / orchestration / safety hierarchy / policy / domain control.
2. Bottom-up: IO / sensors / actuators / FB ownership / GVL ownership / diagnostics.

Runtime behavior is not confirmed here. Findings are based on repository inspection only.

---

## Governing rules used for this audit

Primary hierarchy from `AGENTS.md`:

```text
Safety
  > Coordinator
    > Budget / eligibility
      > Priority / policy bias / guest preheat
        > Domain control
```

Core architecture from `docs/MASTER_GUIDE.md` and `docs/ARCHITECTURE_NOTES.md`:

```text
Fault -> Health -> State -> Policy -> Actuation
```

Additional rule:

```text
GVL_STATE is transport only, not source of truth.
```

IO concept:

```text
Logical -> Mapping -> Physical IO
```

---

## Initial top-down map

`MAIN.st` execution order currently observed:

```text
PRG_IO_Read
PRG_Safety
PRG_System
PRG_Presence_Manager
PRG_Heating_Policy_Observer
PRG_Mode_Manager
PRG_System_Coordinator
PRG_Policy
PRG_Command_Arbitration
PRG_Command_Verifier
PRG_Security
PRG_Heating
PRG_Ventilation
PRG_Lighting
PRG_IO_Write
```

Initial concern: `PRG_Heating_Policy_Manager` is not called from `MAIN.st` in the observed top-level sequence. It may be called elsewhere or may currently be detached from runtime execution. This must be verified before assuming heating predictive/thermal/optimization layers are active at runtime.

---

## Initial findings register

| ID | Direction | Area | Finding | Severity | Evidence | Status |
|---|---|---|---|---|---|---|
| AUD-001 | Top-down | Runtime orchestration | `PRG_Heating_Policy_Manager` is absent from `MAIN.st` execution order. New thermal/predictive/optimization layers may not run unless invoked elsewhere. | High | `MAIN.st` inspected; `PRG_Heating_Policy_Manager.st` exists separately. | Open |
| AUD-002 | Top-down | Time architecture | `PRG_Mode_Manager` still uses `GVL_STATUS.G_System_Time_MS` directly instead of `GVL_TIME_SERVICE.G_Now_MS`. | Medium | `PRG_Mode_Manager.st` inspected. | Open |
| AUD-003 | Bottom-up | IO/time layer | `PRG_IO_Read` still uses `GVL_STATUS.G_System_Time_MS` directly in IO watchdogs, debounce timers, analog filters, and diagnostic timestamps. | Medium | `PRG_IO_Read.st` inspected. | Open |
| AUD-004 | Bottom-up | Output ownership | `PRG_IO_Write` mixes direct `GVL_ALARM` output driving for sirens with `GVL_COMMAND_SHADOW` for valves/locks/gate. Ownership and safety hierarchy should be verified. | Medium | `PRG_IO_Write.st` inspected. | Open |
| AUD-005 | Top-down | Coordinator hierarchy | `PRG_System_Coordinator` applies heating block as `fbCoord.VO_Block_Heating OR GVL_HEATING_POLICY.G_Policy_Block_Heating_Request`. This appears consistent with constraint layering, but ownership of policy block source must be verified. | Low | `PRG_System_Coordinator.st` inspected. | Watch |

---

## Audit rules for next passes

Every finding must include:

```text
ID
Direction: Top-down / Bottom-up / Cross-cutting
Area
Observed fact
Expected rule
Mismatch
Risk
Suggested remediation
Verification mode required
```

No runtime claim is allowed unless confirmed by Full Verification Mode.

---

## Next pass plan

1. Top-down pass A: `MAIN.st`, `PRG_PLC_A.st`, `PRG_PLC_B.st`, orchestration order, detached programs.
2. Top-down pass B: Safety / Health / State / Policy / Coordinator boundary.
3. Bottom-up pass A: IO read/write, direct actuator ownership, command shadow ownership.
4. Bottom-up pass B: GVL ownership and direct writes to `GVL_STATE`, `GVL_IO`, `GVL_COMMAND`, `GVL_COMMAND_SHADOW`.
5. Cross-cutting pass: time source, diagnostics source of truth, scenario test coverage, compile guard coverage.
