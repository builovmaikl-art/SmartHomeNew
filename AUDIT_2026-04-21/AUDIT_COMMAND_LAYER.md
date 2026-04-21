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
- в том числе lock override при пожаре/дыме

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
(см. выше)

---

## 6. Security / Access analysis
(см. выше)

---

## 7. User / System / Gateway analysis

### Таблица команд

| Command | Writers | Conflict | Target Owner |
|--------|--------|----------|--------------|
| G_Arm_Req | HMI / User | может конфликтовать с текущим alarm state | Policy / Security Intent |
| G_Disarm_Req | HMI / User | может конфликтовать с активной тревогой | Policy / Security Intent |
| G_PIN_Code | User / System | shared mutable input | Security Intent |
| G_RFID_Tag | User / System | shared mutable input | Security Intent |
| G_2FA_Code_In | User / External | async race risk | Security Intent |
| Gateway commands | PRG_System | может перезаписывать user intent | System Intent |

### Observations
- пользовательские команды приходят напрямую в `GVL_COMMAND`.
- `PRG_System` может модифицировать или проксировать команды.
- нет разделения между input (intent) и final command.

### Problem USR-001
- смешение intent и execution в одном слое.

### Problem USR-002
- асинхронные источники могут менять значения в середине цикла.

### Problem USR-003
- нет snapshot механизма (фиксированного состояния на цикл).

### Problem USR-004
- нет централизованной валидации пользовательских команд.

---

## 8. Full system-level issue

GVL_COMMAND одновременно содержит:
- intent (user input)
- control (system decisions)
- execution commands (IO layer)

=> фундаментальное архитектурное нарушение

---

## 9. Required target behavior

### Разделение слоёв

GVL_INTENT_USER
GVL_INTENT_SYSTEM
GVL_INTENT_SAFETY
↓
PRG_Command_Arbitration
↓
GVL_COMMAND (final only)

---

## 10. Final critical conclusion

Текущая система:
- не разделяет intent и execution
- допускает race condition от внешних источников
- допускает перезапись safety
- не имеет точки принятия решений

---

## 11. Audit complete for command layer groups

Покрыто:
- Safety
- Security
- User/System/Gateway

=> можно переходить к проектированию arbitration слоя
