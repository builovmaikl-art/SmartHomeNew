# Next Major Scope After Ventilation

Дата фиксации: 2026-04-23

## Назначение
Этот документ фиксирует, куда переходить после текущей ventilation wave, зафиксированной в `74_VENTILATION_INTERIM_STATUS.md`.

Цель:
- признать ventilation wave временно достаточно зрелой для паузы;
- выбрать следующий крупный priority scope проекта;
- сохранить правильную последовательность major waves без возврата в already-narrowed tails.

## Что уже достигнуто до этого решения
К текущему моменту уже выполнено:
- heating cluster recovery / regroup / polish wave;
- command-layer audit / cleanup / interim stabilization;
- security/access interface audit и local fix;
- ventilation audit / local diagnostics ownership cleanup.

Практический результат:
- heating больше не является аварийным recovery scope;
- command-layer больше не является главным непрозрачным cross-cutting риском;
- security/access mismatch подтвержден и локально закрыт;
- ventilation cluster прояснен и локально очищен без broad redesign.

Следовательно, проект можно переводить в следующий major scope.

## Возможные следующие major scopes

### Scope A. Safety subsystem wave
Область:
- `PRG_Safety.st`
- safety-related latches / alarms / interlocks / publications
- связи safety с `PRG_System`, `PRG_Security`, `PRG_Ventilation`, heating-related leaves

Почему это сильный кандидат:
- safety — high-value cross-cutting слой;
- несколько уже разобранных подсистем зависят от safety state и latched signals;
- после ventilation логично проверить именно safety boundary, а не только очередную бытовую subsystem.

### Scope B. Lighting subsystem wave
Область:
- `PRG_Lighting.st`
- lighting requests / override / status logic

Почему это кандидат:
- это отдельная domain subsystem;
- может дать следующую локальную subsystem wave.

Почему это не лучший immediate next step:
- по value/risk safety слой выглядит выше, так как он влияет на несколько уже пройденных подсистем.

### Scope C. Policy layer audit
Область:
- `PRG_Policy.st`
- policy extraction / coordination contracts

Почему это кандидат:
- это потенциально сильный архитектурный слой проекта.

Почему это не лучший immediate next step:
- policy audit сейчас может слишком рано открыть слишком широкий cross-cutting scope;
- safety wave выглядит уже и прикладнее как следующий шаг.

### Scope D. Возврат к tails прошлых волн
Область:
- command-layer tails,
- optional security/access polish,
- broader ventilation redesign topic.

Почему это не лучший immediate next step:
- эти хвосты уже documented and narrowed;
- payoff нового major scope выше, чем deepening diminishing-return tails.

## Решение
На текущем этапе следующим major scope выбирается:

# Scope A — Safety subsystem wave

## Почему выбран именно он

### NMS-V-01. Это следующий high-value cross-cutting слой
Safety связан не с одной subsystem, а сразу с несколькими уже пройденными зонами проекта:
- heating,
- ventilation,
- security,
- system-level mode/interlock behavior.

Вывод:
- следующий risk/value шаг естественно идет сюда.

### NMS-V-02. Это сохраняет правильный порядок проектного раскрытия
Последовательность теперь выглядит так:
- heating stabilization,
- command-layer clarification,
- security/access interface fix,
- ventilation ownership cleanup,
- next: safety boundary.

Вывод:
- это ведет проект от operational subsystems к cross-cutting safety layer в осмысленном порядке.

### NMS-V-03. Это полезнее, чем immediate lighting wave
Lighting остается valid future subsystem scope.

Но safety likely дает более высокий architectural payoff, потому что влияет на already-studied control paths и policy behavior.

## Что выбрать после safety wave
После завершения safety wave логично будет вернуться к выбору между:
- lighting subsystem wave,
- policy layer audit,
- следующей domain subsystem wave,
- optional return to narrowed tails, если появится новый payoff.

## Что это решение НЕ означает
Это решение не означает:
- что lighting потерял ценность;
- что policy layer не важен;
- что tails прошлых волн закрыты навсегда.

Это означает только:
- следующий лучший шаг по value/risk сейчас — safety subsystem wave.

## Рекомендуемый следующий документ
- `76_SAFETY_AUDIT_PLAN.md`

Его задача:
- открыть новый major cycle после ventilation wave;
- зафиксировать область, риски и порядок разбора safety subsystem.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения