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
✔ Diagnostics / Health / Explainability layers
✔ Scheduler / timing / persistence audit
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

---

## Что исправлено

Теперь:

```text
IO/Input layer
не очищает глобальные diagnostics.
```

---

## Статус

```text
ИСПРАВЛЕНО
```

---

# RISK-004

## Safety shutdown aggregation fragility

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

## Статус

```text
АКТИВНЫЙ РИСК
```

Severity:

```text
MEDIUM
```

---

# RISK-008

## Global degraded-state accumulation without lifecycle ownership

## Суть

`Subsystem_Degraded`
стал:

```text
глобальным accumulation flag.
```

Сейчас множество subsystem layers
могут выставлять:

```text
Subsystem_Degraded := TRUE
```

---

## Статус

```text
АКТИВНЫЙ РИСК
```

Severity:

```text
MEDIUM-HIGH
```

---

# RISK-009

## Distributed timer lifecycle semantics

## Суть

Система использует:

```text
- FB_System_Timer;
- FB_System_Timer_TOF.
```

Но lifecycle semantics таймеров:

```text
не централизованы.
```

Subsystem FB:

```text
- самостоятельно управляют reset behavior;
- самостоятельно определяют persistence semantics;
- самостоятельно интерпретируют expiration.
```

---

## Проблема

Пока:

```text
явных catastrophic timing bugs
не найдено.
```

Но уже присутствует:

```text
timing semantics fragmentation.
```

Разные subsystem могут по-разному трактовать:

```text
- reset;
- expiration;
- latch clear;
- recovery timing;
- freeze persistence.
```

---

## Возможные последствия

```text
- inconsistent recovery timing;
- stale timer latches;
- phase persistence leaks;
- recovery races;
- difficult deterministic debugging.
```

---

## Что важно

Пока:

```text
- broken timer reset не найден;
- catastrophic race не найден;
- deadlock не найден.
```

Но:

```text
timer lifecycle governance
уже недостаточно formalized.
```

---

## Рекомендуемое направление

В будущем желательно formalize:

```text
- timer lifecycle ownership;
- reset semantics;
- latch expiration semantics;
- recovery timer policy.
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
