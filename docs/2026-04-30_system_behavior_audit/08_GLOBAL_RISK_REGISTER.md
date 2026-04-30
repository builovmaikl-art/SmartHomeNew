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
