# Command Verifier Semantics Decision

Дата фиксации: 2026-04-23

## Назначение
Этот документ фиксирует следующее узкое решение после `33_COMMAND_LAYER_COMMENT_AND_DOCS_CLEANUP_RESULT.md`:
**какой semantics contract должен быть у `PRG_Command_Verifier` на текущем этапе migration**.

Цель:
- убрать неоднозначность вокруг `Command_Mismatch_Count`, `Command_Match_OK` и `Command_Mismatch_Active`;
- зафиксировать, как трактовать verifier до formal migration close;
- отделить локальный cleanup verifier semantics от более крупного redesign command-layer.

## Основание
Решение опирается на:
- `27_COMMAND_VERIFIER_BEHAVIOR_AUDIT.md`
- `29_COMMAND_LAYER_REMEDIATION_DECISION.md`
- `30_COMMAND_LAYER_CLEANUP_PLAN.md`
- `33_COMMAND_LAYER_COMMENT_AND_DOCS_CLEANUP_RESULT.md`

## Что уже подтверждено
По текущему live root подтверждено:
- `Command_Mismatch_Count` пересчитывается заново каждый цикл;
- `Command_Match_OK` отражает текущее состояние совпадения/расхождения;
- `Command_Mismatch_Active` выставляется в `TRUE` при mismatch;
- симметричный clear-path для `Command_Mismatch_Active` в подтвержденном live root не найден;
- verifier в целом является temporary migration guard, а не финализированным monitoring subsystem.

## Проблема, которую нужно решить
Сейчас внутри verifier coexist одновременно существуют:
- current-state count,
- current-state OK flag,
- latch-like active flag.

Это создает mixed semantics и делает downstream interpretation неоднозначной.

Нужно выбрать, что считать правильным направлением:
1. current-state verifier,
2. latched alarm verifier,
3. removal/simplification later after migration close.

## Решение
На текущем этапе принимается следующее рабочее решение:

# VSD-01. Целевая semantics verifier должна быть current-state based

Это означает:
- `Command_Mismatch_Count` — current-cycle / current-state indicator;
- `Command_Match_OK` — current-state indicator;
- `Command_Mismatch_Active` тоже должен трактоваться как **current-state mismatch flag**, а не как historical latched alarm.

## Почему принято именно такое решение

### VSD-02. Это уже согласуется с двумя из трех текущих сигналов
Сейчас:
- count уже current-state;
- match_ok уже current-state.

Если `Command_Mismatch_Active` тоже сделать current-state flag, verifier contract станет внутренне однородным.

Вывод:
- это минимально ломающий и наиболее согласованный путь.

### VSD-03. Latched alarm semantics в проекте нигде явно не оформлена
Чтобы считать `Command_Mismatch_Active` latched alarm, нужен как минимум:
- reset-owner,
- reset-condition,
- документированный operator/system contract.

По текущему live root такой contract не зафиксирован.

Вывод:
- формализовывать latched alarm без такого контракта сейчас было бы искусственным усложнением.

### VSD-04. Verifier остается temporary migration guard, а не persistent alarm subsystem
Verifier уже зафиксирован как temporary migration guard.

Для такого слоя natural semantics — это:
- показывать, есть ли mismatch сейчас,
- а не накапливать historical-latch без ясного operational workflow.

Вывод:
- current-state model лучше соответствует его текущей роли.

### VSD-05. Это самый безопасный cleanup перед formal migration close
Если позже migration будет formally closed, verifier можно будет:
- упростить,
- ослабить,
- убрать.

Current-state semantics легче упростить потом, чем latched alarm semantics с отдельным reset-contract.

## Формальное решение по сигналам

### `Command_Mismatch_Count`
Статус:
- current-state / current-cycle derived value.

### `Command_Match_OK`
Статус:
- current-state derived flag.

### `Command_Mismatch_Active`
Целевая трактовка:
- current-state mismatch flag.

То есть:
- `TRUE`, когда mismatch сейчас есть;
- `FALSE`, когда mismatch сейчас нет.

## Что это означает practically
На уровне cleanup-направления это означает:
- текущий set-only behavior для `Command_Mismatch_Active` признается **нежелательным transitional artifact**;
- следующий локальный cleanup verifier должен привести `Command_Mismatch_Active` к симметричному current-state contract.

## Что это решение НЕ означает
Это решение не означает:
- немедленное удаление verifier;
- formal migration close;
- redesign verifier в сложный diagnostic subsystem;
- ввод historical alarm memory внутри этого слоя.

## Что теперь считается неправильным направлением
Неправильно:
- оставлять `Command_Mismatch_Active` как set-only latch без clear-path;
- трактовать его как latched alarm без явного reset contract;
- продолжать mixed semantics внутри verifier как будто это приемлемый final state.

## Следующий рекомендуемый шаг
Следующий документ должен быть уже не общим решением, а практическим changeset-планом:
- `35_COMMAND_VERIFIER_CURRENT_STATE_CLEANUP_PLAN.md`

Его задача:
- зафиксировать минимальный безопасный changeset, который сделает `Command_Mismatch_Active` симметричным current-state flag без затрагивания остальных частей command-layer.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения