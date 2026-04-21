# SmartHome PLC — Architecture Migration Map (AS-IS → TO-BE)

## 0. Цель

Привести систему к единой архитектуре:

Sensors → Subsystems → System Health → State Manager → Policy → Subsystems

Ключевой принцип:
**ЕДИНСТВЕННЫЙ источник поведения = System Mode + Policy**
Никаких параллельных контуров.

---

# 1. AS-IS (ФАКТИЧЕСКОЕ СОСТОЯНИЕ)

## 1.1 Контур выполнения

MAIN:
IO → PRG_System → PRG_Safety → PRG_Security → PRG_Heating → PRG_Ventilation → PRG_Lighting → IO

## 1.2 Реальное распределение ответственности

### PRG_System
- health aggregation (FB_System_Health)
- state derivation (FB_State_Manager)
- scenario policy
- command gating
- heating enforcement
- shadow sensor fallback
- history / snapshot
- gateway / HMI arbitration

➡ ПРОБЛЕМА: монолит, смешение слоёв

---

### PRG_Safety
- safety detection
- latch logic
- direct command overrides
- evacuation logic
- ❗ собственная установка G_System_Mode

➡ КРИТИЧЕСКАЯ ПРОБЛЕМА: второй state manager

---

### PRG_Heating
- локальный arbitration (freeze/preheat/normal)
- stabilization (timer)
- priority handling (emergency/gas/degraded)
- target temperature calculation
- + вызов FB_Heating_System_Manager

➡ ПРОБЛЕМА: локальный policy слой

---

### PRG_Ventilation
- локальный arbitration (smoke/gas/CO/degraded)
- command mutation
- + вызов FB_Ventilation_System_Manager

➡ ПРОБЛЕМА: дублирование policy

---

### PRG_Lighting
- normal manager
- + evacuation override (post-processing)

➡ ПРОБЛЕМА: policy после subsystem

---

### PRG_Security
- mostly OK
- ❗ дефект: motion sensors не подключены

---

### Heating Layer
- GVL_STATE.G_Preheat_Request
- GVL_HEATING_REQUEST.G_Preheat_Request

➡ ПРОБЛЕМА: раздвоенный request layer

---

# 2. TO-BE (ЦЕЛЕВАЯ АРХИТЕКТУРА)

## 2.1 Единый поток

Sensors
  ↓
Subsystem Managers (read-only inputs)
  ↓
FB_System_Health
  ↓
FB_State_Manager
  ↓
PRG_Policy (ЕДИНСТВЕННЫЙ policy layer)
  ↓
Subsystem Managers (commands)

---

## 2.2 Владение слоями

| Слой | Владелец | Разрешено | Запрещено |
|------|----------|----------|----------|
| Health | FB_System_Health | агрегация fault | любые команды |
| State | FB_State_Manager | System Mode | side-effects |
| Policy | PRG_Policy | ВСЕ решения | IO, FB внутри |
| Subsystems | FB_*_Manager | управление железом | глобальная логика |
| PRG_* | orchestration | вызов FB | принятие решений |

---

## 2.3 Ключевые правила

1. **Только один writer G_System_Mode**
2. **Policy только в одном месте**
3. **Subsystem не думает — только исполняет**
4. **PRG не содержит бизнес-логики**
5. **Request layers единичны (no duplicates)**

---

# 3. GAP (РАЗРЫВЫ)

## 🔴 Критические

### G1 — Два источника System Mode
- PRG_System
- PRG_Safety

---

### G2 — Распределённый Policy
- PRG_System
- PRG_Safety
- PRG_Heating
- PRG_Ventilation
- PRG_Lighting

---

### G3 — Heating split-brain
- STATE vs HEATING_REQUEST

---

### G4 — Direct command overrides (обход mode)
- Safety напрямую пишет команды

---

## 🟡 Средние

### G5 — PRG_System монолит

### G6 — Domain arbitration в PRG_Heating / Ventilation

### G7 — Lighting override после manager

---

## ⚙️ Локальные

### G8 — PRG_Security bug (motion)

---

# 4. MIGRATION PLAN (ПО СЛОЯМ)

---

## ЭТАП 1 — УНИФИКАЦИЯ MODE (CRITICAL)

### Цель
Оставить ТОЛЬКО FB_State_Manager владельцем режима

### Действия
- удалить установку G_System_Mode из PRG_Safety
- PRG_Safety → только публикует факты (latched flags)

### Результат
✔ единый источник режима

---

## ЭТАП 2 — ВЫДЕЛЕНИЕ POLICY СЛОЯ

### Создать
`PRG_Policy.st`

### Перенести туда:
- scenario logic (из PRG_System)
- heating request logic
- ventilation request logic
- evacuation logic
- degraded behavior

### Удалить из:
- PRG_Heating
- PRG_Ventilation
- PRG_Lighting
- PRG_Safety

### Результат
✔ единый policy owner

---

## ЭТАП 3 — ОЧИСТКА PRG_SYSTEM

Оставить:
- вызов FB_System_Health
- вызов FB_State_Manager

Убрать:
- heating enforcement
- gateway arbitration
- scenario logic
- fallback policy

### Результат
✔ PRG_System = orchestration only

---

## ЭТАП 4 — HEATING LAYER FIX

### Выбрать ОДИН источник:
→ GVL_HEATING_REQUEST (предпочтительно)

### Действия:
- удалить GVL_STATE.G_Preheat_Request
- убрать локальный arbitration из PRG_Heating
- PRG_Heating = adapter only

### Результат
✔ единый heating pipeline

---

## ЭТАП 5 — SUBSYSTEM CLEANUP

### PRG_Heating
убрать:
- priority logic
- timers
- mode selection

оставить:
- вызов FB_Heating_System_Manager

---

### PRG_Ventilation
убрать:
- arbitration
оставить:
- адаптер

---

### PRG_Lighting
убрать:
- evacuation override

---

### Результат
✔ subsystem = чистый исполнитель

---

## ЭТАП 6 — SAFETY РЕФАКТОР

PRG_Safety:
- оставить detection
- оставить latch
- ❌ убрать прямые команды

Policy:
- реализует реакции

---

## ЭТАП 7 — BUG FIX

- исправить PRG_Security (motion mapping)

---

# 5. КОНТРОЛЬНЫЕ КРИТЕРИИ

Система считается мигрированной, если:

- [ ] G_System_Mode пишется в 1 месте
- [ ] нет ни одного IF safety → command вне policy
- [ ] PRG_* не содержит бизнес-логики
- [ ] heating request один
- [ ] вентиляция не содержит arbitration
- [ ] lighting не перезаписывает manager output
- [ ] policy централизован

---

# 6. РИСКИ

- временная потеря поведения (ожидаемо)
- race conditions при partial migration
- скрытые зависимости GVL_STATE

---

# 7. ПРАВИЛО МИГРАЦИИ

❗ НЕЛЬЗЯ делать частично

Каждый этап:
- коммит
- лог
- проверка PLC

---

# 8. СТРАТЕГИЯ

1. Mode cleanup
2. Policy extraction
3. Subsystem cleanup
4. Heating fix
5. Safety refactor

---

# FINAL

Сейчас система:
→ многоконтурная

После миграции:
→ детерминированная, mode-driven, централизованная
