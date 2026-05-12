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

---

# Что уже проверено

Полностью проверены:

```text
✔ MAIN orchestration
✔ Config pipeline
✔ Runtime governance
✔ IO ownership
✔ Transport ownership
✔ Diagnostics/Health layers
✔ Scheduler/timing/persistence
✔ Recovery/watchdog timing
✔ SAFE_STOP sequencing audit
✔ Freeze/recovery interaction audit
✔ Runtime publication/state consistency audit
✔ Orchestration determinism audit
✔ Command/arbitration/finalization timing audit
✔ Cross-subsystem dependency audit
✔ Persistence/governance coupling audit
✔ Initialization / cold-start / reboot integrity audit
```

---

# RISK-004

## Safety shutdown aggregation fragility

Severity:

```text
MEDIUM
```

---

# RISK-005

## Distributed system mode ownership

Severity:

```text
MEDIUM
```

---

# RISK-006

## Monolithic IO projection complexity growth

Severity:

```text
MEDIUM
```

---

# RISK-007

## Stale transport state acceptance

Severity:

```text
MEDIUM
```

---

# RISK-008

## Global degraded-state accumulation without lifecycle ownership

Severity:

```text
MEDIUM-HIGH
```

---

# RISK-009

## Distributed timer lifecycle semantics

Severity:

```text
MEDIUM
```

---

# RISK-010

## Distributed recovery lifecycle governance

Severity:

```text
MEDIUM-HIGH
```

---

# RISK-011

## Non-formalized suppression release sequencing

Severity:

```text
MEDIUM-HIGH
```

---

# RISK-012

## Freeze-protection and recovery semantic overlap

Severity:

```text
MEDIUM
```

---

# RISK-013

## Runtime-state and published-state semantic coupling

Severity:

```text
MEDIUM-HIGH
```

---

# RISK-014

## Non-atomic cross-subsystem transition visibility

Severity:

```text
MEDIUM-HIGH
```

---

# RISK-015

## Command-validity and execution-validity divergence

Severity:

```text
MEDIUM-HIGH
```

---

# RISK-016

## Implicit semantic dependency hub around G_System_Mode

Severity:

```text
HIGH
```

---

# RISK-017

## Persisted-state and runtime-authority overlap

Severity:

```text
HIGH
```

---

# RISK-018

## Startup/init safety clamp can be overwritten by arbitration

## Суть

`PRG_System_Init`
при ошибке конфигурации напрямую выставляет:

```text
GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
GVL_COMMAND_SHADOW.G_Boiler_Stop := TRUE;
```

Но в `MAIN` после `PRG_System_Init` позже вызывается:

```text
PRG_Command_Arbitration();
```

`PRG_Command_Arbitration`:

```text
- сбрасывает локальный command buffer;
- не учитывает init/config fault как отдельный authority source;
- в конце полностью перезаписывает GVL_COMMAND_SHADOW.
```

---

## Проблема

Startup config safety clamp:

```text
может быть снят
в том же PLC cycle
самим arbitration layer.
```

То есть invalid config может сначала выставить:

```text
heating/boiler block
```

но command arbitration позже:

```text
не обязан сохранить этот block.
```

---

## Что показала проверка

Это уже не просто architectural smell.

Найден:

```text
реальный runtime defect.
```

Проверено:

```text
- PRG_System_Init действительно пишет в GVL_COMMAND_SHADOW;
- MAIN вызывает PRG_Command_Arbitration после init/config этапа;
- PRG_Command_Arbitration полностью перезаписывает shadow commands;
- config/init fault не включён в arbitration priority model.
```

---

## Возможные последствия

```text
- invalid config не удержит heating block;
- boiler stop может быть снят позже в том же cycle;
- startup safety clamp выглядит активным, но не является durable;
- диагностика config fault расходится с фактическим command shadow;
- небезопасный startup behavior при ошибке конфигурации.
```

---

## Действие

Нужно исправлять архитектурно:

```text
не писать startup safety clamp напрямую в GVL_COMMAND_SHADOW
или
добавить init/config fault как explicit high-priority source
в PRG_Command_Arbitration.
```

Предпочтительное направление:

```text
PRG_System_Init / PRG_Config_Validation
→ публикуют config/init fault intent
→ PRG_Command_Arbitration удерживает block/boiler stop
   как priority выше user/automation/domain commands.
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
