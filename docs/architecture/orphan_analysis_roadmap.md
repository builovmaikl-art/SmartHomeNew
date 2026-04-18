# Orphan ST Analysis → Architecture Roadmap

## Контекст
Анализ root *.st показал 23 unreachable блока.  
Проведён semantic audit → выявлены архитектурные ветки.

---

## 🔴 PRIORITY 1 — Snapshot / Persistence Layer

**Состав:**
- FB_State_Snapshot_Manager
- FB_State_Snapshot_NVRAM

**Суть:**
- event-driven snapshots
- ring buffer состояния
- persistence (file/NVRAM)

**Статус:**
❗ Частично реализовано (blackbox/history есть, но нет полноценной snapshot-архитектуры)

**Решение:**
→ Кандидат на интеграцию в первую очередь

---

## 🔴 PRIORITY 2 — Heating Protection Layer

**Состав:**
- FB_FloorHeating_Freeze_Protection
- FB_FloorHeating_Overheat_Protection
- (частично) FB_Manifold_Pump_Controller

**Суть:**
- защита контуров
- per-circuit lock
- anti-freeze logic
- pump force / ramp logic

**Статус:**
❗ В активном ядре нет явной реализации

**Решение:**
→ Вторая очередь интеграции (safety)

---

## 🟠 PRIORITY 3 — Calibration Verification

**Состав:**
- FB_Calibration_Manager

**Суть:**
- калибровка + проверка через время
- deviation %
- fail detection

**Статус:**
⚠ Частично реализовано (calibration есть, verification нет)

**Решение:**
→ Интеграция после snapshot/heating

---

## 🟡 PRIORITY 4 — Presence Playback

**Состав:**
- FB_Presence_Playback
- FB_Presence_Simulator

**Суть:**
- запись поведения
- воспроизведение (simulation)

**Статус:**
⚠ Частично реализовано (simulation есть, playback нет)

**Решение:**
→ Feature layer (UX/security)

---

## 🟡 PRIORITY 5 — Zone-Based Access

**Состав:**
- FB_Zone_Access_Manager

**Суть:**
- доступ по зонам
- bitmask + global level

**Статус:**
❗ Не реализовано

**Решение:**
→ Архитектурное расширение (не срочно)

---

## ⚪ LOW PRIORITY (Поглощено / устарело)

- FB_CO_Detector
- FB_Gas_Methane_Detector
- FB_Smoke_Detector
- FB_Outdoor_Lighting_Controller
- FB_Security_Alarm
- FB_Sensor_Distribution
- FB_Exhaust_Ventilation_Controller

---

## Итог

Этот список — **не архив**, а:

→ roadmap развития системы  
→ источник будущих интеграций  
→ reference для архитектурных решений

