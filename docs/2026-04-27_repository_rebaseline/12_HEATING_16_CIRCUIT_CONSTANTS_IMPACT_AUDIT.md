# 12 - Heating 16 Circuit Constants Impact Audit

Date: 2026-04-28

Purpose: analytical impact audit before changing heating circuit count from 8 to 16 according to the updated technical specification.

---

## Verification mode

```text
Analytical repository verification only
No runtime/build claim in this document
No code change in this document
```

---

## Source facts

From `ТЗ обновлен.txt`:

```text
Heating circuits: 16
Manifolds: 5
```

Distribution:

```text
Manifold 1 basement: 2 circuits
Manifold 2 1F: 4 circuits
Manifold 3 2F: 3 circuits
Manifold 4 2F: 3 circuits
Manifold 5 1F: 4 circuits
Total: 16 circuits
```

Current code fact:

```text
GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS = 8
```

---

## Main conclusion

The project is currently built around an 8-heating-circuit runtime contract.

Changing to 16 is not a single constant edit.

It impacts:

```text
- global constants
- config arrays
- state arrays
- PRG_Heating local adapters
- FB_Heating_System_Manager interface
- validators / controllers / timers
- copy-out blocks
- HP-1 / HP-2 policy mapping
```

---

## Confirmed 8-circuit dependencies

### 1. GVL_CONSTANTS

Current:

```text
C_MAX_HEATING_CIRCUITS : INT := 8
```

Required by ТЗ:

```text
C_MAX_HEATING_CIRCUITS : INT := 16
```

Impact:

```text
Any loop using C_MAX_HEATING_CIRCUITS would expand automatically.
But many arrays are still hardcoded [1..8], so changing the constant alone can break compile or runtime logic.
```

---

### 2. GVL_CONFIG

Current:

```text
G_HMI_FloorHeating_Configs : ARRAY[1..8] OF ST_FloorHeating_Circuit_Config
G_FloorTemp_Map : ARRAY[1..8] OF INT
```

Required:

```text
ARRAY[1..16]
```

Impact:

```text
Config must hold all 16 physical heating circuits.
```

---

### 3. GVL_STATE

Current:

```text
G_Floor_Temps : ARRAY[1..8] OF REAL
G_Zone_Valves : ARRAY[1..8] OF BOOL
```

Required:

```text
G_Floor_Temps : ARRAY[1..16] OF REAL
G_Zone_Valves : ARRAY[1..16] OF BOOL
```

Impact:

```text
Current runtime state cannot represent 16 floor sensors / 16 circuit valves.
```

---

### 4. PRG_Heating

Confirmed current patterns:

```text
L_Zone_Valves_8 : ARRAY[1..8] OF BOOL
FOR L_i := 1 TO 8 DO GVL_STATE.G_Zone_Valves[L_i] := L_Zone_Valves_8[L_i]
```

Also uses:

```text
GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS loops
```

Impact:

```text
If C_MAX_HEATING_CIRCUITS becomes 16 while L_Zone_Valves_8 remains 8, compile/runtime mismatch is likely.
```

---

### 5. FB_Heating_System_Manager interface

Current interface includes hardcoded 8-circuit arrays:

```text
VI_Floor_Temps : ARRAY[1..8] OF REAL
VI_Zone_Configs : ARRAY[1..8] OF ST_FloorHeating_Circuit_Config
VO_Zone_Valves : ARRAY[1..8] OF BOOL
```

Current internals include hardcoded 8 arrays:

```text
L_Floor_Controllers : ARRAY[1..8] OF FB_FloorHeating_Controller
L_Overheat_Timer : ARRAY[1..8] OF FB_System_Timer
fbFloorTempValidator : ARRAY[1..8] OF FB_Analog_Validator
```

Also contains at least one direct loop:

```text
FOR L_Adaptive_Zone_i := 1 TO 8 DO
```

Impact:

```text
FB_Heating_System_Manager is a major migration target.
It must be converted from 8-circuit hardcoding to C_MAX_HEATING_CIRCUITS-based arrays.
```

---

### 6. HP-1 / HP-2 mapping

Current HP-1 / HP-2 code iterates current heating circuits and uses policy arrays.

But current design still needs:

```text
G_Heating_Circuit_To_Zone[circuit]
```

because:

```text
logical zone != physical circuit
```

Impact:

```text
The 16-circuit migration and zone/circuit mapping must be handled together or at least sequenced carefully.
```

---

## Risk classification

```text
Severity: HIGH
Reason: current code compiles, but does not represent ТЗ heating topology
```

Risk if only constant is changed:

```text
HIGH compile risk due to array contract mismatch
HIGH behavior risk due to incomplete state/config expansion
```

Risk if code is not changed:

```text
System remains limited to 8 heating circuits while ТЗ requires 16
HP-1 / HP-2 policy behavior remains structurally incomplete
```

---

## Recommended migration strategy

Do NOT change all files blindly.

Use staged migration:

### Stage HC-1 - Define constants and config model

```text
- Update C_MAX_HEATING_CIRCUITS to 16
- Expand G_HMI_FloorHeating_Configs to 16
- Expand G_FloorTemp_Map to 16
- Add G_Heating_Circuit_To_Zone[1..16]
```

### Stage HC-2 - Expand state contract

```text
- Expand G_Floor_Temps to 16
- Expand G_Zone_Valves to 16
```

### Stage HC-3 - Expand FB_Heating_System_Manager contract

```text
- VI_Floor_Temps -> C_MAX_HEATING_CIRCUITS
- VI_Zone_Configs -> C_MAX_HEATING_CIRCUITS
- VO_Zone_Valves -> C_MAX_HEATING_CIRCUITS
- L_Floor_Controllers -> C_MAX_HEATING_CIRCUITS
- L_Overheat_Timer -> C_MAX_HEATING_CIRCUITS
- fbFloorTempValidator -> C_MAX_HEATING_CIRCUITS
- hardcoded FOR 1 TO 8 -> C_MAX_HEATING_CIRCUITS where semantically circuit-based
```

### Stage HC-4 - Expand PRG_Heating adapter

```text
- Replace L_Zone_Valves_8 with C_MAX_HEATING_CIRCUITS-based local array or remove adapter if possible
- Update copy-out loop
- Ensure fbHeatingManager call matches expanded types
```

### Stage HC-5 - Correct HP policy mapping

```text
- use circuit -> zone map
- apply selected aggregation option A
- keep target adjustment out of scope
```

---

## What not to change in this migration

```text
- Do not change MAIN order
- Do not change PRG_IO_Read in the first migration stage unless direct IO array mismatch requires a later dedicated changeset
- Do not change PRG_Safety core logic
- Do not apply G_Zone_Target_Adjustment[]
- Do not repair test harness as part of this migration
- Do not change actuator ownership model
```

---

## Open questions before code

```text
1. Exact circuit numbering 1..16 by room/zone
2. Exact circuit -> manifold assignment table
3. Exact circuit -> logical zone assignment table
4. Whether all 16 circuits have individual floor sensors
5. Whether all 16 circuits have individual valve outputs
6. Whether existing IO mapping already has enough channels
```

---

## Immediate next document

Before code, create:

```text
13_HEATING_16_CIRCUIT_MIGRATION_CHANGESET_PLAN.md
```

It must define:

```text
- exact files for HC-1..HC-5
- one safe first changeset
- compile checkpoints
- rollback approach
```

---

## Current status

```text
16-circuit requirement: confirmed by ТЗ
Current code: 8-circuit contract
Impact: high
Runtime code change: not yet applied
Next: migration changeset plan
```
