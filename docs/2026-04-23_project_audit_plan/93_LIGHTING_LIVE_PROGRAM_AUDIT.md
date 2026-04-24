# Lighting Live Program Audit

Дата фиксации: 2026-04-23

## Назначение
Этот документ выполняет этап `L-A1` из `92_LIGHTING_AUDIT_PLAN.md`:
**live program audit** для `PRG_Lighting.st`.

Цель:
- зафиксировать текущую структуру live lighting program;
- понять, какие inputs lighting layer берет сверху и что публикует наружу;
- определить, выглядит ли `PRG_Lighting.st` как тонкий wrapper/adapter-layer или уже как ownership-heavy program.

## Проверенный объект
- `PRG_Lighting.st`

## Главный вывод этапа L-A1
В текущем live root `PRG_Lighting.st` выглядит не как совсем тонкий wrapper, но и не как откровенно перегруженный монолит.

Наиболее точное первое описание:
- **adapter-heavy orchestration program with direct evacuation override tail**.

Структура читается так:
1. intake user/system override inputs;
2. adapter-копирование в FB-sized arrays;
3. один manager-call для lighting/blinds;
4. один manager-call для sockets;
5. прямые evacuation lighting overrides поверх manager outputs.

Это уже важный ранний вывод:
- lighting program несет не только adapter-role,
- но и часть cross-cutting override logic после manager outputs.

## Структура lighting program

### LPA-01. Override intake and system gating layer
В начале `PRG_Lighting.st` есть явный intake слой для:
- `GVL_INTENT_USER.I_Lighting_Override_32`
- `GVL_INTENT_USER.I_Blinds_Override_32`
- `GVL_INTENT_USER.I_Socket_Override_32`

с system-level gating через:
- `GVL_INTENT_SYSTEM.I_Lighting_Overrides_Block`
- `GVL_INTENT_SYSTEM.I_Blinds_Overrides_Block`
- `GVL_INTENT_SYSTEM.I_Socket_Overrides_Block`

Вывод:
- lighting program already consumes cross-cutting system intent layer directly;
- override blocking responsibility partially lives here.

### LPA-02. Adapter/normalization arrays are a visible first-class layer
`PRG_Lighting.st` использует локальные arrays:
- `L_Manual_Light_Override_32`
- `L_Manual_Blinds_Override_32`
- `L_Manual_Socket_Override_32`
- `L_Sim_Lights_32`
- `L_Physical_Switches_32`
- `L_Motion_Sensors_32`
- `L_Blinds_Override`
- `L_Socket_Override`

Причем есть отдельный copy/adaptation step для:
- `L_Blinds_Override`
- `L_Socket_Override`

Вывод:
- wrapper/program already has a strong adapter character.

### LPA-03. Lighting/blinds manager call is centralized
`fbLightingManager(...)` получает:
- system context,
- scenario,
- simulation status,
- manual overrides,
- physical switches,
- motion sensors,
- is-night,
- rule actions,
- IO modules online,
- wet-zone map,
- scenario configs.

И публикует:
- `VO_Lighting_Levels => GVL_STATE.G_Lighting_Levels`
- `VO_Blinds_Positions => GVL_STATE.G_Blinds_Positions`

Вывод:
- lighting/blinds core behavior mostly delegated into manager-layer.

### LPA-04. Socket manager is orchestrated in the same program
`fbSocketManager(...)` вызывается в том же `PRG_Lighting.st` и получает:
- system context,
- scenario,
- manual socket override,
- physical socket switches,
- rule actions,
- fire/flood/security alarm context,
- IO modules online.

И публикует:
- `VO_Socket_States => GVL_STATE.G_Socket_States`

Вывод:
- `PRG_Lighting.st` already aggregates not just lighting, but also sockets as part of one broader lighting/home-comfort program layer.

### LPA-05. Direct evacuation override tail exists after manager outputs
После manager-calls `PRG_Lighting.st` сам напрямую переопределяет `GVL_STATE.G_Lighting_Levels` при:
- `GVL_STATE.G_Evacuation_Lighting_Active`

Сначала через pattern override для первых 8 зон,
а затем через directional evacuation override по:
- `GVL_STATE.G_Evac_Guidance[L_i]`

Вывод:
- final effective lighting levels can be changed after manager outputs;
- это уже не purely adapter behavior, а post-manager override/publication ownership.

## Что проходит через lighting boundary

### Входной контекст сверху
`PRG_Lighting.st` берет сверху:
- user overrides from `GVL_INTENT_USER`;
- system override blocks from `GVL_INTENT_SYSTEM`;
- simulation / physical switch / motion / scenario / night context;
- rule actions;
- IO online state;
- safety-related alarm context for sockets;
- evacuation state and guidance from `GVL_STATE`.

### Выходной контекст наружу
`PRG_Lighting.st` публикует наружу:
- `GVL_STATE.G_Lighting_Levels`
- `GVL_STATE.G_Blinds_Positions`
- `GVL_STATE.G_Socket_States`

Но часть lighting outputs затем же и переопределяет локально внутри программы during evacuation override phase.

Вывод:
- publication boundary exists,
- but final ownership of effective lighting levels is not purely manager-bounded.

## Первая интерпретация boundary/ownership

### LPA-06. `PRG_Lighting.st` не выглядит thin wrapper в стиле ventilation
В отличие от `PRG_Ventilation.st`, lighting program уже содержит:
- cross-cutting override blocking,
- array adaptation layer,
- orchestration of two managers,
- direct post-manager evacuation overrides.

Вывод:
- lighting layer heavier than a simple wrapper.

### LPA-07. Но и не видно явного broken interface smell на первом чтении
Пока не видно:
- missing required parameters,
- broken call-site mismatch,
- очевидного contract drift.

Вывод:
- early risk here is likely ownership/publication structure, not interface correctness.

### LPA-08. Главный ранний риск lighting-wave — final output ownership and override layering
Уже на первом чтении видно, что effective lighting state рождается из нескольких слоев:
- user overrides,
- system override blocking,
- manager outputs,
- evacuation override tail.

Вывод:
- lighting-wave, вероятно, будет про ownership/publication/override layering,
а не про простой wrapper vs manager mismatch.

## Что пока НЕ утверждается этим этапом
Этот документ не утверждает:
- что `PRG_Lighting.st` уже перегружен дефектно;
- что evacuation override обязательно должен быть вынесен;
- что socket orchestration inside `PRG_Lighting.st` уже является ошибкой.

Он утверждает только:
- lighting program в текущем live root heavier than thin wrapper;
- главное early question now sits around override layering and effective output ownership.

## Практический эффект этапа L-A1
После этого шага уже можно уверенно сказать:
- lighting wave, вероятно, будет разбираться через ownership/publication audit effective levels, overrides and post-manager mutations;
- risk profile lighting differs from both security/access mismatch and ventilation diagnostics cleanup;
- следующий шаг должен идти в ownership/publication audit, а не в premature refactor.

## Следующий рекомендуемый документ
- `94_LIGHTING_OWNERSHIP_AND_PUBLICATION_AUDIT.md`

Его задача:
- выполнить этап `L-A2`;
- разобрать ownership requests/overrides/effective levels/status publication и direct post-manager mutations inside lighting cluster.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения