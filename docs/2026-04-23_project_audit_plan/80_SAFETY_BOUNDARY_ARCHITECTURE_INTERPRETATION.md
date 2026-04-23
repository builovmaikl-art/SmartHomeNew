# Safety Boundary Architecture Interpretation

Дата фиксации: 2026-04-23

## Назначение
Этот документ выполняет этап `S-A4` из `76_SAFETY_AUDIT_PLAN.md`:
**boundary / architecture interpretation** для safety cluster.

Цель:
- интерпретировать уже собранную карту ownership/publication/dependencies;
- определить, выглядит ли safety cluster как coherent layered design, thin but leaky layer, или ownership-heavy concentration point;
- подготовить правильный fix-direction step без premature redesign.

## Основание
Документ опирается на:
- `77_SAFETY_LIVE_PROGRAM_AUDIT.md`
- `78_SAFETY_OWNERSHIP_AND_PUBLICATION_AUDIT.md`
- `79_SAFETY_CROSS_SUBSYSTEM_DEPENDENCY_AUDIT.md`
- текущее состояние `PRG_Safety.st`
- текущее состояние `PRG_Command_Arbitration.st`
- текущее состояние `PRG_System.st`
- текущее состояние `PRG_Heating.st`
- текущее состояние `PRG_Ventilation.st`
- текущее состояние `PRG_Security.st`

## Главный вывод
На текущем live root safety cluster лучше всего описывается не как broken boundary и не как thin but leaky layer.

Наиболее точная интерпретация сейчас:

# Safety cluster = coherent layered design, but producer-heavy at `PRG_Safety.st`

То есть:
- базовая архитектурная идея уже читается и работает;
- publication boundary через `GVL_INTENT_SAFETY` реальна и operationally grounded;
- cross-subsystem dependency-chain не выглядит случайной;
- но `PRG_Safety.st` уже концентрирует слишком большую долю semantic mapping, interlock projection и test-flow logic для одного producer-layer.

Это не повод немедленно ломать архитектуру.

Но это уже и не просто stylistic observation.

## Почему это НЕ broken-boundary case

### SBAI-01. Publication boundary уже существует и реально используется
`PRG_Safety.st` не пишет safety-effects напрямую в shadow execution layer.

Он публикует их через `GVL_INTENT_SAFETY`, а `PRG_Command_Arbitration.st` уже downstream переводит значимую часть intents в `GVL_COMMAND_SHADOW`.

Вывод:
- safety boundary уже организована cleaner, чем legacy direct command ownership pattern.

### SBAI-02. Cross-subsystem consumers действительно есть
У safety layer есть реальные consumers по нескольким формам:
- command arbitration consumes safety intents directly;
- ventilation consumes latched safety state directly;
- heating consumes direct safety state and feeds freeze-hardware state back;
- security/access affected indirectly through arbitration and system mode.

Вывод:
- architecture не выглядит бумажной или пустой.

### SBAI-03. Нет явного interface-mismatch типа security/access case
На текущем этапе не подтверждено:
- broken call-site,
- missing required parameter,
- broken publication binding.

Вывод:
- core issue here is not interface correctness.

## Почему это НЕ thin-but-leaky case

### SBAI-04. `PRG_Safety.st` не тонкий wrapper
Внутри `PRG_Safety.st` уже сосредоточены:
- edge detection,
- reset whole safety-intent surface,
- alarm semantic aggregation,
- required-action projection,
- test/deadline logic,
- lock force-open / close-block logic,
- freeze-related projection.

Вывод:
- safety layer cannot honestly be described as thin.

### SBAI-05. Main smell is not leakage, but concentration
Да, архитектура safety layer многослойна.

Но проблема не в том, что слой слишком маленький и протекает в globals.

Проблема в другом:
- слишком много cross-system semantic responsibility already lives in one producer program.

## Почему это producer-heavy case

### SBAI-06. `PRG_Safety.st` already owns semantic translation across multiple domains
Один и тот же program-layer сейчас переводит safety state в эффекты для:
- heating,
- ventilation,
- water,
- gas,
- access/locks,
- evacuation.

Вывод:
- producer-side ownership already spans several domains.

### SBAI-07. Test/recover flows are mixed into the same producer layer
Valve-test / selective-recover edges, activity flags and deadlines живут в том же `PRG_Safety.st`, где публикуются и core safety required actions.

Вывод:
- program owns not only hazard semantics, but also operator/test workflow semantics.

### SBAI-08. Not every published intent field is equally confirmed as downstream-consumed
Часть publication surface хорошо замыкается downstream.

Но для некоторых полей checked scope пока не дал столь же явного consumer-подтверждения.

Вывод:
- producer surface may be wider than the confirmed active consumer landscape.

Это усиливает producer-heavy interpretation.

## Layered architecture that is still coherent

### SBAI-09. Upstream / producer / downstream roles already exist
Текущая safety architecture уже раскладывается на роли:
- `PRG_System.st` / `fbSafety(...)` / health integration as upstream latched-state and mode integration layer;
- `PRG_Safety.st` as safety semantic producer;
- `PRG_Command_Arbitration.st` as downstream operational translator;
- subsystems as direct or indirect consumers.

Вывод:
- architecture has real layering, not chaos.

### SBAI-10. The next problem is proportionality, not existence of layering
Раз layering already exists and works, главный вопрос теперь не “есть ли boundary вообще”, а:
- **пропорционален ли объем ownership внутри `PRG_Safety.st` текущему consumer landscape**.

Это и есть правильный архитектурный вопрос следующего шага.

## Practical architecture interpretation

### Interpretation summary
На текущем этапе safety cluster лучше всего описывать так:
- **boundary exists**;
- **publication model works**;
- **downstream operational grounding exists**;
- **but producer-side semantic concentration is already high enough to justify a focused cleanup decision**.

Иначе говоря:
- safety cluster coherent,
- but already ownership-heavy.

## What this stage does NOT claim

### SBAI-NO-01
Этот этап не утверждает, что `PRG_Safety.st` нужно немедленно дробить на несколько блоков.

### SBAI-NO-02
Он не утверждает, что `GVL_INTENT_SAFETY` слишком широк по определению.

### SBAI-NO-03
Он не утверждает, что current layered design failed.

Он утверждает только:
- current layered design works,
- but the producer layer is heavy enough that fix-direction should now target ownership concentration, not boundary existence.

## Практический эффект этапа S-A4
После этого этапа safety wave уже достаточно подготовлена для remediation direction decision:
- мы знаем, что safety не broken,
- знаем, что safety не thin,
- знаем, что safety publication real,
- и знаем, что основной architectural smell now sits in producer-side ownership concentration.

Это делает следующий шаг достаточно узким и осмысленным:
- решать не “переделывать ли всё”,
- а “нужен ли focused cleanup around `PRG_Safety.st` ownership scope”.

## Следующий рекомендуемый документ
- `81_SAFETY_FIX_DIRECTION_DECISION.md`

Его задача:
- выполнить этап `S-A5`;
- решить, ограничиваемся ли documentation-level stabilization, или safety cluster уже требует локального cleanup plan around producer-side ownership concentration.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения