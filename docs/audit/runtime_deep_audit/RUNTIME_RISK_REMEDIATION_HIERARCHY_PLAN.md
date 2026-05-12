# ПЛАН RUNTIME-REMEDIATION: STRUCTURAL VALIDATION PHASE

## Назначение

Этот документ фиксирует не список удалений, а программу структурной валидации runtime-архитектуры после первичного cleanup.

Текущий этап:

```text
post-cleanup structural validation
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

Но это состояние ещё не является финально доказанным runtime evidence.

---

# 3. Что уже исправлено

## 3.1 Recursive authority cycles

Устранены:

```text
Runtime_Barrier ↔ Recovery_Governance
Runtime_Snapshot ↔ Output_Freshness
Observability ↔ Runtime authority
Semantic continuity ↔ Physical publication authority
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
STRUCTURALLY_REDUCED
```

Не доказано полностью:

```text
нет indirect feedback через вторичные fields
нет downstream-driven invalidation через transitively consumed flags
```

---

## 3.2 Distributed peer normalization

Distributed layers переведены в:

```text
peer-optional foundation mode
```

Удалена старая модель:

```text
missing peer = distributed failure
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
STRUCTURALLY_REDUCED
```

Не доказано полностью:

```text
корректность peer-session activation при реальном peer
корректность real divergence hard-stop
отсутствие startup quarantine fanout
```

---

## 3.3 Observability demotion

Observability приведён к:

```text
downstream visibility aggregation only
```

Удалены legacy authority residues:

```text
PreActuation_Visibility_Ready
Diagnostics_Synchronized
Explainability_Synchronized
Authority_Snapshot_Valid
Observability_Quarantine_Active
Observability_Invalidation_Count
```

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
STRUCTURALLY_REDUCED
```

Не доказано полностью:

```text
нет foreign writes в visibility escalation fields
нет observability-driven resets
нет indirect HMI/diagnostics escalation в hard-stop path
```

---

