# Domain and IO Write Audit

Date: 2026-04-30

## Scope

Final stage of control chain:

```text
PRG_Heating
PRG_Ventilation
PRG_Lighting
PRG_IO_Write
```

This is where decisions become physical outputs.

---

## Execution position

```text
Policy / Command / Security
→ Domain (Heating / Ventilation / Lighting)
→ PRG_IO_Write
→ Physical IO
```

---

# DOMAIN LAYER ANALYSIS

## DOM-01 — Domain blocks are not pure execution layers

### Classification

OWNERSHIP_CONFLICT

### Status

CONFIRMED_STATIC

### Observation

Domain blocks perform:

- decision making
- safety interpretation
- diagnostics
- actuator control

Example (Heating):

```text
safety flags
policy outputs
coordinator flags
local logic
→ actuator demand
```

### Expected behavior

Domain should ideally:

```text
receive decision → apply → control actuators
```

### Problem

Domain = mixed responsibility layer

### Risk

- hidden decision logic
- duplication of policy
- inconsistent behavior across domains

---

## DOM-02 — Direct safety usage inside domains

### Classification

SAFETY_BYPASS / OWNERSHIP_CONFLICT

### Status

CONFIRMED_STATIC

### Observation

Domains read safety directly:

```text
GVL_STATE.G_Safety_*
```

### Problem

Safety is interpreted independently per domain.

### Risk

- inconsistent shutdown behavior
- safety logic duplication

---

## DOM-03 — No unified actuator ownership

### Classification

OWNERSHIP_CONFLICT (CRITICAL)

### Status

CONFIRMED_STATIC

### Observation

Actuator-related state can be written/affected by:

- Domain logic
- IO_Read fail-safe logic
- Command shadow
- Possibly coordinator/policy indirectly

### Problem

No single owner of actuator state.

### Risk

- last-writer-wins behavior
- race-like conditions in single scan

---

## DOM-04 — Heating is the most complex and risky domain

### Classification

OWNERSHIP_CONFLICT / COMPLEXITY_RISK

### Status

CONFIRMED_STATIC

### Observation

Heating includes:

- demand calculation
- safety reaction
- diagnostics
- timing
- actuator mapping

### Problem

Heating is effectively:

```text
mini-system inside system
```

### Risk

- hard to audit
- hard to guarantee safety completeness

---

## DOM-05 — Ventilation partially respects safety but not centralized

### Classification

INCONSISTENT_BEHAVIOR

### Status

CONFIRMED_STATIC

### Observation

Ventilation uses safety signals (smoke/gas) but through its own mapping.

### Risk

Different safety reaction vs heating.

---

## DOM-06 — Lighting and sockets depend on command layer

### Classification

ORDER_DEPENDENCY

### Status

CONFIRMED_STATIC

### Observation

Lighting relies more on command shadow and less on internal decision logic.

### Risk

Behavior depends strongly on arbitration correctness.

---

# IO WRITE ANALYSIS

## IO-OUT-01 — IO_Write is final projection only

### Classification

CONFIRMED_PATTERN

### Status

CONFIRMED_STATIC

### Observation

`PRG_IO_Write` maps internal state to physical outputs.

---

## IO-OUT-02 — No global safety clamp in IO_Write

### Classification

SAFETY_BYPASS (CRITICAL)

### Status

CONFIRMED_STATIC

### Observation

IO_Write does not enforce:

```text
IF safety THEN force outputs safe
```

### Problem

Relies fully on upstream correctness.

### Risk

Any upstream failure → unsafe output possible.

---

## IO-OUT-03 — Final output depends on upstream consistency

### Classification

ORDER_DEPENDENCY

### Status

CONFIRMED_STATIC

### Observation

Outputs depend on:

```text
state variables
command shadow
```

### Risk

Conflicting upstream writes produce undefined but deterministic result.

---

## IO-OUT-04 — No explicit actuator arbitration layer

### Classification

OWNERSHIP_CONFLICT

### Status

CONFIRMED_STATIC

### Observation

There is no dedicated:

```text
final actuator arbitration layer
```

### Risk

Domains effectively compete for outputs.

---

# FINAL SYSTEM CONCLUSION

## What works

- pipeline is structured
- domains exist
- safety signals exist

## What is missing (critical)

### 1. Single decision owner

### 2. Single actuator owner

### 3. Single safety enforcement point

### 4. Clear layer boundaries

---

## System reality

System is:

```text
functionally correct
but
architecturally distributed
```

---

## Primary risks

```text
order-dependent behavior
multi-owner conflicts
implicit safety enforcement
shadow vs legacy mismatch
```

---

## Next step

Create:

```text
08_GLOBAL_RISK_REGISTER.md
```

Consolidating all findings.
