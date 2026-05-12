# RUNTIME_AUDIT_RISK_REPORT_PART2

# Назначение

Документ является продолжением:

```text
RUNTIME_AUDIT_RISK_REPORT.md
```

И используется для:

```text
- дальнейшей фиксации runtime/systemic risks;
- deep survivability audit;
- ultra-edge runtime verification;
- catastrophic interaction analysis;
- hardware/runtime semantic integrity review.
```

Причина разделения:

```text
основной audit-report
достиг размера,
при котором GitHub connector
начал нестабильно выполнять full-file update.
```

Поэтому дальнейшие риски:

```text
фиксируются в continuation-report.
```

---

# Что уже проверено ранее

См:

```text
RUNTIME_AUDIT_RISK_REPORT.md
```

---

# RISK-036

## Absence of authoritative analog plausibility/sanitization model

Severity:

```text
HIGH
```

---

# RISK-037

## Absence of formal PLC scan-cycle temporal visibility model

Severity:

```text
HIGH
```

---

# RISK-038

## Post-arbitration transport update can affect same-cycle domain execution

## Суть

В `MAIN` фактический порядок execution pipeline такой:

```text
1-6: init/config/safety/policy/command arbitration
6.5: Modbus/OpenTherm transport update
7: domain execution
8: PRG_IO_Write
9: verifier/diagnostics
```

Ключевая проблема:

```text
transport update происходит
после command arbitration,
но до domain execution.
```

---

## Реальная compound-chain

Возможна цепочка:

```text
PRG_Command_Arbitration
уже принял command decision
↓
transport получает stale/delayed/reconnect response
↓
domain execution видит новое transport state
↓
domain output меняется
↓
PRG_IO_Write публикует physical outputs
↓
PRG_Command_Verifier срабатывает только после IO write
```

---

## Проблема

Command arbitration:

```text
не видит transport update,
который произойдёт позже
в том же PLC cycle.
```

При этом domain execution:

```text
уже может увидеть transport state,
обновлённый после arbitration.
```

То есть возникает:

```text
same-cycle arbitration/domain divergence.
```

---

## Почему это опасно

Это не одиночный smell, а cross-risk amplification chain между:

```text
- RISK-015 command/execution validity divergence;
- RISK-027 transport transaction matching gap;
- RISK-037 scan-cycle temporal visibility gap;
- transport reconnect/stale response risks;
- verifier-after-IO ordering.
```

Transport response может:

```text
повлиять на domain output
после arbitration,
но до physical IO write.
```

---

## Возможные последствия

```text
- same-cycle arbitration/domain divergence;
- stale transport response affecting domain output;
- verifier too late to prevent physical write;
- transport-induced output inconsistency;
- compound interaction between transport, arbitration and IO finalization;
- ultra-hard-to-debug one-cycle physical output anomaly.
```

---

## Действие

Нужно formalize:

```text
post-transport arbitration/validation barrier
или
transport update phase isolation.
```

Предпочтительное направление:

```text
- transport updates produce staged state;
- domain execution reads cycle-stable transport snapshot;
- arbitration sees the same snapshot as domains;
- verifier/pre-IO validation happens before PRG_IO_Write;
- post-transport changes cannot affect same-cycle physical outputs without revalidation.
```

Также желательно:

```text
- transport/domain phase contract;
- staged transport publication;
- pre-IO command verifier barrier;
- deterministic transport-to-domain propagation semantics.
```

---

## Статус

```text
ТРЕБУЕТ ИСПРАВЛЕНИЯ
```

Severity:

```text
HIGH
```
