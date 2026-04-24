# Lighting Audit Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ открывает следующий major scope после `91_NEXT_MAJOR_SCOPE_AFTER_SAFETY.md`:
**lighting subsystem wave**.

Цель:
- зафиксировать область нового цикла анализа;
- определить главные риски lighting boundary;
- разложить следующий audit на управляемые этапы;
- не смешивать lighting wave с already-narrowed tails command-layer, ventilation, safety и security/access.

## Почему этот scope выбран следующим
После heating wave, command-layer wave, security/access fix, ventilation cleanup и safety clarification именно lighting выглядит следующим наиболее ценным прикладным subsystem scope проекта.

Это логично, потому что:
- lighting — самостоятельная доменная подсистема с понятным entry point через `PRG_Lighting.st`;
- это естественный возврат от cross-cutting safety wave к следующей прикладной subsystem wave;
- architectural payoff следующего шага здесь выше, чем у немедленного policy-layer audit или возврата в narrowed tails прошлых волн.

## Область lighting audit

### Основные файлы
- `PRG_Lighting.st`

### Связанные точки
- `GVL_COMMAND_SHADOW`
- `GVL_INTENT_USER`
- `GVL_INTENT_SYSTEM`
- `GVL_STATE`
- `GVL_STATUS`
- scenario-related interactions
- lighting overrides / level publication / diagnostics interactions

### При необходимости
- дополнительные FB/struct/config files, если lighting boundary уводит глубже в helper contracts, adapters или policy interactions.

## Уже известная отправная точка
По уже выполненным волнам подтверждено, что:
- command-layer уже переведен в clarified shadow-centered operational model;
- system-mode / safety / scenario layers уже частично очищены и могут влиять на lighting через cross-cutting intents и blocks;
- lighting likely является downstream subsystem, которую теперь можно разбирать уже на более чистом project-wide фоне.

Это означает, что lighting wave можно разбирать не вслепую, а от уже стабилизированной общей архитектурной карты.

## Главные вопросы следующего аудита
Следующий цикл должен ответить на вопросы:
1. как устроен live lighting flow сверху вниз;
2. где проходит boundary между `PRG_Lighting.st` и глобальными слоями command/state/status publication;
3. кто является owner-слоем для lighting requests, overrides, effective levels и status publication;
4. нет ли внутри lighting cluster mixed ownership, wrapper drift, hidden global side effects или unclear diagnostics/publication boundaries;
5. требуется ли lighting только documentation/structure cleanup или там вероятны реальные code fixes.

## Порядок аудита

### Этап L-A1. Live lighting program/wrapper audit
Область:
- `PRG_Lighting.st`

Задача:
- снять текущую структуру live lighting program;
- понять, какие inputs lighting layer берет сверху и что публикует наружу.

Ожидаемый результат:
- точная structure/boundary map lighting-layer.

### Этап L-A2. Lighting ownership and publication audit
Область:
- `PRG_Lighting.st`
- связанные `GVL_STATE` / `GVL_STATUS` / command/intents fields

Задача:
- понять, где именно живет ownership requests/overrides/effective levels/status publication;
- отделить clean publication paths от direct global mutations и cross-cutting side effects.

Ожидаемый результат:
- ownership/publication map lighting cluster.

### Этап L-A3. Lighting dependencies across subsystems
Область:
- связи lighting с scenario/system/safety/command layers

Задача:
- зафиксировать, как lighting boundary зависит от уже разобранных cross-cutting layers;
- понять, нет ли drift между producer-side requests/overrides и consumer-side effective output behavior.

Ожидаемый результат:
- cross-layer dependency map для lighting.

### Этап L-A4. Boundary/architecture interpretation
Область:
- `PRG_Lighting.st` и связанные global publications

Задача:
- оценить, является ли lighting cluster coherent but heavy, thin but leaky, clean but adapter-heavy, или ownership/problematic boundary case.

Ожидаемый результат:
- lighting boundary interpretation.

### Этап L-A5. Fix direction decision
Задача:
- на основе L-A1..L-A4 принять решение:
  - нужен ли только structural/docs cleanup,
  - нужен ли local code fix,
  - или требуется более широкая lighting cleanup wave.

Ожидаемый результат:
- remediation direction for lighting subsystem.

## Что пока НЕ делать
- не возвращаться сразу в safety secondary tail;
- не смешивать lighting audit с broad policy-layer redesign;
- не править `PRG_Lighting.st` до подтвержденной ownership/boundary картины;
- не раздувать scope до полного system-wide override/policy redesign без достаточных оснований.

## Практический следующий документ
- `93_LIGHTING_LIVE_PROGRAM_AUDIT.md`

Его задача:
- открыть этап `L-A1`;
- снять текущую live structure `PRG_Lighting.st`.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения