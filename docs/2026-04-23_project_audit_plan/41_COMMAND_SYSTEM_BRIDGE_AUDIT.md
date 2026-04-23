# Command System Bridge Audit

Дата фиксации: 2026-04-23

## Назначение
Этот документ открывает следующий program-level этап после `40_COMMAND_LEGACY_BRIDGE_FIELD_MAP_AUDIT.md`:
**system-side audit legacy bridge fields в `PRG_System.st`**.

Цель:
- подтвердить, какие поля `GVL_COMMAND` реально живут в `PRG_System` как bridge / coordination surface;
- отделить подтвержденные system-side bridge dependencies от полей, которые здесь уже не играют заметной operational роли;
- подготовить следующую волну cleanup вокруг `PRG_System` без слепого переноса всего legacy-layer.

## Основание
Документ опирается на:
- `38_COMMAND_LEGACY_BRIDGE_BOUNDARY_PLAN.md`
- `40_COMMAND_LEGACY_BRIDGE_FIELD_MAP_AUDIT.md`
- текущее состояние `PRG_System.st`

## Главный вывод
`PRG_System.st` действительно подтверждает, что часть `GVL_COMMAND` еще жива как **system bridge / coordination surface**.

Но эта роль уже не тождественна «главному execution layer».

По текущему live root `PRG_System` использует `GVL_COMMAND` прежде всего для:
- redundancy/state sync;
- gateway bridge;
- user-intent publication;
- reset / operator / scenario bridge.

Это подтверждает, что legacy `GVL_COMMAND` в `PRG_System` еще нужен, но уже как **bridge-tail**, а не как core operational command model.

## Подтвержденные system-side bridge зависимости

### SBA-01. Redundancy / state sync bridge
В `PRG_System.st` подтверждено использование:
- `GVL_COMMAND.G_Gas_Valve_Close`
- `GVL_COMMAND.G_Close_Valve_36`

в логике локального state snapshot и в применении synced state.

Вывод:
- эти поля действительно имеют system-side bridge/use-case;
- их нельзя считать чистым мусором legacy-layer на текущем этапе.

### SBA-02. Reset bridge
В `PRG_System.st` подтверждено использование:
- `GVL_COMMAND.G_Reset_Errors`

в нескольких местах system-side orchestration, включая safety/reset-related path и gateway export/import use-case.

Вывод:
- `G_Reset_Errors` — подтвержденный bridge-only field system-side уровня.

### SBA-03. Gateway / user identity bridge
В `PRG_System.st` подтверждено использование:
- `G_Arm_Req`
- `G_Disarm_Req`
- `G_PIN_Code`
- `G_RFID_Tag`
- `G_2FA_Code_In`

через `fbGateway(...)` и последующую publication в `GVL_INTENT_USER`.

Вывод:
- эта группа является реальной gateway-to-intent bridge surface;
- это не execution-path в смысле downstream actuation, но это активный coordination bridge.

### SBA-04. Override bridge
В `PRG_System.st` подтверждено использование:
- `G_Lighting_Override`
- `G_Blinds_Override`
- `G_Socket_Override`

через gateway bridge и последующую user-intent publication.

Вывод:
- overrides являются подтвержденным system-side bridge-tail.

### SBA-05. Scenario/operator bridge
В `PRG_System.st` подтверждено использование:
- `G_Scenario_Request_Operator`

в operator scenario gate/arbitration path.

Вывод:
- это подтвержденный operator-bridge field.

### SBA-06. Gateway / 2FA outbound bridge
В `PRG_System.st` подтверждено использование:
- `G_Send_2FA_Req`
- `G_2FA_Code_Out`

как входов для `fbGateway(...)` outbound path.

Вывод:
- эти поля подтверждены как system-side gateway/security exchange bridge.

## Поля, которые в `PRG_System.st` НЕ выглядят как главный execution path

### SBA-NX-01. Legacy execution command group
В пределах проверенного `PRG_System.st` не подтверждено, что поля вроде:
- `G_Boiler_Stop`
- `G_Supply_100_Req`
- `G_Supply_80_Req`
- `G_Vent_PV3_Boost`
- `G_Exhaust_100_Req`
- `G_Vent_Stop`
- access open/close commands

играют здесь роль основного execution layer.

Вывод:
- system-side audit не опровергает предыдущую classification как comparison-side residue для этих групп.

### SBA-NX-02. `G_Scenario_Request`
В проверенном `PRG_System.st` явный и такой же сильный current-use-case для `G_Scenario_Request`, как для `G_Scenario_Request_Operator`, не подтвержден.

Вывод:
- поле остается в категории `unclear / needs follow-up`.

### SBA-NX-03. `CMD_*` service / maintenance group
По текущему checked scope `PRG_System.st` не дает достаточно подтверждений, чтобы перевести всю группу `CMD_*` из `unclear` в уверенную category.

Вывод:
- для этой группы still нужен отдельный follow-up.

## Обновленная system-side интерпретация field map

### Подтвержденные system bridge fields
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

### Поля, чья system-side bridge роль не подтверждена этим этапом
- `G_Scenario_Request`
- вся группа `CMD_*`
- legacy execution/access command residue group

## Главный практический эффект этапа
После этого аудита уже можно говорить точнее:
- `PRG_System` действительно является одним из главных держателей остаточной bridge-ценности legacy `GVL_COMMAND`;
- но эта ценность сосредоточена не в старом execution-path, а в sync/gateway/operator/reset/security-exchange хвосте.

Это значит, что future cleanup `PRG_System` должен быть адресным:
- не переносить весь `GVL_COMMAND` wholesale;
- сначала выделить именно bridge-critical subset.

## Что пока не закрыто
Этот этап не закрывает:
- security-side dependency map;
- `CMD_*` group classification;
- судьбу `G_Scenario_Request`;
- future migration path для confirmed system bridge fields.

## Следующий рекомендуемый документ
- `42_COMMAND_SECURITY_BRIDGE_AUDIT.md`

Его задача:
- подтвердить legacy bridge dependencies на стороне `PRG_Security`;
- после этого можно будет свести system-side и security-side bridge map в общий shortlist следующей cleanup-волны.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения