# Policy / Coordinator / Command Audit

Date: 2026-04-30

## Scope

Critical decision-making layer of the system.

Included PRGs:

```text
PRG_Heating_Policy_Manager
PRG_Heating_Policy_Observer
PRG_Mode_Manager
PRG_System_Coordinator
PRG_Policy
PRG_Command_Arbitration
PRG_Command_Verifier
PRG_Security
```

This layer is responsible for transforming intent into actual commands affecting physical outputs.

## Execution position

```text
System Layer
→ PRG_Heating_Policy_Manager
→ PRG_Heating_Policy_Observer
→ PRG_Mode_Manager
→ PRG_System_Coordinator
→ PRG_Policy
→ PRG_Command_Arbitration
→ PRG_Command_Verifier
→ PRG_Security
→ Domain
```

## Critical question

This audit answers:

```text
Who is the final owner of control decisions?
```

---

## POL-01 — No single decision owner

### Classification

OWNERSHIP_CONFLICT (CRITICAL)

### Status

CONFIRMED_STATIC

### Observation

Decision logic is distributed:

- Policy Manager → heating decisions
- Mode Manager → global mode bias
- System Coordinator → blocking/coordination
- Command Arbitration → merges intents
- Security → injects access decisions

No single block has authoritative final decision ownership.

### Expected behavior

One of the following must be true:

1. Policy is final decision owner
2. Arbitration is final decision owner
3. Coordinator is final gate

Currently none is strictly enforced.

### Potential failure behavior

- multiple blocks overwrite same command in sequence
- final behavior depends on execution order

### User implication

System may behave inconsistently under combined conditions.

### Engineer implication

Hard to trace "why system did X".

---

## POL-02 — Command Arbitration duplicates Policy role

### Classification

OWNERSHIP_CONFLICT

### Status

CONFIRMED_STATIC

### Observation

`PRG_Command_Arbitration` reads:

```text
GVL_INTENT_SAFETY
GVL_INTENT_SYSTEM
GVL_INTENT_USER
```

and produces:

```text
GVL_COMMAND_SHADOW
```

This is effectively a policy resolution step.

### Problem

Policy exists separately in `PRG_Policy` and domain policy managers.

### Result

Two policy layers:

```text
Policy
AND
Command Arbitration
```

### Risk

Conflicting precedence logic.

---

## POL-03 — Shadow vs Legacy command system

### Classification

SHADOW_LEGACY_CONFLICT

### Status

CONFIRMED_STATIC

### Observation

System uses:

```text
GVL_COMMAND_SHADOW
vs
legacy command/state variables
```

`PRG_Command_Verifier` compares them.

### Problem

Two parallel command paths exist.

### Risk

- mismatch
- partial migration
- unpredictable actuator state

---

## POL-04 — Coordinator is not a hard gate

### Classification

SAFETY_BYPASS / OWNERSHIP_CONFLICT

### Status

CONFIRMED_STATIC

### Observation

Coordinator exposes flags like:

```text
G_Block_Heating
```

But domains still:

- read safety directly
- apply own logic

### Problem

Coordinator is advisory, not authoritative.

### Risk

Different domains behave differently under same block condition.

---

## POL-05 — Security runs after arbitration

### Classification

ORDER_DEPENDENCY

### Status

CONFIRMED_STATIC

### Observation

Order:

```text
Command Arbitration
→ Command Verifier
→ Security
```

### Problem

Security-generated intent may miss current arbitration cycle.

### Risk

1-cycle delay or inconsistency.

---

## POL-06 — Heating policy is domain + policy hybrid

### Classification

OWNERSHIP_CONFLICT

### Status

CONFIRMED_STATIC

### Observation

`PRG_Heating_Policy_Manager`:

- calculates demand
- runs prediction
- optimizes
- uses time

### Problem

This is both:

```text
Policy + Domain logic
```

### Risk

Hard to separate:

- decision
- execution

---

## POL-07 — Command Verifier is passive

### Classification

OBSERVABILITY_GAP

### Status

CONFIRMED_STATIC

### Observation

Verifier compares shadow vs legacy but does not enforce.

### Problem

Mismatch is detected but not corrected.

### Risk

System continues in inconsistent state.

---

## POL-08 — Mode Manager influence is global but implicit

### Classification

ORDER_DEPENDENCY / USER_INSTRUCTION_GAP

### Status

CONFIRMED_STATIC

### Observation

Mode affects behavior across system but is not a strict gate.

### Risk

Mode interactions are implicit, not enforced.

---

## Initial conclusion

This layer is the most critical architectural hotspot.

Main issues:

1. no single decision owner;
2. duplicated policy logic;
3. shadow vs legacy coexistence;
4. coordinator not authoritative;
5. security timing issue;
6. domain-policy mixing;

System works, but decision-making is distributed and order-dependent.

---

## Next audit step

Proceed to:

```text
07_DOMAIN_AUDIT
```

Covering:

- PRG_Heating
- PRG_Ventilation
- PRG_Lighting
- PRG_IO_Write

Focus:

- actual actuator ownership
- final safety enforcement
