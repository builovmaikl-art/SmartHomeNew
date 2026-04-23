# Command Layer Remediation Decision

Дата фиксации: 2026-04-23

## Назначение
Этот документ открывает этап C-A5 из `24_COMMAND_LAYER_AUDIT_PLAN.md`:
**remediation / migration decision** по command-layer.

Цель:
- зафиксировать целевое направление migration после завершения этапов C-A1..C-A4;
- принять рабочее архитектурное решение по `GVL_COMMAND_SHADOW`, `GVL_COMMAND` и `PRG_Command_Verifier`;
- определить, что считать cleanup, а что уже redesign следующего уровня.

## Основание
Решение опирается на:
- `25_COMMAND_LAYER_LIVE_OWNERSHIP_AUDIT.md`
- `26_COMMAND_LAYER_LEGACY_VS_SHADOW_SEMANTIC_AUDIT.md`
- `27_COMMAND_VERIFIER_BEHAVIOR_AUDIT.md`
- `28_COMMAND_DOWNSTREAM_CONSUMERS_AUDIT.md`

## Что уже подтверждено до этого решения
К текущему моменту по live root подтверждено:
- `PRG_Command_Arbitration` является активным writer-слоем для `GVL_COMMAND_SHADOW`;
- `PRG_IO_Write` и `PRG_Ventilation` уже читают `GVL_COMMAND_SHADOW` как operational downstream layer;
- `GVL_COMMAND` не подтвержден как primary execution layer для этой цепочки;
- `GVL_COMMAND` остается живым в `PRG_System` и `PRG_Security` как bridge / coordination / compatibility surface;
- `PRG_Command_Verifier` сравнивает legacy и shadow layer, но не является owner execution semantics;
- `Command_Mismatch_Active` сейчас выглядит как set-only latch без подтвержденного clear-path.

## Главный вывод
Command-layer уже нельзя честно описывать так, будто проект по-прежнему живет на legacy `GVL_COMMAND` как на основном operational command surface.

По фактическому live root:
- **execution path уже смещен в `GVL_COMMAND_SHADOW`**;
- legacy `GVL_COMMAND` уже играет остаточную bridge / compatibility роль;
- verifier остается переходным guard-layer;
- inline-comments и naming отстают от фактической модели.

Следовательно, remediation должен идти не по пути возврата к legacy, а по пути **formal promotion shadow-centered model**.

## Решение
На текущем этапе принимается следующее рабочее remediation decision:

# RD-01. `GVL_COMMAND_SHADOW` признается текущим operational command layer

Это решение означает:
- следующие cleanup-решения должны опираться на `GVL_COMMAND_SHADOW` как на подтвержденный execution-oriented слой;
- дальнейшая архитектурная работа не должна строиться так, будто `GVL_COMMAND` остается основным downstream source of truth.

Это еще не означает немедленное rename.

Но это означает:
- **semantic promotion уже принята**, даже если naming пока legacy-transition style.

# RD-02. `GVL_COMMAND` фиксируется как legacy bridge / compatibility layer

Это решение означает:
- `GVL_COMMAND` пока остается в проекте;
- но он рассматривается уже не как primary execution layer, а как transitional surface вокруг:
  - system/gateway bridge,
  - security bridge,
  - verifier comparison semantics.

Практический смысл:
- cleanup должен постепенно сокращать его роль,
- а не возвращать через него основной execution path.

# RD-03. `PRG_Command_Verifier` фиксируется как temporary migration guard

Это решение означает:
- verifier не считается финализированным monitoring subsystem;
- его semantics требует отдельного cleanup;
- пока migration formally не closed, verifier допустим как временный comparison guard.

Но:
- текущая неоднородная semantics (`count/current OK` + `set-only active`) признается незавершенной.

# RD-04. Возврат execution-path назад в legacy `GVL_COMMAND` считается неправильным направлением

Такой шаг на текущем этапе признается не remediation, а regress / rollback migration intent.

Практический смысл:
- remediation не должен возвращать `PRG_IO_Write` и `PRG_Ventilation` на legacy-layer;
- cleanup должен идти вперед, а не назад.

## Что именно считается правильным remediation path

### RMP-01. Документально закрепить shadow-centered reality
Нужно:
- обновить inline-comments, прежде всего в `GVL_COMMAND_SHADOW.gvl`;
- убрать формулировки, которые уже противоречат live root;
- привести docs к фактической command model.

### RMP-02. Уточнить остаточную роль legacy `GVL_COMMAND`
Нужно:
- отделить, какие поля остаются bridge-only;
- определить, какие поля можно будет позже убрать или перенаправить;
- не оставлять legacy-layer как бесформенный «старый, но все еще нужный» контейнер.

### RMP-03. Принять отдельное cleanup decision по verifier semantics
Нужно выбрать одно из направлений:
- current-state verifier;
- latched alarm verifier с явным reset contract;
- removal/simplification after migration close.

### RMP-04. Подготовить future bridge migration для `PRG_System` и `PRG_Security`
Нужно:
- не переписывать их вслепую прямо сейчас;
- сначала зафиксировать, какие legacy bridge-поля реально еще нужны;
- затем переводить эти bridges на новую модель уже по явному плану.

## Что считается cleanup, а что уже redesign

### Локальный cleanup
К cleanup относится:
- обновление устаревших inline-comments;
- фиксация semantic documentation;
- явное определение роли verifier;
- явное описание остаточной роли `GVL_COMMAND`.

### Следующий архитектурный cleanup
К следующему cleanup относится:
- перевод отдельных bridge-точек из legacy-layer в более чистую shadow-centered model;
- сокращение роли `GVL_COMMAND` без ломки live execution path.

### Уже redesign следующего уровня
К redesign относится:
- rename `GVL_COMMAND_SHADOW` в новый canonical global layer прямо сейчас;
- крупная перестройка gateway/security/system contracts без промежуточного boundary-plan;
- удаление `GVL_COMMAND` целиком без предварительной карты bridge-dependencies.

## Что НЕ делать после этого решения
- не возвращать execution-consumers на `GVL_COMMAND`;
- не объявлять migration formally closed уже сейчас;
- не удалять verifier без отдельного решения;
- не вычищать legacy layer целиком без отдельной bridge-dependency карты.

## Практический следующий шаг
После этого решения логично идти не в общий command-layer аудит заново, а в **узкий cleanup-план следующей волны**.

Рекомендуемый документ:
- `30_COMMAND_LAYER_CLEANUP_PLAN.md`

Его задача:
- разложить remediation path на маленькие безопасные шаги;
- отдельно выделить:
  - comment/docs cleanup,
  - verifier semantics decision,
  - legacy bridge boundary cleanup,
  - future bridge migration for `PRG_System` / `PRG_Security`.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения