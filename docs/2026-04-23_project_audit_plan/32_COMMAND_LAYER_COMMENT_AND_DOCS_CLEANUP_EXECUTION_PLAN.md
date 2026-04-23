# Command Layer Comment and Docs Cleanup Execution Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ переводит `31_COMMAND_LAYER_COMMENT_AND_DOCS_CLEANUP_PLAN.md` в **исполнительный порядок** для первой cleanup-волны по command-layer.

Это не semantic refactor и не migration rewrite.

Это строго:
- исправление устаревших inline-comments;
- выравнивание локальных semantic labels;
- удаление documented contradictions относительно live root.

## Основание
План опирается на:
- `25_COMMAND_LAYER_LIVE_OWNERSHIP_AUDIT.md`
- `26_COMMAND_LAYER_LEGACY_VS_SHADOW_SEMANTIC_AUDIT.md`
- `27_COMMAND_VERIFIER_BEHAVIOR_AUDIT.md`
- `28_COMMAND_DOWNSTREAM_CONSUMERS_AUDIT.md`
- `29_COMMAND_LAYER_REMEDIATION_DECISION.md`
- `31_COMMAND_LAYER_COMMENT_AND_DOCS_CLEANUP_PLAN.md`

## Цель исполнения
Привести локальные comments command-layer в состояние, при котором:
- они не противоречат current live root;
- они не занижают роль `GVL_COMMAND_SHADOW`;
- они не переоценивают завершенность verifier/migration model;
- они не создают ложное впечатление, что legacy `GVL_COMMAND` остается current primary execution surface.

## Execution Mode
- Режим исполнения: Direct Repository Modification Mode.
- Тип проверки: repository state verification.
- Ограничение: без compile/run подтверждения.

## Зафиксированные инварианты перед изменением
Во время этого этапа нельзя менять:
- логику `PRG_Command_Arbitration.st`;
- логику `PRG_Command_Verifier.st`;
- downstream behavior в `PRG_IO_Write.st` и `PRG_Ventilation.st`;
- naming глобальных переменных и GVL-структур;
- ownership semantics как кодовое поведение;
- migration state как runtime-модель.

Допустимы только documentary/non-functional изменения.

## Исполнительный порядок

### Шаг CDE-01. Исправить самый явный documented contradiction в `GVL_COMMAND_SHADOW.gvl`
Действие:
- найти и заменить комментарий, утверждающий, что `GVL_COMMAND_SHADOW` `Not connected to IO_Write yet.`
- привести формулировку к current live-model, где shadow layer уже используется downstream.

Ожидаемый результат:
- ключевое противоречие между inline-comment и live root устранено.

### Шаг CDE-02. Проверить `GVL_COMMAND_SHADOW.gvl` на другие comments, занижающие operational роль слоя
Действие:
- пройти comments этого файла;
- убрать формулировки, которые описывают layer как purely-shadow / non-operational, если live root уже подтверждает execution use.

Ожидаемый результат:
- file-level self-description становится совместимой с shadow-centered operational baseline.

### Шаг CDE-03. Проверить `PRG_Command_Verifier.st` на misleading finalized-monitoring wording
Действие:
- проверить, нет ли comments, звучащих так, будто verifier уже является fully finalized monitoring subsystem;
- при необходимости ослабить wording до migration-guard semantics.

Ожидаемый результат:
- comments verifier-layer не обещают больше, чем реально подтверждено live audit.

### Шаг CDE-04. Проверить `PRG_Command_Arbitration.st` на устаревший transitional wording
Действие:
- найти локальные comments, если они описывают shadow-layer как временный mirror без downstream dominance;
- исправить wording только там, где он уже конфликтует с live reality.

Ожидаемый результат:
- active writer-layer описан без semantic contradiction.

### Шаг CDE-05. При необходимости сделать короткий pass по `GVL_COMMAND.gvl`, `PRG_IO_Write.st`, `PRG_Ventilation.st`
Действие:
- проверить только короткие comments/labels;
- не трогать файлы, если явного contradictions нет;
- исправлять только documented mismatch с подтвержденной live model.

Ожидаемый результат:
- secondary files не несут заведомо ложной semantic картины.

### Шаг CDE-06. Выполнить repository-state verification после docs-cleanup
Действие:
- перечитать измененные файлы;
- подтвердить, что изменились только comments/labels;
- подтвердить, что runtime logic и interfaces не менялись.

Нужно подтвердить:
1. logic untouched;
2. ownership untouched as code behavior;
3. comments now align with live root;
4. no premature claim that migration is fully closed.

Ожидаемый результат:
- docs-cleanup подтвержден как purely documentary improvement.

## Что считается допустимым изменением
Допустимо:
- редактировать комментарии;
- убирать устаревшие формулировки;
- уточнять semantic labels;
- убирать явные contradictions между кодом и comments.

## Что запрещено на этом шаге
Запрещено:
- менять branch semantics;
- менять reset/set behavior verifier;
- менять writers/readers;
- делать rename `GVL_COMMAND_SHADOW`;
- убирать `GVL_COMMAND`;
- объявлять migration formally closed в comments или docs.

## Критерии успешного завершения execution plan
Этап считается успешно выполненным, если:
1. устранено главное contradiction в `GVL_COMMAND_SHADOW.gvl`;
2. comments command-layer больше не конфликтуют с current live-root ownership map;
3. verifier comments не переоценивают его зрелость;
4. не внесено ни одного логического изменения.

## Следующий документ после исполнения
После выполнения этого плана должен появиться:
- `33_COMMAND_LAYER_COMMENT_AND_DOCS_CLEANUP_RESULT.md`

В нем нужно будет зафиксировать:
- какие comments были исправлены;
- какие файлы реально потребовали правки;
- что осталось для следующей cleanup-волны без documentary contradictions.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения