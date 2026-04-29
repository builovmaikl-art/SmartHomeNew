# 2026-04-29 — PRG_System Core Audit

Mode: Analytical Verification Mode + Direct Repository Documentation Save

---

## Scope

File:

PRG_System.st

---

## Findings

| ID | Area | Finding | Severity | Status |
|----|------|--------|----------|--------|
| AUD-020 | Architecture | PRG_System mixes orchestration, business logic, diagnostics, persistence and command logic | High | Open |
| AUD-021 | Time/Order | Time Service executed inside PRG_System but PRG_IO_Read runs before it → global time inconsistency | High | Open |
| AUD-022 | Safety hierarchy | Dangerous actions, maintenance, and access control handled inside PRG_System instead of dedicated layer | High | Open |
| AUD-023 | State ownership | PRG_System writes to GVL_STATE and also uses it as decision input | Medium | Open |
| AUD-024 | Redundancy | Active/Standby logic exists but no strict execution gating of logic blocks | High | Open |
| AUD-025 | Hidden logic | Rule Engine, Simulation, Scenario arbitration embedded → unclear boundaries | Medium | Open |

---

## Key observations

### AUD-020

PRG_System includes:

- Time
- Health
- Scenario
- Rules
- Simulation
- Logging
- Persistence
- Access control

This violates separation of concerns.

---

### AUD-021

PRG_System calls:

fbTimebase();
fbTime();

But MAIN calls PRG_IO_Read BEFORE PRG_System.

Result:

IO layer cannot rely on Time Service.

---

### AUD-022

PRG_System directly implements:

- dangerous action confirmation
- access control
- maintenance overrides

This bypasses Policy/Safety abstraction.

---

### AUD-024

Redundancy FB exists:

fbSystemRedundancy

But execution of logic is NOT gated by:

GVL_STATUS.G_Is_Active_PLC

Meaning standby PLC may execute logic.

---

## Conclusion

PRG_System is overloaded and is currently:

"system brain + executor + logger + policy fragment"

This is the main architectural bottleneck.

---

## Next step

Audit:

PRG_Safety
PRG_Policy
Command Arbitration
