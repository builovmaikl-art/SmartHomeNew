# RUNTIME_FIELD_OWNERSHIP_MATRIX

## Назначение

Документ фиксирует ownership truth table для runtime/GVL-полей после remediation cleanup, distributed topology restoration, legacy bypass containment и mixed-GVL boundary classification.

Цель:

```text
предотвратить возврат duplicate writers
предотвратить foreign resets
предотвратить visibility → authority leakage
предотвратить semantic → hard-stop leakage
предотвратить distributed startup quarantine regression
предотвратить legacy direct-state HA bypass resurrection
предотвратить mixed GVL surfaces becoming hidden authority buses
```

Документ связан с:

```text
RUNTIME_RISK_REMEDIATION_HIERARCHY_PLAN.md
RUNTIME_RISK_REMEDIATION_HIERARCHY_PLAN_PART2.md
```

---

# 1. Правила ownership

## 1.1 Единственный authoritative writer

Для каждого authority-поля должен быть только один authoritative writer.

Запрещено:

```text
несколько PRG пишут один authority-state
projection layer reset-ит authority-state
visibility layer пишет runtime-state
semantic layer пишет output hard-stop state
simulation layer пишет production authority state без explicit injection boundary
legacy direct-state replication пишет mixed GVL state из active runtime
```

---

## 1.2 Разделение ролей

```text
authority owner      = пишет и валидирует поле
publication owner    = экспортирует canonical local state в boundary
replication boundary = хранит replicated state, не решает governance
ingestion owner      = нормализует replicated peer state в Peer_* inputs
governor             = валидирует и публикует aggregate authority
reader               = читает поле без изменения
projection layer     = публикует downstream visibility only
advisory layer       = публикует предупреждение без hard-stop effect
legacy frozen        = compatibility-only, не active runtime path
```

---

## 1.3 Запрещённые writer patterns

Запрещено:

```text
Observability → Runtime authority
Semantic → Output hard-stop
Diagnostics → Publication arbitration
Telemetry → Forced safe state
Distributed missing peer → Runtime failure
Output freshness → Runtime snapshot invalidation
Simulation/Test → Production authority without explicit boundary review
GVL_STATUS/GVL_STATE → hidden HA direct-state apply surface
Legacy redundancy → active runtime direct GVL apply
```

---

# 2. Runtime authority ownership

| GVL / поле | Authoritative owner | Разрешённые readers | Запрещённые writers | Тип | Связанные риски |
|---|---|---|---|---|---|
| `GVL_RUNTIME_EPOCH.Runtime_Runtime_Barrier_OK` | `PRG_Runtime_Barrier` | Snapshot, Output, Observability, Diagnostics | Recovery, Observability, Semantic, Distributed | authority | A-RISK-001, RISK-037, RISK-047 |
| `GVL_RUNTIME_EPOCH.Runtime_IO_Publication_Allowed` | `PRG_Runtime_Barrier` | Output, IO, Observability | Snapshot, Output, Recovery, Semantic | authority | RISK-040, RISK-047 |
| `GVL_RUNTIME_EPOCH.Runtime_Impossible_State_Detected` | `PRG_Runtime_Barrier` | Snapshot, Observability | Snapshot, Output, Observability | authority | RISK-038, RISK-047 |
| `GVL_RUNTIME_EPOCH.Runtime_PLC_Authority_Valid` | `PRG_Runtime_Barrier` | Snapshot, Output, Observability | Observability, Semantic, Distributed | authority | A-RISK-004 |
| `GVL_RUNTIME_EPOCH.Runtime_Snapshot_Valid` | `PRG_Runtime_Barrier` | Snapshot, Output, Diagnostics | all other layers | orphan-candidate / legacy naming | C-RISK-004 |
| `GVL_RUNTIME_EPOCH.Runtime_Snapshot_Published` | `PRG_Runtime_Barrier` | Snapshot, Output, Diagnostics | all other layers | orphan-candidate / legacy naming | C-RISK-004 |

## Проверки

Нужно периодически проверять:

```text
нет ли новых writers в GVL_RUNTIME_EPOCH
нет ли recovery feedback в Runtime_Barrier
нет ли diagnostics/explainability hard-stop dependency
Runtime_Snapshot_Valid / Runtime_Snapshot_Published are not used as alternate snapshot authority
```

---

# 3. Runtime snapshot ownership

| GVL / поле | Authoritative owner | Разрешённые readers | Запрещённые writers | Тип | Связанные риски |
|---|---|---|---|---|---|
| `GVL_RUNTIME_SNAPSHOT.Snapshot_Frozen` | `PRG_Runtime_Snapshot_Governor` | Distributed Snapshot Publication, Output, IO, Observability | Output, Observability, Semantic | authority | RISK-038, RISK-047 |
| `GVL_RUNTIME_SNAPSHOT.Snapshot_Publication_Allowed` | `PRG_Runtime_Snapshot_Governor` | Distributed Snapshot Publication, Output, IO | Output, Observability, Semantic | authority | RISK-040, RISK-047 |
| `GVL_RUNTIME_SNAPSHOT.Snapshot_Copy_Valid` | `PRG_Runtime_Snapshot_Governor` | Distributed Snapshot Publication, Output, IO | Output, Observability | authority | RISK-038 |
| `GVL_RUNTIME_SNAPSHOT.Snapshot_Isolation_Valid` | `PRG_Runtime_Snapshot_Governor` | Distributed Snapshot Publication, Output, IO | Output, Observability | authority | RISK-038 |
| `GVL_RUNTIME_SNAPSHOT.Snapshot_Mutation_Detected` | `PRG_Runtime_Snapshot_Governor` | Output, IO, Observability | Output, Observability, Semantic | authority | RISK-038, RISK-040 |
| `GVL_RUNTIME_SNAPSHOT.Snapshot_Runtime_Authority_Valid` | `PRG_Runtime_Snapshot_Governor` | Output, Observability | Output, Observability | mirror-authority | A-RISK-007 |

## Удалённые поля

Удалены и не должны возвращаться:

```text
Snapshot_Observability_Synchronized
Snapshot_Invalidation_Count
```

---

# 4. Command authority ownership

| GVL / поле | Authoritative owner | Разрешённые readers | Запрещённые writers | Тип | Связанные риски |
|---|---|---|---|---|---|
| `GVL_COMMAND.*` | operator/HMI/request layer | `PRG_Command_Arbitration`, `PRG_PreOutput_Safety_Barrier`, `PRG_Command_Verifier` | runtime governors, IO, diagnostics, legacy redundancy | legacy/operator request surface | RISK-015, RISK-038 |
| `GVL_COMMAND_SHADOW.*` | `PRG_Command_Arbitration` | domain PRGs, PreOutput, IO, Debug, Verifier | System Init, diagnostics, HMI, IO, legacy redundancy | runtime command authority | RISK-015, RISK-038, RISK-040 |
| `GVL_COMMAND_VERIFY.PreOutput_*` | `PRG_PreOutput_Safety_Barrier` | `PRG_IO_Write`, diagnostics/HMI | Verifier, IO, domain PRGs, diagnostics | pre-output hard-stop authority | RISK-040, RISK-047 |
| `GVL_COMMAND_VERIFY.Command_*` | `PRG_Command_Verifier` | diagnostics/HMI | PreOutput, IO, domain PRGs | diagnostics-only | RISK-015 |
| `GVL_COMMAND_VERIFY.Runtime_*` | `PRG_Command_Verifier` | diagnostics/HMI | PreOutput, IO, domain PRGs | diagnostics-only / last-error retention | RISK-040 |

## Правила

```text
GVL_COMMAND is not final physical output authority.
GVL_COMMAND_SHADOW is not writable outside PRG_Command_Arbitration.
Verifier diagnostics must not mutate shadow, IO or runtime authority.
PreOutput hard-stop must occur before IO_Write.
```

---

# 5. Output freshness ownership

| GVL / поле | Authoritative owner | Разрешённые readers | Запрещённые writers | Тип | Связанные риски |
|---|---|---|---|---|---|
| `GVL_OUTPUT_EPOCH.Output_Publication_Valid` | `PRG_Output_Freshness_Governor` | IO, Observability, Diagnostics | IO, Semantic, Observability | authority | RISK-047 |
| `GVL_OUTPUT_EPOCH.Output_Forced_Safe_Decay` | `PRG_Output_Freshness_Governor` | IO, Observability | Runtime Snapshot, Semantic, Observability | hard-stop authority | RISK-040, RISK-047 |
| `GVL_OUTPUT_EPOCH.Output_Stale_Detected` | `PRG_Output_Freshness_Governor` | IO, Observability | Semantic, Observability | authority | RISK-047 |
| `GVL_OUTPUT_EPOCH.Output_Lease_Expired` | `PRG_Output_Freshness_Governor` | IO, Observability | IO, Semantic | authority | RISK-047 |
| `GVL_OUTPUT_EPOCH.Output_Semantic_Continuity_Warning` | `PRG_Output_Freshness_Governor` | Observability, HMI, Diagnostics | Semantic, IO, Runtime | advisory | S-RISK-001, RISK-047 |

## Разрешённые hard-stop causes

```text
runtime barrier invalidation
immutable snapshot invalidation
transport freshness invalidation
real distributed reconciliation failure
explicit peer fencing conflict
pre-output safety failure
```

## Запрещённые hard-stop causes

```text
semantic suspicion
observability visibility
telemetry stabilization
explainability synchronization
diagnostics projections
trend/history delays
simulation test status without explicit injection boundary
```

---

# 6. Peer session and HA replication boundary ownership

| GVL / поле | Authoritative owner | Разрешённые readers | Запрещённые writers | Тип | Связанные риски |
|---|---|---|---|---|---|
| `GVL_PEER_SESSION.Local_*` | `PRG_Peer_Session_Publication` | `PRG_HA_Session_Replication`, diagnostics | Distributed governors, IO, Observability | local publication | D-RISK-001 |
| `GVL_HA_SESSION_REPLICATION.HA_Remote_Runtime_Epoch` | HA/backend boundary currently `PRG_HA_Session_Replication` scaffold | `PRG_Distributed_Peer_Ingestion` | Modbus runtime, IO, Observability | replicated peer input | D-RISK-001, D-RISK-004 |
| `GVL_HA_SESSION_REPLICATION.HA_Remote_Snapshot_Epoch` | HA/backend boundary currently `PRG_HA_Session_Replication` scaffold | `PRG_Distributed_Peer_Ingestion` | Modbus runtime, IO, Observability | replicated peer input | D-RISK-001, D-RISK-004 |
| `GVL_HA_SESSION_REPLICATION.HA_Remote_Distributed_Snapshot_Epoch` | `PRG_Distributed_Snapshot_Publication` / future real HA backend | `PRG_Distributed_Snapshot_Ingestion` | Snapshot Governor, IO, Observability | replicated snapshot input | D-RISK-003, D-RISK-004 |
| `GVL_HA_SESSION_REPLICATION.HA_Remote_Publication_Epoch` | `PRG_Distributed_Snapshot_Publication` / future real HA backend | `PRG_Distributed_Snapshot_Ingestion` | Snapshot Governor, IO, Observability | replicated snapshot input | D-RISK-003, D-RISK-004 |
| `GVL_HA_SESSION_REPLICATION.HA_Remote_Publication_Commit_Epoch` | `PRG_Distributed_Commit_Publication` / future real HA backend | `PRG_Distributed_Commit_Ingestion` | Commit Governor, IO, Observability | replicated commit input | D-RISK-003, D-RISK-004 |
| `GVL_HA_SESSION_REPLICATION.HA_Remote_Commit_Ack_Valid` | `PRG_Distributed_Commit_Publication` / future real HA backend | `PRG_Distributed_Commit_Ingestion` | Commit Governor, IO, Observability | replicated commit input | D-RISK-004 |

## Ограничение

```text
PRG_HA_Session_Replication is bounded loopback foundation only.
Future real HA backend must replace boundary writer semantics before claiming real distributed validation.
```

---

# 7. Distributed epoch ownership

| GVL / поле | Authoritative owner | Разрешённые readers | Запрещённые writers | Тип | Связанные риски |
|---|---|---|---|---|---|
| `GVL_DISTRIBUTED_EPOCH.Peer_*` | `PRG_Distributed_Peer_Ingestion` | `PRG_Distributed_Epoch_Governor`, diagnostics | Output, Observability, Recovery, legacy redundancy | peer input | D-RISK-001, D-RISK-004 |
| `GVL_DISTRIBUTED_EPOCH.Distributed_Epoch_Consistent` | `PRG_Distributed_Epoch_Governor` | Output, Snapshot, Observability | Output, Observability, Semantic | authority | D-RISK-001, RISK-047 |
| `GVL_DISTRIBUTED_EPOCH.Distributed_Reconciliation_Valid` | `PRG_Distributed_Epoch_Governor` | Snapshot, Output, Observability | Output, Observability | authority | D-RISK-003 |
| `GVL_DISTRIBUTED_EPOCH.Distributed_Publication_Allowed` | `PRG_Distributed_Epoch_Governor` | Snapshot, Output | Output, Observability | authority | D-RISK-003 |
| `GVL_DISTRIBUTED_EPOCH.Distributed_Quarantine_Active` | `PRG_Distributed_Epoch_Governor` | Output, Observability | Output, Observability | authority | D-RISK-002 |
| `GVL_DISTRIBUTED_EPOCH.Peer_Fencing_Conflict` | `PRG_Distributed_Epoch_Governor` | Output, Observability | Output, Observability | authority | RISK-047 |

## Правило peer-optional mode

```text
missing peer != divergence
missing peer != quarantine
missing peer != output decay
```

---

# 8. Distributed snapshot ownership

| GVL / поле | Authoritative owner | Разрешённые readers | Запрещённые writers | Тип | Связанные риски |
|---|---|---|---|---|---|
| `GVL_DISTRIBUTED_SNAPSHOT.Peer_*` | `PRG_Distributed_Snapshot_Ingestion` | `PRG_Distributed_Snapshot_Governor`, diagnostics | Output, Observability, Recovery, legacy redundancy | peer input | D-RISK-003, D-RISK-004 |
| `GVL_DISTRIBUTED_SNAPSHOT.Local_*` | `PRG_Distributed_Snapshot_Governor` | Snapshot Publication, diagnostics | Output, Observability, Recovery | local projection | D-RISK-003 |
| `GVL_DISTRIBUTED_SNAPSHOT.Distributed_Publication_Reconciled` | `PRG_Distributed_Snapshot_Governor` | Commit, Output, Observability | Output, Observability, Semantic | authority | D-RISK-003, RISK-047 |
| `GVL_DISTRIBUTED_SNAPSHOT.Distributed_Publication_Freeze_Valid` | `PRG_Distributed_Snapshot_Governor` | Commit, Output, Observability | Output, Observability | authority | RISK-038, RISK-047 |
| `GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Consistent` | `PRG_Distributed_Snapshot_Governor` | Commit, Output, Observability | Output, Observability | authority | D-RISK-003 |
| `GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Quarantine_Active` | `PRG_Distributed_Snapshot_Governor` | Output, Observability | Output, Observability | authority | D-RISK-002 |
| `GVL_DISTRIBUTED_SNAPSHOT.Peer_Publication_Divergence` | `PRG_Distributed_Snapshot_Governor` | Observability, Output if authoritative | Output, Observability | peer-authority | D-RISK-004 |

## Удалённые поля

Удалены и не должны возвращаться:

```text
Distributed_Snapshot_Forced_Safe_Mode
Distributed_Snapshot_Invalidation_Count
```

---

# 9. Distributed commit ownership

| GVL / поле | Authoritative owner | Разрешённые readers | Запрещённые writers | Тип | Связанные риски |
|---|---|---|---|---|---|
| `GVL_DISTRIBUTED_COMMIT.Peer_*` | `PRG_Distributed_Commit_Ingestion` | `PRG_Distributed_Commit_Governor`, diagnostics | Output, Observability, Recovery, legacy redundancy | peer input | D-RISK-003, D-RISK-004 |
| `GVL_DISTRIBUTED_COMMIT.Local_*` | `PRG_Distributed_Commit_Governor` | Commit Publication, diagnostics | Output, Observability, Recovery | local projection | D-RISK-003 |
| `GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Valid` | `PRG_Distributed_Commit_Governor` | Output, Observability | Output, Observability, Semantic | authority | D-RISK-003, RISK-047 |
| `GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Quarantine_Active` | `PRG_Distributed_Commit_Governor` | Output, Observability | Output, Observability | authority | D-RISK-002 |
| `GVL_DISTRIBUTED_COMMIT.Peer_Commit_Mismatch` | `PRG_Distributed_Commit_Governor` | Output, Observability | Output, Observability | peer-authority | D-RISK-004 |
| `GVL_DISTRIBUTED_COMMIT.Peer_Commit_Replay_Detected` | `PRG_Distributed_Commit_Governor` | Output, Observability | Output, Observability | peer-authority | D-RISK-004 |
| `GVL_DISTRIBUTED_COMMIT.Commit_Lease_Expired` | `PRG_Distributed_Commit_Governor` | Output, Observability | Output, Observability | peer-authority | D-RISK-004 |

## Удалённые поля

Удалены и не должны возвращаться:

```text
Distributed_Commit_Forced_Safe_Mode
Distributed_Commit_Invalidation_Count
GVL_DISTRIBUTED_COMMIT.Local_Commit_Token
GVL_DISTRIBUTED_COMMIT.Peer_Commit_Token
```

---

# 10. Mixed global GVL ownership

| GVL / surface | Owner / classification | Разрешённые readers | Запрещённые writers / uses | Тип | Связанные риски |
|---|---|---|---|---|---|
| `GVL_STATUS` time fields | `PRG_Time_Service` / monotonic time flow | runtime, domain, diagnostics | legacy redundancy, observability resets | mixed status / time projection | RISK-037 |
| `GVL_STATUS` PLC role fields | `PRG_PLC_Arbitration` | fencing, runtime barrier, command arbitration | diagnostics, HMI, simulation, legacy redundancy | PLC role authority projection | A-RISK-004, RISK-047 |
| `GVL_STATUS` diagnostics/text fields | domain/diagnostics projection owners | HMI, diagnostics | runtime authority, distributed authority | projection | O-RISK-001 |
| `GVL_STATE` sensor/input fields | input/domain processing owners | domain PRGs, diagnostics | HA direct-state apply, runtime governors as writer | normalized state projection | RISK-037 |
| `GVL_STATE` safety projection fields | safety/domain owners | command arbitration, domain, diagnostics | legacy redundancy, HMI, simulation direct writes | safety projection, not hidden bus | RISK-040, RISK-047 |
| `GVL_STATE` policy/allocation fields | policy/observer projection owners | HMI, diagnostics, explainability | hard-stop authority, IO direct authority | observability/projection | S-RISK-001 |
| `GVL_SIMULATION` | `PRG_System_Simulation` | diagnostics/HMI/test tooling | production authority without injection boundary | isolated test surface | V-RISK-001 |

## Правила

```text
GVL_STATUS and GVL_STATE are not HA direct-state apply surfaces.
GVL_STATUS and GVL_STATE are not distributed reconciliation buses.
GVL_SIMULATION does not mutate production authority in current topology.
G_PLC_ID / G_Local_PLC_ID coexistence must not be merged without direct reference sweep.
```

---

# 11. Legacy redundancy ownership

| Surface / type | Status | Allowed use | Forbidden use | Тип | Связанные риски |
|---|---|---|---|---|---|
| `ST_System_State_Snapshot` | legacy frozen marker | compatibility/reference only | current distributed runtime protocol | legacy direct-state snapshot | A-RISK-008, RISK-047 |
| `FB_System_Redundancy_Orchestrator` | disconnected from active runtime base | none in production MAIN | direct GVL apply, parallel HA topology | legacy direct-state apply | RISK-037, RISK-038, RISK-047 |
| `FB_State_Replication` | legacy helper | none in production MAIN | runtime replication authority | legacy direct-state replication | D-RISK-004 |

## Правило

```text
legacy redundancy subsystem must remain disconnected/frozen until explicit barrier/governance review.
```

---

# 12. Observability ownership

| GVL / поле | Authoritative owner | Разрешённые readers | Запрещённые writers | Тип | Связанные риски |
|---|---|---|---|---|---|
| `GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required` | `PRG_Observability_Governor` | HMI, Diagnostics | Distributed projections, Semantic projections, Runtime | visibility escalation | O-RISK-001 |
| `GVL_OBSERVABILITY_AUTHORITY.Unsafe_State_Published` | `PRG_Observability_Governor` | HMI, Diagnostics | Distributed projections, Semantic projections, Runtime | visibility escalation | O-RISK-001 |
| `GVL_OBSERVABILITY_AUTHORITY.*_Visible` | `PRG_Observability_Governor` or dedicated projection owner | HMI, Diagnostics | Runtime authority layers | visibility | O-RISK-003 |

## Удалённые поля

Удалены и не должны возвращаться:

```text
PreActuation_Visibility_Ready
Diagnostics_Synchronized
Explainability_Synchronized
Authority_Snapshot_Valid
Observability_Quarantine_Active
Observability_Invalidation_Count
```

---

# 13. Semantic ownership

| GVL / поле | Authoritative owner | Разрешённые readers | Запрещённые writers | Тип | Связанные риски |
|---|---|---|---|---|---|
| `GVL_SEMANTIC_PROGRESS.Semantic_Forward_Progress_Valid` | `PRG_Semantic_Progress_Governor` | Output advisory, Observability, HMI | Output, Runtime, IO | advisory | S-RISK-001 |
| `GVL_SEMANTIC_PROGRESS.Semantic_Progress_Quarantine_Active` | `PRG_Semantic_Progress_Governor` | Output advisory, Observability | Output, Runtime, IO | advisory-only | S-RISK-004 |
| `GVL_OUTPUT_EPOCH.Output_Semantic_Continuity_Warning` | `PRG_Output_Freshness_Governor` | Observability, HMI | Semantic, IO | advisory projection | S-RISK-001 |

## Правило

```text
semantic suspicion != physical hard-stop
semantic warning != forced decay
semantic quarantine != output authority
```

---

# 14. Anti-regression checklist

Перед любым новым runtime layer проверить:

```text
кто authoritative owner
кто publication owner
кто ingestion owner
кто allowed reader
есть ли hard-stop effect
есть ли feedback loop
есть ли duplicate degraded mirror
есть ли startup default-fail behavior
есть ли hidden mixed-GVL authority use
нужен ли новый DUT, или достаточно existing scalar/GVL contract
```

Запрещено merge, если новый код:

```text
пишет foreign GVL authority state
создаёт Runtime ↔ Downstream cycle
создаёт Semantic → Output hard-stop path
создаёт Observability → Runtime authority path
создаёт missing peer = failure behavior
возвращает удалённые Forced_Safe_Mode mirrors
reconnects legacy direct-state redundancy into MAIN
uses GVL_STATUS/GVL_STATE as hidden HA replication bus
adds simulation injection into production authority without explicit boundary review
adds new DUT for HA backend before transport contract design
```
