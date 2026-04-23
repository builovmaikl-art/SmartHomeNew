# Command Bridge Shortlist Decision

Дата фиксации: 2026-04-23

## Назначение
Этот документ сводит выводы из:
- `41_COMMAND_SYSTEM_BRIDGE_AUDIT.md`
- `42_COMMAND_SECURITY_BRIDGE_AUDIT.md`
- `40_COMMAND_LEGACY_BRIDGE_FIELD_MAP_AUDIT.md`

в единое решение по следующему cleanup shortlist для legacy `GVL_COMMAND`.

Цель:
- зафиксировать, какие поля legacy-layer временно считаются оправданным bridge-tail;
- какие поля уже выглядят как comparison-only residue;
- какие поля и группы требуют следующей отдельной targeted-проверки.

## Главный вывод
После system-side и security-side program-level audit legacy `GVL_COMMAND` уже можно разбирать не как единый «старый слой», а как три практические зоны:

1. **Retain temporarily as bridge-only**
2. **Treat as comparison-only residue**
3. **Target next because still unclear**

Это и есть рабочий shortlist следующей cleanup-волны.

## Shortlist A. Retain temporarily as bridge-only
Эта группа пока не должна убираться или переноситься вслепую, потому что для нее подтвержден реальный bridge-use-case.

### A1. System bridge fields
- `G_Gas_Valve_Close`
- `G_Close_Valve_36`
- `G_Reset_Errors`
- `G_Scenario_Request_Operator`
- `G_Arm_Req`
- `G_Disarm_Req`
- `G_PIN_Code`
- `G_RFID_Tag`
- `G_2FA_Code_In`
- `G_Lighting_Override`
- `G_Blinds_Override`
- `G_Socket_Override`

Подтвержденная роль:
- sync / redundancy bridge,
- gateway bridge,
- user-intent bridge,
- operator scenario bridge.

### A2. Security / gateway exchange bridge fields
- `G_Send_2FA_Req`
- `G_2FA_Code_Out`

Подтвержденная роль:
- outbound 2FA exchange bridge between security manager and gateway/system layer.

## Shortlist B. Treat as comparison-only residue
Эта группа в подтвержденной live chain уже не выглядит как primary execution path и в system/security audits не получила сильного bridge-use-case.

### B1. Legacy execution residue
- `G_Boiler_Stop`
- `G_Supply_100_Req`
- `G_Supply_80_Req`
- `G_Vent_PV3_Boost`
- `G_Exhaust_100_Req`
- `G_Vent_Stop`
- `G_Close_Valve_35`

### B2. Legacy access command residue
- `G_Gate_Open`
- `G_Wicket_Open`
- `G_Lock_1_Open`
- `G_Lock_1_Close`
- `G_Lock_2_Open`
- `G_Lock_2_Close`

Подтвержденная текущая интерпретация:
- comparison-side legacy surface,
- migration continuity residue,
- но не подтвержденный primary downstream execution layer.

Практический смысл:
- эту группу пока не нужно удалять немедленно,
- но именно она является главным кандидатом на future reduction after further migration cleanup.

## Shortlist C. Target next because still unclear
Эта группа не должна ни автоматически сохраняться навсегда, ни автоматически считаться мусором.

### C1. Scenario ambiguity
- `G_Scenario_Request`

Почему отдельно:
- для него не подтвержден такой же сильный current-use-case, как для `G_Scenario_Request_Operator`;
- нужен отдельный scenario/gateway follow-up.

### C2. Service / maintenance / admin command group
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

Почему отдельно:
- по already checked scope их роль пока не доказана ни как чистый bridge-tail, ни как явный мусор;
- им нужен отдельный service/admin dependency audit.

## Практическое решение по очередности

### Priority 1
Не трогать Shortlist A кодово без отдельного bridge migration plan.

### Priority 2
Не считать Shortlist B нормальным final-state; рассматривать его как main candidate for later reduction.

### Priority 3
Следующим targeted audit брать Shortlist C, потому что именно он сейчас мешает завершить field-level картину legacy-layer.

## Что это означает для следующей cleanup-волны
Следующая волна должна идти не по всему `GVL_COMMAND`, а по двум отдельным направлениям:

### Path 1. Preserve but map bridge-only subset
Для Shortlist A:
- сохранить временно,
- но не расширять его без необходимости,
- позже переводить по controlled bridge migration plan.

### Path 2. Resolve ambiguity subset
Для Shortlist C:
- провести следующий targeted audit,
- после него решить, что из этой группы реально еще нужно,
- и только затем возвращаться к вопросу final shortlist reduction.

## Что НЕ делать после этого решения
- не пытаться удалить весь legacy-layer целиком;
- не смешивать bridge-only subset и comparison-only residue в одну группу;
- не считать `CMD_*` автоматически мусором;
- не переносить Shortlist A целиком на shadow-layer без dependency-level plan.

## Главный практический эффект этапа
После этого решения command-layer cleanup получает уже не абстрактную, а управляемую форму:
- что временно оставляем;
- что считаем residue;
- что берем следующим targeted scope.

Это существенно сужает неопределенность перед следующей волной.

## Следующий рекомендуемый документ
- `44_COMMAND_SERVICE_ADMIN_GROUP_AUDIT_PLAN.md`

Его задача:
- открыть targeted audit по `CMD_*` группе;
- проверить service / maintenance / dangerous-action / valve-test / recover команды на реальную зависимость в live root.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения