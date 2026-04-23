# Command Service/Admin Group Audit

Дата фиксации: 2026-04-23

## Назначение
Этот документ выполняет targeted audit, открытый в `44_COMMAND_SERVICE_ADMIN_GROUP_AUDIT_PLAN.md`:
service / maintenance / admin группа `CMD_*` внутри legacy `GVL_COMMAND`.

Цель:
- проверить реальную live-root зависимость от `CMD_*` группы;
- отделить подтвержденный service/admin bridge-tail от still-unclear residue;
- не допустить слепой чистки maintenance и dangerous-action flows.

## Проверенные объекты
- `GVL_COMMAND.gvl`
- `PRG_System.st`
- ранее подтвержденные field-map и bridge audits текущего цикла
- live-root search по representative `CMD_*` сигналам

## Главный вывод
`CMD_*` группа не является однородной.

По доступному live-root подтверждению она уже распадается как минимум на две разные зоны:
1. **dangerous-action / admin-governed subcluster**, который действительно выглядит живым в `PRG_System`;
2. **valve-test / selective-recover / maintenance subcluster**, для которого по текущему checked scope еще не найдено столь же сильного program-level подтверждения.

Это означает, что treating всей `CMD_*` группы как мусор или всей группы как одинаково нужной — неверно.

## Подтвержденный subcluster A: dangerous-action / admin-governed

### Поля
- `CMD_Dangerous_Action_Request`
- `CMD_Dangerous_Action_Confirm`
- `CMD_User_Access_Level`

## Что подтверждено
По live-root search эти поля привязаны к `PRG_System.st`.

Дополнительно по самому `PRG_System.st` подтвержден контекст dangerous-action governance:
- локальные переменные `L_Dangerous_Action_Armed`, `L_Dangerous_Action_Deadline_MS`, `L_Gateway_Writes_Allowed`; 
- диагностический gate `GVL_STATUS.G_Diagnostics.Dangerous_Action_Pending_Confirm` используется как часть command arbitration / write allowance логики.

## Вывод
Этот subcluster нельзя считать простым residue.

Рабочая интерпретация на текущем этапе:
- **service/admin bridge-tail with dangerous-action governance role**.

Практический смысл:
- эти поля требуют отдельного contract-review и не должны чиститься автоматически.

## Подтвержденный subcluster B: maintenance/service context around `PRG_System`

### Косвенно поддерживающий контекст
В `PRG_System.st` подтверждено наличие maintenance-oriented локального контекста:
- `L_Last_DHW_Heating_In_Service`
- `L_Last_DHW_Circ_In_Service`
- `L_Maintenance_Apply_Intent`
- `GVL_Retain.G_Valve_Test_Results[...]`

## Вывод
Это подтверждает, что service/maintenance domain в system-layer реально существует и не является выдуманной категорией.

Но этого недостаточно, чтобы автоматически утверждать program-level use-case для каждого `CMD_Valve_Test_*` или `CMD_*_Recover` поля.

## Still-unclear subcluster C: valve-test / recover / service commands

### Поля
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

## Что подтверждено
По текущему checked live scope:
- эти поля присутствуют в `GVL_COMMAND.gvl`;
- service/maintenance контекст в `PRG_System.st` существует;
- но сильного program-level подтверждения readers/writers именно для этой подгруппы через доступный live search не получено.

## Вывод
На текущем этапе эта подгруппа должна оставаться в категории:
- **unclear / needs narrower dependency follow-up**.

Это честнее, чем:
- автоматически признать ее bridge-only,
- или автоматически признать ее residue.

## Обновленная классификация `CMD_*` группы

### Category 1. Dangerous-action governed
- `CMD_Dangerous_Action_Request`
- `CMD_Dangerous_Action_Confirm`
- `CMD_User_Access_Level`

Статус:
- подтвержденно живой admin/governance subcluster;
- не candidate на blind cleanup.

### Category 2. Service / maintenance context confirmed, field-level dependency not yet confirmed
- `CMD_Set_Manifold_Pump_In_Service`
- `CMD_Set_DHW_Heating_Pump_In_Service`
- `CMD_Set_DHW_Circ_Pump_In_Service`
- `CMD_Valve_Test_*`
- `CMD_Water_Valve_Test_*`
- `CMD_Gas_Valve_Test_*`
- `CMD_Water_Selective_Recover`
- `CMD_Gas_Selective_Recover`

Статус:
- service/maintenance domain подтвержден,
- но field-level live dependency для этой подгруппы еще не доказана достаточно сильно.

## Что этот аудит НЕ утверждает

### SAGA-NO-01
Он не утверждает, что valve-test/recover подгруппа бесполезна.

### SAGA-NO-02
Он не утверждает, что dangerous-action subcluster уже fully understood contract-wise.

### SAGA-NO-03
Он не утверждает, что вся `CMD_*` группа должна оставаться в `GVL_COMMAND` без изменений навсегда.

## Главный практический эффект этапа
После этого аудита неопределенность вокруг `CMD_*` уже заметно сузилась:
- dangerous-action / admin-governed часть больше не является «непонятным хвостом»;
- основной remaining ambiguity сосредоточен в valve-test / recover / in-service maintenance подгруппе.

То есть следующий шаг уже можно делать не по всей `CMD_*` группе, а по более узкому maintenance/test cluster.

## Следующий рекомендуемый документ
- `46_COMMAND_MAINTENANCE_TEST_CLUSTER_PLAN.md`

Его задача:
- открыть узкий follow-up по valve-test / recover / in-service подгруппе;
- определить, какие files/programs нужно пройти для field-level dependency confirmation.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения