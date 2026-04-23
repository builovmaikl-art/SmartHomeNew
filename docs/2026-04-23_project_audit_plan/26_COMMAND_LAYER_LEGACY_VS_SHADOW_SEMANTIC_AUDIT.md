# Command Layer Legacy vs Shadow Semantic Audit

Дата фиксации: 2026-04-23

## Назначение
Этот документ открывает этап C-A2 из `24_COMMAND_LAYER_AUDIT_PLAN.md`:
**semantic audit для legacy vs shadow command model**.

Цель:
- определить смысловую роль `GVL_COMMAND` и `GVL_COMMAND_SHADOW` в текущем live root;
- зафиксировать, какой слой уже стал operational truth;
- отделить временный migration-layer от того, что уже фактически стало боевым контуром.

## Основание
Документ опирается на результаты `25_COMMAND_LAYER_LIVE_OWNERSHIP_AUDIT.md` и текущее состояние:
- `PRG_Command_Arbitration.st`
- `PRG_Command_Verifier.st`
- `PRG_IO_Write.st`
- `PRG_Ventilation.st`
- `GVL_COMMAND.gvl`
- `GVL_COMMAND_SHADOW.gvl`

## Главный вывод
В текущем live root semantic center command-layer уже сместился в `GVL_COMMAND_SHADOW`.

То есть:
- `GVL_COMMAND_SHADOW` фактически выполняет роль **operational command layer** для подтвержденной live chain;
- `GVL_COMMAND` в этой подтвержденной цепочке уже не выглядит главным downstream source of truth;
- legacy layer сейчас смыслово ближе к **comparison / compatibility layer**, а не к конечному operational owner-layer.

Однако migration еще не завершена формально, потому что:
- verifier продолжает сравнивать оба слоя;
- комментарии и naming проекта еще не приведены к новой reality-model;
- часть командного контура все еще несет признаки переходного состояния.

## Semantic-профиль слоев

### SA-01. Semantic role of `GVL_COMMAND_SHADOW`
По текущему live root `GVL_COMMAND_SHADOW`:
- активно заполняется в `PRG_Command_Arbitration`;
- используется downstream в `PRG_IO_Write`;
- используется downstream в `PRG_Ventilation`.

Это означает, что shadow layer уже выполняет функции:
1. consolidated arbitration output;
2. downstream operational command feed;
3. intermediate execution-oriented command surface.

Вывод:
- термин `shadow` уже плохо отражает фактическую operational роль этого слоя;
- по смыслу это уже не просто тень legacy-слоя, а текущий боевой выход arbitration.

### SA-02. Semantic role of `GVL_COMMAND`
По подтвержденной live chain `GVL_COMMAND`:
- не подтвержден как текущий downstream source в `PRG_IO_Write`;
- не подтвержден как текущий command input для `PRG_Ventilation`;
- подтвержден как слой, с которым verifier сравнивает `GVL_COMMAND_SHADOW`.

Вывод:
- в пределах подтвержденной цепочки semantic роль `GVL_COMMAND` ближе к legacy compatibility/reference layer;
- это уже не выглядит как главный текущий execution-layer.

### SA-03. Semantic role of verifier
`PRG_Command_Verifier` сравнивает legacy и shadow команды и публикует mismatch indicators.

Это придает verifier следующий смысл:
- verifier пока нужен не для исполнения команд,
- а для контроля консистентности между старой и новой migration-моделью.

Вывод:
- само существование verifier подтверждает, что проект формально еще не объявил migration closed;
- verifier сейчас — маркер переходной фазы command model.

## Что уже можно считать semantic truth

### ST-01
`PRG_Command_Arbitration -> GVL_COMMAND_SHADOW` уже является подтвержденным operational output path.

### ST-02
`GVL_COMMAND_SHADOW -> PRG_IO_Write` уже является подтвержденным physical-output semantic path для gas/water/access command surfaces.

### ST-03
`GVL_COMMAND_SHADOW -> PRG_Ventilation` уже является подтвержденным subsystem-command semantic path.

### ST-04
`GVL_COMMAND` в подтвержденной live chain уже не выглядит как current operational truth для этих downstream consumers.

## Что остается semantic ambiguity

### SA-ISSUE-01. Имя `SHADOW` больше не соответствует фактической роли
Если слой реально используется downstream как operational truth, то слово `shadow` вводит в заблуждение.

Проблема:
- название и комментарии поддерживают ощущение вторичного временного слоя;
- фактическое использование уже говорит о почти главном execution-oriented слое.

### SA-ISSUE-02. Legacy layer формально еще жив, но смыслово уже ослаблен
`GVL_COMMAND` еще существует как полноценная глобальная структура и участвует в verifier-сравнении.

Проблема:
- без отдельного formal decision непонятно, должен ли он:
  - остаться как compatibility layer,
  - быть полностью выведен из operational модели,
  - или быть синхронизирован обратно как canonical layer.

### SA-ISSUE-03. Документация и inline-comments отстают от live semantics
`GVL_COMMAND_SHADOW.gvl` все еще содержит комментарий `Not connected to IO_Write yet.`

Проблема:
- внутренняя self-documentation проекта уже противоречит live root;
- это делает semantic model менее доверенной для следующего разработчика или ревьюера.

### SA-ISSUE-04. Migration end-state не закреплен как explicit architectural decision
Сейчас наблюдается фактический end-state одного типа и формальная риторика другого типа:
- фактически downstream уже живет на shadow layer;
- формально проект еще не объявил, что именно это и есть новая каноническая модель.

Проблема:
- без такого решения verifier и legacy layer могут зависнуть в проекте как бесконечное transitional baggage.

## Промежуточное semantic-решение для текущего audit baseline
На текущем этапе фиксируется следующее рабочее baseline-решение:

### Current operational semantic baseline
`GVL_COMMAND_SHADOW` рассматривается как **current operational command layer**.

### Current legacy semantic baseline
`GVL_COMMAND` рассматривается как **legacy comparison / compatibility layer**, а не как подтвержденный primary downstream execution layer.

Это решение еще не означает финальную ликвидацию legacy layer.

Оно означает только следующее:
- дальнейший аудит не должен строиться так, будто legacy-layer все еще является главным downstream owner для подтвержденной live chain.

## Что пока не решено этим документом
Этот документ еще не отвечает окончательно:
- должен ли `GVL_COMMAND_SHADOW` быть переименован или концептуально promoted;
- нужно ли зеркалить/synchronize legacy layer дальше;
- должен ли verifier остаться постоянным guard-layer или быть удален после закрытия migration;
- какие именно поля legacy-layer еще реально нужны за пределами уже подтвержденной цепочки.

## Практический следующий шаг
Следующим этапом должен стать уже целевой verifier audit.

Рекомендуемый документ:
- `27_COMMAND_VERIFIER_BEHAVIOR_AUDIT.md`

Его задача:
- подтвердить текущую роль verifier;
- проверить mismatch semantics, включая latch/reset behavior;
- определить, является ли verifier временным migration-guard или постоянным monitoring-layer.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения