# Command Legacy Bridge Boundary Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ открывает следующую cleanup-волну после `37_COMMAND_VERIFIER_CURRENT_STATE_CLEANUP_RESULT.md`:
**формализация legacy bridge boundary внутри command-layer**.

Цель:
- зафиксировать остаточную роль `GVL_COMMAND`;
- отделить execution-path от bridge/admin/security хвоста;
- подготовить безопасную следующую волну cleanup вокруг `PRG_System` и `PRG_Security`.

## Основание
План опирается на:
- `28_COMMAND_DOWNSTREAM_CONSUMERS_AUDIT.md`
- `29_COMMAND_LAYER_REMEDIATION_DECISION.md`
- `30_COMMAND_LAYER_CLEANUP_PLAN.md`
- `37_COMMAND_VERIFIER_CURRENT_STATE_CLEANUP_RESULT.md`

## Что уже подтверждено
По текущему live root уже зафиксировано:
- `GVL_COMMAND_SHADOW` доминирует в подтвержденном execution-consumer path;
- `PRG_IO_Write` и `PRG_Ventilation` уже используют shadow-layer как operational downstream surface;
- `GVL_COMMAND` остается живым в первую очередь вокруг `PRG_System` и `PRG_Security`;
- verifier больше не имеет mixed semantics по mismatch flags, но overall migration еще не closed formally.

## Главная boundary-проблема
Сейчас command-layer уже не хаотичен, но его остаточная mixed model все еще недостаточно формализована.

Практическая двусмысленность состоит в следующем:
- execution-path уже ушел в `GVL_COMMAND_SHADOW`;
- legacy `GVL_COMMAND` все еще жив в bridge/coordination/security flows;
- без явной границы проект выглядит так, будто оба слоя все еще равноправны, хотя это уже не так.

## Главный вывод
На текущем этапе `GVL_COMMAND` должен рассматриваться как:

# legacy bridge / compatibility surface

а не как основной execution command layer.

Это boundary-решение не удаляет `GVL_COMMAND` немедленно.

Но оно требует:
- описать, какие use-cases еще оправдывают его существование;
- отделить bridge-tail от реального operational execution path;
- не допускать повторного смешения этих ролей в следующих cleanup-шагах.

## Что именно входит в legacy bridge boundary

### LBB-01. System / gateway bridge surface
Под это попадают участки в `PRG_System`, где `GVL_COMMAND` используется для:
- gateway-oriented request/response paths;
- scenario/operator request bridging;
- redundancy/sync-related bridging;
- 2FA request / code transfer fields.

Смысл:
- это coordination/bridge behavior,
- а не подтвержденный direct execution path текущей command-model.

### LBB-02. Security / access bridge surface
Под это попадают участки в `PRG_Security`, где `GVL_COMMAND` используется для:
- 2FA send/request outputs;
- связей access/security logic с command-layer surface.

Смысл:
- это bridge between security/access logic and broader command model,
- а не доказанный главный execution layer.

### LBB-03. Legacy comparison surface for verifier
Под это попадает роль `GVL_COMMAND` как comparison-side в `PRG_Command_Verifier`.

Смысл:
- verifier пока еще использует legacy-layer как reference/comparison surface,
- но это не делает его primary operational owner-layer.

## Что НЕ входит в legacy bridge boundary

### LBB-NO-01
Не входит подтвержденный execution-path через:
- `PRG_IO_Write`
- `PRG_Ventilation`

Эти участки уже относятся к shadow-centered operational path.

### LBB-NO-02
Не входит `PRG_Command_Arbitration` как active writer-layer для `GVL_COMMAND_SHADOW`.

### LBB-NO-03
Не входит предположение, что весь `GVL_COMMAND` еще нужен целиком — это как раз должно быть проверено следующими cleanup-шагами.

## Практическая цель boundary-plan
После этого этапа следующая волна cleanup должна отвечать не на абстрактный вопрос «убирать ли legacy?», а на конкретные вопросы:
1. какие поля `GVL_COMMAND` реально еще нужны только для system/gateway/security bridging;
2. какие поля уже не оправданы даже как bridge-tail;
3. какие bridge-use-cases можно позже перевести на shadow-centered model;
4. какие поля verifier все еще должен сравнивать до migration close.

## Правильный порядок следующей волны

### Этап LBP-1. Field-level bridge map
Нужно разложить `GVL_COMMAND` по полям и use-cases:
- bridge-only,
- comparison-only,
- unclear / legacy residue.

Результат:
- granular карта остаточной полезности legacy-layer.

### Этап LBP-2. `PRG_System` bridge audit
Нужно отдельно пройти:
- scenario/gateway/operator/sync/2FA use-cases,
- и понять, какие из них реально зависят от `GVL_COMMAND` как от legacy bridge surface.

Результат:
- system-side dependency map.

### Этап LBP-3. `PRG_Security` bridge audit
Нужно отдельно пройти:
- 2FA/access bridge paths,
- и определить, где `GVL_COMMAND` еще является реальной bridge-surface necessity.

Результат:
- security-side dependency map.

### Этап LBP-4. Future bridge migration shortlist
Только после field-level и program-level карт можно составлять shortlist:
- что переводить первым,
- что оставить временно,
- что считать candidate на удаление later.

Результат:
- controlled future migration wave instead of blind cleanup.

## Что НЕ делать на этом этапе

### LBB-AVOID-01
Не удалять `GVL_COMMAND` целиком.

### LBB-AVOID-02
Не переносить вслепую `PRG_System` и `PRG_Security` на shadow-layer.

### LBB-AVOID-03
Не объявлять bridge-boundary cleanup равным migration close.

### LBB-AVOID-04
Не смешивать bridge-boundary cleanup с rename/promote decision для `GVL_COMMAND_SHADOW`.

## Критерии успеха этого этапа
Этап считается успешным, если после него:
1. `GVL_COMMAND` перестает восприниматься как неясный «еще зачем-то живой» слой;
2. его роль описана именно как bridge / compatibility surface;
3. execution-path и bridge-path разведены по смыслу;
4. следующий cleanup идет уже по field-level and program-level dependency map, а не наугад.

## Следующий рекомендуемый документ
- `39_COMMAND_LEGACY_BRIDGE_FIELD_MAP_PLAN.md`

Его задача:
- начать field-level разбор `GVL_COMMAND`;
- разложить поля по категориям `bridge-only / comparison-only / unclear residue`.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения