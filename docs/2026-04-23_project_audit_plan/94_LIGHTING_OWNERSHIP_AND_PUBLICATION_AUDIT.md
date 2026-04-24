# Lighting Ownership and Publication Audit

Дата фиксации: 2026-04-23

## Назначение
Этот документ выполняет этап `L-A2` из `92_LIGHTING_AUDIT_PLAN.md`:
**ownership/publication audit** для lighting cluster.

Цель:
- понять, где именно живет ownership lighting requests, overrides, effective levels и publication semantics;
- отделить clean publication paths от direct post-manager mutations и cross-cutting side effects;
- определить, где lighting cluster already structurally healthy, а где начинается ownership smell.

## Основание
Документ опирается на:
- `93_LIGHTING_LIVE_PROGRAM_AUDIT.md`
- текущее состояние `PRG_Lighting.st`

## Главный вывод
Ownership lighting cluster в текущем live root уже можно описать достаточно четко:
- **user/system override intake** организован явно и читаемо;
- **core lighting/blinds/sockets computation** в значительной степени делегирован manager-блокам;
- но **final effective lighting levels** уже не являются purely manager-owned, потому что после manager-call `PRG_Lighting.st` сам напрямую переопределяет `GVL_STATE.G_Lighting_Levels` в evacuation mode.

Именно это является главным ownership smell текущего lighting cluster:
- final output ownership split between manager outputs and post-manager override tail.

## Requests and overrides ownership

### LOPA-01. User overrides не рождаются внутри lighting layer
`PRG_Lighting.st` читает сверху:
- `GVL_INTENT_USER.I_Lighting_Override_32`
- `GVL_INTENT_USER.I_Blinds_Override_32`
- `GVL_INTENT_USER.I_Socket_Override_32`

Вывод:
- ownership user-driven manual override requests находится выше lighting program-layer;
- lighting выступает consumer/adapter этого input surface, а не producer.

### LOPA-02. System override blocking применяется прямо в `PRG_Lighting.st`
`PRG_Lighting.st` сам интерпретирует:
- `GVL_INTENT_SYSTEM.I_Lighting_Overrides_Block`
- `GVL_INTENT_SYSTEM.I_Blinds_Overrides_Block`
- `GVL_INTENT_SYSTEM.I_Socket_Overrides_Block`

и на этой основе обнуляет соответствующие manual override arrays.

Вывод:
- override-gating ownership частично находится внутри lighting program;
- это уже не просто pass-through input layer, а cross-cutting policy application point.

### LOPA-03. Lighting override intake path выглядит structurally clean
Текущая цепочка для manual overrides выглядит так:
- `GVL_INTENT_USER` -> local lighting arrays -> manager inputs

При этом system-block intents применяются до manager-call как явный pre-processing layer.

Вывод:
- input-side override path пока выглядит clean and understandable.

## Adapter ownership

### LOPA-04. `PRG_Lighting.st` владеет adapter-role для array normalization
Программа использует локальные arrays для:
- manual light/blinds/socket overrides,
- simulation lights,
- physical switches,
- motion sensors,
- blinds/socket arrays reduced to FB-sized contracts.

Вывод:
- adapter ownership явно лежит в `PRG_Lighting.st`;
- это нормальная роль wrapper/program layer и не выглядит defect сама по себе.

### LOPA-05. Lighting layer already aggregates more than one domain-output family
В одном program-layer собираются:
- lighting,
- blinds,
- sockets.

Вывод:
- lighting cluster уже не узкий single-output wrapper;
- это broader home-comfort/control aggregation layer.

Само по себе это пока не дефект, но усиливает важность чистого ownership разделения.

## Manager-bounded publication paths

### LOPA-06. Lighting/blinds core publication initially идет через manager contract
`fbLightingManager(...)` публикует:
- `VO_Lighting_Levels => GVL_STATE.G_Lighting_Levels`
- `VO_Blinds_Positions => GVL_STATE.G_Blinds_Positions`

Вывод:
- baseline publication path для lighting/blinds initially manager-bounded.

### LOPA-07. Socket publication initially идет через отдельный manager contract
`fbSocketManager(...)` публикует:
- `VO_Socket_States => GVL_STATE.G_Socket_States`

Вывод:
- socket path на текущем этапе выглядит clean manager-bounded publication.

### LOPA-08. Явной status-publication surface в `PRG_Lighting.st` почти нет
В отличие от heating/ventilation/security,
в `PRG_Lighting.st` нет ярко выраженного отдельного `GVL_STATUS` publication tail для lighting/blinds/sockets.

Вывод:
- lighting cluster сейчас больше про effective state publication, чем про status-msg ownership.

## Effective output ownership

### LOPA-09. `GVL_STATE.G_Lighting_Levels` не является purely manager-owned final output
После `fbLightingManager(...)` программа выполняет:
- evacuation lighting override;
- directional evacuation override;
- прямые записи в `GVL_STATE.G_Lighting_Levels`.

Вывод:
- final effective owner `G_Lighting_Levels` в runtime оказывается split between:
  - manager-produced baseline,
  - program-level evacuation override tail.

Это главный ownership smell lighting cluster.

### LOPA-10. `GVL_STATE.G_Blinds_Positions` пока выглядит cleaner than lighting levels
`G_Blinds_Positions` публикуется manager-блоком и не получает аналогичного post-manager override tail в `PRG_Lighting.st`.

Вывод:
- blinds path currently cleaner than lighting levels path.

### LOPA-11. `GVL_STATE.G_Socket_States` тоже выглядит cleaner than lighting levels
`G_Socket_States` публикуется через `fbSocketManager(...)` и не получает аналогичного post-manager mutation tail в текущем checked scope.

Вывод:
- sockets path currently cleaner than lighting levels path.

## Evacuation override ownership

### LOPA-12. Evacuation override живет вне manager, но внутри `PRG_Lighting.st`
При `GVL_STATE.G_Evacuation_Lighting_Active` программа сама задает effective lighting behavior:
- сначала pattern override для первых 8 зон,
- затем directional override через `GVL_STATE.G_Evac_Guidance`.

Вывод:
- evacuation semantics не делегирована manager-слою;
- она уже является direct post-manager publication logic inside `PRG_Lighting.st`.

### LOPA-13. Это не broken behavior by itself, but it makes final ownership layered
Сама идея evacuation override может быть полностью оправданной.

Но архитектурно это означает:
- final effective lighting state складывается из нескольких последовательно применяемых owner-layers.

Вывод:
- cluster risk sits in output layering clarity, not necessarily in wrong runtime intention.

## Clean paths vs smell-prone paths

### Structurally cleaner paths
- user override intake -> local arrays -> manager inputs
- blinds publication path
- socket publication path
- adapter array normalization

### Smell-prone path
- lighting effective levels publication path

Причина:
- manager initially writes `GVL_STATE.G_Lighting_Levels`,
- then `PRG_Lighting.st` mutates the same output directly again during evacuation logic.

## Practical interpretation

### LOPA-14. Main problem is not override intake
Override intake and system-level blocking выглядят уже довольно читаемо и структурно понятно.

### LOPA-15. Main problem is not sockets/blinds publication either
Слои sockets и blinds по текущему checked scope выглядят cleaner.

### LOPA-16. Main problem is final effective ownership of lighting levels
Именно `GVL_STATE.G_Lighting_Levels` сейчас является местом, где:
- manager contract,
- cross-cutting safety/system semantics,
- and direct program-level override
пересекаются наиболее явно.

Вывод:
- lighting wave, вероятнее всего, будет сводиться к вопросу:
  - acceptable layered override design это,
  - или ownership/publication smell, который уже требует focused cleanup.

## Что пока НЕ утверждается этим этапом

### LOPA-NO-01. Immediate need to move evacuation logic into manager
Не подтверждено.

### LOPA-NO-02. Immediate need to split `PRG_Lighting.st`
Тоже не подтверждено.

### LOPA-NO-03. Broken manager contracts
Не подтверждено.

Наоборот, primary contracts пока выглядят рабочими.

## Практический эффект этапа L-A2
После этого этапа lighting ownership picture уже достаточно ясна:
- input override path is relatively clean;
- blinds and sockets publication paths are relatively clean;
- effective lighting levels path is the main ownership hotspot;
- `PRG_Lighting.st` owns a real post-manager output mutation tail.

Этого достаточно, чтобы следующий шаг шел не в random scan, а в cross-layer dependency audit:
- scenario/system/safety/command interactions with final lighting output ownership.

## Следующий рекомендуемый документ
- `95_LIGHTING_CROSS_LAYER_DEPENDENCY_AUDIT.md`

Его задача:
- выполнить этап `L-A3`;
- пройти зависимости lighting с scenario/system/safety/command layers и понять, насколько final override layering justified or excessive.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения