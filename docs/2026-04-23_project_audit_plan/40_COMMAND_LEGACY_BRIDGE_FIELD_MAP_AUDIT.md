# Command Legacy Bridge Field Map Audit

Дата фиксации: 2026-04-23

## Назначение
Этот документ выполняет этап из `39_COMMAND_LEGACY_BRIDGE_FIELD_MAP_PLAN.md`:
field-level разбор `GVL_COMMAND` как legacy bridge / compatibility surface.

## Проверенные объекты
- `GVL_COMMAND.gvl`
- `PRG_System.st`
- `PRG_Security.st`
- `PRG_Command_Verifier.st`
- ранее подтвержденная downstream-картина по `PRG_IO_Write.st` и `PRG_Ventilation.st`

## Главный вывод
`GVL_COMMAND` уже не выглядит как единый execution-layer.

По текущему live root его поля распадаются на три класса:
1. `bridge-only`
2. `comparison-only`
3. `unclear / legacy residue`

## Карта полей

### A. Gas / boiler / ventilation / water
Поля:
- `G_Gas_Valve_Close`
- `G_Boiler_Stop`
- `G_Supply_100_Req`
- `G_Supply_80_Req`
- `G_Vent_PV3_Boost`
- `G_Exhaust_100_Req`
- `G_Vent_Stop`
- `G_Close_Valve_35`
- `G_Close_Valve_36`

Предварительная категория:
- `G_Gas_Valve_Close`, `G_Close_Valve_36` -> `bridge-only`
- остальные поля группы -> `comparison-only`

Основание:
- execution-path уже подтвержден на `GVL_COMMAND_SHADOW`;
- в `PRG_System` подтвержден bridge-use-case для `G_Gas_Valve_Close` и `G_Close_Valve_36` через sync/redundancy path;
- остальные поля группы в проверенной цепочке выглядят как legacy-side для verifier/migration continuity.

### B. Access / locks / gate / wicket
Поля:
- `G_Gate_Open`
- `G_Wicket_Open`
- `G_Lock_1_Open`
- `G_Lock_1_Close`
- `G_Lock_2_Open`
- `G_Lock_2_Close`

Предварительная категория:
- `comparison-only`

Основание:
- access execution-path уже подтвержден на shadow/intents side;
- в проверенных live files прямой bridge-use-case для этих legacy-полей не подтвержден.

### C. Reset / scenario / gateway identity / 2FA / overrides
Поля:
- `G_Reset_Errors`
- `G_Scenario_Request`
- `G_Scenario_Request_Operator`
- `G_Arm_Req`
- `G_Disarm_Req`
- `G_PIN_Code`
- `G_RFID_Tag`
- `G_2FA_Code_In`
- `G_Send_2FA_Req`
- `G_2FA_Code_Out`
- `G_Lighting_Override`
- `G_Blinds_Override`
- `G_Socket_Override`

Предварительная категория:
- `G_Reset_Errors`, `G_Scenario_Request_Operator`, `G_Arm_Req`, `G_Disarm_Req`, `G_PIN_Code`, `G_RFID_Tag`, `G_2FA_Code_In`, `G_Send_2FA_Req`, `G_2FA_Code_Out`, `G_Lighting_Override`, `G_Blinds_Override`, `G_Socket_Override` -> `bridge-only`
- `G_Scenario_Request` -> `unclear / legacy residue`

Основание:
- в `PRG_System` подтверждены gateway/operator/intent-bridge use-cases;
- в `PRG_Security` подтверждены `G_Send_2FA_Req` и `G_2FA_Code_Out` как security-side bridge outputs;
- для `G_Scenario_Request` столь же явный current-use-case не подтвержден.

### D. Service / maintenance / test commands
Поля:
- `CMD_Set_Manifold_Pump_In_Service`
- `CMD_Set_DHW_Heating_Pump_In_Service`
- `CMD_Set_DHW_Circ_Pump_In_Service`
- `CMD_Dangerous_Action_Confirm`
- `CMD_Dangerous_Action_Request`
- `CMD_User_Access_Level`
- `CMD_Valve_Test_Open`
- `CMD_Valve_Test_Close`
- `CMD_Valve_Test_Confirm`
- `CMD_Water_Valve_Test_Open`
- `CMD_Water_Valve_Test_Close`
- `CMD_Water_Valve_Test_Confirm`
- `CMD_Gas_Valve_Test_Open`
- `CMD_Gas_Valve_Test_Close`
- `CMD_Gas_Valve_Test_Confirm`
- `CMD_Water_Selective_Recover`
- `CMD_Gas_Selective_Recover`

Предварительная категория:
- `unclear / needs program-level confirmation`

Основание:
- по текущему checked scope для этой группы не подтвержден ни явный execution-path, ни достаточный bridge-use-case.

## Сводная классификация

### Bridge-only
- `G_Gas_Valve_Close`
- `G_Close_Valve_36`
- `G_Reset_Errors`
- `G_Scenario_Request_Operator`
- `G_Arm_Req`
- `G_Disarm_Req`
- `G_PIN_Code`
- `G_RFID_Tag`
- `G_2FA_Code_In`
- `G_Send_2FA_Req`
- `G_2FA_Code_Out`
- `G_Lighting_Override`
- `G_Blinds_Override`
- `G_Socket_Override`

### Comparison-only
- `G_Boiler_Stop`
- `G_Supply_100_Req`
- `G_Supply_80_Req`
- `G_Vent_PV3_Boost`
- `G_Exhaust_100_Req`
- `G_Vent_Stop`
- `G_Close_Valve_35`
- `G_Gate_Open`
- `G_Wicket_Open`
- `G_Lock_1_Open`
- `G_Lock_1_Close`
- `G_Lock_2_Open`
- `G_Lock_2_Close`

### Unclear / legacy residue
- `G_Scenario_Request`
- вся группа `CMD_*`

## Практический смысл
После этой карты уже можно говорить предметно:
- часть полей оправдана как bridge-tail;
- часть полей выглядит как comparison-side residue;
- часть полей требует отдельной следующей проверки.

## Что пока не утверждается
- comparison-only поля не предлагается удалять уже сейчас;
- `CMD_*` группа не считается бесполезной без следующей проверки;
- `G_Scenario_Request` не признается лишним без scenario/gateway follow-up.

## Следующий рекомендуемый документ
- `41_COMMAND_SYSTEM_BRIDGE_AUDIT.md`

Его задача:
- пройти `PRG_System.st` уже прицельно по legacy bridge fields;
- подтвердить зависимости группы `bridge-only` и уточнить `unclear` поля system-side уровня.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения