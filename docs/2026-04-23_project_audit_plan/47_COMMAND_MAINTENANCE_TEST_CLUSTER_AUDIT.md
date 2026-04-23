# Command Maintenance/Test Cluster Audit

Дата фиксации: 2026-04-23

## Назначение
Этот документ выполняет targeted audit, открытый в `46_COMMAND_MAINTENANCE_TEST_CLUSTER_PLAN.md`:
maintenance/test/recover подкластер внутри legacy `GVL_COMMAND`.

Цель:
- проверить field-level dependency для maintenance/test/recover use-cases;
- отделить подтвержденный maintenance bridge-tail от still-unclear residue;
- сузить remaining ambiguity внутри legacy `CMD_*` группы.

## Проверенные объекты
- `GVL_COMMAND.gvl`
- `PRG_System.st`
- live-root search по representative полям:
  - `CMD_Set_*_In_Service`
  - `CMD_Valve_Test_*`
  - `CMD_Water_Valve_Test_*`
  - `CMD_Gas_Valve_Test_*`
  - `CMD_*Selective_Recover`
- ранее подтвержденный service/admin audit текущего цикла

## Главный вывод
Подкластер maintenance/test/recover тоже не является однородным.

По доступному live-root подтверждению он уже разделяется минимум на две части:
1. **maintenance in-service subcluster**, который подтвержденно связан с `PRG_System` и maintenance-oriented system context;
2. **valve-test / selective-recover subcluster**, для которого по текущему checked scope не найдено столь же сильного program-level подтверждения readers/writers.

Это означает:
- вся maintenance/test группа не может считаться residue целиком;
- но и подтвержденной целиком как live bridge/workflow dependency она тоже пока не является.

## Подтвержденный subcluster A: in-service maintenance commands

### Поля
- `CMD_Set_Manifold_Pump_In_Service`
- `CMD_Set_DHW_Heating_Pump_In_Service`
- `CMD_Set_DHW_Circ_Pump_In_Service`

## Что подтверждено
По live-root search эти поля привязаны к `PRG_System.st`.

По самому `PRG_System.st` подтвержден maintenance-oriented локальный контекст:
- `L_Last_DHW_Heating_In_Service`
- `L_Last_DHW_Circ_In_Service`
- `L_Maintenance_Apply_Intent`

Также наличие шага `gate_maintenance_apply_by_mode` в репозитории дополнительно поддерживает интерпретацию этой подгруппы как maintenance-governed, а не случайного residue.

## Вывод
Эта подгруппа должна трактоваться как:
- **confirmed maintenance bridge/use-case candidate**.

Практический смысл:
- её нельзя убирать или объявлять мусором без отдельного maintenance contract review.

## Still-unclear subcluster B: valve-test commands

### Поля
- `CMD_Valve_Test_Open`
- `CMD_Valve_Test_Close`
- `CMD_Valve_Test_Confirm`
- `CMD_Water_Valve_Test_Open`
- `CMD_Water_Valve_Test_Close`
- `CMD_Water_Valve_Test_Confirm`
- `CMD_Gas_Valve_Test_Open`
- `CMD_Gas_Valve_Test_Close`
- `CMD_Gas_Valve_Test_Confirm`

## Что подтверждено
По текущему checked scope:
- эти поля присутствуют в `GVL_COMMAND.gvl`;
- в `PRG_System.st` есть косвенный maintenance/test контекст, включая `GVL_Retain.G_Valve_Test_Results[...]`;
- но сильного live-root подтверждения readers/writers именно для этих command-полей через доступный search не получено.

## Вывод
Эта подгруппа остается в категории:
- **unclear / needs narrower workflow confirmation**.

Это честнее, чем автоматически считать её:
- либо точно live,
- либо точно residue.

## Still-unclear subcluster C: selective recover commands

### Поля
- `CMD_Water_Selective_Recover`
- `CMD_Gas_Selective_Recover`

## Что подтверждено
По текущему checked scope:
- поля присутствуют в `GVL_COMMAND.gvl`;
- сам домен maintenance/recovery в system-layer выглядит реальным;
- но сильного live-root подтверждения program-level readers/writers именно для этих полей пока не найдено.

## Вывод
Эта подгруппа тоже остается в категории:
- **unclear / needs recovery-specific follow-up**.

## Обновленная классификация maintenance/test cluster

### Category 1. Confirmed maintenance bridge/use-case candidate
- `CMD_Set_Manifold_Pump_In_Service`
- `CMD_Set_DHW_Heating_Pump_In_Service`
- `CMD_Set_DHW_Circ_Pump_In_Service`

### Category 2. Unclear valve-test workflow dependency
- `CMD_Valve_Test_*`
- `CMD_Water_Valve_Test_*`
- `CMD_Gas_Valve_Test_*`

### Category 3. Unclear selective-recover workflow dependency
- `CMD_Water_Selective_Recover`
- `CMD_Gas_Selective_Recover`

## Что этот audit НЕ утверждает

### MTCA-NO-01
Он не утверждает, что valve-test подгруппа бесполезна.

### MTCA-NO-02
Он не утверждает, что selective-recover подгруппа лишняя.

### MTCA-NO-03
Он не утверждает, что in-service подгруппа уже fully understood contract-wise.

Он утверждает только, что:
- у in-service подгруппы уже есть подтвержденный maintenance-oriented system-side след;
- у valve-test и selective-recover подгрупп такой же силы подтверждения пока нет.

## Главный практический эффект этапа
После этого audit remaining ambiguity в maintenance/test cluster еще сильнее сузилась:
- confirmed maintenance side теперь отделена от test/recover unknowns;
- следующий follow-up уже не должен проходить по всей подгруппе разом;
- если продолжать, то нужно идти уже в еще более узкий workflow-level audit:
  - отдельно valve-test,
  - отдельно selective recover.

## Следующий рекомендуемый документ
- `48_COMMAND_VALVE_TEST_AND_RECOVER_FOLLOWUP_DECISION.md`

Его задача:
- решить, идем ли следующим шагом в valve-test/recover deep follow-up,
- или считаем текущую степень детализации достаточной для временной фиксации shortlist.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения