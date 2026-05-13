# RUNTIME_RISK_REMEDIATION_HIERARCHY_PLAN_PART2

# Назначение

Этот документ является:

```text
runtime structural validation workbook
```

А не cleanup-log.

Документ содержит:

```text
writer graph validation
hard-stop graph validation
advisory leakage validation
runtime evidence criteria
remaining topology hypotheses
cross-layer verification matrix
```

Основной файл:

```text
RUNTIME_RISK_REMEDIATION_HIERARCHY_PLAN.md
```

фиксирует:

```text
стратегию remediation
иерархию рисков
стадии работ
```

PART2 фиксирует:

```text
как именно проверяется архитектура
```

---

# 0. RUNTIME REMEDIATION STATE CHECKPOINT

Дата фиксации:

```text
2026-05-13
```

Назначение checkpoint:

```text
зафиксировать фактическое состояние после topology restoration,
legacy bypass containment и mixed-GVL boundary classification
```

---

## 0.1 Resolved / remediated authority issues

### Distributed peer ingestion topology restoration

Исправлено:

```text
restored explicit distributed peer ingestion topology
```

Текущая topology:

```text
physical peer heartbeat
    ↓
PRG_Peer_Heartbeat_Ingestion
    ↓
PRG_PLC_Arbitration
    ↓
PRG_PLC_Fencing_Governor
    ↓
PRG_Peer_Session_Publication
    ↓
GVL_PEER_SESSION
    ↓
PRG_HA_Session_Replication
    ↓
GVL_HA_SESSION_REPLICATION
    ↓
PRG_Distributed_Peer_Ingestion
    ↓
PRG_Distributed_Epoch_Governor
```

Подтверждено:

```text
publication owner exists
HA/session boundary exists
peer ingestion owner exists
stale peer fields are cleared when HA session is invalid
MAIN execution order restored
```

Статус:

```text
FOUNDATION_RESTORED_RUNTIME_VALIDATION_PENDING
```

---

### Distributed snapshot topology restoration

Исправлено:

```text
restored explicit distributed snapshot publication and ingestion topology
```

Текущая topology:

```text
GVL_RUNTIME_SNAPSHOT
    ↓
PRG_Distributed_Snapshot_Publication
    ↓
GVL_HA_SESSION_REPLICATION
    ↓
PRG_Distributed_Snapshot_Ingestion
    ↓
GVL_DISTRIBUTED_SNAPSHOT.Peer_*
    ↓
PRG_Distributed_Snapshot_Governor
```

Подтверждено:

```text
snapshot publication owner exists
HA snapshot boundary fields exist
snapshot ingestion owner exists
stale peer snapshot fields are cleared when HA session is invalid
MAIN execution order restored before snapshot governor
```

Статус:

```text
FOUNDATION_RESTORED_RUNTIME_VALIDATION_PENDING
```

---

### Distributed commit topology restoration

Исправлено:

```text
restored explicit distributed commit publication and ingestion topology
```

Текущая topology:

```text
GVL_DISTRIBUTED_SNAPSHOT
    ↓
PRG_Distributed_Commit_Publication
    ↓
GVL_HA_SESSION_REPLICATION
    ↓
PRG_Distributed_Commit_Ingestion
    ↓
GVL_DISTRIBUTED_COMMIT.Peer_*
    ↓
PRG_Distributed_Commit_Governor
```

Подтверждено:

```text
commit publication owner exists
HA commit boundary fields exist
commit ingestion owner exists
stale peer commit ack fields are cleared when HA session is invalid
MAIN execution order restored before commit governor
```

Статус:

```text
FOUNDATION_RESTORED_RUNTIME_VALIDATION_PENDING
```

---

### Mandatory HA backend replacement requirement

Зафиксировано:

```text
PRG_HA_Session_Replication is temporary bounded loopback foundation only.
```

Это НЕ:

```text
final distributed runtime transport
```

И НЕ:

```text
acceptable permanent production topology
```

Обязательное future replacement:

```text
PRG_HA_Session_Replication must be replaced by:
- real PLC-to-PLC replication transport
or
- deterministic HA synchronization backend
```

Допустимые направления:

```text
SysCom HA channel
shared memory replication
industrial Ethernet HA link
fieldbus synchronization
redundant runtime transport
```

Запрещено:

```text
оставлять bounded loopback as permanent production implementation
переносить HA replication внутрь Modbus runtime transport
смешивать distributed reconciliation с transport replication layer
```

Причина:

```text
иначе distributed validation становится self-mirroring topology
и теряет способность обнаруживать real peer divergence.
```

---

### Legacy direct-state redundancy bypass containment

Найден и отключён active runtime bypass:

```text
MAIN
    ↓
PRG_System_Runtime_Base
    ↓
FB_System_Redundancy_Orchestrator
    ↓
FB_Redundancy_Manager / FB_State_Replication
    ↓
direct GVL_STATUS / GVL_ALARM / GVL_STATE / GVL_COMMAND apply
```

Исправлено:

```text
FB_System_Redundancy_Orchestrator disconnected from PRG_System_Runtime_Base
ST_System_State_Snapshot marked as legacy direct-state replication snapshot
```

Статус:

```text
CONFIRMED_RESOLVED_FOR_ACTIVE_RUNTIME_PATH
```

Остаётся доказать:

```text
no remaining indirect invocation path through diagnostics, maintenance, simulation or HMI
```

---

### Command authority convergence

Классификация:

```text
GVL_COMMAND
    legacy/operator command request surface
    verifier comparison source

GVL_COMMAND_SHADOW
    runtime operational command authority
    owner: PRG_Command_Arbitration

GVL_COMMAND_VERIFY.PreOutput_*
    current-cycle pre-output hard-stop state
    owner: PRG_PreOutput_Safety_Barrier

GVL_COMMAND_VERIFY.Command_*/Runtime_*
    post-IO diagnostics
    owner: PRG_Command_Verifier
```

Исправлено:

```text
PRG_System_Init foreign writes to GVL_COMMAND_SHADOW removed
```

Статус:

```text
CONFIRMED_RESOLVED_FOR_KNOWN_DIRECT_PATHS
```

---

### Simulation boundary containment

Классификация:

```text
GVL_SIMULATION is isolated simulation/test request and status surface.
```

Подтверждено:

```text
PRG_System_Simulation writes only GVL_SIMULATION
FB_Simulation_Manager does not mutate production authority
FB_Presence_Playback is called with VI_Mode_Record := FALSE in PRG_System_Simulation
G_Sim_* production consumers were not found in current direct/search pass
```

Статус:

```text
CONFIRMED_ISOLATED_FOR_KNOWN_DIRECT_PATHS
```

Ограничение:

```text
a direct production injection bridge is not currently implemented.
Any future bridge requires explicit boundary review.
```

---

### Mixed GVL boundary classification

Классифицированы:

```text
GVL_STATUS
GVL_STATE
```

Правило:

```text
GVL_STATUS and GVL_STATE must not become hidden HA replication,
distributed reconciliation or direct-state runtime authority buses.
```

Найден drift:

```text
GVL_STATUS contains both G_PLC_ID and G_Local_PLC_ID.
Do not merge/remove without direct reference sweep.
```

Статус:

```text
BOUNDARY_CLASSIFIED_REFERENCE_SWEEP_PENDING
```

---

## 0.2 Current directed authority stack

Текущая validated directionality:

```text
Monotonic
  ↓
Transport_Freshness
  ↓
PLC_Fencing
  ↓
Runtime_Barrier
  ↓
Runtime_Snapshot
  ↓
Peer_Session_Publication
  ↓
HA_Session_Replication
  ↓
Distributed_Peer_Ingestion
  ↓
Distributed_Epoch
  ↓
Distributed_Snapshot_Publication
  ↓
Distributed_Snapshot_Ingestion
  ↓
Distributed_Snapshot
  ↓
Distributed_Commit_Publication
  ↓
Distributed_Commit_Ingestion
  ↓
Distributed_Commit
  ↓
PreOutput_Barrier
  ↓
Output_Freshness
  ↓
IO_Write
  ↓
Command_Verifier
  ↓
Recovery_Cleanup
  ↓
Observability / Diagnostics / HMI
```

---

# 1. WRITER GRAPH VALIDATION

## VALIDATION-W-001 — Command shadow writer graph

### Проверка

```text
GVL_COMMAND_SHADOW writer ownership
```

### Подтверждено

```text
PRG_Command_Arbitration is runtime operational writer.
Domain PRGs, IO_Write and Debug_View read GVL_COMMAND_SHADOW but do not write it.
PRG_System_Init foreign writes were removed.
```

### Статус

```text
CONFIRMED_RESOLVED_FOR_KNOWN_DIRECT_PATHS
```

### Остаётся проверить

```text
HMI/operator/debug/diagnostics paths do not mutate GVL_COMMAND_SHADOW
```

---

## VALIDATION-W-002 — Runtime authority writer graph

### Проверка

```text
GVL_RUNTIME_EPOCH / GVL_RUNTIME_SNAPSHOT ownership
```

### Подтверждено

```text
GVL_RUNTIME_EPOCH owner: PRG_Runtime_Barrier
GVL_RUNTIME_SNAPSHOT owner: PRG_Runtime_Snapshot_Governor
foreign assignments not found in current direct/search pass
```

### Drift candidate

```text
GVL_RUNTIME_EPOCH.Runtime_Snapshot_Valid
GVL_RUNTIME_EPOCH.Runtime_Snapshot_Published
```

Причина:

```text
snapshot-named state exists in runtime epoch GVL and may overlap with GVL_RUNTIME_SNAPSHOT.
Do not remove without direct reference sweep.
```

### Статус

```text
CLEAN_FOR_DIRECT_WRITERS_ORPHAN_CANDIDATE_PENDING_REFERENCE_SWEEP
```

---

## VALIDATION-W-003 — Distributed topology writer graph

### Проверка

```text
GVL_DISTRIBUTED_EPOCH / SNAPSHOT / COMMIT writer ownership
```

### Подтверждено

```text
GVL_DISTRIBUTED_EPOCH:
- peer inputs owned by PRG_Distributed_Peer_Ingestion
- aggregate fields owned by PRG_Distributed_Epoch_Governor

GVL_DISTRIBUTED_SNAPSHOT:
- peer inputs owned by PRG_Distributed_Snapshot_Ingestion
- aggregate fields owned by PRG_Distributed_Snapshot_Governor

GVL_DISTRIBUTED_COMMIT:
- peer inputs owned by PRG_Distributed_Commit_Ingestion
- aggregate fields owned by PRG_Distributed_Commit_Governor
```

### Статус

```text
FOUNDATION_RESTORED_RUNTIME_VALIDATION_PENDING
```

### Остаётся проверить

```text
real remote PLC transport/session/snapshot/commit replication backend
self-mirror and self-ack behavior when HA_Replication_Enabled becomes TRUE
```

---

## VALIDATION-W-004 — Mixed GVL writer graph

### Проверка

```text
GVL_STATUS / GVL_STATE / GVL_COMMAND / GVL_ALARM direct-write paths
```

### Подтверждено

```text
GVL_STATUS PLC role fields are owned by PRG_PLC_Arbitration.
GVL_STATUS and GVL_STATE are documented as mixed projection surfaces.
GVL_COMMAND is documented as legacy/operator request surface, not final output authority.
```

### Остаётся проверить

```text
field-level writer graph for GVL_STATE
field-level writer graph for GVL_ALARM
operator/HMI writers for GVL_COMMAND
legacy redundancy indirect invocation paths
```

### Статус

```text
BOUNDARY_CLASSIFIED_REFERENCE_SWEEP_PENDING
```

---

# 2. HARD-STOP GRAPH VALIDATION

## VALIDATION-H-001 — Pre-output hard-stop ownership

### Проверка

```text
GVL_COMMAND_VERIFY.PreOutput_Block_IO
```

### Подтверждено

```text
owner: PRG_PreOutput_Safety_Barrier
consumer: PRG_IO_Write
```

### Статус

```text
CONFIRMED_RESOLVED_FOR_KNOWN_DIRECT_PATHS
```

---

## VALIDATION-H-002 — Output freshness hard-stop inputs

### Проверка

```text
Output_Freshness consumes only aggregate authority surfaces
```

### Подтверждено

```text
Output_Freshness consumes distributed aggregate authority only,
not peer-detail diagnostics.
Recovery and observability do not write distributed/peer authority state.
```

### Статус

```text
PARTIALLY_CONFIRMED_FOR_DIRECT_PATHS
```

### Остаётся проверить

```text
mixed GVL consumer sweep
runtime validation after real HA backend replacement
```

---

# 3. ADVISORY LEAKAGE VALIDATION

## VALIDATION-A-001 — Observability / diagnostics authority leakage

### Подтверждено

```text
Observability remains downstream visibility-only.
Command verifier diagnostics do not mutate command shadow, IO or runtime/distributed authority.
Simulation GVL is isolated for known direct paths.
```

### Статус

```text
PARTIALLY_CONFIRMED_FOR_DIRECT_PATHS
```

### Остаётся проверить

```text
HMI/diagnostics consumers do not reinterpret advisory fields as hard-stop authority
GVL_STATE policy/semantic observability fields do not feed hard-stop paths directly
```

---

# 4. DISTRIBUTED VALIDATION

