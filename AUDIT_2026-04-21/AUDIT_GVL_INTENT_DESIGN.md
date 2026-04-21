# GVL_INTENT DESIGN (STRUCTURES AND FIELDS)

## Цель
Определить новые слои intent, которые отделяют источники намерений от финальных команд исполнения.

---

## 1. Общая модель

Вместо прямых записей в `GVL_COMMAND` проект переходит к трём слоям:

- `GVL_INTENT_SAFETY`
- `GVL_INTENT_SYSTEM`
- `GVL_INTENT_USER`

Далее `PRG_Command_Arbitration` преобразует эти intent-слои в финальный `GVL_COMMAND`.

---

## 2. Принципы проектирования

### Safety intent
- хранит только факты, запреты, обязательные override и safety-constraints;
- не должен содержать пользовательские желания;
- имеет наивысший приоритет.

### System intent
- хранит системные решения, policy-ограничения, режимные ограничения и automation-intent;
- не должен напрямую писать в physical command layer.

### User intent
- хранит пользовательские и внешние запросы;
- не является финальной командой;
- может быть отклонён arbitration-слоем.

---

## 3. Предлагаемая структура: GVL_INTENT_SAFETY

### Группа Gas / Fire / Ventilation safety
- `I_Gas_Close_Required : BOOL`
- `I_Boiler_Stop_Required : BOOL`
- `I_Vent_Stop_Required : BOOL`
- `I_Vent_Force_PV3_Boost : BOOL`
- `I_Vent_Force_Supply_100 : BOOL`
- `I_Vent_Force_Supply_80 : BOOL`
- `I_Vent_Force_Exhaust_100 : BOOL`

### Группа Water safety
- `I_Water_Main_Close_Required : BOOL`
- `I_Water_Zone_Close_Required : ARRAY[1..32] OF BOOL`
- `I_Water_Selective_Recovery_Allowed : BOOL`
- `I_Water_Recovery_Target_Zone : INT`

### Группа Locks / Evacuation safety
- `I_Lock_1_Force_Open : BOOL`
- `I_Lock_1_Force_Close_Block : BOOL`
- `I_Lock_2_Force_Open : BOOL`
- `I_Lock_2_Force_Close_Block : BOOL`
- `I_Evacuation_Mode_Active : BOOL`

### Safety facts for arbitration traceability
- `I_Fire_Alarm_Active : BOOL`
- `I_Gas_Alarm_Active : BOOL`
- `I_Leak_Alarm_Active : BOOL`
- `I_CO_Warning_Active : BOOL`
- `I_System_Safe_Stop_Required : BOOL`
- `I_Freeze_Protection_Required : BOOL`

---

## 4. Предлагаемая структура: GVL_INTENT_SYSTEM

### System mode / policy constraints
- `I_Mode_Safe_Stop_Active : BOOL`
- `I_Mode_Degraded_Active : BOOL`
- `I_Mode_Freeze_Protection_Active : BOOL`

### Scenario / automation
- `I_Scenario_Intent : E_SCENARIO_TYPE`
- `I_Scenario_Source : E_SCENARIO_SOURCE`
- `I_Preheat_Request : BOOL`
- `I_Freeze_Request : BOOL`

### System command wishes
- `I_Reset_Errors_Request : BOOL`
- `I_Gateway_Command_Valid : BOOL`
- `I_Gateway_Command_Type : E_Gateway_Command_Type`

### Access / operation constraints
- `I_Access_Open_Allowed : BOOL`
- `I_Manual_Override_Allowed : BOOL`
- `I_Dangerous_Action_Allowed : BOOL`

---

## 5. Предлагаемая структура: GVL_INTENT_USER

