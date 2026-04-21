# COMMAND LAYER AUDIT (GVL_COMMAND)

## Цель
Полностью разобрать текущую модель команд, выявить все источники записи, конфликты и определить целевой ownership.

---

## 1. Общая характеристика

GVL_COMMAND используется как:
- вход (user / HMI / gateway)
- внутренние команды (safety / system / security)
- выход в IO

=> слой не разделён, отсутствует arbitration

---

## 2. Первичная классификация команд

### Safety commands
- CMD_Water_*
- CMD_Gas_*
- CMD_Ventilation_*

### Security / Access
- G_Gate_Open
- G_Wicket_Open
- G_Lock_*
- G_2FA_*

### User / Control
- G_Arm_Req
- G_Disarm_Req
- PIN / RFID

### System / Maintenance
- gateway / reset / service команды

---

## 3. Writers (фактические)

### PRG_Safety
- аварийные команды (газ, вода, вентиляция)

### PRG_Security
- доступ (замки, ворота, 2FA)

### PRG_System
- gateway / operator / maintenance

### External (HMI / Config / Retain)
- пользовательские команды

---

## 4. Конфликты (обнаруженные)

### CMD layer multi-writer
- несколько PRG пишут в один GVL
- нет приоритета

### Safety override risk
- safety команды могут быть перезаписаны

### User override risk
- пользователь может перебить safety

---

## 5. Примеры конфликтов

### CASE-001 Gas control
- Safety: CMD_Gas_Close = TRUE
- User: CMD_Gas_Open = TRUE
=> конфликт без arbitration

### CASE-002 Ventilation
- Safety: stop
- Manager: start
=> последний writer выигрывает

---

## 6. Target ownership (черновой)

| Command Group | Owner |
|--------------|------|
| Safety       | PRG_Safety |
| Security     | PRG_Security |
| System       | PRG_System |
| User input   | External (intent only) |

---

## 7. Проблемы архитектуры

- нет разделения intent / command
- нет arbitration слоя
- нет приоритетов
- нет single owner

---

## 8. Следующий шаг

- полный список всех команд
- маппинг writers по каждой переменной
- фиксация ownership для каждой команды
