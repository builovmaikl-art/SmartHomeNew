# 12 - Heating 16 Circuit Constants Impact Audit

Date: 2026-04-28

Purpose: analytical impact audit before changing heating circuit count from 8 to 16 according to the updated technical specification.

---

## Verification mode

```text
Analytical repository verification
Runtime/build result added after migration
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

Original drift fact:

```text
GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS was 8
Required value is 16
```

---

## Main conclusion

The project had drifted to an 8-heating-circuit runtime contract.

Changing to 16 was not a single constant edit. It required restoring the same 16-circuit contract across constants, configuration, state, orchestration, heating manager interfaces, snapshot synchronization, and adapter/copy-out logic.

---

## REGRESSION FINDING

```text
FINDING-HC-01:
Heating circuit count regression

Observed:
Code modeled 8 heating circuits

Required (ТЗ):
16 heating circuits

Conclusion:
This was a regression / drift from original system requirements

Impact:
- Half of system was not represented
- Policy worked on incomplete topology
- Heating decisions were structurally incorrect

Required action:
Restore 16-circuit contract across system

Priority: CRITICAL
```

---

## Migration changes applied

### 1. Constants

```text
GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS = 16
```

### 2. Configuration

Updated to use the 16-circuit contract:

```text
GVL_CONFIG.G_HMI_FloorHeating_Configs
GVL_CONFIG.G_FloorTemp_Map
```

Added:

```text
GVL_CONFIG.G_Heating_Circuit_To_Zone
```

Purpose:

```text
Explicit physical circuit -> logical zone mapping.
This prevents using circuit index as zone index.
```

Current mapping status:

```text
Temporary identity mapping 1..16.
Requires final alignment with real topology / ТЗ room table.
```

### 3. State

Updated to 16-circuit contract:

```text
GVL_STATE.G_Floor_Temps
GVL_STATE.G_Zone_Valves
```

### 4. Snapshot synchronization

Updated:

```text
ST_System_State_Snapshot.Zone_Valves
```

Reason:

```text
PRG_System sync path must use the same 16-circuit valve array as GVL_STATE.
```

### 5. Heating manager core

Updated in `FB_Heating_System_Manager`:

```text
VI_Floor_Temps
VI_Zone_Configs
VO_Zone_Valves
L_Floor_Controllers
L_Overheat_Timer
fbFloorTempValidator
```

From:

```text
ARRAY[1..8]
```

To:

```text
ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS]
```

Also updated:

```text
FOR L_Adaptive_Zone_i := 1 TO 8
```

To:

```text
FOR L_Adaptive_Zone_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS
```

### 6. Heating orchestration

Updated in `PRG_Heating`:

```text
Removed legacy L_Zone_Valves_8 adapter.
Introduced L_Zone_Valves [1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS].
Updated coordinator and copy-out loops to C_MAX_HEATING_CIRCUITS.
```

Critical policy correction:

```text
Policy bias/preheat now uses:
physical circuit -> G_Heating_Circuit_To_Zone -> logical zone policy
```

This avoids treating circuit index as zone index.

---

## Compile result

```text
Compilation result after fixes: 0 errors
Reported by operator after CODESYS compile.
```

Compile blockers resolved:

```text
1. ST_System_State_Snapshot.Zone_Valves 8/16 mismatch in PRG_System
2. FB_Heating_System_Manager input/output 8/16 mismatch in PRG_Heating
3. PRG_Heating legacy L_Zone_Valves_8 buffer mismatch
```

---

## Current status

```text
16-circuit requirement: confirmed by ТЗ
Migration status: completed at code level
Compile status: 0 errors
Runtime validation: pending
Real circuit->zone mapping: pending final topology alignment
```

---

## Remaining risks / next checks

```text
1. Validate real G_Heating_Circuit_To_Zone mapping against room/topology table.
2. Verify IO read/write paths cover all 16 physical heating circuits.
3. Validate HMI screens expose all 16 circuits or use grouped zone view.
4. Validate manifold distribution against ТЗ:
   - M1 basement: 2
   - M2 1F: 4
   - M3 2F: 3
   - M4 2F: 3
   - M5 1F: 4
5. Runtime behavior tests still required.
```

---

## Process note

During this migration, large-file edits were performed through terminal patching because API-based full-file replacement is unsafe for large ST files when returned content is truncated.

Required workflow for future large-file changes:

```text
1. Synchronize branch with main.
2. Apply narrow terminal patch.
3. Write patch log under migration_logs/.
4. Commit and push.
5. Immediately re-read changed files from repository.
6. Only then continue to the next change.
```