## VALIDATION-D-001 — Peer-input ingestion contract

### Текущий результат

```text
FOUNDATION_RESTORED
```

### Подтверждено

```text
explicit peer publication owner exists
explicit HA replication boundary exists
explicit peer ingestion owner exists
execution order restored in MAIN
stale peer fields clear on invalid HA session
```

### Всё ещё отсутствует

```text
real remote PLC transport/session replication backend
```

### Статус

```text
FOUNDATION_RESTORED_RUNTIME_VALIDATION_PENDING
```

---

## VALIDATION-D-002 — Snapshot ingestion contract

### Текущий результат

```text
FOUNDATION_RESTORED
```

### Подтверждено

```text
explicit snapshot publication owner exists
explicit HA snapshot boundary fields exist
explicit snapshot ingestion owner exists
execution order restored in MAIN before snapshot governor
stale peer snapshot fields clear on invalid HA session
```

### Всё ещё отсутствует

```text
real remote PLC snapshot replication backend
```

### Статус

```text
FOUNDATION_RESTORED_RUNTIME_VALIDATION_PENDING
```

---

## VALIDATION-D-003 — Commit ingestion contract

### Текущий результат

```text
FOUNDATION_RESTORED
```

### Подтверждено

```text
explicit commit publication owner exists
explicit HA commit boundary fields exist
explicit commit ingestion owner exists
execution order restored in MAIN before commit governor
stale peer commit ack fields clear on invalid HA session
```

### Всё ещё отсутствует

```text
real remote PLC commit acknowledgement backend
```

### Статус

```text
FOUNDATION_RESTORED_RUNTIME_VALIDATION_PENDING
```

---

## VALIDATION-D-004 — Mandatory HA backend replacement

### Проверка

```text
bounded loopback must not become production transport
```

### Текущий результат

```text
REQUIRED_REPLACEMENT_RECORDED
```

### Требование

```text
bounded loopback foundation must be replaced before
claiming real distributed runtime validation.
```

### Запрещено

```text
оставлять bounded loopback as permanent production implementation
переносить HA replication внутрь Modbus runtime transport
смешивать distributed reconciliation с transport replication layer
```

### Статус

```text
FOUNDATION_RESTORED_RUNTIME_VALIDATION_PENDING
```

---

# 5. COMPILE / REFERENCE CONVERGENCE

## VALIDATION-C-001 — New PRG call graph

### Проверить

```text
new PRGs are called exactly once from MAIN
```

Список:

```text
PRG_Peer_Heartbeat_Ingestion
PRG_Peer_Session_Publication
PRG_HA_Session_Replication
PRG_Distributed_Peer_Ingestion
PRG_Distributed_Snapshot_Publication
PRG_Distributed_Snapshot_Ingestion
PRG_Distributed_Commit_Publication
PRG_Distributed_Commit_Ingestion
```

### Статус

```text
VALIDATION_REQUIRED
```

---

## VALIDATION-C-002 — DUT requirements after new PRG/GVL additions

### Текущий результат

```text
NO_NEW_DUT_REQUIRED_AT_THIS_STAGE
```

### Причина

```text
new snapshot/commit/peer publication and ingestion PRGs use existing scalar types:
BOOL, UDINT, ULINT, STRING and existing GVL fields.
```

### Остаётся проверить

```text
future real HA backend may require structured session/transport DUTs.
Do not introduce them before real transport contract is designed.
```

### Статус

```text
CONFIRMED_FOR_CURRENT_PRG_ADDITIONS
```

---

## VALIDATION-C-003 — Legacy redundancy reachability

### Проверить

```text
FB_System_Redundancy_Orchestrator is not reachable from active runtime
```

### Подтверждено

```text
direct active path through PRG_System_Runtime_Base was removed
```

### Остаётся проверить

```text
indirect diagnostic / maintenance / HMI / simulation invocation paths
```

### Статус

```text
CONFIRMED_RESOLVED_FOR_ACTIVE_RUNTIME_PATH
```

---

# 6. CURRENT NEXT ACTIONS

Следующий порядок действий:

```text
1. compile/reference convergence for newly added PRGs and HA fields
2. refresh RUNTIME_FIELD_OWNERSHIP_MATRIX.md
3. field-level writer graph for GVL_STATE and GVL_ALARM
4. HMI/diagnostics/operator command consumer sweep
5. real HA backend design/replacement only after current graph converges
```

Запрещено:

```text
расширять cleanup без evidence
удалять mixed GVL fields без direct reference sweep
добавлять новые DUT/FB для HA backend до transport contract design
```
