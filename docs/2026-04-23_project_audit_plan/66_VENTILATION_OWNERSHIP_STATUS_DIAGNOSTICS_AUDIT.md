# Ventilation Ownership / Status / Diagnostics Audit

Дата фиксации: 2026-04-23

## Назначение
Этот документ выполняет этап `V-A4` из `62_VENTILATION_AUDIT_PLAN.md`:
**ownership audit** для ventilation requests, status publication, diagnostics и global-state side effects.

Цель:
- понять, где именно живет ownership вентиляционных requests и outputs;
- отделить contract-bounded publications от manager-side global writes;
- определить, где ventilation cluster already clean, а где начинается ownership smell.

## Основание
Документ опирается на:
- `63_VENTILATION_LIVE_WRAPPER_AUDIT.md`
- `64_VENTILATION_MANAGER_CONTRACT_AUDIT.md`
- `65_VENTILATION_WRAPPER_VS_MANAGER_BOUNDARY_AUDIT.md`
- текущее состояние `PRG_Ventilation.st`
- текущее состояние `FB_Ventilation_System_Manager.st`

## Главный вывод
Ownership вентиляционного кластера в текущем live root уже можно разделить достаточно четко:
- **requests ownership** приходит сверху и аккуратно входит в manager через wrapper;
- **main actuation/status outputs** публикуются через явный block contract;
- но **часть diagnostics/state side effects** уже живет внутри manager как direct writes в `GVL_STATE`.

Именно последняя часть является главным ownership smell текущего ventilation cluster.

## Requests ownership

### VOSD-01. Requests не рождаются внутри manager
`PRG_Ventilation.st` получает ventilation requests из `GVL_COMMAND_SHADOW`:
- `G_Vent_PV3_Boost`
- `G_Supply_100_Req`
- `G_Exhaust_100_Req`
- `G_Supply_80_Req`
- `G_Vent_Stop`

и передает их в manager как явные `VI_*_Req` inputs.

Вывод:
- ownership operational requests находится выше manager-layer;
- manager выступает конечным consumer этих requests, но не owner их публикации.

### VOSD-02. Request boundary выглядит clean
Requests проходят по цепочке:
- arbitration / command layer -> `GVL_COMMAND_SHADOW` -> wrapper local flags -> manager inputs.

Вывод:
- здесь ownership drift пока не подтверждается;
- request path выглядит значительно чище, чем legacy mixed command surfaces в других частях проекта.

## Main outputs ownership

### VOSD-03. Fan outputs публикуются через wrapper adapters
Manager возвращает:
- `VO_Supply_Fans`
- `VO_Exhaust_Fans`

Далее wrapper копирует их в:
- `GVL_STATE.G_Supply_Fans[...]`
- `GVL_STATE.G_Exhaust_Fans[...]`

через явный copy-out adapter.

Вывод:
- ownership publication fan outputs проходит через wrapper boundary и выглядит contract-bounded.

### VOSD-04. Heater power and status message возвращаются через contract outputs
Manager возвращает:
- `VO_Heater_Power`
- `VO_Status_Msg`

а wrapper публикует их в:
- `GVL_STATE.G_Vent_Heater_Power`
- `GVL_STATUS.G_Vent_Status_Msg`

Вывод:
- это тоже clean output path через declared block contract.

## Diagnostics and side effects ownership

### VOSD-05. IO fault flag пишется напрямую внутри manager
Внутри `FB_Ventilation_System_Manager.st` подтверждено:
- `GVL_STATE.G_Ventilation_IO_Fault := FALSE;`
- затем при offline modules
  `GVL_STATE.G_Ventilation_IO_Fault := TRUE;`

Вывод:
- diagnostics ownership здесь уже не проходит через wrapper или declared output;
- manager выполняет direct global-state mutation.

### VOSD-06. Subsystem degraded flag тоже пишется напрямую внутри manager
Внутри manager подтверждено:
- `GVL_STATE.G_Ventilation_Subsystem_Degraded := FALSE;`
- и при `L_Policy_Degraded`
  `GVL_STATE.G_Ventilation_Subsystem_Degraded := TRUE;`

Вывод:
- degraded-state ownership тоже находится внутри manager как direct global write.

### VOSD-07. Diagnostics policy и control policy слиты в одном owner-layer
Тот же manager одновременно:
- решает safe-stop / degraded / freeze behavior;
- управляет outputs;
- формирует status message;
- выставляет diagnostic/degraded flags в globals.

Вывод:
- diagnostics ownership не отделена от control-policy ownership;
- это и есть главный ownership concentration risk ventilation cluster.

## Status publication ownership

### VOSD-08. Human-readable status message остается contract-bounded
Хотя manager формирует `VO_Status_Msg` сам, публикация наружу происходит через declared output и wrapper boundary.

Вывод:
- message publication выглядит чище, чем diagnostics flags.

### VOSD-09. Status semantics уже сильно завязана на manager policy layer
`VO_Status_Msg` формируется внутри manager на основе:
- safe stop,
- freeze protection,
- degraded,
- nominal behavior,
- IO fault handling.

Вывод:
- текстовый status — это extension manager policy interpretation.
- Это не обязательно дефект, но усиливает концентрацию responsibilities внутри manager.

## Ownership map по типам данных

### Clean / bounded ownership paths
- command requests (`GVL_COMMAND_SHADOW` -> wrapper -> manager)
- fan outputs (`manager outputs` -> wrapper copy-out -> `GVL_STATE`)
- heater power (`manager output` -> `GVL_STATE`)
- status message (`manager output` -> `GVL_STATUS`)

### Concentrated / smell-prone ownership paths
- `GVL_STATE.G_Ventilation_IO_Fault`
- `GVL_STATE.G_Ventilation_Subsystem_Degraded`

Причина:
- эти поля не проходят через wrapper publication contract;
- они мутируются напрямую внутри manager.

## Практическая интерпретация

### VOSD-10. Главная проблема не в requests и не в normal outputs
Эти части выглядят уже достаточно clean.

### VOSD-11. Главная проблема — direct global diagnostics/state writes inside manager
Это означает:
- manager не просто рассчитывает outputs;
- он уже partially owns global ventilation diagnostics/state layer напрямую.

Это делает manager тяжелее и повышает coupling with `GVL_STATE`.

### VOSD-12. Ventilation cluster risk surface manager-centric и ownership-centric
После текущего этапа уже видно, что вентиляционный кластер, вероятнее всего, не требует heating-style wrapper cleanup first.

Если remediation понадобится, она скорее будет сосредоточена вокруг:
- manager-side ownership concentration,
- direct diagnostics writes,
- policy/control/status coupling.

## Что пока НЕ утверждается этим этапом

### VOSD-NO-01. Immediate need to refactor manager now
Не подтверждено.

### VOSD-NO-02. Need to move all diagnostics out of manager immediately
Тоже не подтверждено.

### VOSD-NO-03. Broken output contract
Не подтверждено.

Наоборот, основной output contract выглядит достаточно clean.

## Практический итог этапа V-A4
На текущем этапе ventilation ownership picture уже достаточно ясна для решения следующего шага:
- requests path clean;
- main outputs path clean;
- diagnostics/degraded global-state writes are the main smell;
- manager remains the main concentration point.

Этого достаточно, чтобы принимать remediation direction без дополнительных broad scans.

## Следующий рекомендуемый документ
- `67_VENTILATION_FIX_DIRECTION_DECISION.md`

Его задача:
- выполнить этап `V-A5`;
- решить, ограничиваемся ли documentation/structure фиксацией, или ventilation cluster уже требует локального manager-side cleanup plan.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения