# RUNTIME_FIELD_OWNERSHIP_MATRIX

## Назначение

Документ фиксирует ownership truth table для runtime/GVL-полей после remediation cleanup.

Цель:

```text
предотвратить возврат duplicate writers
предотвратить foreign resets
предотвратить visibility → authority leakage
предотвратить semantic → hard-stop leakage
предотвратить distributed startup quarantine regression
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
```

---

## 1.2 Разделение ролей

```text
authority owner  = пишет и валидирует поле
reader           = читает поле без изменения
projection layer = публикует downstream visibility only
advisory layer   = публикует предупреждение без hard-stop effect
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
```

---

# 2. Runtime authority ownership

| GVL / поле | Authoritative owner | Разрешённые readers | Запрещённые writers | Тип | Связанные риски |
|---|---|---|---|---|---|
| `GVL_RUNTIME_EPOCH.Runtime_Runtime_Barrier_OK` | `PRG_Runtime_Barrier` | Snapshot, Output, Observability, Diagnostics | Recovery, Observability, Semantic, Distributed | authority | A-RISK-001, RISK-037, RISK-047 |
| `GVL_RUNTIME_EPOCH.Runtime_IO_Publication_Allowed` | `PRG_Runtime_Barrier` | Output, IO, Observability | Snapshot, Output, Recovery, Semantic | authority | RISK-040, RISK-047 |
| `GVL_RUNTIME_EPOCH.Runtime_Impossible_State_Detected` | `PRG_Runtime_Barrier` | Snapshot, Observability | Snapshot, Output, Observability | authority | RISK-038, RISK-047 |
| `GVL_RUNTIME_EPOCH.Runtime_PLC_Authority_Valid` | `PRG_Runtime_Barrier` | Snapshot, Output, Observability | Observability, Semantic, Distributed | authority | A-RISK-004 |

## Проверки

Нужно периодически проверять:

```text
нет ли новых writers в GVL_RUNTIME_EPOCH
нет ли recovery feedback в Runtime_Barrier
нет ли diagnostics/explainability hard-stop dependency
```

---

# 3. Runtime snapshot ownership

| GVL / поле | Authoritative owner | Разрешённые readers | Запрещённые writers | Тип | Связанные риски |
|---|---|---|---|---|---|
| `GVL_RUNTIME_SNAPSHOT.Snapshot_Frozen` | `PRG_Runtime_Snapshot_Governor` | Distributed Snapshot, Output, IO, Observability | Output, Observability, Semantic | authority | RISK-038, RISK-047 |
| `GVL_RUNTIME_SNAPSHOT.Snapshot_Publication_Allowed` | `PRG_Runtime_Snapshot_Governor` | Distributed Snapshot, Output, IO | Output, Observability, Semantic | authority | RISK-040, RISK-047 |
| `GVL_RUNTIME_SNAPSHOT.Snapshot_Copy_Valid` | `PRG_Runtime_Snapshot_Governor` | Distributed Snapshot, Output, IO | Output, Observability | authority | RISK-038 |
| `GVL_RUNTIME_SNAPSHOT.Snapshot_Isolation_Valid` | `PRG_Runtime_Snapshot_Governor` | Distributed Snapshot, Output, IO | Output, Observability | authority | RISK-038 |
| `GVL_RUNTIME_SNAPSHOT.Snapshot_Mutation_Detected` | `PRG_Runtime_Snapshot_Governor` | Output, IO, Observability | Output, Observability, Semantic | authority | RISK-038, RISK-040 |
| `GVL_RUNTIME_SNAPSHOT.Snapshot_Runtime_Authority_Valid` | `PRG_Runtime_Snapshot_Governor` | Output, Observability | Output, Observability | mirror-authority | A-RISK-007 |

## Удалённые поля

Удалены и не должны возвращаться:

```text
Snapshot_Observability_Synchronized
Snapshot_Invalidation_Count
```

## Проверки

```text
Snapshot не должен читать Output_Forced_Safe_Decay
Snapshot не должен зависеть от Observability
Snapshot не должен иметь telemetry-driven invalidation counters
```

---

# 4. Output freshness ownership

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
```

---

# 5. Distributed epoch ownership

| GVL / поле | Authoritative owner | Разрешённые readers | Запрещённые writers | Тип | Связанные риски |
|---|---|---|---|---|---|
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

## Проверки

```text
проверить отсутствие remaining forced-safe mirrors
проверить startup default states
проверить peer session activation logic
```

---

# 6. Distributed snapshot ownership

| GVL / поле | Authoritative owner | Разрешённые readers | Запрещённые writers | Тип | Связанные риски |
|---|---|---|---|---|---|
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

# 7. Distributed commit ownership

| GVL / поле | Authoritative owner | Разрешённые readers | Запрещённые writers | Тип | Связанные риски |
|---|---|---|---|---|---|
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
```

---

# 8. Observability ownership

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

## Проверки

```text
visibility fields не должны влиять на runtime authority
projection layers не должны писать Emergency_Visibility_Required
projection layers не должны писать Unsafe_State_Published
```

---

# 9. Semantic ownership

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

# 10. Anti-regression checklist

Перед любым новым runtime layer проверить:

```text
кто authoritative owner
кто allowed reader
есть ли hard-stop effect
есть ли feedback loop
есть ли duplicate degraded mirror
есть ли startup default-fail behavior
```

Запрещено merge, если новый код:

```text
пишет foreign GVL authority state
создаёт Runtime ↔ Downstream cycle
создаёт Semantic → Output hard-stop path
создаёт Observability → Runtime authority path
создаёт missing peer = failure behavior
возвращает удалённые Forced_Safe_Mode mirrors
```
