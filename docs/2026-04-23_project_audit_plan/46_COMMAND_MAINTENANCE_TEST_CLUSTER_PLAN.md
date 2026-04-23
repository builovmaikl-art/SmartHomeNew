# Command Maintenance/Test Cluster Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ открывает следующий узкий follow-up после `45_COMMAND_SERVICE_ADMIN_GROUP_AUDIT.md`:
**audit maintenance/test/recover подгруппы внутри legacy `GVL_COMMAND`**.

Цель:
- сузить remaining ambiguity до конкретного поднабора `CMD_*` полей;
- проверить field-level dependency для maintenance/test/recover use-cases;
- отделить реально живой maintenance bridge-tail от возможного residue.

## Основание
План опирается на:
- `44_COMMAND_SERVICE_ADMIN_GROUP_AUDIT_PLAN.md`
- `45_COMMAND_SERVICE_ADMIN_GROUP_AUDIT.md`
- `40_COMMAND_LEGACY_BRIDGE_FIELD_MAP_AUDIT.md`
- текущее состояние `GVL_COMMAND.gvl`

## Почему этот scope идёт следующим
После `45_COMMAND_SERVICE_ADMIN_GROUP_AUDIT.md` уже зафиксировано:
- dangerous-action / admin-governed subcluster подтверждён как живой;
- основная remaining ambiguity сосредоточена уже не во всей `CMD_*` группе, а только в maintenance/test/recover подгруппе.

Следовательно, следующий шаг должен быть уже не broad audit, а **narrow dependency follow-up**.

## Область следующего аудита
Под targeted audit попадает maintenance/test/recover подгруппа:
- `CMD_Set_Manifold_Pump_In_Service`
- `CMD_Set_DHW_Heating_Pump_In_Service`
- `CMD_Set_DHW_Circ_Pump_In_Service`
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

## Главные вопросы следующего шага
Для этой подгруппы нужно ответить на вопросы:
1. какие поля реально читаются в live root;
2. какие поля реально записываются из system/HMI/gateway flows;
3. какие поля участвуют в maintenance-mode workflows;
4. какие поля связаны с valve-test / selective-recover logic;
5. какие поля не получают достаточного live-root подтверждения и становятся residue candidates.

## Рабочие гипотезы

### MTC-01
Подгруппа `CMD_Set_*_In_Service` может быть связана с maintenance/apply-intent flows и не должна чиститься без проверки.

### MTC-02
Подгруппа `CMD_*Valve_Test*` может быть частью отдельного valve-test workflow, который не виден в уже пройденном грубом search.

### MTC-03
Подгруппа `CMD_*Selective_Recover` может быть связана с recovery logic и потому требует отдельного контекстного подтверждения.

### MTC-04
Часть этих полей может оказаться слабо подтверждённым residue, но это нужно доказать program-level зависимостями, а не только по названиям.

## Что именно нужно проверить

### MTC-P1. Readers
Нужно найти реальные readers подгруппы в live root.

Особый приоритет:
- `PRG_System.st`
- heating-related files
- safety/recovery paths
- maintenance/test related files
- HMI or gateway related bridges

### MTC-P2. Writers
Нужно понять, кто реально пишет эти поля:
- system bridge,
- HMI/config path,
- gateway path,
- operator/admin workflows.

### MTC-P3. Workflow grouping
Нужно попытаться разложить подгруппу не только по отдельным полям, но и по workflows:
- in-service toggles,
- valve-test workflow,
- selective recovery workflow.

### MTC-P4. Evidence threshold
Если для какого-то поля нет уверенного live-root подтверждения, его нужно пометить как:
- `unclear / insufficient evidence`,
а не автоматически относить к useless residue.

## Что НЕ нужно делать на этом этапе

### MTC-NO-01
Не удалять maintenance/test/recover поля кодово.

### MTC-NO-02
Не переносить их автоматически в `GVL_COMMAND_SHADOW`.

### MTC-NO-03
Не делать вывод, что весь подкластер нужен или весь подкластер лишний.

### MTC-NO-04
Не смешивать этот узкий follow-up с already-confirmed dangerous-action/admin subcluster.

## Ожидаемый результат этапа
После targeted audit должна появиться более точная карта maintenance/test/recover подгруппы:
- `confirmed maintenance bridge`
- `confirmed test workflow dependency`
- `confirmed recovery workflow dependency`
- `still unclear / residue candidates`

## Практический следующий документ
- `47_COMMAND_MAINTENANCE_TEST_CLUSTER_AUDIT.md`

Его задача:
- пройти maintenance/test/recover подгруппу по readers/writers;
- разложить её по workflow-зависимостям и подготовить следующий cleanup shortlist.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения