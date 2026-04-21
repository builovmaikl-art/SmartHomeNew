# SYSTEM MODE CHAIN AUDIT

## Цепочка
Safety → Health → State_Manager → G_System_Mode → Policy → Managers

---

## 1. Источник: Safety

### Наблюдение
- Safety формирует latched-флаги (Smoke, Gas и т.д.)
- Эти флаги используются дальше в системе

### Проблема SM-001
- Safety напрямую записывает `GVL_STATE.G_System_Mode`
- это нарушает архитектуру single-owner

---

## 2. Health (FB_System_Health)

### Наблюдение
- агрегирует safety + диагностику
- формирует состояние системы

### Риск SM-002
- возможна зависимость от несинхронных источников (GVL_STATUS vs GVL_STATE)

---

## 3. State Manager (FB_State_Manager)

### Наблюдение
- принимает решение о режиме
- должен быть единственным owner System_Mode

### Риск SM-003
- результат может быть перезаписан позже (PRG_Safety)

---

## 4. Публикация G_System_Mode

### Фактические writers
- PRG_System
- PRG_Safety

### Проблема SM-004
- нарушение single source of truth

---

## 5. Использование в Policy

### Наблюдение
- Policy читает G_System_Mode

### Проблема SM-005
- Policy вызывается до актуализации режима

---

## 6. Использование в Managers

### Heating / Ventilation / Lighting

### Наблюдение
- Managers получают G_System_Mode

### Риск SM-006
- возможна работа на устаревшем или неконсистентном режиме

---

## Итоговые проблемы цепочки

- SM-001: Safety нарушает ownership
- SM-002: возможная несинхронность входов Health
- SM-003: результат State_Manager может быть перезаписан
- SM-004: два writer-а System_Mode
- SM-005: Policy работает раньше режима
- SM-006: Managers зависят от нестабильного режима

---

## Требуемое поведение

- единственный writer System_Mode — PRG_System
- порядок: Safety → System → Policy → Managers
- все потребители читают уже финализированный режим

---

## Следующие шаги

- проверить все места использования G_System_Mode
- проверить наличие mode-gating в Managers
- проверить latched vs non-latched использование
