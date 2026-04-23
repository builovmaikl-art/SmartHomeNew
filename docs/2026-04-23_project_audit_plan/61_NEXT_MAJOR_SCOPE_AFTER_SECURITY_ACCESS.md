# Next Major Scope After Security / Access

Дата фиксации: 2026-04-23

## Назначение
Этот документ фиксирует, куда переходить после текущей security/access wave, зафиксированной в `60_SECURITY_ACCESS_INTERIM_STATUS.md`.

Цель:
- признать security/access wave временно достаточно зрелой для паузы;
- выбрать следующий крупный priority scope проекта;
- удержать последовательность major waves без распыления.

## Что уже достигнуто до этого решения
К текущему моменту уже выполнено:
- heating cluster recovery / regroup / polish wave;
- command-layer audit / cleanup / interim stabilization;
- security/access interface audit;
- локальный security/access fix по `VI_System_Mode`.

Практический результат:
- heating больше не является аварийным recovery scope;
- command-layer больше не является главным непрозрачным cross-cutting риском;
- security/access mismatch подтвержден и локально закрыт.

Следовательно, проект можно переводить в следующую subsystem wave.

## Возможные следующие major scopes

### Scope A. Ventilation subsystem wave
Область:
- `PRG_Ventilation.st`
- `FB_Ventilation_System_Manager.st`
- вентиляционные requests / status / policy interactions

Почему это сильный кандидат:
- ventilation уже частично всплывала во время command-layer wave;
- это естественное продолжение после heating и security/access;
- следующий domain-level payoff здесь выше, чем от возврата к узкому tail уже стабилизированных scopes.

### Scope B. Возврат к command-layer tail
Область:
- rename/promote decision для `GVL_COMMAND_SHADOW`
- bridge migration for `PRG_System` / `PRG_Security`
- valve-test / selective-recover unresolved tail

Почему это не лучший immediate next step:
- tail уже документирован и narrowed;
- architectural payoff deep follow-up ниже, чем у новой subsystem wave.

### Scope C. Broader security/access polish
Область:
- comments/docs cleanup,
- optional boundary polish,
- deeper redesign review.

Почему это не лучший immediate next step:
- primary mismatch уже исправлен;
- remaining value здесь уже secondary, не first-priority.

## Решение
На текущем этапе следующим major scope выбирается:

# Scope A — Ventilation subsystem wave

## Почему выбран именно он

### NMS-SEC-01. Это следующий наиболее ценный domain-level scope
После heating логично продолжить в следующую инженерную subsystem wave, а ventilation уже partially touched by command-layer context.

### NMS-SEC-02. Остальные текущие хвосты уже имеют меньший payoff
Command-layer tail и security/access polish уже narrowed и documented.

Ventilation дает больший architectural payoff на следующем шаге.

### NMS-SEC-03. Это сохраняет правильный rhythm проекта
Последовательность теперь выглядит так:
- heating stabilization,
- command-layer clarification,
- security/access local integration fix,
- next subsystem wave.

Это более здоровый путь, чем бесконечно углубляться в diminishing-return tails предыдущих scopes.

## Что выбрать после ventilation wave
После завершения ventilation wave логично будет вернуться к выбору между:
- следующей subsystem wave,
- command-layer tail reduction,
- optional broader polish of already stabilized scopes.

## Что это решение НЕ означает
Это решение не означает:
- что command-layer tail исчез;
- что security/access больше никогда не потребует полировки;
- что ventilation гарантированно потребует кодовых правок заранее.

Это означает только:
- следующий лучший шаг по value/risk сейчас — ventilation subsystem wave.

## Рекомендуемый следующий документ
- `62_VENTILATION_AUDIT_PLAN.md`

Его задача:
- открыть новый major cycle после security/access wave;
- зафиксировать область, риски и порядок разбора ventilation subsystem.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения