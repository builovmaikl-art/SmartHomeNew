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

Текущее правило:

```text
peer-session publication
HA/session replication
peer ingestion
and distributed reconciliation
are now explicitly separated ownership layers.
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
Distributed_Epoch / Distributed_Snapshot / Distributed_Commit
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
Observability
```

---

# 6. DISTRIBUTED VALIDATION

## Новая архитектурная модель

Distributed layer теперь:

```text
explicit peer-session ingestion and HA replication topology
```

Текущая модель:

```text
runtime authority
    ↓
peer session publication
    ↓
HA/session replication boundary
    ↓
distributed peer ingestion
    ↓
distributed reconciliation governors
```

Важно:

```text
Modbus RTU SysCom transport remains isolated byte/frame transport.
HA peer replication must not contaminate Modbus runtime transport layers.
```

Дополнительное ограничение:

```text
bounded loopback replication is validation scaffolding only.
It must not become permanent runtime architecture.
```

---

## VALIDATION-D-003

### Проверка

```text
peer-input ingestion contract
```

### Текущий результат

```text
FOUNDATION_RESTORED
```

### Подтверждено

```text
explicit publication owner exists
explicit HA replication boundary exists
explicit peer ingestion owner exists
execution order restored in MAIN
```

### Всё ещё отсутствует

```text
real remote PLC transport/session replication backend
```

### Требование

```text
bounded loopback foundation must be replaced before
claiming real distributed runtime validation.
```

### Статус

```text
FOUNDATION_RESTORED_RUNTIME_VALIDATION_PENDING
```
