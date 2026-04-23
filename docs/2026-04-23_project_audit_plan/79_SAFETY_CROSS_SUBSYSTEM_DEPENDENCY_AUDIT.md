# Safety Cross-Subsystem Dependency Audit

Дата фиксации: 2026-04-23

## Назначение
Этот документ выполняет этап `S-A3` из `76_SAFETY_AUDIT_PLAN.md`:
**cross-subsystem dependency audit** для safety layer.

Цель:
- пройти связи safety с heating, ventilation, security, system layer и command arbitration;
- понять, как producer-side safety logic реально замыкается в downstream interlock usage;
- выявить, где dependency-chain уже чистая и где возможен producer-heavier хвост.

## Основание
Документ опирается на:
- `78_SAFETY_OWNERSHIP_AND_PUBLICATION_AUDIT.md`
- текущее состояние `PRG_Safety.st`
- текущее состояние `PRG_Command_Arbitration.st`
- текущее состояние `PRG_Heating.st`
- текущее состояние `PRG_Ventilation.st`
- текущее состояние `PRG_System.st`
- текущее состояние `PRG_Security.st`

## Главный вывод
Safety layer уже не является изолированным локальным program-block.

По текущему live root он встроен в выраженную cross-subsystem dependency-chain:
- `PRG_System.st` производит/восстанавливает часть latched safety state;
- `PRG_Safety.st` проектирует этот state и detector results в `GVL_INTENT_SAFETY`;
- `PRG_Command_Arbitration.st` превращает часть этих intents в `GVL_COMMAND_SHADOW` operational commands;
- `PRG_Ventilation.st` и `PRG_Heating.st` дополнительно имеют direct safety-state dependencies;
- `PRG_Security.st` в текущем виде не выглядит direct consumer `GVL_INTENT_SAFETY`, но safety effects доходят до access/security paths downstream через command arbitration и system mode.

Это означает:
- safety действительно cross-cutting layer;
- его risk surface определяется не только внутренним кодом `PRG_Safety.st`, но и тем, как разные подсистемы потребляют разные формы safety semantics: raw/latched state, intents и mode/interlock outputs.

## Dependency chain by layer

### SCSA-01. `PRG_System.st` как upstream owner of latched safety state and mode integration
`PRG_System.st`:
- восстанавливает из persistent state
  - `G_Safety_Gas_Latched`
  - `G_Safety_Smoke_Latched`
  - `G_Safety_Leak_Latched`
  - `G_System_Mode`
- вызывает `fbSafety(...)`, который публикует:
  - `VO_Gas_Latched => GVL_STATE.G_Safety_Gas_Latched`
  - `VO_Leak_Latched => GVL_STATE.G_Safety_Leak_Latched`
  - `VO_Smoke_Latched => GVL_STATE.G_Safety_Smoke_Latched`
  - `VO_Emergency_Stop => GVL_STATE.G_Safety_Emergency_Stop`
- далее интегрирует safety/health into system health and system mode.

Вывод:
- `PRG_System.st` является важным upstream owner safety-latched state и system-wide integration layer.

### SCSA-02. `PRG_Safety.st` как producer of cross-system required actions
`PRG_Safety.st`:
- читает latched safety state и health bridge results;
- формирует `GVL_INTENT_SAFETY` как главный safety publication surface;
- сам задает interlock-oriented required actions для газа, воды, вентиляции, отопления, замков и эвакуации.

Вывод:
- `PRG_Safety.st` является центральным producer-side semantic mapping layer.

### SCSA-03. `PRG_Command_Arbitration.st` как главный downstream operational consumer of safety intents
`PRG_Command_Arbitration.st` подтверждает direct consumption safety-intents, в том числе:
- `I_Fire_Alarm_Active` -> `G_Boiler_Stop`, `G_Vent_Stop`, `G_Lock_1_Open`, `G_Lock_2_Open`
- `I_Gas_Close_Required` -> `G_Gas_Valve_Close`, `G_Boiler_Stop`
- `I_Vent_Force_PV3_Boost` -> `G_Vent_PV3_Boost`
- `I_Vent_Force_Supply_100` -> `G_Supply_100_Req`
- `I_Vent_Force_Supply_80` -> `G_Supply_80_Req`
- `I_Vent_Stop_Required` -> `G_Vent_Stop`
- `I_Water_Main_Close_Required` -> `G_Close_Valve_35`, `G_Close_Valve_36`

Вывод:
- значительная часть safety publication реально замыкается в operational command layer через arbitration.

## Dependencies into already-audited subsystems

### SCSA-04. Ventilation has direct dependency on latched safety state
`PRG_Ventilation.st` передает в manager:
- `VI_Fire_Alarm := GVL_STATE.G_Safety_Smoke_Latched`
- `VI_Gas_Alarm := GVL_STATE.G_Safety_Gas_Latched`

Вывод:
- ventilation зависит от safety не только через arbitration/commands, но и напрямую через latched safety state.

Практический смысл:
- ventilation получает safety semantics по двум каналам:
  1. direct latched state;
  2. operational safety-forced requests через command arbitration.

### SCSA-05. Heating has direct dependency on safety state and feeds safety back via freeze hardware status
`PRG_Heating.st` использует:
- `GVL_STATE.G_Safety_Emergency_Stop`
- `GVL_STATE.G_Safety_Gas_Latched`

для heating arbitration/gating.

Одновременно `PRG_Heating.st` публикует:
- `GVL_STATE.G_Freeze_Hardware_Degraded`
- `GVL_STATE.G_Freeze_Hardware_Failed`

А `PRG_Safety.st` далее читает:
- `GVL_STATE.G_Freeze_Hardware_Degraded`

и проецирует это в:
- `GVL_INTENT_SAFETY.I_Freeze_Protection_Required`.

Вывод:
- между heating и safety существует двухсторонняя dependency-chain;
- это не defect само по себе, но это подтвержденный feedback loop.

### SCSA-06. Security is affected more indirectly than directly
`PRG_Security.st` в текущем live root не выглядит direct consumer `GVL_INTENT_SAFETY`.

При этом безопасность/access path затрагивается двумя downstream путями:
- через `PRG_Command_Arbitration.st`, где fire alarm принудительно открывает lock commands в shadow layer;
- через `VI_System_Mode := GVL_STATE.G_System_Mode` в `fbAccessControl(...)`, то есть через system-level mode gating.

Вывод:
- security/access находится под safety influence mostly indirectly, not through direct safety-intent consumption inside `PRG_Security.st`.

## Cross-subsystem patterns now visible

### SCSA-07. Safety semantics split across three forms
По текущему live root safety semantics распространяется тремя формами:
1. **Latched/raw safety state** in `GVL_STATE`
2. **Safety intent projection** in `GVL_INTENT_SAFETY`
3. **System-mode / health integration** through `PRG_System.st` and `GVL_STATE.G_System_Mode`

Вывод:
- safety architecture уже многоуровневая, а не однослойная.

### SCSA-08. Different subsystems consume different safety forms
- ventilation consumes latched state directly and command-forced requests indirectly;
- heating consumes direct safety state and publishes freeze-hardware state back upward;
- command arbitration consumes `GVL_INTENT_SAFETY` directly;
- security/access consumes system mode and is indirectly affected by arbitration outcomes.

Вывод:
- нет единой universal safety-consumption model для всех подсистем.

### SCSA-09. This is where ownership complexity really lives
Сложность safety layer рождается не из broken single interface, а из того, что разные consumers читают safety semantics на разных стадиях pipeline.

Вывод:
- именно это делает safety wave более cross-cutting и architecturally subtle, чем предыдущие локальные subsystem waves.

## Potential producer-heavier tail

### SCSA-10. Not every published safety-intent is equally confirmed as downstream-consumed
По доступному checked live scope хорошо подтверждены downstream-consumers для:
- fire/gas/vent/water related required actions in `PRG_Command_Arbitration.st`.

Но для некоторых полей вроде:
- `I_Freeze_Protection_Required`
- `I_Evacuation_Mode_Active`
- `I_System_Safe_Stop_Required`

на этом этапе не получено столь же явного live downstream-consumer подтверждения внутри checked scope.

Вывод:
- это не означает, что поля лишние;
- это означает, что safety producer layer может быть heavier than confirmed consumer set for part of its publication surface.

Это важное наблюдение для следующего boundary interpretation step.

## What this stage does NOT claim yet

### SCSA-NO-01
Этот этап не утверждает, что multi-form safety semantics already wrong by design.

### SCSA-NO-02
Он не утверждает, что `PRG_Safety.st` нужно немедленно дробить.

### SCSA-NO-03
Он не утверждает, что all safety intents must have direct consumers in the same cycle to be valid.

Он утверждает только:
- cross-subsystem dependency-chain реально существует;
- direct, indirect and feedback dependencies уже достаточно сложны;
- часть safety publication surface подтвержденно operationally grounded, а часть пока выглядит менее явно consumed.

## Practical interpretation

### SCSA-11. Safety boundary is not broken, but semantically layered
Это не broken-boundary case.

Это layered-boundary case с несколькими consumer forms.

### SCSA-12. The key architecture question now is proportionality of producer-side ownership
Раз главный publication boundary работает, следующий вопрос не «где сломан интерфейс», а:
- не слишком ли много semantic mapping и publication surface владеет один `PRG_Safety.st` относительно подтвержденного consumer landscape.

## Практический эффект этапа S-A3
После этого этапа safety wave уже достаточно подготовлена для boundary/architecture interpretation:
- мы видим upstream owners,
- central producer,
- direct operational consumers,
- direct subsystem consumers,
- feedback loops,
- and partially unconfirmed tail of publication surface.

Это дает хорошую базу для следующего решения:
- трактовать current safety architecture как acceptable layered design,
или
- считать ownership concentration уже слишком широкой.

## Следующий рекомендуемый документ
- `80_SAFETY_BOUNDARY_ARCHITECTURE_INTERPRETATION.md`

Его задача:
- выполнить этап `S-A4`;
- решить, выглядит ли safety cluster coherent but heavy, thin but leaky, или ownership-heavy enough to justify a focused cleanup direction.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения