# RUNTIME_AUDIT_RISK_REPORT

# Назначение

Документ фиксирует:

```text
- найденные runtime/architecture риски;
- уже исправленные проблемы;
- текущие опасные зоны;
- результаты системного аудита;
- дальнейшие направления проверки.
```

Документ является:

```text
живым audit-report.
```

Он должен обновляться после каждого крупного audit/refactor этапа.

---

# Что уже проверено

Полностью проверены:

```text
✔ MAIN orchestration
✔ Config pipeline
✔ Config simulation integration
✔ Runtime base layer
✔ PLC arbitration
✔ IO/Input pipeline
✔ Diagnostics persistence
✔ Safety/Shutdown/Recovery chain
✔ Heating runtime governance
✔ Runtime ownership consistency
✔ Intent/Policy/Command arbitration chain
✔ IO write / physical projection ownership
✔ Transport / Modbus / OpenTherm ownership
```

---

# Исправленные проблемы

# RISK-001

## Проблема

```text
FB_Config_Simulation
сбрасывал результат проверки каждый цикл.
```

Из-за этого:

```text
PRG_Config_Manager
не мог надёжно блокировать применение
опасной конфигурации.
```

---

## Что исправлено

Теперь:

```text
результат simulation/validation
сохраняется
до следующего подтверждённого запуска.
```

---

## Статус

```text
ИСПРАВЛЕНО
```

---

# RISK-002

## Проблема

```text
PRG_PLC_Arbitration
некорректно обрабатывал одинаковые PLC ID.
```

При одинаковых ID:

```text
локальная PLC
могла потерять ownership.
```

---

## Что исправлено

Теперь:

```text
- lower ID wins;
- equality keeps local owner;
- arbitration стал deterministic.
```

---

## Статус

```text
ИСПРАВЛЕНО
```

---

# RISK-003

## Проблема

```text
PRG_IO_Read
сбрасывал:
- Sensor_Fault
- Subsystem_Degraded
```

в середине execution pipeline.

Из-за этого:

```text
другие subsystem diagnostics
могли silently erase.
```

Например:

```text
- Config validation errors;
- Safety degradation;
- manifold/runtime faults.
```

---

## Что исправлено

Теперь:

```text
IO/Input layer
не очищает глобальные diagnostics.
```

Он:

```text
только добавляет свои faults.
```

---

## Статус

```text
ИСПРАВЛЕНО
```

---

# RISK-004

## Safety shutdown aggregation fragility

## Суть

Сейчас:

```text
PRG_Safety
→ создаёт safety intent

PRG_Safety_Shutdown
→ агрегирует final shutdown state

PRG_Safety_Recovery
→ работает уже через aggregated shutdown mode
```

---

## Проблема

Архитектура сейчас:

```text
корректна,
но fragile.
```

Если позже появится:

```text
ещё один writer
в GVL_SAFETY_SHUTDOWN
```

то:

```text
Recovery layer
может начать реагировать
не только на реальные safety alarms.
```

---

## Обязательный invariant

```text
GVL_SAFETY_SHUTDOWN
должен оставаться:

single shutdown authority.
```

---

## Статус

```text
АКТИВНЫЙ РИСК
```

Severity:

```text
MEDIUM
```

---

# RISK-005

## Distributed system mode ownership

## Суть

`GVL_STATE.G_System_Mode`
имеет:

```text
несколько runtime writers.
```

Например:

```text
- Policy layer;
- Recovery layer;
- Health layer;
- Safety-related orchestration.
```

---

## Что показала проверка

Catastrophic conflict:

```text
НЕ найден.
```

Сейчас система работает как:

```text
layered escalation model.
```

Пример:

```text
NORMAL
→ DEGRADED
→ SAFE_STOP
→ RECOVERY
→ NORMAL
```

То есть сейчас:

```text
это intentional behavior,
а не случайный conflict.
```

---

## Проблема

Архитектура держится на:

```text
implicit discipline.
```

Нет formal owner для:

```text
system mode transitions.
```

Сейчас subsystem layers:

```text
"знают"
какие transitions им разрешены.
```

Но это:

```text
fragile при дальнейшем росте системы.
```

---

## Возможные последствия в будущем

```text
- conflicting transitions;
- stale recovery;
- unsafe downgrade paths;
- non-deterministic mode restore;
- hidden escalation loops.
```

---

## Что важно

Пока:

```text
runtime deterministic.
```

И:

```text
critical runtime conflict
не обнаружен.
```

Но:

```text
risk accumulation присутствует.
```

---

## Рекомендуемое направление

В будущем желательно:

```text
formalize:

single system-mode authority
или
explicit transition contract.
```

---

## Статус

```text
АКТИВНЫЙ РИСК
```

Severity:

```text
MEDIUM
```

---

# RISK-006

## Monolithic IO projection complexity growth

## Суть

`PRG_IO_Write`
стал:

```text
слишком большим aggregation/finalization layer.
```

Сейчас он содержит одновременно:

```text
- physical projection;
- safety masking;
- hard-stop logic;
- freeze exceptions;
- access suppression;
- recovery masking;
- siren logic;
- failover logic.
```

---

## Что показала проверка

На текущий момент:

```text
critical runtime conflict
не найден.
```

Также подтверждено:

```text
✔ PRG_IO_Write остаётся single physical projection layer
✔ hidden direct IO writers не обнаружены
✔ shadow/output separation сохранён
✔ hardware ownership пока coherent
```

---

## Проблема

Архитектура пока:

```text
управляема.
```

Но:

```text
complexity accumulation
уже заметна.
```

Особенно опасны future interactions между:

```text
- freeze exceptions;
- gas/fire overrides;
- recovery masking;
- access emergency bypass.
```

---

## Возможные последствия в будущем

```text
- conflicting masking rules;
- hidden output suppression;
- unsafe override ordering;
- difficult debugging;
- accidental output starvation.
```

---

## Что важно

Пока:

```text
single IO ownership
сохраняется.
```

И:

```text
physical output architecture
остаётся coherent.
```

Но:

```text
future masking conflicts
становятся всё вероятнее.
```

---

## Рекомендуемое направление

В будущем желательно:

```text
разделить:
- projection;
- masking;
- failover policy;
- emergency suppression.
```

При этом:

```text
single final IO ownership
должен сохраниться.
```

---

## Статус

```text
АКТИВНЫЙ РИСК
```

Severity:

```text
MEDIUM
```

---

# RISK-007

## Stale transport state acceptance

## Суть

Transport layer:

```text
слишком доверяет external wire state
без explicit freshness governance.
```

Например:

```text
PRG_OpenTherm_Transport:
- декодирует wire image;
- публикует Raw_Status;
- считает transport online.
```

Но при этом отсутствует полноценное:

```text
- stale frame detection;
- heartbeat aging governance;
- stale ACK validation;
- frozen transport supervision.
```

---

## Что показала проверка

Критических ownership conflicts:

```text
не найдено.
```

Также подтверждено:

```text
✔ transport layer остаётся bounded
✔ protocol ownership coherent
✔ hidden boiler authority не найден
✔ direct output bypass не найден
✔ Modbus scheduler isolation корректен
✔ OpenTherm transport isolation корректен
```

---

## Проблема

Сейчас:

```text
старые valid transport данные
могут продолжать выглядеть валидными.
```

Особенно опасно если:

```text
- serial transport завис;
- adapter подвис;
- wire image перестал обновляться;
- heartbeat frozen;
- stale ACK остаётся valid.
```

---

## Возможные последствия в будущем

```text
- stale boiler state;
- false online state;
- delayed fault detection;
- dangerous trust in frozen transport;
- recovery instability.
```

---

## Что важно

Пока:

```text
runtime deterministic.
```

И:

```text
transport layer
не владеет runtime policy.
```

Но:

```text
freshness governance gap
присутствует.
```

---

## Рекомендуемое направление

В будущем желательно:

```text
formalize:
- freshness ownership;
- stale-state invalidation;
- transport aging policy;
- ACK expiration governance.
```

---

## Статус

```text
АКТИВНЫЙ РИСК
```

Severity:

```text
MEDIUM
```

---

# Что дополнительно подтверждено

# Heating runtime

Подтверждено:

```text
✔ нет detached orchestration
✔ нет Runtime_* actuation
✔ нет duplicate boiler ownership
✔ нет hidden manifold finalizer
✔ phase-oriented runtime сохранён
✔ bounded finalization сохранён
```

---

# MAIN architecture

Подтверждено:

```text
✔ MAIN вызывает только PRG_*
✔ FB остаются subordinate layers
✔ нет hidden FB orchestration
```

---

# Config/runtime separation

Подтверждено:

```text
✔ Config simulation изолирован
✔ commissioning validation отделён от runtime
✔ heating phases не загрязнены config logic
```

---

# Safety ownership

Подтверждено:

```text
✔ single safety intent owner
✔ single shutdown aggregation owner
✔ recovery layer не владеет outputs
✔ duplicate emergency ownership не найден
```

---

# Intent / Command arbitration

Подтверждено:

```text
✔ direct arbitration bypass не найден
✔ hidden command writers пока не найдены
✔ GVL_COMMAND_SHADOW остаётся главным command aggregation layer
✔ catastrophic command conflicts пока не найдены
```

---

# IO ownership

Подтверждено:

```text
✔ direct runtime writers в GVL_IO вне PRG_IO_Write не найдены
✔ physical IO ownership централизован
✔ hidden hardware bypass пока не найден
✔ domain layers используют dedicated OUTPUT GVL
```

---

# Transport ownership

Подтверждено:

```text
✔ transport layer не владеет runtime policy
✔ hidden boiler authority не найден
✔ transport isolation coherent
✔ protocol ownership централизован
✔ direct IO bypass не найден
```

---

# Самые опасные future drift направления

# 1. Runtime_* authority growth

Риск:

```text
наблюдательные/governance слои
начнут получать actuation writes.
```

Severity:

```text
HIGH
```

---

# 2. Hidden output finalization

Риск:

```text
появятся новые output masking layers
вне explicit phase finalization.
```

Severity:

```text
HIGH
```

---

# 3. Policy bypass

Риск:

```text
policy layer
начнёт напрямую менять outputs
вместо influence-only semantics.
```

Severity:

```text
HIGH
```

---

# 4. Duplicate safety aggregation

Риск:

```text
появятся параллельные shutdown aggregators.
```

Severity:

```text
MEDIUM
```

---

# Текущее состояние архитектуры

На текущий момент:

```text
архитектура выглядит:
- coherent;
- deterministic;
- governance-consistent.
```

Подтверждено:

```text
✔ ownership boundaries сохранены
✔ write-boundary governance сохранён
✔ phase runtime сохранён
✔ detached runtime resurrection не найден
✔ catastrophic runtime conflicts пока не обнаружены
```

---

# Следующая audit-зона

Следующий этап проверки:

```text
Diagnostics / History / Explainability / Health
```

Там наиболее вероятны:

```text
- recursive degradation loops;
- stale diagnostics;
- hidden runtime mutation из observability layers;
- health escalation feedback;
- explainability/runtime coupling.
```
