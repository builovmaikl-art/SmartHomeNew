# 2026-04-29 — PRG_Safety Audit

Mode: Analytical Verification Mode + Direct Repository Documentation Save

---

## Scope

File:

PRG_Safety.st

---

## Findings

| ID | Area | Finding | Severity | Status |
|----|------|--------|----------|--------|
| AUD-026 | Architecture | PRG_Safety correctly uses intent-based output model (GVL_INTENT_SAFETY) | Positive | Noted |
| AUD-027 | Layering | PRG_Safety reads directly from GVL_STATE instead of pure Health layer | Medium | Open |
| AUD-028 | Health flow | Mixed usage of GVL_HEALTH_BRIDGE and GVL_STATE for safety decisions | Medium | Open |
| AUD-029 | Redundancy | No explicit gating by Active PLC in safety execution | High | Open |
| AUD-030 | IO conflict | PRG_IO_Read bypasses PRG_Safety decisions (conflict with AUD-015) | High | Open |

---

## Key observations

### AUD-026 (Positive)

Safety layer outputs only through:

GVL_INTENT_SAFETY

This matches architecture:

Safety → Intent → Arbitration → Actuation

---

### AUD-027

Observed:

GVL_STATE.G_Safety_Smoke_Latched
GVL_STATE.G_Safety_Gas_Latched
GVL_STATE.G_Safety_Leak_Latched

Expected:

Safety should rely on Health layer, not direct state.

Risk:

State may contain raw or intermediate values.

---

### AUD-028

Mixed sources:

- GVL_HEALTH_BRIDGE (correct abstraction)
- GVL_STATE (lower-level data)

This indicates incomplete layering.

---

### AUD-029

No pattern like:

IF GVL_STATUS.G_Is_Active_PLC THEN

Safety logic runs on all PLCs.

Risk:

Dual PLC may issue conflicting intents.

---

### AUD-030 (Critical link)

PRG_IO_Read directly sets commands:

GVL_COMMAND.*

PRG_Safety sets intents:

GVL_INTENT_SAFETY.*

Conflict:

Two different layers control actuators.

Breaks hierarchy:

IO → Safety → Coordinator → Command

---

## Conclusion

PRG_Safety is architecturally close to correct model, BUT:

- layering is incomplete
- ownership conflicts exist
- redundancy model is not enforced

---

## Next step

Audit:

PRG_Policy
PRG_Command_Arbitration