## 3.4 Semantic demotion

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
STRUCTURALLY_REDUCED
```

Не доказано полностью:

```text
нет semantic quarantine fanout
нет semantic-driven output invalidation
нет dormant semantic commit leakage
```

---

## 3.5 Dead-state / mirror pruning

Удалены duplicate degraded-state mirrors:

```text
Snapshot_Observability_Synchronized
Snapshot_Invalidation_Count
Distributed_Forced_Safe_Mode
Distributed_Invalidation_Count
Distributed_Snapshot_Forced_Safe_Mode
Distributed_Snapshot_Invalidation_Count
Distributed_Commit_Forced_Safe_Mode
Distributed_Commit_Invalidation_Count
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
STRUCTURALLY_REDUCED
```

Не доказано полностью:

```text
нет оставшихся mirror fields в GVL_OUTPUT_EPOCH
нет orphan visibility fields
нет stale references после removals
```

---

# 4. Новое понимание после cleanup

Ранее главный риск выглядел как:

```text
speculative semantic / observability governance
```

Сейчас главный remaining risk:

```text
implicit authority propagation
```

То есть слой формально advisory или downstream, но другой downstream-код начинает трактовать его состояние как authority.

Это особенно опасно в:

```text
GVL_OUTPUT_EPOCH
GVL_RUNTIME_EPOCH
GVL_RUNTIME_SNAPSHOT
GVL_OBSERVABILITY_AUTHORITY
GVL_DISTRIBUTED_*
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
→ STAGE-F Compile/reference convergence
→ STAGE-G Targeted remediation only if evidence exists
→ STAGE-H Update plans and ownership matrix
```

---

# 6. STAGE-A — Freeze current topology

## Цель

Зафиксировать фактический execution graph перед следующими правками.

## Нужно получить

```text
MAIN.st PRG order
runtime authority order
snapshot publication order
distributed order
output/IO order
observability order
```

## Связанные риски

```text
RISK-037
RISK-038
RISK-040
RISK-047
C-RISK-004
```

## Статус

```text
IN_PROGRESS
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
GVL_OBSERVABILITY_AUTHORITY
GVL_SEMANTIC_PROGRESS
```

## Evidence required

Для каждого authority field:

```text
единственный authoritative writer
нет foreign reset
нет duplicate writer
нет projection writer в authority field
```

## Связанные риски

```text
A-RISK-008
O-RISK-003
P-RISK-004
C-RISK-004
```

## Статус

```text
IN_PROGRESS
```

---

# 8. STAGE-C — Hard-stop graph validation

## Цель

Доказать, что output hard-stop получает только physical-authoritative причины.

## Проверяемые поля

```text
GVL_OUTPUT_EPOCH.Output_Forced_Safe_Decay
GVL_OUTPUT_EPOCH.Output_Publication_Valid
GVL_COMMAND_VERIFY.PreOutput_Block_IO
GVL_RUNTIME_EPOCH.Runtime_IO_Publication_Allowed
GVL_RUNTIME_SNAPSHOT.*
GVL_DISTRIBUTED_*.*Quarantine_Active
```

## Разрешённые hard-stop причины

```text
runtime barrier invalidation
immutable snapshot invalidation
transport freshness invalidation
real distributed reconciliation failure
explicit peer fencing conflict
pre-output safety failure
```

## Запрещённые hard-stop причины

```text
semantic suspicion
observability visibility
telemetry stabilization
explainability synchronization
diagnostics projections
trend/history delays
```

## Связанные audit risks

```text
RISK-015
RISK-038
RISK-040
RISK-047
```

## Статус

```text
VALIDATION_REQUIRED
```

---

# 9. STAGE-D — Advisory leakage validation

## Цель

Проверить, что advisory fields не становятся authority через downstream consumers.

## Проверяемые advisory fields

```text
Output_Semantic_Continuity_Warning
Semantic_Progress_Quarantine_Active
Semantic_Livelock_Suspected
Semantic_Replay_Suspected
*_Visible
Emergency_Visibility_Required
Unsafe_State_Published
```

## Evidence required

```text
нет write-path от advisory к hard-stop
нет IO dependency от advisory
нет runtime barrier dependency от visibility
```

## Связанные риски

```text
RISK-037
RISK-040
RISK-047
O-RISK-001
S-RISK-001
```

## Статус

```text
VALIDATION_REQUIRED
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
```

## Связанные риски

```text
RISK-037
RISK-047
D-RISK-001
D-RISK-002
D-RISK-003
D-RISK-004
```

## Статус

```text
VALIDATION_REQUIRED
```

---

# 11. STAGE-F — Compile/reference convergence

## Цель

Подтвердить, что cleanup не оставил stale references.

## Проверить

```text
removed fields are not referenced
removed PRGs are not called
new fields are declared
ownership matrix matches code
PART2 matches current plan
```

## Связанные риски

```text
C-RISK-001
C-RISK-002
C-RISK-003
C-RISK-004
```

## Статус

```text
IN_PROGRESS
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
```

Запрещено:

```text
cleanup by intuition
удалять fields только потому что они выглядят лишними
переписывать topology без writer/hard-stop evidence
```

---

# 13. Статусы remediation

Используются только эти статусы:

```text
CONFIRMED_RESOLVED        доказано кодом и reference validation
STRUCTURALLY_REDUCED      структура исправлена, но runtime evidence ещё нужна
VALIDATION_REQUIRED       гипотеза или зона риска, нужна проверка
UNVERIFIED_RUNTIME_BEHAVIOR поведение не подтверждено runtime evidence
IN_PROGRESS               работа идёт
```

---

# 14. Текущий главный риск

```text
implicit authority propagation
```

А не:

```text
missing semantic intelligence
```

Главный фокус:

```text
writer graph
hard-stop graph
advisory leakage graph
compile/reference convergence
```
