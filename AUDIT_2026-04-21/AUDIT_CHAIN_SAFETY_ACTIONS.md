# SAFETY → COMMANDS → IO CHAIN AUDIT

## Цепочка
Latched Safety → PRG_Safety → GVL_COMMAND → Managers / PRG_IO_Write → Physical IO

---

## 1. Источник: Latched Safety

### Наблюдение
- используются `*_Latched` сигналы (Smoke, Gas)
- корректно используются в вентиляции

### Риск SA-001
- возможное смешивание latched и не-latched сигналов в разных местах

---

## 2. PRG_Safety

### Наблюдение
- формирует команды:
  - газ
  - вентиляция
  - клапаны

### Проблема SA-002
- PRG_Safety пишет напрямую в GVL_COMMAND
- нет явного arbitration слоя

### Проблема SA-003
- PRG_Safety также влияет на System_Mode (см. предыдущий аудит)

---

## 3. Command Layer (GVL_COMMAND)

### Наблюдение
- используется как общий слой команд
- в него пишут:
  - PRG_Safety
  - PRG_Security
  - PRG_System
  - HMI / Gateway

### Проблема SA-004
- нет единственного owner на команду
- возможен конфликт записей

### Проблема SA-005
- нет приоритетов (Safety vs User vs Scenario)

---

## 4. Managers (Ventilation / Heating / Lighting)

### Наблюдение
- читают команды из GVL_COMMAND
- могут модифицировать поведение

### Проблема SA-006
- Managers могут переопределить safety intent
- пример: вентиляция может включиться после safety stop

---

## 5. PRG_IO_Write

### Наблюдение
- единая точка записи в IO

### Риск SA-007
- если upstream команды конфликтуют, IO_Write не решает конфликт

---

## 6. Прямые записи в GVL_STATE (обход команды)

### Наблюдение
- Lighting напрямую пишет G_Lighting_Levels

### Проблема SA-008
- bypass command layer
- невозможно централизованно отключить действия при аварии

---

## Итоговые проблемы

- SA-002: Safety пишет напрямую в командный слой
- SA-004: нет ownership команд
- SA-005: нет приоритетов
- SA-006: Managers могут нарушить safety
- SA-008: прямые записи в состояние

---

## Требуемое поведение

- Safety имеет высший приоритет
- команды проходят через единый arbitration layer
- Managers не могут нарушить safety ограничения
- IO получает уже разрешённые команды

---

## Следующие шаги

- ввести command arbitration layer
- запретить прямые записи в GVL_STATE для исполнительных действий
- зафиксировать приоритеты: Safety > System > User
