# Heating Supervision Extension Roadmap

Дата: 2026-05-07

## Назначение

Документ фиксирует допустимые направления развития heating runtime supervision после завершения passive observer integration phase.

Все пункты roadmap относятся только к:
- read-only supervision;
- bounded telemetry;
- commissioning visibility;
- diagnostics visibility.

Документ не описывает runtime delegation или изменение отопительной логики.

---

# Phase 1 — Commissioning Visibility Expansion

## Цель

Сделать activation lifecycle полностью прозрачным для:
- HMI;
- telemetry;
- commissioning.

## Возможные расширения

### 1. Activation timestamps

Добавить:
- last enable request timestamp;
- last operational timestamp;
- last rollback timestamp.

### 2. Lifecycle transition journal

Добавить bounded ring-buffer:
- lifecycle transition history;
- фиксированный размер;
- без replay.

### 3. Observer uptime counters

Добавить:
- operational scan counter;
- stabilization scan counter;
- denied scan counter;
- rollback scan counter.

---

# Phase 2 — Authorization Diagnostics Expansion

## Цель

Сделать причины denied-state полностью читаемыми.

## Возможные расширения

### 1. Deny reason enum

Создать:
- `E_Runtime_Observer_Deny_Reason`

Примеры:
- bootstrap disabled;
- passive mode disabled;
- read-only disabled;
- governance unlocked.

### 2. Explicit deny publication

Публиковать:
- deny reason;
- deny text;
- deny counter.

---

# Phase 3 — HMI Projection Layer

## Цель

Отделить raw observation publication от HMI representation.

## Возможные расширения

### 1. Dedicated HMI projection FB

Создать:
- `FB_Heating_Runtime_Observer_HMI_Projection`

### 2. HMI-safe fields

Публиковать отдельно:
- lifecycle;
- commissioning;
- authorization;
- observation validity;
- bootstrap limitation visibility.

---

# Phase 4 — Bounded Event Timeline

## Цель

Добавить ограниченную runtime timeline visibility.

## Возможные расширения

### 1. Lifecycle event buffer

Добавить bounded event array:
- activation;
- stabilization;
- operational;
- rollback.

### 2. Event severity tagging

Добавить:
- info;
- warning;
- fault.

---

# Phase 5 — Runtime Observation Realism Improvement

## Цель

Уменьшить synthetic observation flags.

## Возможные расширения

### 1. Real publication sequencing validation

Подтверждать:
- publication-before-diagnostics;
- diagnostics-before-observer;
- output-projection-last.

### 2. Real execution evidence

Подтверждать:
- DHW executed;
- heating executed;
- diagnostics executed.

---

# Phase 6 — Documentation Consolidation

## Цель

Свести supervision architecture в единый индекс.

## Возможные расширения

### 1. Final architecture index

Создать:
- `HEATING_SUPERVISION_RUNTIME_FINAL_ARCHITECTURE_INDEX.md`

### 2. Runtime file map

Зафиксировать:
- source-of-truth файлы;
- execution order;
- lifecycle ownership.

---

# Что intentionally НЕ входит в roadmap

Следующие темы intentionally excluded:
- predictive runtime authority;
- adaptive runtime authority;
- autonomous orchestration;
- replay execution;
- writable runtime supervision;
- automatic runtime correction.

---

# Текущее состояние проекта

Проект находится в состоянии:
- passive runtime supervision integrated;
- lifecycle semantics normalized;
- commissioning visibility available;
- read-only runtime observation operational.

Следующие шаги должны оставаться bounded и deterministic.
