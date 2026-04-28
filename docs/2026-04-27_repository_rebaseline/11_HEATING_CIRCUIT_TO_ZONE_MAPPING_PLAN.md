# 11 - Heating Circuit To Zone Mapping Plan

Date: 2026-04-28

Purpose: define the required heating circuit -> logical zone mapping model after confirming that real heating zones and physical heating circuits are not 1:1.

---

## Source facts

Source:

```text
ТЗ обновлен.txt
```

Key heating facts:

```text
16 physical heating circuits
5 manifolds
Some logical rooms/zones may have more than one physical heating circuit
```

User clarification:

```text
Living room + kitchen is one logical zone / one room.
It has 2 heating circuits, not 4.
One basement room can also have 2 heating circuits.
```

---

## Core model

The project must treat these as separate concepts:

```text
Logical heating zone / room
Physical heating circuit
Manifold
```

Correct relationship:

```text
logical zone -> one or more heating circuits -> manifold
```

Not valid:

```text
zone index == circuit index
```

---

## Selected aggregation decision

Selected option:

```text
A - a zone with multiple heating circuits gets proportionally stronger total priority contribution.
```

Meaning:

```text
If one logical zone has 2 physical circuits, its policy bias is applied through both circuits.
```

Rationale:

```text
More circuits usually mean larger heated area or higher thermal load.
Therefore multiplied contribution is acceptable and intentional.
```

---

## Consequence for current HP-1 / HP-2 code

Current code in PRG_Heating.st already applies policy bias per heating circuit.

With decision A, this is no longer automatically considered wrong.

However, the current implementation still has a serious missing piece:

```text
It assumes circuit index can be used directly as zone index.
```

This must be replaced with explicit mapping:

```text
circuit -> logical zone
```

---

## Required configuration addition

Introduce a config array, for example:

```text
GVL_CONFIG.G_Heating_Circuit_To_Zone : ARRAY[1..16] OF INT
```

or, if constants are updated first:

```text
GVL_CONFIG.G_Heating_Circuit_To_Zone : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF INT
```

But note current code has:

```text
C_MAX_HEATING_CIRCUITS = 8
```

while the technical specification requires:

```text
16 heating circuits
```

Therefore constants/config must be audited before changing PRG_Heating.

---

## Required constants audit

Current known mismatch:

```text
GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS = 8
ТЗ requires 16 heating circuits
```

This is a blocker for correct HP-1 / HP-2 implementation.

Before PRG_Heating behavior is corrected, decide/update:

```text
C_MAX_HEATING_CIRCUITS := 16
GVL_CONFIG.G_HMI_FloorHeating_Configs : ARRAY[1..16]
related zone valve arrays / adapters currently sized 8
```

---

## Preliminary mapping model from ТЗ

Manifold-level facts from ТЗ:

```text
Manifold 1 basement: 2 circuits
Manifold 2 1F: 4 circuits
Manifold 3 2F: 3 circuits
Manifold 4 2F: 3 circuits
Manifold 5 1F: 4 circuits
Total: 16 circuits
```

Known logical multi-circuit zones:

```text
Living room + kitchen: one logical zone, 2 circuits
Basement room: one logical zone, 2 circuits
```

Exact circuit numbering still needs final user/project confirmation.

---

## HP-1 / HP-2 corrected conceptual formula

For each physical heating circuit:

```text
zone := G_Heating_Circuit_To_Zone[circuit]
manifold := G_HMI_FloorHeating_Configs[circuit].manifold_id
AdjustedManifoldPriority[manifold] += TO_INT(G_Zone_Priority_Bias[zone])
```

For guest preheat:

```text
IF G_Zone_Guest_Preheat_Request[zone] THEN
    AdjustedManifoldPriority[manifold] += G_Guest_Preheat_Priority_Boost
END_IF
```

Because aggregation option A is selected, this intentionally applies once per circuit.

---

## Remaining design risks

### Risk 1 - REAL to INT conversion

Policy bias is REAL, while manifold priority is INT.

Current code uses:

```text
TO_INT(G_Zone_Priority_Bias[])
```

Need separate decision:

```text
keep coarse INT behavior or introduce scaled/rounded priority model
```

### Risk 2 - circuit count expansion from 8 to 16

Changing `C_MAX_HEATING_CIRCUITS` may affect:

```text
PRG_Heating
FB_Heating_System_Manager
GVL_CONFIG.G_HMI_FloorHeating_Configs
zone valve arrays
adapter copy-out blocks
HMI expectations
```

Must be handled as a controlled changeset.

### Risk 3 - living room/kitchen wording in ТЗ

ТЗ names:

```text
living room zone 1
living room zone 2
kitchen zone 1
kitchen zone 2
```

User clarification overrides interpretation:

```text
living room + kitchen = one logical room/zone with 2 heating circuits
```

This should be reflected in final room/circuit table.

---

## Immediate next step

Do not modify runtime logic yet.

Next audit document:

```text
12_HEATING_16_CIRCUIT_CONSTANTS_IMPACT_AUDIT.md
```

Purpose:

```text
check all code impacted by increasing heating circuits from 8 to 16
```

---

## Current status

```text
Aggregation decision: A selected
Mapping model: circuit -> zone required
Runtime code change: paused
Blocking issue: current constants/config still model only 8 heating circuits
```
