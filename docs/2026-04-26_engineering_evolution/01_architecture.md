# 01 — Wave 5.0 System Coordinator Architecture

Дата: 2026-04-26
Wave: 5.0
Scope: engineering evolution / system coordination

---

## Baseline

После audit closure система находится в состоянии:

```text
- deterministic
- ownership-safe
- diagnostics-aware
- self-testing
- fault-injectable
- traceable
```

Wave 5.0 не является recovery/fix wave.

Это архитектурное развитие поверх стабильного baseline.

---

## Проблема as-is

Сейчас система состоит из нескольких сильных subsystem-program layers:

```text
PRG_IO_Read
PRG_Safety
PRG_Heating
PRG_Lighting
PRG_Ventilation
PRG_DHW / DHW manager path
PRG_Command_Arbitration
PRG_IO_Write
```

Каждая подсистема уже имеет собственную внутреннюю логику, но глобальный уровень координации пока выражен неявно:

```text
- через порядок вызова PRG;
- через GVL_STATE / GVL_INTENT_*;
- через safety interlocks;
- через command arbitration;
- через локальные constraints внутри подсистем.
```

Это работает, но глобальное поведение системы пока не оформлено как отдельный first-class layer.

---

## Цель Wave 5.0

Ввести explicit System Coordinator layer, который отвечает не за управление конкретным исполнительным механизмом, а за глобальный режим системы.

Coordinator должен отвечать на вопросы:

```text
- какой глобальный режим сейчас активен;
- какие подсистемы должны быть ограничены;
- какие intent/block flags должны быть подняты;
- какой приоритет имеет safety / emergency / away / night / normal;
- допустима ли comfort-логика при текущем состоянии системы.
```

---

## Важное ограничение

Coordinator не должен становиться новым монолитом.

Он НЕ должен:

```text
- напрямую управлять насосами;
- напрямую писать IO outputs;
- подменять PRG_Safety;
- подменять PRG_Heating;
- подменять Command Arbitration;
- писать в domain-specific state без явного ownership решения.
```

Он должен публиковать только global coordination intents.

---

## Target responsibility

Coordinator owns:

```text
- global system mode interpretation;
- global block/allow intents;
- high-level safe/comfort/energy decision;
- cross-subsystem coordination flags;
- system-level degradation summary.
```

Subsystems own:

```text
- domain control algorithms;
- final actuator-specific decisions;
- subsystem diagnostics;
- subsystem state publication.
```

---

## Proposed layer

Новый слой:

```text
FB_System_Coordinator
PRG_System_Coordinator
GVL_SYSTEM_COORDINATION
```

### FB_System_Coordinator

Pure decision block.

Inputs:

```text
- safety latched states
- emergency stop
- system mode
- IO online/degraded state
- diagnostics/test status
- current scenario
```

Outputs:

```text
- block heating
- block ventilation
- block lighting overrides
- block socket overrides
- force safe stop
- system degraded
- global coordination status code
```

### PRG_System_Coordinator

Orchestration wrapper.

Responsibilities:

```text
- call FB_System_Coordinator;
- publish outputs into GVL_SYSTEM_COORDINATION;
- optionally mirror selected flags into existing GVL_INTENT_SYSTEM if already supported.
```

### GVL_SYSTEM_COORDINATION

Global publication surface for coordinator outputs.

---

## Execution order

Recommended order:

```text
PRG_IO_Read
PRG_Test_Injection          // test only, if enabled
PRG_Safety
PRG_System_Coordinator      // new
PRG_Command_Arbitration
PRG_Heating
PRG_Ventilation
PRG_Lighting
PRG_System_Test_Harness     // test only, if enabled
PRG_IO_Write
```

Reasoning:

```text
- IO and Safety must run before Coordinator;
- Coordinator publishes global constraints before domain PRGs;
- domain PRGs consume coordination intent;
- test harness validates resulting system state.
```

---

## Minimal first integration

Wave 5.0 must start non-invasively:

```text
1. Create GVL_SYSTEM_COORDINATION
2. Create FB_System_Coordinator
3. Create PRG_System_Coordinator
4. Do not yet modify all downstream PRGs
5. Publish coordination outputs for observation/test first
```

Only after observation is stable:

```text
6. Connect selected outputs into GVL_INTENT_SYSTEM / domain constraints
```

---

## Safety priority model

Priority order:

```text
1. Emergency stop
2. Fire / smoke latched
3. Gas latched
4. Leak latched
5. IO offline / degraded
6. Test failure / ownership violation
7. Scenario / comfort modes
8. Normal operation
```

Higher priority always overrides lower priority.

---

## Acceptance criteria

Wave 5.0 architecture is accepted when:

```text
- Coordinator exists as explicit layer;
- no actuator direct writes are introduced;
- global coordination flags are observable;
- test harness can inspect coordinator output;
- domain PRGs are not broken by the new layer;
- execution order is documented.
```

---

## Status

```text
ARCHITECTURE DEFINED
```
