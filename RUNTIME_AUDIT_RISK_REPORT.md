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

Например:

```text
- IO_Read;
- Diagnostics;
- Health;
- Policy;
- Config validation;
- subsystem managers.
```

---

## Проблема

Нет централизованного owner для:

```text
- reset;
- aging;
- recovery;
- degradation expiration.
```

Сейчас архитектура работает как:

```text
sticky degradation accumulation.
```

То есть subsystem может:

```text
permanently degraded систему,
если recovery path неполный.
```

---

## Дополнительная опасность

В будущем возможно:

```text
recursive degradation amplification.
```

Пример:

```text
Health
→ выставляет degraded

Diagnostics
→ усиливает severity

Policy
→ переводит system mode

Health
→ снова усиливает degraded
```

---

## Что важно

Пока:

```text
реального recursive loop
не найдено.
```

И:

```text
runtime пока deterministic.
```

Но:

```text
degradation lifecycle governance
уже недостаточно formalized.
```

---

## Возможные последствия

```text
- stale degraded state;
- non-resettable degradation;
- recursive escalation loops;
- false degraded persistence;
- recovery instability.
```

---

## Рекомендуемое направление

В будущем желательно:

```text
formalize:
- degraded-state ownership;
- degradation aging;
- recovery authority;
- degradation expiration lifecycle.
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
