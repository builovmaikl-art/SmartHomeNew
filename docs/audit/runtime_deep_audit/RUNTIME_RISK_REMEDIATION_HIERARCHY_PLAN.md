# ПЛАН RUNTIME-REMEDIATION: STRUCTURAL VALIDATION PHASE

## Назначение

Этот документ фиксирует не список удалений, а программу структурной валидации runtime-архитектуры после первичного cleanup и последующего восстановления distributed peer/commit topology.

Текущий этап:

```text
post-cleanup structural validation + distributed topology restoration
```

Главный принцип:

```text
сначала доказать нарушение через graph / ownership / hard-stop validation,
только потом менять код
```

---

# 0. Связанные документы

```text
RUNTIME_RISK_REMEDIATION_HIERARCHY_PLAN.md
    основной план, этапы, риски, порядок действий

RUNTIME_RISK_REMEDIATION_HIERARCHY_PLAN_PART2.md
    рабочая матрица структурной валидации и evidence criteria

RUNTIME_FIELD_OWNERSHIP_MATRIX.md
    ownership truth table и anti-regression guard
```

---

# 1. Подтверждённые риски аудита

В текущем remediation-context подтверждены следующие audit IDs:

```text
RISK-015 — command/execution divergence
RISK-037 — scan-cycle visibility gap
RISK-038 — post-arbitration mutation window
RISK-040 — verifier-after-IO physical unsafe window
RISK-047 — stale/unsafe output survivability foundation
```

Временные группы используются только для структурной декомпозиции, пока не завершена полная сверка соседних audit-файлов:

```text
A-RISK-* — authority / ownership
P-RISK-* — publication / physical output
D-RISK-* — distributed reconciliation
O-RISK-* — observability authority leakage
S-RISK-* — semantic authority leakage
C-RISK-* — compile/reference consistency
V-RISK-* — validation coverage gaps
```

Нельзя считать временный bucket заменой audit ID.

---

# 2. Текущая runtime topology

Текущая validated directionality после remediation:

```text
Time_Monotonic
→ Transport_Freshness
→ PLC_Fencing
→ Runtime_Barrier
→ Runtime_Snapshot
→ Peer_Session_Publication
→ HA_Session_Replication
→ Distributed_Peer_Ingestion
→ Distributed_Epoch
→ Distributed_Snapshot
→ Distributed_Commit_Publication
→ Distributed_Commit_Ingestion
→ Distributed_Commit
→ Semantic_Progress
→ Observability
→ Recovery_Cleanup
→ Domain execution
→ PreOutput_Barrier
→ Output_Freshness
→ IO_Write
→ Command_Verifier
→ Diagnostics / HMI
```

Текущее состояние:

```text
restored explicit distributed peer/commit topology foundation
```

Ограничение:

```text
HA_Session_Replication currently remains bounded loopback foundation.
Real PLC-to-PLC HA transport backend is still required before claiming real distributed runtime validation.
```

---

# 3. Что уже исправлено

## 3.1 Recursive authority cycles

Устранены:

```text
Runtime_Barrier ↔ Recovery_Governance
Runtime_Snapshot ↔ Output_Freshness
Observability ↔ Runtime authority
Semantic continuity ↔ Physical publication authority
Distributed snapshot/commit ↔ downstream output publication epoch
```

Влияние:

```text
RISK-037
RISK-038
RISK-040
RISK-047
A-RISK-001
A-RISK-006
P-RISK-001
O-RISK-001
S-RISK-001
```

Статус:

```text
CONFIRMED_RESOLVED_FOR_KNOWN_DIRECT_PATHS
```

Остаётся проверить:

```text
runtime evidence on PLC execution
secondary diagnostics/HMI paths after future transport backend replacement
```

---

## 3.2 Distributed peer normalization and ingestion restoration

Distributed layers переведены из orphan peer fields в explicit topology:

```text
physical peer heartbeat
→ PRG_Peer_Heartbeat_Ingestion
→ PRG_PLC_Arbitration
→ PRG_PLC_Fencing_Governor
→ PRG_Peer_Session_Publication
→ GVL_PEER_SESSION
→ PRG_HA_Session_Replication
→ GVL_HA_SESSION_REPLICATION
→ PRG_Distributed_Peer_Ingestion
→ PRG_Distributed_Epoch_Governor
```

Исправлено:

```text
missing heartbeat ingestion bridge
missing peer-input ingestion owner
stale peer fields after invalid HA session
distributed peer ownership ambiguity
```

Влияние:

```text
RISK-037
RISK-047
D-RISK-001
D-RISK-002
D-RISK-003
D-RISK-004
```

Статус:

```text
FOUNDATION_RESTORED_RUNTIME_VALIDATION_PENDING
```

Ограничение:

```text
real remote PLC transport/session replication backend is not implemented yet.
PRG_HA_Session_Replication is temporary bounded loopback foundation only.
```

Запрещено:

```text
оставлять bounded loopback as permanent production implementation
удалять transitional fencing suppression before real remote token transport exists
```

---

## 3.3 Distributed commit topology restoration

Distributed commit peer fields переведены из orphan handshake state в explicit topology:

```text
Distributed_Snapshot
→ PRG_Distributed_Commit_Publication
→ GVL_HA_SESSION_REPLICATION
→ PRG_Distributed_Commit_Ingestion
→ GVL_DISTRIBUTED_COMMIT.Peer_*
→ PRG_Distributed_Commit_Governor
```

Исправлено:

```text
missing commit peer ingestion owner
missing replicated commit handshake boundary
stale peer commit ack continuity after invalid HA session
phantom peer commit session risk
```

Влияние:

```text
D-RISK-003
D-RISK-004
RISK-047
C-RISK-004
```

Статус:

```text
FOUNDATION_RESTORED_RUNTIME_VALIDATION_PENDING
```

Ограничение:

```text
self-ack risk remains if bounded loopback is enabled and treated as real remote transport.
Real remote commit acknowledgement transport is still required.
```

---

## 3.4 Observability demotion

Observability приведён к:

```text
downstream visibility aggregation only
```

Удалены legacy authority residues и добавлена missing distributed commit visibility coverage.

Влияние:

```text
RISK-037
RISK-040
O-RISK-001
O-RISK-002
O-RISK-003
O-RISK-004
```

Статус:

```text
CONFIRMED_RESOLVED_FOR_KNOWN_DIRECT_PATHS
```

Остаётся проверить:

```text
HMI/diagnostics consumers after ownership matrix refresh
```

---

## 3.5 Semantic demotion

Semantic continuity переведён в:

```text
advisory-only
```

Output получает только warning:

```text
GVL_OUTPUT_EPOCH.Output_Semantic_Continuity_Warning
```

Влияние:

```text
RISK-047
S-RISK-001
S-RISK-004
P-RISK-004
```

Статус:

```text
CONFIRMED_RESOLVED_FOR_KNOWN_DIRECT_PATHS
```

Остаётся проверить:

```text
future diagnostics/HMI paths do not reinterpret semantic warning as hard-stop authority
```

---

## 3.6 Dead-state / mirror pruning

Удалены duplicate degraded-state mirrors and verified removed-field convergence, including:

```text
Snapshot_Observability_Synchronized
Snapshot_Invalidation_Count
Distributed_Forced_Safe_Mode
Distributed_Invalidation_Count
Distributed_Snapshot_Forced_Safe_Mode
Distributed_Snapshot_Invalidation_Count
Distributed_Commit_Forced_Safe_Mode
Distributed_Commit_Invalidation_Count
GVL_CONFIG_VALIDATION.G_Runtime_*
GVL_DISTRIBUTED_COMMIT.Local_Commit_Token
GVL_DISTRIBUTED_COMMIT.Peer_Commit_Token
```

Влияние:

```text
RISK-047
A-RISK-008
D-RISK-005
C-RISK-004
```

Статус:

```text
CONFIRMED_RESOLVED_FOR_KNOWN_REMOVED_FIELDS
```

Остаётся проверить:

```text
fresh compile/reference sweep after latest PRG additions
ownership matrix update
```

---

# 4. Текущее понимание после remediation

Ранее главный риск выглядел как:

```text
speculative semantic / observability governance
```

Сейчас главный remaining risk:

```text
transport-backed distributed validation gap
```

То есть topology восстановлена, но bounded loopback foundation ещё не доказывает real peer divergence behavior.

Особенно опасны:

```text
self-mirroring HA replication
self-ack commit validation
ghost peer session after invalid HA transport
real remote fencing-token equality semantics
```

---

# 5. Новый порядок работ

Дальше запрещён blind cleanup.

Правильный порядок:

```text
STAGE-A Freeze current topology
→ STAGE-B Build writer graph
→ STAGE-C Build hard-stop graph
→ STAGE-D Build advisory leakage graph
→ STAGE-E Validate distributed peer behavior
→ STAGE-E2 Replace bounded HA loopback with real transport backend
→ STAGE-E3 Validate real remote token/commit semantics
→ STAGE-F Compile/reference convergence
→ STAGE-G Targeted remediation only if evidence exists
→ STAGE-H Update plans and ownership matrix
```

---

# 6. STAGE-A — Freeze current topology

## Цель

Зафиксировать фактический execution graph перед следующими правками.

## Статус

```text
FOUNDATION_RESTORED_NEEDS_MATRIX_REFRESH
```

Evidence:

```text
MAIN now contains explicit peer heartbeat, peer session publication,
HA session replication, distributed peer ingestion,
distributed commit publication and distributed commit ingestion stages.
```

---

# 7. STAGE-B — Writer graph validation

## Цель

Построить реальный writer/reset graph.

## Проверяемые GVL

```text
GVL_RUNTIME_EPOCH
GVL_RUNTIME_SNAPSHOT
GVL_OUTPUT_EPOCH
GVL_DISTRIBUTED_EPOCH
GVL_DISTRIBUTED_SNAPSHOT
GVL_DISTRIBUTED_COMMIT
GVL_PEER_SESSION
GVL_HA_SESSION_REPLICATION
GVL_OBSERVABILITY_AUTHORITY
GVL_SEMANTIC_PROGRESS
```

## Evidence required

Для каждого authority / replication / ingestion field:

```text
единственный authoritative writer
нет foreign reset
нет duplicate writer
нет projection writer в authority field
```

## Статус

```text
IN_PROGRESS_AFTER_TOPOLOGY_RESTORATION
```

---

# 8. STAGE-C — Hard-stop graph validation

## Цель

Доказать, что output hard-stop получает только physical-authoritative причины.

## Статус

```text
PARTIALLY_CONFIRMED_FOR_DIRECT_PATHS
```

Evidence:

```text
IO_Write consumes Output_Forced_Safe_Decay as final output freshness hard-stop.
Output_Freshness consumes distributed aggregate authority only, not peer-detail diagnostics.
Recovery and observability do not write distributed/peer authority state.
```

Остаётся:

```text
runtime validation after real HA transport backend replacement
```

---

# 9. STAGE-D — Advisory leakage validation

## Цель

Проверить, что advisory fields не становятся authority через downstream consumers.

## Статус

```text
PARTIALLY_CONFIRMED_FOR_DIRECT_PATHS
```

Evidence:

```text
Observability remains downstream visibility-only.
Semantic continuity remains advisory-only for Output_Freshness.
```

Остаётся:

```text
HMI/diagnostics ownership sweep
```

---

# 10. STAGE-E — Distributed peer behavior validation

## Цель

Проверить, что peer-optional mode не сломал real peer failure detection.

## Evidence required

```text
startup without peer remains valid
missing peer does not quarantine
real peer session activates validation
real peer mismatch can quarantine publication
real peer fencing conflict still hard-stops output
real commit ack/replay behavior is not self-acknowledged
```

## Статус

```text
FOUNDATION_RESTORED_RUNTIME_VALIDATION_PENDING
```

Остаётся:

```text
replace bounded HA loopback with real PLC-to-PLC backend
validate real remote fencing token issuance/exchange
validate real remote commit acknowledgement exchange
```

---

# 11. STAGE-F — Compile/reference convergence

## Цель

Подтвердить, что cleanup и topology restoration не оставили stale references.

## Проверить

```text
removed fields are not referenced
new PRGs are called exactly once from MAIN
new GVLs are declared and consumed by intended owners
ownership matrix matches code
PART2 matches current plan
```

## Статус

```text
IN_PROGRESS_AFTER_NEW_PRG_ADDITIONS
```

---

# 12. STAGE-G — Targeted remediation only

Новые изменения кода разрешены только при evidence:

```text
duplicate writer found
foreign reset found
hidden hard-stop path found
advisory leakage found
stale compile reference found
real topology cycle found
self-ack / self-mirror validation found
```

Запрещено:

```text
cleanup by intuition
удалять fields только потому что они выглядят лишними
переписывать topology без writer/hard-stop evidence
оставлять bounded loopback HA replication as production behavior
```

---

# 13. Статусы remediation

Используются только эти статусы:

```text
CONFIRMED_RESOLVED                доказано кодом и reference validation
CONFIRMED_RESOLVED_FOR_KNOWN_DIRECT_PATHS
CONFIRMED_RESOLVED_FOR_KNOWN_REMOVED_FIELDS
STRUCTURALLY_REDUCED              структура исправлена, но runtime evidence ещё нужна
FOUNDATION_RESTORED_RUNTIME_VALIDATION_PENDING
PARTIALLY_CONFIRMED_FOR_DIRECT_PATHS
VALIDATION_REQUIRED               гипотеза или зона риска, нужна проверка
UNVERIFIED_RUNTIME_BEHAVIOR        поведение не подтверждено runtime evidence
IN_PROGRESS                        работа идёт
```

---

# 14. Текущий главный риск

```text
transport-backed distributed validation gap
```

А не:

```text
missing semantic intelligence
```

Главный фокус:

```text
real HA backend replacement
writer graph refresh
hard-stop graph validation
compile/reference convergence
ownership matrix update
```
