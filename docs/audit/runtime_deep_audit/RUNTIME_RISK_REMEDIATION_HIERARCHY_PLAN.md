# ПЛАН УСТРАНЕНИЯ RUNTIME-РИСКОВ С ВЛИЯНИЕМ НА РИСКИ АУДИТА

## Назначение

Документ фиксирует remediation-граф, а не линейную сводку.

Формат:

```text
риск аудита
→ корневая причина
→ правильный порядок исправления
→ затронутые файлы
→ влияние на другие риски
→ что ещё не проверено
```

---

# 0. Подтверждённые audit risk IDs

Из текущего remediation-context подтверждены следующие audit IDs:

```text
RISK-015 — command/execution divergence
RISK-037 — scan-cycle visibility gap
RISK-038 — post-arbitration mutation window
RISK-040 — verifier-after-IO physical unsafe window
RISK-047 — stale/unsafe output survivability foundation
```

Дополнительные runtime-группы используются только как временные internal buckets до полной сверки с соседними audit-файлами:

```text
A-RISK-* — authority / ownership
D-RISK-* — distributed runtime
S-RISK-* — semantic authority
O-RISK-* — observability authority
P-RISK-* — physical publication/output
C-RISK-* — compile/reference consistency
```

Что не доделано:

```text
перечитать все соседние файлы docs/audit/runtime_deep_audit
и заменить временные buckets на реальные номера рисков, где они есть
```

---

# 1. Текущее runtime topology

```text
Time_Monotonic
→ PLC_Fencing
→ Transport_Freshness
→ Runtime_Barrier
→ Runtime_Snapshot
→ Distributed_Epoch
→ Distributed_Snapshot
→ Distributed_Commit
→ Semantic_Progress
→ Output_Freshness
→ IO_Write
```

Текущее состояние:

```text
compressed deterministic runtime governance
```

---

# 2. Правильная последовательность исправлений

Правильный порядок remediation:

```text
STAGE-00 Compile/reference baseline
→ STAGE-01 Root runtime authority
→ STAGE-02 Immutable runtime snapshot boundary
→ STAGE-03 Output hard-stop boundary
→ STAGE-04 Distributed peer-optional foundation
→ STAGE-05 Observability demotion
→ STAGE-06 Semantic demotion
→ STAGE-07 Dead-state / mirror pruning
→ STAGE-08 Final validation
```

Почему именно так:

```text
сначала чинится authority graph,
потом publication boundary,
потом output hard-stop,
и только потом semantic / observability / telemetry cleanup
```

Иначе возникают ложные патчи:

```text
semantic patch поверх broken runtime authority
observability patch поверх recursive invalidation
telemetry patch поверх missing peer topology
```

---

# 3. Матрица влияния исправлений на риски

| Исправление | Прямо закрывает | Также влияет на | Статус |
|---|---|---|---|
| Удаление `Runtime_Barrier ↔ Recovery_Governance` | A-RISK-001 | RISK-037, RISK-047 | MOSTLY_RESOLVED |
| Удаление `Runtime_Snapshot ↔ Output_Freshness` | A-RISK-006, P-RISK-001 | RISK-038, RISK-040, RISK-047 | MOSTLY_RESOLVED |
| Очистка hard-stop границ Output_Freshness | P-RISK-001..004 | RISK-015, RISK-037, RISK-038, RISK-040, RISK-047 | MOSTLY_RESOLVED |
| Перевод distributed в peer-optional mode | D-RISK-001..004 | RISK-037, RISK-047 | MOSTLY_RESOLVED |
| Демонтаж observability authority | O-RISK-001..004 | RISK-037, RISK-040 | MOSTLY_RESOLVED |
| Semantic advisory-only | S-RISK-001..004 | RISK-047 | MOSTLY_RESOLVED |
| Удаление forced-safe / invalidation mirrors | D-RISK-005, A-RISK-007 | RISK-047 | MOSTLY_RESOLVED |
| Compile/reference pass | C-RISK-001..004 | все runtime risks | IN_PROGRESS |

---

# 4. STAGE-00 — Compile/reference baseline

## Цель

Исключить:

```text
missing PRG calls
removed PRG references
undeclared GVL fields
stale zombie fields
```

## Риски

```text
C-RISK-001 — missing program reference
C-RISK-002 — undeclared GVL field
C-RISK-003 — stale deleted layer call
C-RISK-004 — plan/code drift
```

## Уже выполнено

```text
проверен MAIN.st active PRG chain
проверены удалённые semantic observability calls
добавлено GVL_OUTPUT_EPOCH.Output_Semantic_Continuity_Warning
```

## Влияние

```text
влияет на все runtime risks,
потому что stale references ломают любую remediation достоверность
```

## Что не доделано

```text
полная сверка всех GVL-полей после последних removals
проверка compiler diagnostics после final cleanup
сверка временных risk buckets с реальными audit IDs
```

---

# 5. STAGE-01 — Root runtime authority

## Цель

Root authority должен быть первым уровнем runtime-решений.

Файлы:

```text
PRG_Time_Monotonic_Governor.st
PRG_PLC_Fencing_Governor.st
PRG_Transport_Freshness_Governor.st
PRG_Runtime_Barrier.st
PRG_Recovery_Cleanup_Governor.st
```

## Риски

```text
A-RISK-001 — recursive runtime governance
A-RISK-002 — PLC ownership ambiguity
A-RISK-003 — transport freshness bypass
A-RISK-004 — runtime authority pollution
```

## Влияние на audit risks

```text
RISK-037
RISK-038
RISK-047
```

## Уже выполнено

```text
Runtime_Barrier очищен от observability authority leakage
Runtime_Barrier очищен от diagnostics/explainability sync authority
Recovery_Governance переведён в downstream cleanup governance
```

## Cross-impact

Является prerequisite для:

```text
STAGE-02 Runtime Snapshot
STAGE-03 Output Hard-stop Boundary
STAGE-05 Observability Demotion
```

## Что не доделано

```text
проверить indirect consumers Runtime_Runtime_Barrier_OK
проверить отсутствие recovery feedback fanout
проверить отсутствие diagnostics/explainability authority feedback
```

---

# 6. STAGE-02 — Immutable runtime snapshot boundary

## Цель

Snapshot должен быть immutable publication boundary между runtime authority и downstream publication.

Файлы:

```text
GVL_RUNTIME_SNAPSHOT.gvl
PRG_Runtime_Snapshot_Governor.st
```

## Риски

```text
A-RISK-005 — mutable runtime publication leakage
A-RISK-006 — Runtime_Snapshot ↔ Output_Freshness recursion
A-RISK-007 — fake snapshot synchronization authority
P-RISK-001 — output publication from unstable runtime state
```

## Влияние на audit risks

```text
RISK-038
RISK-040
RISK-047
```

## Уже выполнено

Удалено:

```text
Runtime_Snapshot dependency on Output_Forced_Safe_Decay
Snapshot_Observability_Synchronized
Snapshot_Invalidation_Count
```

Текущий порядок:

```text
Runtime_Barrier
→ Runtime_Snapshot
→ Output_Freshness
```

## Cross-impact

Снижает:

```text
P-RISK-001
O-RISK-002
A-RISK-006
```

## Что не доделано

```text
проверить все записи в GVL_RUNTIME_SNAPSHOT
проверить, что Snapshot_Runtime_Authority_Valid не стал duplicate mirror
проверить отсутствие hidden downstream dependencies
```

---

# 7. STAGE-03 — Pre-output и output hard-stop boundary

## Цель

Physical outputs должны блокироваться только физически значимыми authority failures.

Файлы:

```text
PRG_PreOutput_Safety_Barrier.st
PRG_Output_Freshness_Governor.st
PRG_IO_Write.st
GVL_OUTPUT_EPOCH.gvl
```

## Риски

```text
P-RISK-001 — unsafe output survivability
P-RISK-002 — stale output publication
P-RISK-003 — command/output divergence
P-RISK-004 — hard-stop authority overreach
```

## Влияние на audit risks

```text
RISK-015
RISK-037
RISK-038
RISK-040
RISK-047
```

## Уже выполнено

```text
semantic hard-stop removed
observability hard-stop removed
output freshness оставлен physical publication authority
IO_Write использует output freshness как final hard-stop input
```

## Разрешённые hard-stop authorities

```text
runtime barrier invalidation
immutable snapshot invalidation
transport freshness invalidation
real distributed reconciliation failure
explicit peer fencing conflict
pre-output safety failure
```

## Cross-impact

Снижает:

```text
S-RISK-001
O-RISK-001
D-RISK-003
```

## Что не доделано

```text
проверить все причины Output_Forced_Safe_Decay
проверить, что IO_Write не добавляет speculative gates
проверить отсутствие advisory signals в hard-stop path
```

---

# 8. STAGE-04 — Distributed peer-optional foundation

## Цель

Distributed layers должны быть publication-continuity foundation, а не startup failure generator.

Файлы:

```text
GVL_DISTRIBUTED_EPOCH.gvl
GVL_DISTRIBUTED_SNAPSHOT.gvl
GVL_DISTRIBUTED_COMMIT.gvl
PRG_Distributed_Epoch_Governor.st
PRG_Distributed_Snapshot_Governor.st
PRG_Distributed_Commit_Governor.st
```

## Риски

```text
D-RISK-001 — missing peer treated as failure
D-RISK-002 — startup distributed quarantine storm
D-RISK-003 — distributed fake output decay
D-RISK-004 — peer replay detection before peer session
D-RISK-005 — duplicate distributed degraded-state mirrors
```

## Влияние на audit risks

```text
RISK-037
RISK-047
```

## Уже выполнено

Distributed governors переведены в:

```text
peer-optional foundation mode
```

Удалены:

```text
Distributed_Snapshot_Forced_Safe_Mode
Distributed_Snapshot_Invalidation_Count
Distributed_Commit_Forced_Safe_Mode
Distributed_Commit_Invalidation_Count
```

## Текущее правило

```text
missing peer != divergence
missing peer != quarantine
missing peer != replay
missing peer != output decay
```

## Cross-impact

Снижает:

```text
P-RISK-002
A-RISK-004
O-RISK-003
```

## Что не доделано

```text
проверить GVL_DISTRIBUTED_EPOCH на remaining forced-safe mirrors
проверить Distributed_Quarantine_Active consumers
проверить peer-session activation criteria
проверить, что real peer divergence всё ещё блокирует publication
```

---

# 9. STAGE-05 — Observability demotion

## Цель

Observability должен быть downstream visibility layer, а не runtime authority.

Файлы:

```text
GVL_OBSERVABILITY_AUTHORITY.gvl
PRG_Observability_Governor.st
PRG_Distributed_Commit_Observability.st
```

## Риски

```text
O-RISK-001 — observability authority leakage
O-RISK-002 — diagnostics/explainability publication blocking
O-RISK-003 — reset-owned visibility races
O-RISK-004 — fake observability synchronization barriers
```

## Влияние на audit risks

```text
RISK-037
RISK-040
```

## Уже выполнено

Удалены:

```text
PreActuation_Visibility_Ready
Diagnostics_Synchronized
Explainability_Synchronized
Authority_Snapshot_Valid
Observability_Quarantine_Active
Observability_Invalidation_Count
```

Observability приведён к:

```text
downstream visibility aggregation only
```

## Cross-impact

Снижает:

```text
A-RISK-004
P-RISK-004
S-RISK-002
```

## Что не доделано

```text
проверить все записи в GVL_OBSERVABILITY_AUTHORITY
проверить отсутствие foreign writes в visibility fields
проверить необходимость Distributed_*_Visible fields
```

---

# 10. STAGE-06 — Semantic demotion

## Цель

Semantic continuity не должна быть runtime authority без operational evidence.

Файлы:

```text
PRG_Semantic_Progress_Governor.st
GVL_SEMANTIC_PROGRESS.gvl
PRG_Output_Freshness_Governor.st
GVL_OUTPUT_EPOCH.gvl
```

## Риски

```text
S-RISK-001 — semantic hard-stop authority leakage
S-RISK-002 — speculative semantic observability fanout
S-RISK-003 — semantic commit without real peer feed
S-RISK-004 — semantic suspicion treated as physical failure
```

## Влияние на audit risks

```text
RISK-047
```

## Уже выполнено

```text
semantic hard-stop removed from Output_Freshness
Semantic_Progress оставлен advisory-only
Output_Semantic_Continuity_Warning добавлен как non-blocking signal
semantic commit остаётся dormant
```

## Cross-impact

Снижает:

```text
P-RISK-004
O-RISK-001
D-RISK-003
```

## Что не доделано

```text
проверить, что Semantic_Progress_Quarantine_Active нигде не hard-stop
проверить dormant semantic commit references
проверить отсутствие semantic visibility escalation
```

---

# 11. STAGE-07 — Dead-state / mirror pruning

## Цель

Удалить runtime entropy:

```text
orphan fields
stale counters
duplicate mirrors
unreachable quarantine states
```

## Риски

```text
A-RISK-008 — authority mirror duplication
D-RISK-005 — duplicate distributed degraded-state mirrors
O-RISK-004 — fake synchronization barriers
C-RISK-004 — plan/code drift
```

## Уже выполнено

Удалены:

```text
Snapshot_Observability_Synchronized
Snapshot_Invalidation_Count
Distributed_Snapshot_Forced_Safe_Mode
Distributed_Snapshot_Invalidation_Count
Distributed_Commit_Forced_Safe_Mode
Distributed_Commit_Invalidation_Count
Authority_Snapshot_Valid
Observability_Quarantine_Active
Observability_Invalidation_Count
```

## Что не доделано

```text
проверить GVL_DISTRIBUTED_EPOCH
проверить GVL_OUTPUT_EPOCH на stale mirrors
проверить GVL_OBSERVABILITY_AUTHORITY на orphan visibility fields
```

---

# 12. STAGE-08 — Final validation

## Цель

Подтвердить, что topology стала:

```text
acyclic
minimal
deterministic
runtime-authoritative
```

## Нужно проверить

```text
нет duplicate writers
нет foreign resets
нет hidden authority cycles
нет advisory hard-stop paths
нет missing compile references
```

## Статус

```text
IN_PROGRESS
```

---

# 13. Текущие запреты

Запрещено:

```text
re-expand speculative governance
reintroduce forced-safe mirrors
create recursive synchronization
make visibility runtime-authoritative
use semantic heuristics as hard-stop authority
```

Предпочтительно:

```text
single-direction authority flow
minimal deterministic topology
compressed runtime governance
peer-optional distributed foundations
runtime-backed authority only
advisory-only semantic continuity
```
