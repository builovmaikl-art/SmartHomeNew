# Command Service/Admin Group Audit Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ открывает следующий targeted scope после `43_COMMAND_BRIDGE_SHORTLIST_DECISION.md`:
**audit service / maintenance / admin command group внутри legacy `GVL_COMMAND`**.

Цель:
- проверить реальную live-root зависимость от группы `CMD_*`;
- отделить реально используемые service/admin команды от possible legacy residue;
- не допустить ошибочного удаления полезных maintenance recovery paths.

## Основание
План опирается на:
- `40_COMMAND_LEGACY_BRIDGE_FIELD_MAP_AUDIT.md`
- `41_COMMAND_SYSTEM_BRIDGE_AUDIT.md`
- `43_COMMAND_BRIDGE_SHORTLIST_DECISION.md`
- текущее состояние `GVL_COMMAND.gvl`

## Почему этот scope выбран следующим
После bridge shortlist decision именно группа `CMD_*` остается самым крупным блоком с недостаточно подтвержденной ролью.

Эта группа не попала уверенно ни в:
- bridge-only subset,
ни в:
- comparison-only residue.

Следовательно, она сейчас является главным источником remaining ambiguity внутри legacy `GVL_COMMAND`.

## Область следующего аудита
Под audit попадает вся service/admin группа:
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

## Главные вопросы следующего аудита
Для этой группы нужно ответить на вопросы:
1. какие поля реально читаются в live root;
2. какие поля реально записываются из gateway/HMI/system paths;
3. какие из них относятся к maintenance/service workflows;
4. какие из них завязаны на dangerous-action gating/confirm flows;
5. какие поля уже выглядят как residue без подтвержденного use-case.

## Рабочие гипотезы перед audit

### H-01
Часть `CMD_*` может оказаться реальным maintenance/admin bridge-tail, а не мусором.

### H-02
Часть `CMD_*` может быть связана с dangerous-action governance и потому не должна чиститься без отдельного contract-review.

### H-03
Часть `CMD_*` может уже не иметь подтвержденного current-use-case и оказаться кандидатом на later reduction.

## Что именно нужно проверить

### SGA-01. Program-level readers
Нужно найти, какие program/files реально читают `CMD_*` поля.

Особый интерес:
- `PRG_System.st`
- heating-related files
- maintenance/test logic
- recovery/selective-recover paths
- HMI/gateway related bridges

### SGA-02. Program-level writers
Нужно понять, кто реально пишет эти поля:
- gateway,
- HMI/config layer,
- system bridge,
- другие integration paths.

### SGA-03. Dangerous-action contract
Нужно отдельно проверить связку:
- `CMD_Dangerous_Action_Request`
- `CMD_Dangerous_Action_Confirm`
- `CMD_User_Access_Level`

Это может быть не просто service residue, а часть safety-governed administrative workflow.

### SGA-04. Valve test / selective recover cluster
Нужно отдельно проверить:
- `CMD_Valve_Test_*`
- `CMD_Water_Valve_Test_*`
- `CMD_Gas_Valve_Test_*`
- `CMD_Water_Selective_Recover`
- `CMD_Gas_Selective_Recover`

Это likely отдельный subcluster, который нельзя оценивать поштучно без контекста maintenance/recovery logic.

## Что НЕ нужно делать на этом этапе

### SGA-NO-01
Не удалять `CMD_*` поля кодово.

### SGA-NO-02
Не переносить их автоматически в `GVL_COMMAND_SHADOW`.

### SGA-NO-03
Не считать всю группу одинаковой по роли.

### SGA-NO-04
Не смешивать service/admin audit с general bridge-only subset.

## Ожидаемый результат этапа
После targeted audit должна появиться более точная карта:
- `service/admin bridge-only`
- `dangerous-action governed`
- `maintenance/test live-use`
- `unclear residue candidates`

## Практический следующий документ
- `45_COMMAND_SERVICE_ADMIN_GROUP_AUDIT.md`

Его задача:
- пройти `CMD_*` группу по реальным readers/writers;
- разложить ее по use-case категориям и подготовить следующий cleanup shortlist.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения