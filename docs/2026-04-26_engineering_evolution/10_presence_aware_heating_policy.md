# 10 — Presence-aware Heating Policy

Дата: 2026-04-26
Wave: 5.1 / future heating evolution
Scope: thermal occupancy policy

---

## Ключевое правило

```text
Presence MUST NOT directly disable heating circuits.
Presence MAY influence heating targets, preheat requests and thermal allocation priority.
```

Причина:

```text
- тёплый пол имеет высокую тепловую инерцию;
- резкое выключение пустой комнаты создаёт cold-room эффект вечером;
- comfort recovery должен быть предсказуемым.
```

---

## Базовая модель

Presence влияет не на `ON/OFF`, а на thermal policy:

```text
occupied zone      -> comfort target / normal priority
short empty zone   -> mild eco target / normal-low priority
long empty zone    -> deep eco target / low priority
guest/preheat zone -> preheat target / elevated priority
```

---

## Empty duration classes

### Short empty

```text
zone empty < 24h
```

Policy:

```text
- do not turn off heating;
- allow mild eco reduction;
- keep comfort recovery possible.
```

Example:

```text
comfort 21.0°C -> eco 19.0°C
```

---

### Long empty

```text
zone empty >= 24h
```

Policy:

```text
- allow deeper eco target;
- never below configured minimum;
- keep frost/safety protection independent.
```

Example:

```text
comfort 21.0°C -> deep eco 16.0..17.0°C
```

---

## Guest / HMI preheat rule

HMI may request guest-room preparation:

```text
Guest mode / selected room preheat
```

Policy:

```text
- selected zone gets preheat target;
- selected zone gets elevated thermal allocation priority;
- policy expires after timeout or manual reset;
- safety/system constraints still override.
```

Example:

```text
Guest room selected -> preheat to 20..21°C before arrival
```

---

## Priority relation

```text
Safety > Freeze protection > Guest/preheat > Occupied comfort > Short empty eco > Long empty deep eco
```

---

## Required future data

```text
GVL_PRESENCE.G_Zone_Occupied[]
GVL_PRESENCE.G_Zone_Last_Motion_TS[]
GVL_HEATING_POLICY.G_Zone_Empty_Duration_MS[]
GVL_HEATING_POLICY.G_Zone_Target_Adjustment[]
GVL_HEATING_POLICY.G_Guest_Preheat_Request[]
```

---

## Non-goals for first implementation

```text
- no direct pump OFF by presence;
- no direct valve OFF by presence;
- no override of safety/freeze;
- no breaking of existing heating manager.
```

---

## Recommended implementation path

### Phase A — observe-only

```text
compute per-zone empty duration and policy class
publish target adjustment / priority bias
no behavior change
```

### Phase B — controlled integration

```text
feed adjustment into heating decision/policy layer
apply only as target/priority bias
```

### Phase C — HMI guest preheat

```text
add explicit selected-zone preheat request
add timeout/manual reset
```

---

## Status

```text
DESIGN DECISION RECORDED
```