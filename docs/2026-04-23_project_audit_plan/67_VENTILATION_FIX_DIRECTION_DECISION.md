# Ventilation Fix Direction Decision

Дата фиксации: 2026-04-23

## Назначение
Этот документ выполняет этап `V-A5` из `62_VENTILATION_AUDIT_PLAN.md`:
**принятие remediation direction для ventilation subsystem wave**.

Цель:
- зафиксировать, что считать правильным следующим шагом по вентиляционному кластеру;
- отделить documentation-only stabilization от реального local cleanup;
- не раздувать scope до premature redesign.

## Основание
Документ опирается на:
- `63_VENTILATION_LIVE_WRAPPER_AUDIT.md`
- `64_VENTILATION_MANAGER_CONTRACT_AUDIT.md`
- `65_VENTILATION_WRAPPER_VS_MANAGER_BOUNDARY_AUDIT.md`
- `66_VENTILATION_OWNERSHIP_STATUS_DIAGNOSTICS_AUDIT.md`

## Что уже подтверждено
К текущему моменту по live root подтверждено:
- `PRG_Ventilation.st` выглядит как тонкий и в целом аккуратный wrapper;
- `FB_Ventilation_System_Manager.st` является главным центром ventilation control/policy logic;
- requests path через `GVL_COMMAND_SHADOW` -> wrapper -> manager выглядит clean;
- main outputs path через declared outputs manager -> wrapper -> `GVL_STATE` / `GVL_STATUS` выглядит clean;
- главный ownership smell сосредоточен в manager-side direct writes:
  - `GVL_STATE.G_Ventilation_IO_Fault`
  - `GVL_STATE.G_Ventilation_Subsystem_Degraded`
- полный boundary collapse или interface mismatch не подтвержден.

## Варианты remediation direction

### Option A. Documentation-only stop
Суть:
- признать ventilation wave достаточно разобранной;
- оставить manager-side ownership concentration как documented smell;
- не делать локальный cleanup сейчас.

### Option B. Local manager-side cleanup plan
Суть:
- не переписывать ventilation cluster широко,
- но открыть узкий cleanup-plan вокруг manager-side diagnostics/global-state ownership;
- сосредоточиться на direct global writes и на boundary между manager outputs и diagnostics/state publication.

### Option C. Broader ventilation redesign
Суть:
- пересматривать распределение responsibility между wrapper и manager глубже,
- возможно декомпозировать manager,
- выносить policy/diagnostics/control layers в отдельные части.

## Решение
На текущем этапе принимается:

# Decision: Option B — локальный manager-side cleanup plan

## Почему выбран именно этот вариант

### VFD-01. Documentation-only stop уже недостаточен
Да, основная картина вентиляции уже понятна.

Но unlike narrow tails прошлых waves, здесь подтвержден конкретный ownership smell в active live code:
- direct diagnostics/state writes inside manager.

Вывод:
- просто остановиться на документации уже недостаточно.

### VFD-02. Broader redesign пока не подтвержден
При этом не подтверждено, что нужно:
- сразу дробить manager,
- переносить policy layer наружу,
- делать heating-style restructure wave.

Вывод:
- большой redesign сейчас был бы непропорционален подтвержденным данным.

### VFD-03. Есть узкая и осмысленная точка приложения cleanup
Подтвержденная проблема локализуется достаточно хорошо:
- manager-side diagnostics/global-state ownership,
а не весь ventilation cluster целиком.

Вывод:
- это идеально подходит для next-step local cleanup plan.

### VFD-04. Requests/output paths уже достаточно clean
Поскольку requests path и main outputs path уже выглядят здоровыми, нет смысла трогать их без необходимости.

Вывод:
- cleanup нужно нацеливать только на smell-prone subset, а не на весь manager contract.

## Что именно считается правильным remediation direction

### RD-V-01. Не трогать wrapper first
`PRG_Ventilation.st` не является текущим problem-center.

Следовательно:
- ventilation remediation не должна начинаться с wrapper refactor.

### RD-V-02. Открыть cleanup-plan по manager-side diagnostics/global-state writes
Нужно отдельно разобрать и зафиксировать:
- should `GVL_STATE.G_Ventilation_IO_Fault` и `GVL_STATE.G_Ventilation_Subsystem_Degraded` оставаться direct writes inside manager,
- или их publication должна идти через более явный boundary/output path.

### RD-V-03. Не трогать чистые paths без подтвержденной причины
Не нужно сейчас менять:
- requests ingestion path,
- fan/heater output path,
- status message output path,
если новый анализ не подтвердит дополнительный defect.

### RD-V-04. Не поднимать scope до full redesign
На текущем этапе не нужно:
- дробить manager на несколько новых blocks,
- переносить scenario/control/policy логику wholesale,
- делать broad ventilation architecture rewrite.

## Практический смысл решения
Ventilation wave на текущем этапе трактуется так:
- wrapper acceptable,
- manager heavy but still coherent,
- cleanup нужен точечно around diagnostics/global-state ownership.

Это дает хороший next-step scope:
- достаточный, чтобы реально улучшить architecture hygiene,
- но не настолько широкий, чтобы снова открыть большой redesign cycle.

## Что пока не требуется

### NOT-V-01
Не требуется немедленный wrapper cleanup.

### NOT-V-02
Не требуется immediate manager decomposition.

### NOT-V-03
Не требуется менять command-shadow intake path.

### NOT-V-04
Не требуется менять normal output publications.

## Следующий рекомендуемый документ
- `68_VENTILATION_MANAGER_DIAGNOSTICS_CLEANUP_PLAN.md`

Его задача:
- зафиксировать минимальный cleanup scope вокруг `G_Ventilation_IO_Fault` и `G_Ventilation_Subsystem_Degraded`;
- определить, как двигаться к cleaner ownership boundary без premature redesign.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения