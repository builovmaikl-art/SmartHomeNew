# TARGET ARCHITECTURE (REFERENCE MODEL)

## Цель
Зафиксировать эталонную архитектуру, к которой должен быть приведён проект после рефакторинга.

---

## 1. Глобальный pipeline (строгий порядок выполнения)

1. PRG_IO_Read
2. PRG_Safety
3. PRG_System (Health + State_Manager)
4. PRG_Policy
5. PRG_Command_Arbitration (НОВЫЙ СЛОЙ)
6. Managers (Heating / Ventilation / Lighting / Security)
7. PRG_IO_Write

---

## 2. Ownership (единственные владельцы)

### System_Mode
- Owner: PRG_System
- Источник: FB_System_Health + FB_State_Manager
- Запрещено: запись из других PRG

### Scenario_Intent
- Owner: PRG_Policy
- Хранение: GVL_POLICY

### Command Layer
- Owner: PRG_Command_Arbitration (новый слой)
- Источники:
  - Safety
  - Policy
  - User / HMI
- Выход: финальные команды для Managers

### Physical IO
- Owner: PRG_IO_Write
- Единственная точка записи

---

## 3. Command Arbitration Layer (обязательный слой)

### Назначение
- объединение всех источников команд
- разрешение конфликтов
- применение приоритетов

### Приоритеты
1. Safety
2. System (mode constraints)
3. Policy
4. User / Manual

### Выход
- только разрешённые команды
- без конфликтов

---

## 4. Managers (жёсткие правила)

Managers НЕ имеют права:
- игнорировать System_Mode
- обходить safety
- писать напрямую в GVL_STATE

Managers ОБЯЗАНЫ:
- использовать System_Mode как hard constraint
- использовать только разрешённые команды
- работать детерминированно

---

## 5. Запрещённые паттерны

❌ запись System_Mode вне PRG_System
❌ прямые записи в GVL_STATE (исполнительные действия)
❌ множественные writer-ы GVL_COMMAND
❌ зависимость поведения от порядка PRG
❌ использование не-latched safety в критических решениях

---

## 6. Требования к детерминизму

- одинаковый вход → одинаковый выход
- отсутствие race condition
- отсутствие "последний записал — победил"

---

## 7. Критерий соответствия

Система считается соответствующей архитектуре, если:
- все ownership соблюдены
- pipeline строго соблюдается
- отсутствуют прямые обходы
- команды проходят через arbitration
- managers не нарушают ограничения

---

## 8. Связь с аудитом

Все найденные проблемы должны:
- быть привязаны к нарушению этой архитектуры
- исправляться с приведением к данной модели

