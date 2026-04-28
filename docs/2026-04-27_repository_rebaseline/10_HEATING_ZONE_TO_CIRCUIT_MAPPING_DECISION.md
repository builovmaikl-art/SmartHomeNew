# 10 - Heating Zone To Circuit Mapping Decision

Date: 2026-04-28

Purpose: зафиксировать критичное архитектурное уточнение по связи отопительных зон, контуров и коллекторов перед дальнейшими правками HP-1 / HP-2.

---

## Trigger

During analytical audit of HP-1 / HP-2 code behavior, a mismatch was found:

```text
Policy layer is zone-based.
Current PRG_Heating priority application iterates heating circuits 1..C_MAX_HEATING_CIRCUITS.
```

User clarification:

```text
Heating zones are minimum 14-16.
Some zones have multiple heating circuits.
Example 1: living room + kitchen = one heating zone, two heating circuits.
Example 2: one basement room = one heating zone, two heating circuits.
```

---

## Important conclusion

The relationship is NOT:

```text
1 zone = 1 heating circuit
```

The actual required model is:

```text
1 heating zone -> one or more heating circuits -> one or more manifolds
```

or more generally:

```text
zone -> circuit(s) -> manifold(s)
```

---

## Current code problem

Current HP-1/HP-2 code in `PRG_Heating.st` effectively uses:

```text
FOR circuit := 1 TO C_MAX_HEATING_CIRCUITS
    manifold := G_HMI_FloorHeating_Configs[circuit].manifold_id
    manifold_priority += G_Zone_Priority_Bias[circuit]
```

This assumes:

```text
zone index == heating circuit index
```

That assumption is invalid for the real installation.

---

## Impact

If unchanged, current policy behavior may be wrong because:

```text
1. A zone with two circuits may be underrepresented or incorrectly represented.
2. Zones above index 8 may not influence heating priority at all.
3. Circuit count and zone count are different concepts.
4. Policy decisions may look valid in GVL_HEATING_POLICY but not affect real heating allocation correctly.
```

---

## Decision

Before changing HP-1 / HP-2 runtime logic further, define explicit mapping:

```text
Heating zone -> heating circuit list
Heating circuit -> manifold
```

The priority application must not assume index equality.

---

## Required future data model

A future configuration structure is needed, for example one of these forms:

### Option A - zone to circuit map

```text
G_Heating_Zone_To_Circuit_Map[zone, slot] : INT
G_Heating_Zone_Circuit_Count[zone] : INT
```

Meaning:

```text
zone can own several heating circuits
```

### Option B - circuit to zone map

```text
G_Heating_Circuit_To_Zone[circuit] : INT
```

Meaning:

```text
each heating circuit belongs to exactly one logical heating zone
```

Recommended initial choice:

```text
Option B is simpler for current PRG_Heating loop.
```

Reason:

```text
PRG_Heating already iterates circuits and maps circuit -> manifold.
Adding circuit -> zone allows correct lookup of G_Zone_Priority_Bias[zone].
```

---

## Proposed HP fix direction

Instead of:

```text
G_Zone_Priority_Bias[circuit]
```

Use:

```text
zone := G_Heating_Circuit_To_Zone[circuit]
G_Zone_Priority_Bias[zone]
```

Then:

```text
manifold := G_HMI_FloorHeating_Configs[circuit].manifold_id
AdjustedManifoldPriority[manifold] += zone bias contribution
```

---

## Open design question

When one zone has multiple circuits, how should policy bias be applied?

Options:

```text
A. add full zone bias once per circuit
B. divide zone bias across circuits
C. apply zone bias once per manifold touched by the zone
D. apply max zone priority per manifold
```

Current recommendation:

```text
Do not decide in code yet.
Define desired behavior first.
```

---

## Critical audit finding

```text
FINDING-HP-05: Heating policy zone/circuit mapping mismatch
Severity: HIGH
Status: open
Runtime code change: paused until mapping decision is completed
```

---

## What must not be done now

```text
1. Do not continue HP-1/HP-2 code changes using zone == circuit assumption.
2. Do not apply target adjustment.
3. Do not expand guest preheat behavior.
4. Do not use test harness as validation basis for this mapping issue.
```

---

## Next required step

Create mapping design / configuration decision:

```text
11_HEATING_CIRCUIT_TO_ZONE_MAPPING_PLAN.md
```

It should define:

```text
- number of logical heating zones
- number of physical heating circuits
- circuit -> zone mapping
- circuit -> manifold mapping source
- how bias is aggregated when one zone has multiple circuits
- how guest preheat is applied when zone owns multiple circuits
```

---

## Current status

```text
HP-1/HP-2 compile: OK
HP-1/HP-2 behavior audit: blocked by mapping mismatch
Mapping decision required before further runtime changes
```
