# Next Major Scope After Safety

Дата фиксации: 2026-04-23

## Назначение
Этот документ фиксирует, куда переходить после текущей safety wave, зафиксированной в `90_SAFETY_INTERIM_STATUS.md`.

Цель:
- признать safety wave временно достаточно зрелой для паузы;
- выбрать следующий крупный priority scope проекта;
- сохранить правильную последовательность major waves без возврата в already-narrowed tails.

## Что уже достигнуто до этого решения
К текущему моменту уже выполнено:
- heating cluster recovery / regroup / polish wave;
- command-layer audit / cleanup / interim stabilization;
- security/access interface audit и local fix;
- ventilation audit / local diagnostics ownership cleanup;
- safety audit / workflow-cluster structural cleanup.

Практический результат:
- heating больше не является аварийным recovery scope;
- command-layer больше не является главным непрозрачным cross-cutting риском;
- security/access mismatch подтвержден и локально закрыт;
- ventilation cluster прояснен и локально очищен без broad redesign;
- safety cluster прояснен как layered producer-heavy design и локально очищен по workflow subset.

Следовательно, проект можно переводить в следующий major scope.

## Возможные следующие major scopes

### Scope A. Lighting subsystem wave
Область:
- `PRG_Lighting.st`
- lighting requests / overrides / level publication / scenario interaction
- lighting-related status, diagnostics and policy interactions

Почему это сильный кандидат:
- это следующий естественный domain subsystem scope после уже разобранных heating, ventilation и safety-cross-cutting layers;
- lighting likely имеет высокий прикладной payoff и понятный boundary-entry point через `PRG_Lighting.st`;
- это дает следующий крупный scope без преждевременного ухода в слишком широкую policy abstraction.

### Scope B. Policy layer audit
Область:
- `PRG_Policy.st`
- policy extraction / coordination contracts / cross-cutting decision routing

Почему это кандидат:
- это потенциально важный архитектурный слой проекта.

Почему это не лучший immediate next step:
- policy audit сейчас может открыть слишком широкий и слишком абстрактный scope;
- после safety более здорово вернуться к следующей прикладной subsystem wave, а не прыгать сразу в broad architecture meta-layer.

### Scope C. Return to safety secondary tail
Область:
- safety-access coupling subset
- producer-heavier publication tail
- possible helper extraction discussion

Почему это не лучший immediate next step:
- эти хвосты уже documented and narrowed;
- первый local cleanup по safety уже выполнен;
- payoff нового major scope выше, чем immediate deepening of narrowed safety tails.

### Scope D. Return to other narrowed tails
Область:
- command-layer tails,
- optional broader ventilation follow-up,
- optional security/access polish.

Почему это не лучший immediate next step:
- эти хвосты уже documented and narrowed;
- diminishing-return risk здесь выше, чем у новой subsystem wave.

## Решение
На текущем этапе следующим major scope выбирается:

# Scope A — Lighting subsystem wave

## Почему выбран именно он

### NMS-S-01. Это следующий естественный domain subsystem после пройденных крупных волн
После heating, ventilation и safety cross-cutting clarification lighting выглядит как логичный следующий прикладной cluster.

Вывод:
- проект сохраняет здоровый rhythm: subsystem wave -> cross-cutting wave -> subsystem wave.

### NMS-S-02. Это лучше, чем immediate jump into policy abstraction
`PRG_Policy.st` потенциально важен, но сейчас policy audit может слишком рано открыть meta-scope, который хуже ограничивается.

Вывод:
- lighting дает более управляемый и осязаемый next step.

### NMS-S-03. Это полезнее, чем immediate return to narrowed tails
Safety secondary tail, command tails и optional ventilation/security follow-ups уже narrowed and documented.

Вывод:
- новый major scope сейчас дает лучший value/risk payoff.

## Что выбрать после lighting wave
После завершения lighting wave логично будет вернуться к выбору между:
- policy layer audit,
- следующей domain subsystem wave,
- optional return to narrowed tails, если появится новый payoff.

## Что это решение НЕ означает
Это решение не означает:
- что policy layer не важен;
- что safety secondary tails закрыты навсегда;
- что other narrowed tails потеряли ценность.

Это означает только:
- следующий лучший шаг по value/risk сейчас — lighting subsystem wave.

## Рекомендуемый следующий документ
- `92_LIGHTING_AUDIT_PLAN.md`

Его задача:
- открыть новый major cycle после safety wave;
- зафиксировать область, риски и порядок разбора lighting subsystem.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения