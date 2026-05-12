# HEATING_REMARKS_REMAINING_WORK

# Purpose

This document records the remaining root-level work after cleanup of disconnected blocks listed in:

```text
замечания.txt
```

The original goal is:

```text
- inspect disconnected / no-codegen blocks;
- extract useful ideas into active runtime where needed;
- delete donor blocks after extraction;
- keep only explicitly justified exceptions.
```

---

# Current cleanup status

Bulk deletion of disconnected experimental `FB_Heating_Runtime_*` scaffold blocks has been performed in production root.

Removed groups include:

```text
- adaptive drift/risk scaffold;
- anomaly aggregation/correlation/severity/weighting scaffold;
- predictive cascade/OT scaffold;
- causality/replay/timeline scaffold;
- confidence/degradation/stability scaffold;
- runtime governance/orchestration scaffold;
- observation aggregation/validation scaffold;
- phase sequencing/telemetry/transition scaffold;
- supervision confidence/integrity scaffold;
- unused runtime health/intelligence scaffold.
```

Important:

```text
snapshots/history were not touched.
```

---

# Verified remaining root files from remarks list

## 1. FB_Heating_Runtime_Observability

Status:

```text
KEEP ACTIVE
```

Reason:

```text
active projection/publication layer used by heating runtime architecture.
```

Role:

```text
- allocation snapshot publication;
- policy diagnostics projection;
- freeze/DHW bypass visibility;
- bounded policy bridge visibility.
```

Restriction:

```text
does not own runtime outputs.
```

Action:

```text
Do not delete.
```

---

## 2. FB_Heating_Runtime_Observer

Status:

```text
KEEP ACTIVE / RUNTIME-ADJACENT
```

Reason:

```text
participates in governed finalized-state observation path.
```

Role:

```text
read-only runtime observer
```

Action:

```text
Do not delete unless observer architecture is intentionally removed later.
```

---

## 3. FB_Heating_Runtime_Observer_Authorization

Status:

```text
KEEP ACTIVE / RUNTIME-ADJACENT
```

Reason:

```text
authorization gate for passive runtime observer bootstrap.
```

Role:

```text
- governance lock validation;
- passive/read-only observer authorization;
- runtime authority isolation validation.
```

Action:

```text
Do not delete unless observer architecture is intentionally removed later.
```

---

## 4. FB_Heating_Diagnostics

Status:

```text
INTEGRATION REQUIRED BEFORE DELETE
```

Reason:

```text
contains service/OOS/freeze diagnostics event projection not fully covered elsewhere.
```

Useful semantics:

```text
- backup pump out-of-service diagnostics event;
- electric heater out-of-service diagnostics event;
- manifold pump out-of-service diagnostics event;
- DHW heating pump out-of-service diagnostics event;
- DHW circulation pump out-of-service diagnostics event;
- freeze hardware failed diagnostics event;
- combined freeze hardware event text.
```

Current finding:

```text
PRG_Heating currently contains service-gating flags,
but does not yet call FB_Heating_Diagnostics
or otherwise publish the same diagnostics event stream.
```

Required next action:

```text
Integrate diagnostics event projection into active diagnostics phase,
then delete FB_Heating_Diagnostics donor if no longer needed.
```

Recommended integration target:

```text
PRG_Heating diagnostics phase
after FB_Heating_RootCause_Diagnostics call.
```

---

## 5. FB_State_Snapshot_Manager

Status:

```text
SEPARATE ARCHITECTURAL DECISION
```

Reason:

```text
not a heating governance scaffold;
possible blackbox/snapshot prototype.
```

Possible value:

```text
- fault snapshot;
- freeze-state dump;
- service export;
- future blackbox/replay architecture.
```

Action:

```text
Do not delete in this cleanup pass.
Evaluate separately.
```

---

## 6. F_Modbus_RTU_CRC16

Status:

```text
KEEP UTILITY
```

Reason:

```text
standalone deterministic utility function.
```

Action:

```text
Do not delete.
```

---

# Important correction

A previous attempt to integrate `FB_Heating_Diagnostics` into `PRG_Heating` was not present after verification fetch.

Therefore:

```text
FB_Heating_Diagnostics must remain until integration is actually completed and verified.
```

---

# Next recommended step

Proceed with:

```text
HEATING_DIAGNOSTICS_DONOR_INTEGRATION
```

Minimum required work:

```text
1. add FB_Heating_Diagnostics instance to PRG_Heating;
2. call it in HRP_DIAGNOSTICS phase after FB_Heating_RootCause_Diagnostics;
3. verify service/OOS/freeze diagnostics events are produced;
4. delete FB_Heating_Diagnostics donor only if its logic is fully integrated or directly active;
5. update remarks cleanup documentation.
```

---

# Strategic conclusion

The mass deletion phase is complete for confirmed disconnected experimental Runtime_* scaffold donors.

Remaining work is not bulk deletion.

It is:

```text
- preserve active observer path;
- integrate diagnostics donor semantics;
- decide snapshot manager separately;
- keep CRC utility.
```