### Security / Access requests
- `I_Arm_Request : BOOL`
- `I_Disarm_Request : BOOL`
- `I_PIN_Code : STRING(4)`
- `I_RFID_Tag : STRING(20)`
- `I_2FA_Code_In : STRING(6)`
- `I_Gate_Open_Request : BOOL`
- `I_Wicket_Open_Request : BOOL`
- `I_Lock_1_Open_Request : BOOL`
- `I_Lock_1_Close_Request : BOOL`
- `I_Lock_2_Open_Request : BOOL`
- `I_Lock_2_Close_Request : BOOL`

### Manual override requests
- `I_Lighting_Override : ARRAY[1..32] OF BYTE`
- `I_Blinds_Override : ARRAY[1..GVL_CONSTANTS.C_MAX_BLINDS] OF BYTE`
- `I_Socket_Override : ARRAY[1..GVL_CONSTANTS.C_MAX_SOCKETS] OF BOOL`

### Maintenance / dangerous actions
- `I_Reset_Errors_Request : BOOL`
- `I_Dangerous_Action_Request : BOOL`
- `I_Dangerous_Action_Confirm : BOOL`
- `I_User_Access_Level : INT`

### Test / recovery requests
- `I_Water_Valve_Test_Open : BOOL`
- `I_Water_Valve_Test_Close : BOOL`
- `I_Water_Valve_Test_Confirm : BOOL`
- `I_Gas_Valve_Test_Open : BOOL`
- `I_Gas_Valve_Test_Close : BOOL`
- `I_Gas_Valve_Test_Confirm : BOOL`
- `I_Water_Selective_Recover : BOOL`
- `I_Gas_Selective_Recover : BOOL`

---

## 6. Правила соответствия старому слою

### Что уходит из прямой записи в GVL_COMMAND
- все safety writes из `PRG_Safety`
- все access writes из `PRG_Security`
- все user / gateway requests из `PRG_System` и внешних источников

### Что остаётся в GVL_COMMAND
- только финальные, уже арбитрированные сигналы
- только значения, готовые к использованию managers / IO

---

## 7. Обязательные метаполя (рекомендуется)

Для трассировки и повторного аудита рекомендуется в каждый intent-layer добавить:
- `I_Source_Valid : BOOL`
- `I_Last_Update_Cycle : UDINT`
- `I_Last_Update_MS : UDINT`

Это позволит:
- ловить устаревшие intent
- отслеживать порядок обновления
- упрощать повторный аудит после миграции

---

## 8. Ключевые правила именования

- префикс `I_` означает Intent;
- поля должны описывать желание или ограничение, а не финальную физическую команду;
- safety intent должен формулироваться через `Required`, `Force`, `Block`, `Allowed`, а не через абстрактные флаги.

---

## 9. Migration-first subset (первый обязательный набор)

Для первого шага внедрения достаточно ввести минимальный набор:

### GVL_INTENT_SAFETY
- `I_Gas_Close_Required`
- `I_Boiler_Stop_Required`
- `I_Vent_Stop_Required`
- `I_Water_Main_Close_Required`
- `I_Lock_1_Force_Open`
- `I_Lock_2_Force_Open`
- `I_Evacuation_Mode_Active`

### GVL_INTENT_SYSTEM
- `I_Mode_Safe_Stop_Active`
- `I_Mode_Degraded_Active`
- `I_Mode_Freeze_Protection_Active`
- `I_Preheat_Request`
- `I_Freeze_Request`

### GVL_INTENT_USER
- `I_Arm_Request`
- `I_Disarm_Request`
- `I_PIN_Code`
- `I_RFID_Tag`
- `I_Gate_Open_Request`
- `I_Wicket_Open_Request`
- `I_Lock_1_Open_Request`
- `I_Lock_1_Close_Request`
- `I_Lock_2_Open_Request`
- `I_Lock_2_Close_Request`

---

## 10. Следующий шаг

После фиксации intent-структур нужно создать:
- `GVL_INTENT_SAFETY.gvl`
- `GVL_INTENT_SYSTEM.gvl`
- `GVL_INTENT_USER.gvl`
- затем спроектировать контракт `PRG_Command_Arbitration` field-by-field.
