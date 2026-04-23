# Safety Live Program Audit

Дата фиксации: 2026-04-23

## Назначение
Этот документ выполняет этап `S-A1` из `76_SAFETY_AUDIT_PLAN.md`:
**live program audit** для `PRG_Safety.st`.

Цель:
- зафиксировать текущую структуру live safety program;
- понять, какие inputs safety layer берет сверху и что публикует наружу;
- определить, выглядит ли `PRG_Safety.st` как аккуратный producer/boundary-layer или уже как перегруженный cross-cutting owner.

## Проверенный объект
- `PRG_Safety.st`

## Главный вывод этапа S-A1
В текущем live root `PRG_Safety.st` выглядит не как actuation-layer и не как тяжелый orchestration-monolith, а как **producer/boundary program для `GVL_INTENT_SAFETY`**.

Структура читается достаточно последовательно:
1. edge detection по operator/test/recover командам из `GVL_INTENT_USER`;
2. reset/initialization всего safety-intent surface;
3. вызовы detection-managers (`fbWaterLeakageManager`, `fbGasSmokeManager`);
4. projection из latched safety state и health bridge в `GVL_INTENT_SAFETY`;
5. отдельные test/freeze flows.

Это уже важный ранний вывод:
- safety program в текущем виде больше похож на **cross-cutting intent producer**, чем на место прямого исполнительного управления.

## Структура safety program

### SLA-01. Edge detection для operator/test/recover inputs
В `PRG_Safety.st` есть локальный edge-detection слой для:
- `I_Water_Selective_Recover`
- `I_Gas_Selective_Recover`
- `I_Water_Valve_Test_Open`
- `I_Water_Valve_Test_Close`
- `I_Water_Valve_Test_Confirm`
- `I_Gas_Valve_Test_Open`
- `I_Gas_Valve_Test_Close`
- `I_Gas_Valve_Test_Confirm`

Вывод:
- safety program уже берет на себя нормализацию operator/test intents перед дальнейшей обработкой.

### SLA-02. Total reset/init of `GVL_INTENT_SAFETY`
В начале основного тела `PRG_Safety.st` явно сбрасывает/инициализирует большой набор полей `GVL_INTENT_SAFETY`, включая:
- alarm flags,
- safe-stop / freeze / evacuation flags,
- gas/boiler/vent/water required flags,
- recovery target fields,
- lock force-open / close-block signals.

Вывод:
- `PRG_Safety.st` является явным owner-продюсером safety intent surface;
- boundary уже организована не как scattered writes по коду, а через один centralized intent-reset/pass.

### SLA-03. Detection managers подключены как upstream detectors
`PRG_Safety.st` вызывает:
- `fbWaterLeakageManager(...)`
- `fbGasSmokeManager(...)`

И далее использует их результаты через `GVL_HEALTH_BRIDGE` и status publications.

Вывод:
- program выступает как интегратор детектирующих safety managers, а не как место низкоуровневого sensor processing.

### SLA-04. Core safety flows проектируются в intent layer
На основе latched state:
- `GVL_STATE.G_Safety_Smoke_Latched`
- `GVL_STATE.G_Safety_Gas_Latched`
- `GVL_STATE.G_Safety_Leak_Latched`
- `GVL_STATE.G_Freeze_Hardware_Degraded`

`PRG_Safety.st` устанавливает поля `GVL_INTENT_SAFETY`, например:
- `I_System_Safe_Stop_Required`
- `I_Evacuation_Mode_Active`
- `I_Boiler_Stop_Required`
- `I_Vent_Stop_Required`
- `I_Gas_Close_Required`
- `I_Water_Main_Close_Required`
- `I_Freeze_Protection_Required`
- force-open / close-block for locks

Вывод:
- текущий core safety flow уже организован как projection from state/health to intent layer.

### SLA-05. CO / gas / smoke / leak semantics частично агрегируются здесь
`PRG_Safety.st` сам устанавливает:
- `I_Fire_Alarm_Active`
- `I_Gas_Alarm_Active`
- `I_CO_Warning_Active`
- `I_Leak_Alarm_Active`

на основе latched state и `GVL_HEALTH_BRIDGE` outputs.

Вывод:
- safety program несет не только routing, но и часть semantic aggregation alarm meanings.

### SLA-06. Test flows находятся внутри `PRG_Safety.st`
Программа ведет:
- `L_Water_Test_Active` / `L_Water_Test_Deadline`
- `L_Gas_Test_Active` / `L_Gas_Test_Deadline`

и по таймауту переводит их в:
- `I_Water_Main_Close_Required`
- `I_Gas_Close_Required`

Вывод:
- operator/test logic частично сосредоточена внутри safety program, а не вынесена в отдельный helper-layer.

## Что проходит через safety boundary

### Входной контекст сверху
`PRG_Safety.st` берет сверху:
- user test/recover intents из `GVL_INTENT_USER`;
- sensor-derived arrays / effective safety arrays через managers/selectors;
- latched state из `GVL_STATE`;
- config из `GVL_CONFIG`;
- system time / active PLC из `GVL_STATUS`.

### Выходной контекст наружу
`PRG_Safety.st` публикует наружу:
- большой набор полей `GVL_INTENT_SAFETY`;
- status messages через `GVL_STATUS.G_Flood_Status_Msg` и `GVL_STATUS.G_Gas_Status_Msg` (через manager outputs);
- часть health results через `GVL_HEALTH_BRIDGE` (через manager outputs).

Вывод:
- main outward boundary safety program — это прежде всего `GVL_INTENT_SAFETY`.

## Первая интерпретация boundary/ownership

### SLA-07. `PRG_Safety.st` не выглядит thin wrapper в стиле ventilation
В отличие от `PRG_Ventilation.st`, safety program делает больше, чем просто adapter + один manager-call.

Он сам содержит:
- edge detection,
- reset of whole intent surface,
- semantic alarm projection,
- test/deadline logic,
- mapping from safety state to cross-system required actions.

Вывод:
- safety program уже является заметным ownership center, а не тонким wrapper.

### SLA-08. Но он и не выглядит как direct actuation owner
При этом `PRG_Safety.st` в текущем live root не занимается прямой записью в command execution outputs.

Он в основном производит:
- intents,
- alarms/status semantics,
- cross-system required-action flags.

Вывод:
- это скорее policy/intent producer layer, чем исполнительный control-layer.

### SLA-09. Главный ранний риск safety-wave — не wrapper clutter, а ownership concentration in intent production
Уже на первом чтении видно, что program концентрирует:
- safety alarm semantics,
- interlock requirements,
- operator test flow,
- lock-force behavior,
- freeze and evacuation intent projection.

Вывод:
- основной вопрос safety-wave, вероятно, будет в ownership/publication semantics, а не в простом interface mismatch.

## Что пока НЕ утверждается этим этапом
Этот документ не утверждает:
- что `PRG_Safety.st` уже обязательно перегружен дефектно;
- что его нужно немедленно дробить;
- что boundary safety cluster уже плохая.

Он утверждает только:
- safety program в текущем live root является существенным cross-cutting intent producer, а не тонким wrapper.

## Практический эффект этапа S-A1
После этого шага уже можно уверенно сказать:
- safety wave, вероятно, будет разбираться через ownership/publication semantics `GVL_INTENT_SAFETY` и cross-system mappings;
- риск здесь по типу отличается от ventilation и heating;
- следующий шаг должен идти в ownership/publication audit, а не в premature structural refactor.

## Следующий рекомендуемый документ
- `78_SAFETY_OWNERSHIP_AND_PUBLICATION_AUDIT.md`

Его задача:
- выполнить этап `S-A2`;
- разобрать ownership alarms/latches/interlocks и publication semantics safety cluster.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения