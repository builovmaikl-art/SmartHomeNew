# Next Major Scope After Command-Layer

Дата фиксации: 2026-04-23

## Назначение
Этот документ фиксирует, куда переходить после текущей command-layer wave, зафиксированной в `49_COMMAND_LAYER_INTERIM_STATUS.md`.

Цель:
- признать command-layer wave временно достаточно зрелой для паузы;
- выбрать следующий крупный priority scope проекта;
- не распыляться между несколькими направлениями одновременно.

## Что уже достигнуто до этого решения
К текущему моменту уже выполнено:
- heating cluster recovery, regroup и polish wave;
- command-layer ownership/semantic audit;
- verifier cleanup;
- bridge boundary clarification;
- field/program-level bridge decomposition;
- interim stabilization command-layer wave.

Практический результат:
- heating cluster больше не является срочным аварийным архитектурным узлом;
- command-layer больше не выглядит как главный непрозрачный cross-cutting риск;
- проект можно переводить в следующий крупный scope без ощущения, что базовый command execution layer остался неразобранным.

## Возможные следующие major scopes

### Scope A. Security / Access interface audit
Область:
- `PRG_Security.st`
- `FB_Access_Control.st`
- `FB_Security_System_Manager.st`
- security/access interface contracts

Почему это сильный кандидат:
- ранее уже был отмечен вероятный interface mismatch;
- это относительно локальный, но potentially compile-sensitive узел;
- он хорошо следует после command-layer, потому что security-side command bridge уже частично разобран.

### Scope B. Следующая subsystem wave
Наиболее логичный кандидат:
- `Ventilation`

Почему это кандидат:
- после heating естественно продолжать subsystem-by-subsystem audit;
- ventilation уже частично касалась command-layer audit;
- это позволит дальше расчистить доменную карту проекта.

### Scope C. Возврат к command-layer tail
Область:
- rename/promote decision для `GVL_COMMAND_SHADOW`
- bridge migration for `PRG_System` / `PRG_Security`
- valve-test / selective-recover unresolved tail

Почему это не лучший immediate next step:
- remaining ambiguity уже сужена до narrow tail;
- architectural payoff следующего deep follow-up ниже, чем у нового major scope;
- command-layer уже оставлен в documented and temporarily stable состоянии.

## Решение
На текущем этапе следующим major scope выбирается:

# Scope A — Security / Access interface audit

## Почему выбран именно он

### NMS-01. Это следующий подтвержденный high-value риск после command-layer
Security/access уже ранее отмечался как потенциально проблемный интерфейсный узел.

После стабилизации command-layer логично идти именно сюда, а не сразу в очередную subsystem wave, потому что:
- interface mismatch способен давать более концентрированный риск, чем размытый subsystem debt.

### NMS-02. Это хороший момент после security-side bridge clarification
Во время command-layer wave уже было подтверждено, что:
- security-side legacy bridge-tail узкий;
- основной arm/disarm/access path уже живет через intents.

Это создает хорошую отправную точку для более чистого interface audit `PRG_Security` ↔ `FB_Access_Control`.

### NMS-03. Это закрывает старый high-priority вопрос до перехода к следующей subsystem wave
Если сейчас пройти security/access audit, то затем можно идти в `Ventilation` уже с более чистой картиной по:
- command-layer,
- security/access boundary,
- базовым project-wide integration risks.

## Что выбрать после security/access audit
После завершения security/access audit следующим major scope рекомендуется:
- `Ventilation subsystem wave`

И только потом:
- возвращаться к command-layer tail, если на тот момент это все еще будет давать полезный payoff.

## Что это решение НЕ означает
Это решение не означает:
- что command-layer fully finished forever;
- что command-layer tail больше не важен;
- что ventilation потеряла приоритет полностью.

Это означает только:
- следующий лучший шаг по value/risk сейчас — именно security/access interface audit.

## Рекомендуемый следующий документ
- `51_SECURITY_ACCESS_AUDIT_PLAN.md`

Его задача:
- открыть новый цикл после command-layer wave;
- зафиксировать область, риски и порядок разбора security/access interface boundary.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения