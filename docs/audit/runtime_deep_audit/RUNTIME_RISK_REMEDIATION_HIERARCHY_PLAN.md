# ПЛАН RUNTIME-REMEDIATION: STRUCTURAL VALIDATION PHASE

## Назначение

Этот документ фиксирует не список удалений, а программу структурной валидации runtime-архитектуры после первичного cleanup, восстановления distributed peer/snapshot/commit topology, отключения legacy direct-state redundancy bypass и первичной классификации mixed GVL surfaces.

Текущий этап:

```text
post-cleanup structural validation + distributed topology restoration + legacy bypass containment + GVL ownership boundary classification
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
→ Distributed_Snapshot_Publication
→ Distributed_Snapshot_Ingestion
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
restored explicit distributed peer/snapshot/commit topology foundation
legacy direct-state redundancy bypass disconnected from runtime base
GVL_STATUS / GVL_STATE / GVL_COMMAND / GVL_SIMULATION ownership boundaries documented
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

## 3.3 Distributed snapshot topology restoration

Distributed snapshot peer fields переведены из orphan peer snapshot state в explicit topology:

```text
Runtime_Snapshot
→ PRG_Distributed_Snapshot_Publication
→ GVL_HA_SESSION_REPLICATION
→ PRG_Distributed_Snapshot_Ingestion
→ GVL_DISTRIBUTED_SNAPSHOT.Peer_*
→ PRG_Distributed_Snapshot_Governor
```

Исправлено:

```text
missing distributed snapshot publication owner
missing distributed snapshot peer ingestion owner
missing replicated snapshot handshake boundary
stale peer snapshot continuity after invalid HA session
phantom peer snapshot reconciliation risk
```

Влияние:

```text
D-RISK-002
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
snapshot publication/ingestion currently uses existing scalar fields only.
No new DUT is required by the newly added snapshot PRGs at this stage.
Real remote snapshot transport still requires HA backend replacement.
```

---

## 3.4 Distributed commit topology restoration

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

## 3.5 Legacy direct-state redundancy bypass containment

Найден активный runtime bypass:

```text
MAIN
→ PRG_System_Runtime_Base
→ FB_System_Redundancy_Orchestrator
→ FB_Redundancy_Manager
→ FB_State_Replication
→ direct GVL_STATUS / GVL_ALARM / GVL_STATE / GVL_COMMAND apply
```

Проблема:

```text
legacy redundancy path bypassed Runtime_Barrier, Runtime_Snapshot,
Distributed_Epoch, Distributed_Snapshot, Distributed_Commit,
Output_Freshness and new HA topology.
```

Исправлено:

```text
FB_System_Redundancy_Orchestrator disconnected from PRG_System_Runtime_Base.
ST_System_State_Snapshot marked as legacy direct-state replication snapshot.
```

Влияние:

```text
RISK-037
RISK-038
RISK-040
RISK-047
A-RISK-008
D-RISK-001
D-RISK-004
```

Статус:

```text
CONFIRMED_RESOLVED_FOR_ACTIVE_RUNTIME_PATH
```

Остаётся проверить:

```text
no remaining indirect invocation of FB_System_Redundancy_Orchestrator
no simulator/diagnostics/maintenance path can reconnect legacy direct-state apply
ownership matrix marks legacy redundancy subsystem frozen
```

---

## 3.6 Command authority ownership convergence

Command surfaces classified:

```text
GVL_COMMAND
    legacy/operator command request surface and verifier comparison source

GVL_COMMAND_SHADOW
    runtime operational command authority owned by PRG_Command_Arbitration

GVL_COMMAND_VERIFY.PreOutput_*
    pre-output hard-stop state owned by PRG_PreOutput_Safety_Barrier

GVL_COMMAND_VERIFY.Command_*/Runtime_*
    post-IO diagnostics owned by PRG_Command_Verifier
```

Исправлено:

```text
PRG_System_Init foreign writes to GVL_COMMAND_SHADOW removed.
GVL_COMMAND ownership boundary documented.
GVL_COMMAND_VERIFY split hard-stop/diagnostics ownership confirmed.
```

Влияние:

```text
RISK-015
RISK-038
RISK-040
RISK-047
A-RISK-001
P-RISK-001
```

Статус:

```text
CONFIRMED_RESOLVED_FOR_KNOWN_DIRECT_PATHS
```

Остаётся проверить:

```text
HMI/operator command writer graph for GVL_COMMAND
no diagnostics/debug path mutates GVL_COMMAND_SHADOW
```

---

## 3.7 Simulation boundary containment

Simulation/test surface classified:

```text
GVL_SIMULATION
    isolated simulation/test request and status surface
```

Проверено:

```text
PRG_System_Simulation writes only GVL_SIMULATION.
FB_Simulation_Manager does not mutate production authority state.
FB_Presence_Playback does not write production authority in current simulation call path.
G_Sim_* live production consumers were not found in current search.
```

Статус:

```text
CONFIRMED_ISOLATED_FOR_KNOWN_DIRECT_PATHS
```

Ограничение:

```text
injection request flags remain as test-control inputs.
A direct production injection bridge is not currently implemented.
Any future injection bridge requires explicit boundary review.
```

---

## 3.8 Mixed GVL ownership boundary classification

Classified and documented:

```text
GVL_STATUS
    mixed global status surface
    time fields owned by time service / monotonic flow
    PLC role fields owned by PRG_PLC_Arbitration
    diagnostics/domain/HMI fields are projections

GVL_STATE
    mixed global domain state surface
    sensor/input projections
    domain runtime projections
    physical/output feedback projections
    safety projections
    policy/allocation observability
    simulation/convenience residues
    diagnostics/explainability projections
```

Anti-regression rule:

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

## 3.9 Observability demotion

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

## 3.10 Semantic demotion

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

## 3.11 Dead-state / mirror pruning

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
transport-backed distributed validation gap + legacy bypass regression + mixed-GVL authority regression
```

То есть topology восстановлена и active legacy direct-state bypass отключён,
но bounded loopback foundation ещё не доказывает real peer divergence behavior.
Также mixed global surfaces now require reference-backed ownership matrix refresh.

Особенно опасны:

```text
self-mirroring HA replication
self-ack commit validation
ghost peer session after invalid HA transport
real remote fencing-token equality semantics
legacy direct-state redundancy reconnection
GVL_STATUS/GVL_STATE reinterpreted as hidden authority buses
simulation injection bridge added without boundary review
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
→ STAGE-E3 Validate real remote token/snapshot/commit semantics
→ STAGE-E4 Freeze legacy redundancy subsystem
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
distributed snapshot publication, distributed snapshot ingestion,
distributed commit publication and distributed commit ingestion stages.
Legacy FB_System_Redundancy_Orchestrator disconnected from PRG_System_Runtime_Base.
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
GVL_STATUS / GVL_STATE / GVL_COMMAND / GVL_ALARM legacy direct-write paths
GVL_SIMULATION test/injection surfaces
```

## Evidence required

Для каждого authority / replication / ingestion field:

```text
единственный authoritative writer
нет foreign reset
нет duplicate writer
нет projection writer в authority field
нет legacy direct-state bypass writer in active runtime path
нет simulation/test bridge into production authority without explicit review
```

## Статус

```text
IN_PROGRESS_AFTER_TOPOLOGY_AND_GVL_BOUNDARY_RESTORATION
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
Legacy direct-state redundancy runtime bypass was disconnected from PRG_System_Runtime_Base.
PreOutput_Block_IO is owned by PRG_PreOutput_Safety_Barrier and consumed by IO_Write.
```

Остаётся:

```text
runtime validation after real HA transport backend replacement
legacy subsystem freeze verification
mixed GVL consumer sweep
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
GVL_SIMULATION is isolated for known direct paths.
GVL_STATUS/GVL_STATE boundaries classify diagnostics/policy/simulation fields as projections unless proven otherwise.
```

Остаётся:

```text
HMI/diagnostics ownership sweep
legacy subsystem freeze verification
GVL_STATE field-level consumer sweep
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
real snapshot divergence can quarantine publication
real commit ack/replay behavior is not self-acknowledged
legacy direct-state redundancy cannot run in parallel
```

## Статус

```text
FOUNDATION_RESTORED_RUNTIME_VALIDATION_PENDING
```

Остаётся:

```text
replace bounded HA loopback with real PLC-to-PLC backend
validate real remote fencing token issuance/exchange
validate real remote snapshot exchange
validate real remote commit acknowledgement exchange
freeze legacy redundancy subsystem
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
legacy redundancy FBs are not reachable from active runtime
ownership matrix matches code
PART2 matches current plan
DUT requirements after new PRG/GVL additions
```

## Current DUT assessment

```text
New PRGs added for distributed snapshot publication/ingestion currently use existing scalar types only:
BOOL, UDINT, ULINT and existing GVL fields.
No new DUT is required at this stage.
```

## Статус

```text
IN_PROGRESS_AFTER_SNAPSHOT_TOPOLOGY_AND_GVL_BOUNDARY_CLASSIFICATION
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
legacy active runtime bypass found
mixed GVL authority reinterpretation found
simulation/test bridge bypass found
```

Запрещено:

```text
cleanup by intuition
удалять fields только потому что они выглядят лишними
переписывать topology без writer/hard-stop evidence
оставлять bounded loopback HA replication as production behavior
reconnecting legacy direct-state redundancy without governance review
using GVL_STATUS/GVL_STATE as hidden direct-state replication surfaces
adding simulation injection into production authority without explicit boundary review
```

---

# 13. Статусы remediation

Используются только эти статусы:

```text
CONFIRMED_RESOLVED
CONFIRMED_RESOLVED_FOR_KNOWN_DIRECT_PATHS
CONFIRMED_RESOLVED_FOR_KNOWN_REMOVED_FIELDS
CONFIRMED_RESOLVED_FOR_ACTIVE_RUNTIME_PATH
CONFIRMED_ISOLATED_FOR_KNOWN_DIRECT_PATHS
BOUNDARY_CLASSIFIED_REFERENCE_SWEEP_PENDING
STRUCTURALLY_REDUCED
FOUNDATION_RESTORED_RUNTIME_VALIDATION_PENDING
PARTIALLY_CONFIRMED_FOR_DIRECT_PATHS
VALIDATION_REQUIRED
UNVERIFIED_RUNTIME_BEHAVIOR
IN_PROGRESS
```

---

# 14. Текущий главный риск

```text
transport-backed distributed validation gap + legacy bypass regression + mixed-GVL authority regression
```

А не:

```text
missing semantic intelligence
```

Главный фокус:

```text
compile/reference convergence
ownership matrix update
PART2 sync
real HA backend replacement
legacy redundancy subsystem freeze
writer graph refresh
hard-stop graph validation
mixed GVL consumer sweep
```
