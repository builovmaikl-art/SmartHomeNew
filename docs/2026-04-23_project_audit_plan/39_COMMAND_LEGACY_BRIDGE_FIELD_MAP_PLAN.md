# Command Legacy Bridge Field Map Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ открывает следующий практический шаг после `38_COMMAND_LEGACY_BRIDGE_BOUNDARY_PLAN.md`:
**field-level разбор `GVL_COMMAND` как legacy bridge / compatibility surface**.

Цель:
- перестать рассматривать `GVL_COMMAND` как единый неделимый legacy-блок;
- разложить его поля по фактической остаточной роли;
- подготовить базу для controlled cleanup и future bridge migration.

## Основание
План опирается на:
- `28_COMMAND_DOWNSTREAM_CONSUMERS_AUDIT.md`
- `29_COMMAND_LAYER_REMEDIATION_DECISION.md`
- `30_COMMAND_LAYER_CLEANUP_PLAN.md`
- `38_COMMAND_LEGACY_BRIDGE_BOUNDARY_PLAN.md`
- текущее состояние `GVL_COMMAND.gvl`

## Уже зафиксированная базовая рамка
К текущему моменту уже подтверждено:
- `GVL_COMMAND_SHADOW` — operational execution layer;
- `GVL_COMMAND` — legacy bridge / compatibility surface;
- execution-path и legacy bridge-path не должны больше смешиваться;
- следующий cleanup должен идти по dependency map, а не по инерции.

Следовательно, `GVL_COMMAND` нужно разбирать не как «старый слой целиком», а как набор полей с разной остаточной ценностью.

## Главная задача field map
Построить карту полей `GVL_COMMAND` по трем категориям:

### Категория F-01. bridge-only
Поля, которые еще оправданы как часть:
- system/gateway bridge,
- security/access bridge,
- scenario/operator bridge,
- redundancy/sync bridge.

### Категория F-02. comparison-only
Поля, которые фактически нужны только потому, что:
- `PRG_Command_Verifier` еще сравнивает legacy layer с shadow layer.

### Категория F-03. unclear / legacy residue
Поля, для которых по текущему состоянию репозитория еще не ясно:
- есть ли у них реальный bridge-use-case,
- или это уже просто остаток незавершенной migration.

## Почему этот этап нужен до любых bridge-migration действий
Без field-level карты слишком легко ошибиться в одну из двух сторон:

1. **удалить лишнее слишком рано**,
   если поле все еще реально нужно для `PRG_System` или `PRG_Security`;

2. **оставить лишнее слишком надолго**,
   если поле уже не используется даже как bridge-surface.

Field map нужен именно для того, чтобы:
- отличить реальную зависимость от инерционного наследия;
- сделать следующую волну cleanup доказательной, а не эвристической.

## Что именно должно быть сделано на этом этапе

### FLM-01. Перечислить все поля `GVL_COMMAND`
Нужно пройти `GVL_COMMAND.gvl` сверху вниз и собрать полный список актуальных полей.

Это создаст:
- полную инвентаризацию legacy command surface.

### FLM-02. Для каждого поля зафиксировать current confirmed role
Для каждого поля нужно попытаться ответить:
- есть ли подтвержденный execution-consumer?
- есть ли подтвержденный bridge-consumer?
- используется ли оно verifier как comparison surface?
- есть ли признаки, что это просто residue без явной полезности?

### FLM-03. Разложить поля по группам use-case
Практически полезно группировать поля хотя бы по блокам:
- gas / boiler / ventilation,
- water valves,
- access / locks / gate / wicket,
- scenario / operator,
- gateway / 2FA / security exchange,
- sync / redundancy / service commands.

Это нужно, чтобы не терять subsystem-context каждого поля.

### FLM-04. Для unclear residue полей явно пометить, что они требуют следующей проверки
Если по полю нет уверенного live-root подтверждения, его нельзя сразу считать мусором.

Но и оставлять его без метки нельзя.

Нужна явная пометка:
- `unclear / needs program-level confirmation`.

## Что НЕ нужно делать на этом этапе

### FLM-NO-01
Не менять `GVL_COMMAND.gvl` кодом.

### FLM-NO-02
Не переводить поля автоматически в `GVL_COMMAND_SHADOW`.

### FLM-NO-03
Не убирать поля только потому, что они «похожи на legacy».

### FLM-NO-04
Не смешивать field-map с runtime cleanup.

### FLM-NO-05
Не считать comparison-only поля автоматически useless до решения по final verifier lifecycle.

## Практический формат результата
После этапа должен появиться документ/карта, где для каждого поля или блока полей будет указано:
- confirmed role,
- confirmed consumers,
- preliminary category:
  - bridge-only,
  - comparison-only,
  - unclear residue.

## Критерии успеха этапа
Этап считается успешно подготовленным, если:
1. `GVL_COMMAND` перестает быть «черным ящиком legacy-хвоста`;
2. появляется инвентаризация его полей;
3. следующие program-level audits (`PRG_System`, `PRG_Security`) смогут опираться на уже готовую field-map;
4. cleanup перестает зависеть от общих впечатлений и переходит на уровень доказуемых зависимостей.

## Следующий рекомендуемый документ
- `40_COMMAND_LEGACY_BRIDGE_FIELD_MAP_AUDIT.md`

Его задача:
- пройти `GVL_COMMAND.gvl` field-by-field;
- присвоить полям предварительные категории и связи.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения