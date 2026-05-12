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

---

# RISK-048

## Runtime timing logic не защищена от rollback и monotonic violations

Severity:

```text
CRITICAL
```

### Runtime mechanics

`PRG_Time_Service` централизует runtime timebase через:

```text
GVL_TIME_SERVICE.G_Now_MS
```

и прокидывает canonical time в:

```text
GVL_STATUS.G_System_Time_MS
```

Однако не найдено:

```text
- monotonic-time enforcement;
- rollback detection;
- UDINT overflow handling;
- timebase generation/epoch;
- invalid-time quarantine;
- timer delta safety wrapper.
```

Во многих местах runtime использует timing semantics вида:

```text
Now_MS - Start_MS > Timeout
```

или:

```text
Now_MS - Last_Seen_MS < Timeout
```

При rollback/overflow/reset эти вычисления
могут стать semantically invalid.

---

### Trigger conditions

```text
- time rollback;
- UDINT overflow;
- reboot with retained timestamps;
- corrupted time update;
- monotonic violation;
- partial timebase reset.
```

---

### Failure chain

```text
timebase rollback/overflow/reset occurs
↓
delta calculation becomes semantically invalid
↓
heartbeat/recovery/timeout logic misfires
↓
runtime accepts false alive/dead or false cooldown completion
↓
authority/recovery/output semantics become corrupted
```

---

### Consequences

```text
- false PLC liveness;
- premature recovery release;
- missed timeout;
- endless cooldown/stabilization;
- stale authority survival;
- catastrophic timing-dependent behavior.
```

---

### Почему это критично

Текущая архитектура предполагает:

```text
runtime time
всегда monotonic и valid.
```

Но distributed runtime должен выдерживать:

```text
- rollback;
- overflow;
- reboot;
- stale retained timestamps;
- corrupted timebase.
```

Без monotonic guarantees:

```text
time-dependent safety logic
может стать semantically corrupted.
```

Особенно опасно вместе с:

```text
- RISK-044 ownership/fencing gap;
- RISK-045 asymmetric heartbeat;
- RISK-046 semantic brownout;
- RISK-047 stale outputs;
- recovery convergence gaps.
```

---

### Corrective directions

```text
- внедрить monotonic epoch model;
- добавить rollback detection;
- защитить delta calculations;
- добавить overflow-safe timing wrappers;
- quarantine invalid timebase state.
```

---

### Verification strategy

```text
- forced time rollback tests;
- overflow simulation;
- retained timestamp reboot tests;
- corrupted time injection;
- monotonic violation failover tests.
```
