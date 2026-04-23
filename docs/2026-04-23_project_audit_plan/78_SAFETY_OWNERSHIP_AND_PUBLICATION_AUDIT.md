# Safety Ownership and Publication Audit

Дата фиксации: 2026-04-23

## Назначение
Этот документ выполняет этап `S-A2` из `76_SAFETY_AUDIT_PLAN.md`:
**ownership/publication audit** для safety cluster.

Цель:
- понять, где именно живет ownership alarms/latches/interlocks;
- отделить clean publication paths от direct global mutations и cross-cutting side effects;
- проверить, является ли `GVL_INTENT_SAFETY` реальным boundary-layer, а не промежуточным буфером без operational веса.

## Основание
Документ опирается на:
- `77_SAFETY_LIVE_PROGRAM_AUDIT.md`
- текущее состояние `PRG_Safety.st`
- текущее состояние `PRG_Command_Arbitration.st`

## Главный вывод
На текущем live root safety ownership/publication уже выглядит достаточно структурированной:
- `PRG_Safety.st` действительно является **главным producer-слоем `GVL_INTENT_SAFETY`**;
- `GVL_INTENT_SAFETY` не является декоративным промежуточным слоем, а реально замыкается в downstream operational effects через `PRG_Command_Arbitration.st`;
- при этом внутри самого `PRG_Safety.st` уже сосредоточено много alarm/interlock semantics, test-flow logic и cross-system required-action projection.

Иначе говоря:
- publication boundary safety layer уже существует и работает,
- но ownership concentration внутри producer-layer уже заметна.

## Ownership of inputs, alarms and latches

### SOPA-01. Detector ownership находится вне `PRG_Safety.st`
`PRG_Safety.st` не выглядит owner-слоем низкоуровневой sensor detection.

Он использует upstream detectors:
- `fbWaterLeakageManager(...)`
- `fbGasSmokeManager(...)`

и effective arrays/selectors.

Вывод:
- ownership первичного detection не находится внутри `PRG_Safety.st`.

### SOPA-02. Latched safety state ownership приходит сверху в `PRG_Safety.st`
`PRG_Safety.st` читает:
- `GVL_STATE.G_Safety_Smoke_Latched`
- `GVL_STATE.G_Safety_Gas_Latched`
- `GVL_STATE.G_Safety_Leak_Latched`
- `GVL_STATE.G_Freeze_Hardware_Degraded`

Вывод:
- latched/raw safety state itself не производится этим program-layer;
- `PRG_Safety.st` интерпретирует и проектирует его дальше.

### SOPA-03. Semantic aggregation ownership уже находится внутри `PRG_Safety.st`
На основе health bridge и latched state программа формирует:
- `I_Fire_Alarm_Active`
- `I_Gas_Alarm_Active`
- `I_CO_Warning_Active`
- `I_Leak_Alarm_Active`

Вывод:
- ownership alarm semantics already shifted into safety producer layer.

## Publication boundary

### SOPA-04. `GVL_INTENT_SAFETY` является главным outward publication surface
В `PRG_Safety.st` centralized reset/init делается именно по `GVL_INTENT_SAFETY`, после чего программа заполняет required-action fields, включая:
- `I_System_Safe_Stop_Required`
- `I_Freeze_Protection_Required`
- `I_Evacuation_Mode_Active`
- `I_Gas_Close_Required`
- `I_Boiler_Stop_Required`
- `I_Vent_Stop_Required`
- `I_Vent_Force_PV3_Boost`
- `I_Vent_Force_Supply_100`
- `I_Vent_Force_Supply_80`
- `I_Water_Main_Close_Required`
- lock force-open / close-block fields

Вывод:
- safety boundary уже выстроена вокруг intent publication, а не вокруг scattered direct command writes.

### SOPA-05. `GVL_INTENT_SAFETY` реально consumed downstream
`PRG_Command_Arbitration.st` подтверждает, что safety intents directly translate into shadow operational commands, например:
- `I_Fire_Alarm_Active` -> `G_Boiler_Stop`, `G_Vent_Stop`, `G_Lock_1_Open`, `G_Lock_2_Open`
- `I_Gas_Close_Required` -> `G_Gas_Valve_Close`, `G_Boiler_Stop`
- `I_Vent_Force_PV3_Boost` -> `G_Vent_PV3_Boost`
- `I_Vent_Force_Supply_100` -> `G_Supply_100_Req`
- `I_Vent_Force_Supply_80` -> `G_Supply_80_Req`
- `I_Vent_Stop_Required` -> `G_Vent_Stop`
- `I_Water_Main_Close_Required` -> `G_Close_Valve_35`, `G_Close_Valve_36`

Вывод:
- safety intent layer operationally real;
- это не документарный слой и не пустой bridge.

### SOPA-06. Safety publication уже cleaner than legacy direct command ownership
Поскольку `PRG_Safety.st` публикует cross-system required actions через intent layer, а не напрямую в command execution fields, current design уже выглядит cleaner, чем старые mixed legacy patterns.

Вывод:
- с точки зрения publication boundary safety layer currently follows healthier architecture than direct command writing would.

## Where ownership concentration is already visible

### SOPA-07. `PRG_Safety.st` владеет не только publication, но и interlock semantics
Программа не просто пробрасывает alarms наружу, а сама решает, какие cross-system effects должны быть инициированы:
- safe stop,
- evacuation mode,
- boiler stop,
- ventilation stop/boost,
- gas close,
- water main close,
- lock force-open / close-block.

Вывод:
- `PRG_Safety.st` является policy/intent owner, а не только relay layer.

### SOPA-08. Test/recover flows тоже сосредоточены здесь
Внутри `PRG_Safety.st` подтверждены:
- edge detection по valve-test / selective-recover user intents,
- test activity flags and deadlines,
- timeout-driven projection into required actions.

Вывод:
- operator/test semantics также сосредоточены внутри safety producer layer.

### SOPA-09. Publication semantics и partial workflow logic слиты в одном program layer
В одном и том же `PRG_Safety.st` уже вместе находятся:
- intent reset,
- semantic aggregation,
- interlock mapping,
- test/deadline flow,
- force-open / block-close logic.

Вывод:
- ownership concentration есть, even if boundary publication itself is fairly clean.

## Clean paths vs smell-prone areas

### Clean / structurally healthy paths
- detector outputs -> `GVL_HEALTH_BRIDGE`
- latched/global safety state -> `PRG_Safety.st`
- `PRG_Safety.st` -> `GVL_INTENT_SAFETY`
- `GVL_INTENT_SAFETY` -> `PRG_Command_Arbitration.st` -> `GVL_COMMAND_SHADOW`

### Smell-prone / concentration-prone areas
- semantic aggregation of alarms inside one program layer
- interlock mapping for multiple subsystems inside one program layer
- test/recover deadline logic inside same producer program
- force-open / close-block access semantics mixed into safety producer

## Practical interpretation

### SOPA-10. Главная проблема safety wave пока не в broken publication boundary
Наоборот, publication boundary через `GVL_INTENT_SAFETY` already looks meaningful and operationally grounded.

### SOPA-11. Главная потенциальная проблема safety wave — ownership concentration inside producer layer
То есть risk surface здесь ближе не к:
- broken interface,
и не к:
- dirty direct command writes,

а к:
- concentration of too many safety semantics/interlocks/test flows inside `PRG_Safety.st`.

### SOPA-12. Это другой тип риска, чем у ventilation
В ventilation smell был в manager-side diagnostics/global writes.

В safety на текущем этапе smell скорее в том, что **one producer program may own too much cross-system semantic mapping**.

## What this stage does NOT claim yet

### SOPA-NO-01
Он не утверждает, что `PRG_Safety.st` уже обязательно нужно дробить.

### SOPA-NO-02
Он не утверждает, что `GVL_INTENT_SAFETY` спроектирован плохо.

### SOPA-NO-03
Он не утверждает, что current downstream safety arbitration неверна.

Он утверждает только:
- publication boundary safety intent реальна и работает;
- ownership concentration внутри producer layer уже заметна и должна стать следующей темой safety-wave.

## Практический эффект этапа S-A2
После этого этапа уже можно уверенно сказать:
- safety wave не похожа на security/access mismatch case;
- safety wave не похожа и на ventilation diagnostics cleanup case;
- её основной architecture question now sits around **cross-subsystem ownership concentration in `PRG_Safety.st`**.

Это задает правильный следующий шаг:
- не immediate code fix,
- а cross-subsystem dependency map, чтобы понять, насколько эта концентрация justified or excessive.

## Следующий рекомендуемый документ
- `79_SAFETY_CROSS_SUBSYSTEM_DEPENDENCY_AUDIT.md`

Его задача:
- выполнить этап `S-A3`;
- пройти связи safety с heating, ventilation, security и system layer и проверить, нет ли drift между producer-side safety logic и consumer-side interlock usage.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения