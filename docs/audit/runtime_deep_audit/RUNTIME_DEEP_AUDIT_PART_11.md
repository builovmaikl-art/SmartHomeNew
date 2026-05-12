# RUNTIME_DEEP_AUDIT_PART_11

# RISK-047

## Physical outputs могут переживать потерю semantic authority

Severity:

```text
CRITICAL
```

### Runtime mechanics

Текущая архитектура output handling выглядит как:

```text
last-value persistent
```

а не:

```text
freshness-authoritative.
```

Не найдено:

```text
- output freshness epoch;
- stale-output invalidation;
- output lease timeout;
- authority-bound output ownership;
- automatic output decay;
- semantic output expiration.
```

В результате:

```text
physical outputs
могут оставаться активными
после потери semantic authority.
```

---

### Trigger conditions

```text
- runtime partial freeze;
- semantic brownout;
- split-brain;
- reconnect stall;
- degraded failover;
- stale authority survival.
```

---

### Failure chain

```text
controller publishes output
↓
runtime loses semantic validity
↓
authority becomes stale/ambiguous
↓
no output invalidation occurs
↓
physical outputs remain active
↓
unsafe stale actuation survives
```

---

### Consequences

```text
- stale dangerous outputs;
- split-brain actuation persistence;
- failover with obsolete physical state;
- semantically orphaned outputs;
- unsafe physical survivability;
- catastrophic stale-control behavior.
```

---

### Почему это критично

Сейчас система предполагает:

```text
published output
≈ valid output.
```

Но в distributed/safety runtime:

```text
output validity
должна зависеть
от актуальности authority.
```

Это создаёт:

```text
stale-output survivability.
```

Особенно опасно вместе с:

```text
- RISK-044 stale authority resurrection;
- RISK-045 asymmetric heartbeat visibility;
- RISK-046 semantic brownout survivability;
- verifier-after-IO execution;
- observability lag.
```

---

### Corrective directions

```text
- внедрить output freshness epochs;
- реализовать authority-bound outputs;
- добавить forced safe decay;
- реализовать stale-output watchdog;
- сбрасывать outputs при потере authority.
```

---

### Verification strategy

```text
- stale-output survivability tests;
- failover under frozen outputs;
- split-brain output persistence;
- semantic brownout simulation;
- authority-loss output invalidation tests.
```
