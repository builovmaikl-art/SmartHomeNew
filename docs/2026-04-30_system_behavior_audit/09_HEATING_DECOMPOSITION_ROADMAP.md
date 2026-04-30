# PRG_Heating Decomposition Roadmap

Date: 2026-04-30

## Purpose

Define a safe, non-destructive decomposition strategy for `PRG_Heating`.

Goal:

- identify all responsibilities;
- define target structure;
- extract logic without breaking runtime;
- only then clean original block;
- finally reconnect through defined interfaces.

---

# 🔴 KEY PRINCIPLE

Refactoring is done in **three distinct phases**:

```text
1. Extract (no behavior change)
2. Isolate (remove duplication)
3. Reconnect (enforce architecture)
```

NO mixing of phases.

---

# 🧠 CURRENT STATE (FACTUAL)

`PRG_Heating` currently contains:

```text
1. Safety interpretation
2. Demand calculation
3. Policy influence
4. Timing / delays
5. Diagnostics
6. Actuator mapping
7. State aggregation
```

This is a **VIOLATION block** (multi-owner logic).

---

# 🎯 TARGET STATE

```text
PRG_Heating = DOMAIN EXECUTOR ONLY
```

Responsibilities after refactor:

```text
- receive commands
- apply domain algorithms
- prepare actuator state
```

---

# 🧩 DECOMPOSITION MAP ("ПО КОСТОЧКАМ")

## BLOCK GROUPING

### 1. SAFETY ADAPTER

Current location:
- inside PRG_Heating

Target:

```text
FB_Heating_Safety_Interface
```

Responsibility:
- interpret safety → domain-safe flags

---

### 2. DEMAND CALCULATION

Target:

```text
FB_Heating_Demand
```

Responsibility:
- zone demand
- DHW demand

---

### 3. POLICY INTERFACE

Target:

```text
FB_Heating_Policy_Interface
```

Responsibility:
- consume policy outputs
- adjust demand/targets

---

### 4. COORDINATOR INTERFACE

Target:

```text
FB_Heating_Coordinator_Interface
```

Responsibility:
- apply system-level blocks

---

### 5. ACTUATOR MAPPING

Target:

```text
FB_Heating_Actuator_Map
```

Responsibility:
- convert logical state → pumps/valves

---

### 6. DIAGNOSTICS

Target:

```text
FB_Heating_Diagnostics
```

Responsibility:
- events
- root cause hints

---

### 7. TIMING

Target:

```text
FB_Heating_Timing
```

Responsibility:
- delays
- hysteresis

---

# 🧭 EXTRACTION PLAN (STEP BY STEP)

## STEP 1 — SNAPSHOT

- freeze current behavior
- no logic changes

---

## STEP 2 — IDENTIFY CALL BOUNDARIES

Mark in code:

```text
// SAFETY
// DEMAND
// POLICY
// ACTUATOR
// DIAGNOSTICS
```

---

## STEP 3 — CREATE EMPTY FBs

Create all target FBs with:

```text
same inputs
same outputs
no logic yet
```

---

## STEP 4 — COPY LOGIC (NO CHANGE)

Move logic block-by-block:

```text
copy → paste → connect
```

NO optimization.

---

## STEP 5 — PARALLEL EXECUTION (IMPORTANT)

Run:

```text
old logic + new FB
```

Compare outputs.

---

## STEP 6 — SWITCH OVER

Replace old logic with FB calls.

---

## STEP 7 — CLEAN ORIGINAL PRG

Remove:
- duplicated logic
- decision fragments

Keep only:

```text
call FBs → assemble → output
```

---

# ⚠️ CRITICAL RULES

## Rule 1

NO logic rewrite during extraction.

---

## Rule 2

Each FB must be:

```text
single responsibility
```

---

## Rule 3

PRG_Heating must NOT:

- decide global behavior
- override safety
- bypass command layer

---

# 🧪 VALIDATION CHECKS

After EACH step:

```text
Heating ON works
Heating OFF works
Emergency stop works
DHW works
Manual override works
```

---

# 🧠 FINAL RESULT

Before:

```text
PRG_Heating = mini-system
```

After:

```text
PRG_Heating = executor
+ modular FBs
```

---

# NEXT STEP

After decomposition:

- integrate strictly with Command Arbitration
- remove direct decision logic
- enforce safety via IO_Write

