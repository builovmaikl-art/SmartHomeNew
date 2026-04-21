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

## 5. Safety-critical analysis (Gas / Water / Ventilation)

### Таблица команд

| Command | Writers | Conflict | Target Owner |
|--------|--------|----------|--------------|
| CMD_Gas_Close | PRG_Safety | override possible | Safety |
| CMD_Gas_Open | User/System | conflicts Close | System |
| CMD_Water_Close | PRG_Safety | override possible | Safety |
| CMD_Water_Open | User/System | conflicts Close | System |
| CMD_Vent_Stop | PRG_Safety | conflicts Start | Safety |
| CMD_Vent_Start | Ventilation | conflicts Stop | Manager (via arbitration) |

---

## 6. Conflict cases

### CASE-001 Gas
Safety close vs user open → race condition

### CASE-002 Water
Leak close vs manual open → unsafe override

### CASE-003 Ventilation
Safety stop vs manager start → safety violation

---

## 7. Propagation to IO (critical)

### Observation
- PRG_IO_Write напрямую использует итоговые команды
- не выполняет проверку приоритетов

### Problem SA-IO-001
- конфликт не разрешается перед IO
- unsafe команда может попасть в физическое устройство

### Problem SA-IO-002
- нет final safety gate перед IO

---

## 8. Full chain breakdown

Safety → GVL_COMMAND → Managers → GVL_STATE → IO_Write → Physical Output

### Issues
- команды перезаписываются на каждом этапе
- нет единой точки контроля
- нет гарантии выполнения safety

---

## 9. Required target behavior

- Safety формирует ограничения, а не просто команды
- команды проходят через arbitration
- перед IO выполняется final validation

---

## 10. Critical conclusion

GVL_COMMAND в текущем виде:
- не гарантирует безопасность
- не гарантирует детерминизм
- допускает unsafe состояния на уровне IO

---

## 11. Next step

- перейти к Security / Access commands
- затем объединить в единую модель arbitration
