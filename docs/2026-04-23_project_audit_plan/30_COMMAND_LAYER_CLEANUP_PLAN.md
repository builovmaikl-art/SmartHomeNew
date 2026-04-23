# Command Layer Cleanup Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ переводит `29_COMMAND_LAYER_REMEDIATION_DECISION.md` в следующий практический этап:
**cleanup command-layer после принятого remediation direction**.

Цель:
- разложить работу по command-layer на безопасные и управляемые шаги;
- не смешивать локальный cleanup с крупным redesign;
- закрепить shadow-centered operational model без преждевременного ломания bridge-слоев.

## Основание
План опирается на:
- `25_COMMAND_LAYER_LIVE_OWNERSHIP_AUDIT.md`
- `26_COMMAND_LAYER_LEGACY_VS_SHADOW_SEMANTIC_AUDIT.md`
- `27_COMMAND_VERIFIER_BEHAVIOR_AUDIT.md`
- `28_COMMAND_DOWNSTREAM_CONSUMERS_AUDIT.md`
- `29_COMMAND_LAYER_REMEDIATION_DECISION.md`

## Базовое решение, от которого идем дальше
На текущем этапе уже зафиксировано:
- `GVL_COMMAND_SHADOW` — current operational command layer;
- `GVL_COMMAND` — legacy bridge / compatibility layer;
- `PRG_Command_Verifier` — temporary migration guard;
- rollback execution-path назад в `GVL_COMMAND` считается неверным направлением.

Следовательно, cleanup должен идти по пути:
- закрепления shadow-centered reality;
- сокращения semantic ambiguity;
- подготовки controlled bridge migration;
- без преждевременного глобального rename/delete действий.

## Цель cleanup-этапа
Привести command-layer к более чистому и понятному transitional состоянию, при котором:
- live reality не противоречит inline-comments и локальной документации;
- verifier semantics становится явной, а не смешанной;
- остаточная роль legacy `GVL_COMMAND` описана и ограничена;
- следующий bridge migration step можно планировать на основе зафиксированных границ.

## Что входит в cleanup первой волны

### CLC-01. Comment / docs cleanup
Что нужно сделать:
- найти и исправить inline-comments, уже противоречащие live root;
- в первую очередь почистить `GVL_COMMAND_SHADOW.gvl`;
- затем проверить связанные описания command-layer в живых документах текущего цикла.

Почему это first priority:
- сейчас documentation прямо отстает от operational model;
- это мешает любому следующему решению по ownership и migration close.

Приоритет: HIGH.

### CLC-02. Verifier semantics cleanup decision
Что нужно сделать:
- принять отдельное решение по `Command_Mismatch_Active`;
- выбрать один из режимов:
  1. current-state flag,
  2. latched alarm с явным reset contract,
  3. упрощение/удаление verifier после следующего migration stage.

Почему это second priority:
- verifier уже подтвержден как transition-layer,
- но его semantics сейчас неоднородна и может вводить в заблуждение downstream users.

Приоритет: HIGH.

### CLC-03. Legacy bridge boundary cleanup
Что нужно сделать:
- зафиксировать, какие части `GVL_COMMAND` действительно остаются bridge-only;
- отделить их от того, что уже не должно считаться активным operational path;
- описать boundary между:
  - shadow execution path,
  - legacy bridge/admin/security tail.

Почему это важно:
- без этой границы проект остается в «туманной mixed model»;
- следующий migration step будет слишком рискованным.

Приоритет: HIGH.

### CLC-04. Future bridge migration preparation
Что нужно сделать:
- подготовить отдельную карту зависимостей для `PRG_System` и `PRG_Security`;
- не мигрировать их сразу,
- а сначала определить, какие поля legacy-layer им действительно еще нужны.

Почему это не first step:
- это уже ближе к следующей волне изменений,
- и без boundary cleanup туда идти рано.

Приоритет: MEDIUM.

## Что пока НЕ входит в cleanup первой волны

### CLC-NO-01
Не делать глобальный rename `GVL_COMMAND_SHADOW` в этом этапе.

### CLC-NO-02
Не удалять `GVL_COMMAND` целиком.

### CLC-NO-03
Не переводить `PRG_System` и `PRG_Security` на новую модель без отдельного bridge migration plan.

### CLC-NO-04
Не переписывать `PRG_Command_Arbitration` как новый архитектурный слой, если задача ограничивается semantic cleanup.

### CLC-NO-05
Не закрывать migration formally до завершения verifier/bridge cleanup.

## Очередность cleanup-работ

### Этап CLP-1. Fix live-model comments and local docs
Результат:
- inline-comments больше не противоречат текущему operational path.

### Этап CLP-2. Decide verifier semantics
Результат:
- `PRG_Command_Verifier` получает однозначный contract.

### Этап CLP-3. Formalize legacy bridge boundary
Результат:
- становится понятно, что именно еще живет в `GVL_COMMAND` и почему.

### Этап CLP-4. Prepare bridge migration wave
Результат:
- можно безопасно планировать отдельную migration wave для `PRG_System` / `PRG_Security`.

## Практический формат следующего шага
Следующий документ должен идти по самому безопасному и очевидному направлению первой волны:
- `31_COMMAND_LAYER_COMMENT_AND_DOCS_CLEANUP_PLAN.md`

Его задача:
- зафиксировать, какие именно inline-comments и короткие локальные описания уже противоречат live root;
- определить минимальный changeset для их исправления без изменения логики.

## Критерии успеха cleanup-плана
Этап считается правильно запущенным, если:
1. shadow-centered operational model остается базовой точкой;
2. cleanup не превращается в rollback или premature redesign;
3. verifier semantics вынесена в отдельное решение;
4. legacy bridge boundary начинает описываться явно, а не подразумеваться.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения