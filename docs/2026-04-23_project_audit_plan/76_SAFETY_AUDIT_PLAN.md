# Safety Audit Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ открывает следующий major scope после `75_NEXT_MAJOR_SCOPE_AFTER_VENTILATION.md`:
**safety subsystem wave**.

Цель:
- зафиксировать область нового цикла анализа;
- определить главные риски safety boundary;
- разложить следующий audit на управляемые этапы;
- не смешивать safety wave с already-narrowed tails command-layer, security/access и ventilation.

## Почему этот scope выбран следующим
После heating wave, command-layer wave, security/access fix и ventilation cleanup именно safety выглядит следующим наиболее ценным cross-cutting scope проекта.

Это логично, потому что:
- safety-сигналы и latches уже участвуют в нескольких ранее разобранных подсистемах;
- safety влияет не только на один domain block, а на system-level behavior;
- architectural payoff следующего шага здесь выше, чем у immediate lighting wave или возврата в narrow tails прошлых волн.

## Область safety audit

### Основные файлы
- `PRG_Safety.st`

### Связанные точки
- `GVL_STATE`
- `GVL_STATUS`
- `GVL_ALARM`
- `PRG_System.st`
- `PRG_Security.st`
- `PRG_Ventilation.st`
- heating-related safety leaves and interlocks

### При необходимости
- дополнительные FB/struct/config files, если safety boundary уводит глубже в helper contracts или state publications.

## Уже известная отправная точка
По уже выполненным волнам подтверждено, что safety-сигналы и latches участвуют в:
- security/access boundary;
- ventilation manager inputs;
- system-level mode/interlock behavior;
- heating-related recovery и safety-sensitive flows.

Это означает, что safety wave уже опирается на частично расчищенную карту проекта и может разбираться не вслепую, а от текущих live dependencies.

## Главные вопросы следующего аудита
Следующий цикл должен ответить на вопросы:
1. как устроен live safety flow сверху вниз;
2. где проходит boundary между `PRG_Safety.st` и глобальными слоями публикации alarm/state/status;
3. кто является owner-слоем для latches, alarms, interlocks и их reset/publication semantics;
4. нет ли внутри safety cluster mixed ownership, hidden global side effects или unclear publication boundaries;
5. требуется ли safety только documentation/structure cleanup или там вероятны реальные code fixes.

## Порядок аудита

### Этап S-A1. Live safety wrapper/program audit
Область:
- `PRG_Safety.st`

Задача:
- снять текущую структуру live safety program;
- понять, какие inputs он берет сверху и что публикует наружу.

Ожидаемый результат:
- точная structure/boundary map safety-layer.

### Этап S-A2. Safety ownership and publication audit
Область:
- `PRG_Safety.st`
- связанные `GVL_STATE` / `GVL_STATUS` / `GVL_ALARM` поля

Задача:
- понять, где именно живет ownership alarms/latches/interlocks;
- отделить clean publication paths от direct global mutations и cross-cutting side effects.

Ожидаемый результат:
- ownership/publication map safety cluster.

### Этап S-A3. Safety dependencies across subsystems
Область:
- связи safety с heating, ventilation, security и system layer

Задача:
- зафиксировать, как safety boundary влияет на уже пройденные подсистемы;
- понять, нет ли drift между producer-side safety logic и consumer-side interlock usage.

Ожидаемый результат:
- cross-subsystem dependency map для safety layer.

### Этап S-A4. Boundary/architecture interpretation
Область:
- `PRG_Safety.st` и связанные global publications

Задача:
- оценить, является ли safety cluster coherent but heavy, thin but leaky, или mixed ownership/problematic boundary.

Ожидаемый результат:
- safety boundary interpretation.

### Этап S-A5. Fix direction decision
Задача:
- на основе S-A1..S-A4 принять решение:
  - нужен ли только structural/docs cleanup,
  - нужен ли local code fix,
  - или требуется более широкая safety cleanup wave.

Ожидаемый результат:
- remediation direction for safety subsystem.

## Что пока НЕ делать
- не возвращаться сразу в command-layer tail;
- не смешивать safety audit с broad policy-layer redesign;
- не править `PRG_Safety.st` до подтвержденной ownership/boundary картины;
- не раздувать scope до полного system-wide interlock redesign без достаточных оснований.

## Практический следующий документ
- `77_SAFETY_LIVE_PROGRAM_AUDIT.md`

Его задача:
- открыть этап `S-A1`;
- снять текущую live structure `PRG_Safety.st`.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения