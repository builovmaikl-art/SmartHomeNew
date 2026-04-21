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

## 9. Security / Access analysis

### Таблица команд

| Command | Writers | Conflict | Target Owner |
|--------|--------|----------|--------------|
| G_Gate_Open | PRG_Security | direct to IO without final gate | Security (via arbitration) |
| G_Wicket_Open | PRG_Security | direct to IO without final gate | Security (via arbitration) |
| G_Lock_1_Open | PRG_Security, PRG_Safety | fire/smoke override vs normal access logic | Safety constraint + Security owner |
| G_Lock_1_Close | PRG_Security, PRG_Safety | evacuation unlock may conflict with close | Safety constraint + Security owner |
| G_Lock_2_Open | PRG_Security, PRG_Safety | fire/smoke override vs normal access logic | Safety constraint + Security owner |
| G_Lock_2_Close | PRG_Security, PRG_Safety | evacuation unlock may conflict with close | Safety constraint + Security owner |
| G_Send_2FA_Req | PRG_Security / fbSecurityManager | shared mutable command output | Security |
| G_2FA_Code_Out | PRG_Security / fbSecurityManager | shared mutable command output | Security |

### Observations
- `PRG_Security` writes gate / wicket / lock outputs into `GVL_COMMAND` via `fbAccessControl`.
- `PRG_Safety` also writes `G_Lock_1_Open`, `G_Lock_1_Close`, `G_Lock_2_Open`, `G_Lock_2_Close` during fire/smoke evacuation logic.
- `PRG_IO_Write` directly forwards gate / wicket / lock commands from `GVL_COMMAND` to physical outputs.

### Problem SEC-CMD-001
- lock commands are multi-writer already in current codebase.
- normal access logic and evacuation unlock logic share the same final variables.

### Problem SEC-CMD-002
- no explicit safety-first arbitration exists before lock outputs go to IO.
- current behavior still depends on execution order.

### Problem SEC-CMD-003
- gate / wicket commands also bypass any final validation layer and go straight from `GVL_COMMAND` to IO.

---

## 10. Required target behavior

- Safety формирует ограничения, а не просто команды.
- Security / Access формируют intent, а не final command.
- lock / gate / wicket commands must pass through arbitration.
- evacuation unlock must act as a higher-priority constraint than regular access control.
- before IO, final validation must ensure no forbidden lock-close action survives active evacuation state.

---

## 11. Critical conclusion

GVL_COMMAND в текущем виде:
- не гарантирует безопасность
- не гарантирует детерминизм
- допускает unsafe состояния на уровне IO
- already contains confirmed multi-writer conflicts in access/lock commands

---

## 12. Next step

- перейти к User / System / Gateway command groups
- затем объединить все группы в единую ownership matrix and arbitration model
