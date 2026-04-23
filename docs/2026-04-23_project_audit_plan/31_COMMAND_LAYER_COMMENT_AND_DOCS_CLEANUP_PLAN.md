# Command Layer Comment and Docs Cleanup Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ открывает первую практическую волну cleanup из `30_COMMAND_LAYER_CLEANUP_PLAN.md`:
**comment / docs cleanup для command-layer**.

Цель:
- зафиксировать, какие inline-comments и локальные описания уже противоречат live root;
- определить минимальный changeset для их исправления;
- не смешивать docs-cleanup с логическим изменением command semantics.

## Основание
План опирается на:
- `25_COMMAND_LAYER_LIVE_OWNERSHIP_AUDIT.md`
- `26_COMMAND_LAYER_LEGACY_VS_SHADOW_SEMANTIC_AUDIT.md`
- `28_COMMAND_DOWNSTREAM_CONSUMERS_AUDIT.md`
- `29_COMMAND_LAYER_REMEDIATION_DECISION.md`
- `30_COMMAND_LAYER_CLEANUP_PLAN.md`

## Почему этот шаг идет первым
На текущем этапе уже подтверждено, что:
- `GVL_COMMAND_SHADOW` фактически работает как operational command layer;
- `PRG_IO_Write` и `PRG_Ventilation` уже используют его downstream;
- часть inline-comments все еще описывает старую transitional reality.

Это делает docs-cleanup самым безопасным первым шагом, потому что:
- он снижает semantic ambiguity;
- не требует изменения логики;
- подготавливает почву для verifier cleanup и legacy bridge boundary cleanup.

## Главная цель этапа
Привести локальные комментарии command-layer в состояние, при котором:
- они не противоречат текущему live root;
- они не обещают то, чего уже нет или что уже изменилось;
- они не поддерживают ложное ощущение, что `GVL_COMMAND_SHADOW` еще не участвует в реальном execution path.

## Основные проблемные точки comments/docs

### CDC-01. `GVL_COMMAND_SHADOW.gvl`
Уже подтверждено противоречие:
- в файле присутствует комментарий `Not connected to IO_Write yet.`
- live root подтверждает, что `PRG_IO_Write` уже читает `GVL_COMMAND_SHADOW` для physical outputs.

Вывод:
- этот комментарий должен быть исправлен в первую очередь.

Приоритет: CRITICAL.

### CDC-02. Комментарии, подразумевающие вторичную или purely-shadow роль слоя
После live-root audit и semantic audit уже видно, что слово `shadow` по naming еще сохраняется, но фактическая роль слоя давно вышла за рамки «временной тени без downstream dominance».

Что нужно проверить:
- нет ли локальных пояснений, где `GVL_COMMAND_SHADOW` описан как исключительно transitional mirror, хотя он уже operational downstream layer.

Приоритет: HIGH.

### CDC-03. Комментарии вокруг verifier, если они звучат как finalized monitoring model
После verifier audit уже зафиксировано, что:
- verifier сейчас больше похож на temporary migration guard;
- его semantics еще не финализирована.

Что нужно проверить:
- нет ли комментариев, которые звучат так, будто verifier уже является завершенным и стабильным monitoring-layer.

Приоритет: HIGH.

### CDC-04. Локальные comments в command-layer, которые размывают legacy bridge role
После downstream consumers audit уже видно, что:
- `GVL_COMMAND` еще жив,
- но semantic center command execution уже не там.

Что нужно проверить:
- нет ли формулировок, которые продолжают описывать `GVL_COMMAND` как primary execution surface без оговорки про legacy/bridge role.

Приоритет: MEDIUM-HIGH.

## Область первой волны docs-cleanup

### Обязательные файлы
- `GVL_COMMAND_SHADOW.gvl`
- `PRG_Command_Verifier.st`
- `PRG_Command_Arbitration.st`

### Дополнительные кандидаты на проверку
- `GVL_COMMAND.gvl`
- короткие локальные comments в `PRG_IO_Write.st`
- короткие локальные comments в `PRG_Ventilation.st`

## Принцип минимального changeset
На этом этапе исправляются только:
- неверные или устаревшие comments;
- локальные описания, противоречащие live root;
- краткие semantic labels, если они вводят в заблуждение.

На этом этапе НЕ исправляются:
- naming глобальных переменных;
- execution semantics;
- verifier logic;
- legacy bridge contracts;
- архитектурные границы между слоями.

## Что именно должно получиться после cleanup

### CC-OUT-01
В `GVL_COMMAND_SHADOW.gvl` не должно остаться комментариев, утверждающих, что слой еще не подключен к `IO_Write`, если live root подтверждает обратное.

### CC-OUT-02
Локальные descriptions command-layer должны быть совместимы с baseline:
- `GVL_COMMAND_SHADOW` — operational command layer;
- `GVL_COMMAND` — legacy bridge / compatibility layer;
- verifier — temporary migration guard.

### CC-OUT-03
Ни один comment не должен преждевременно объявлять migration fully closed, если по текущим audit-документам это еще не подтверждено.

## Что НЕ входит в этот этап

### CDC-NO-01
Не менять логику `PRG_Command_Verifier`.

### CDC-NO-02
Не менять логику `PRG_Command_Arbitration`.

### CDC-NO-03
Не менять downstream consumers.

### CDC-NO-04
Не делать rename `GVL_COMMAND_SHADOW`.

### CDC-NO-05
Не удалять `GVL_COMMAND`.

### CDC-NO-06
Не объявлять migration formally closed.

## Очередность cleanup-работ

### Этап CDL-1
Почистить `GVL_COMMAND_SHADOW.gvl` как самую явную точку противоречия.

### Этап CDL-2
Проверить `PRG_Command_Verifier.st` на misleading comments about monitoring/finalized semantics.

### Этап CDL-3
Проверить `PRG_Command_Arbitration.st` и связанные локальные comments на предмет transitional wording, уже противоречащего live reality.

### Этап CDL-4
Только после этого решать, требуется ли отдельная short docs pass по `GVL_COMMAND.gvl`, `PRG_IO_Write.st`, `PRG_Ventilation.st`.

## Критерии успешного завершения этапа
Этап считается успешно подготовленным, если:
1. исправлен хотя бы основной documented contradiction вокруг `GVL_COMMAND_SHADOW`;
2. comments command-layer больше не конфликтуют с live-root ownership map;
3. cleanup остается purely documentary и не превращается в semantic refactor.

## Следующий рекомендуемый документ
- `32_COMMAND_LAYER_COMMENT_AND_DOCS_CLEANUP_EXECUTION_PLAN.md`

Его задача:
- перевести этот cleanup-план в конкретный исполнительный порядок по файлам и правкам.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения