# Safety Fix Direction Decision

Дата фиксации: 2026-04-23

## Назначение
Этот документ выполняет этап `S-A5` из `76_SAFETY_AUDIT_PLAN.md`:
**принятие remediation direction для safety subsystem wave**.

Цель:
- зафиксировать, что считать правильным следующим шагом по safety cluster;
- отделить documentation-level stabilization от реального local cleanup;
- не раздувать scope до premature system-wide redesign.

## Основание
Документ опирается на:
- `77_SAFETY_LIVE_PROGRAM_AUDIT.md`
- `78_SAFETY_OWNERSHIP_AND_PUBLICATION_AUDIT.md`
- `79_SAFETY_CROSS_SUBSYSTEM_DEPENDENCY_AUDIT.md`
- `80_SAFETY_BOUNDARY_ARCHITECTURE_INTERPRETATION.md`

## Что уже подтверждено
К текущему моменту по live root подтверждено:
- `PRG_Safety.st` является существенным cross-cutting intent producer;
- publication boundary через `GVL_INTENT_SAFETY` реальна и operationally grounded;
- `PRG_Command_Arbitration.st` реально переводит значимую часть safety intents в `GVL_COMMAND_SHADOW`;
- safety semantics распространяется несколькими формами: latched state, safety intents и system-mode integration;
- full boundary collapse или interface mismatch не подтвержден;
- главный архитектурный smell сосредоточен не в broken publication, а в producer-side ownership concentration inside `PRG_Safety.st`.

## Варианты remediation direction

### Option A. Documentation-only stop
Суть:
- признать safety wave достаточно разобранной;
- оставить producer-heavy concentration как documented architecture characteristic;
- не делать локальный cleanup сейчас.

### Option B. Local producer-side cleanup plan
Суть:
- не переписывать safety architecture широко,
- но открыть узкий cleanup-plan вокруг ownership concentration inside `PRG_Safety.st`;
- сосредоточиться на semantic/interlock/test-flow concentration, а не на publication boundary itself.

### Option C. Broad safety redesign
Суть:
- пересматривать распределение responsibilities между `PRG_System.st`, `PRG_Safety.st`, `PRG_Command_Arbitration.st` и subsystem consumers шире;
- возможно выносить части producer logic в новые blocks/layers.

## Решение
На текущем этапе принимается:

# Decision: Option B — локальный producer-side cleanup plan

## Почему выбран именно этот вариант

### SFD-01. Documentation-only stop уже недостаточен
Да, safety architecture уже лучше понята и сама publication boundary выглядит рабочей.

Но unlike harmless architectural notes, здесь уже подтвержден достаточно конкретный smell:
- один `PRG_Safety.st` концентрирует слишком много cross-system semantic ownership.

Вывод:
- просто оставить это как observation уже недостаточно.

### SFD-02. Broad redesign пока не подтвержден
При этом не подтверждено, что нужно:
- немедленно дробить `PRG_Safety.st` на несколько новых blocks,
- менять layered model safety intents,
- переписывать cross-subsystem safety flow целиком.

Вывод:
- большой redesign сейчас был бы непропорционален подтвержденным данным.

### SFD-03. Есть узкая и осмысленная точка приложения cleanup
Подтвержденная проблема локализуется достаточно хорошо:
- producer-side ownership concentration inside `PRG_Safety.st`,
а не safety architecture целиком.

Вывод:
- это хорошо подходит для focused cleanup plan.

### SFD-04. Boundary publication уже clean enough and should not be broken
Так как `GVL_INTENT_SAFETY` already works as meaningful boundary, следующий шаг должен быть не в ломке publication model, а в разгрузке или clarification ownership inside producer layer.

Вывод:
- cleanup нужно нацеливать только на smell-prone ownership subset.

## Что именно считается правильным remediation direction

### RD-S-01. Не трогать first publication boundary through `GVL_INTENT_SAFETY`
`GVL_INTENT_SAFETY` не является текущим problem-center.

Следовательно:
- safety remediation не должна начинаться с dismantling intent publication model.

### RD-S-02. Открыть cleanup-plan по producer-side ownership concentration inside `PRG_Safety.st`
Нужно отдельно разобрать и зафиксировать:
- какие semantics действительно должны оставаться внутри `PRG_Safety.st`;
- какие части выглядят как candidate for extraction/segregation/explicit sub-scope;
- где именно проходит граница между acceptable producer role и overloaded semantic ownership.

### RD-S-03. Не трогать already-confirmed healthy downstream paths
На текущем этапе не нужно менять:
- downstream consumption through `PRG_Command_Arbitration.st`;
- direct subsystem safety consumers, если нет отдельного подтвержденного defect;
- system-mode integration path без нового основания.

### RD-S-04. Не поднимать scope до full safety redesign
На текущем этапе не нужно:
- разносить всю safety semantics по новым слоям;
- перепридумывать entire cross-subsystem safety model;
- ломать current layered architecture, которая в целом уже coherent.

## Практический смысл решения
Safety wave на текущем этапе трактуется так:
- boundary acceptable,
- publication meaningful,
- architecture layered,
- but producer layer heavy enough to justify focused cleanup planning.

Это дает хороший next-step scope:
- достаточно узкий, чтобы не открыть большой redesign cycle;
- достаточно содержательный, чтобы реально улучшить architecture hygiene.

## Что пока не требуется

### NOT-S-01
Не требуется немедленный redesign `GVL_INTENT_SAFETY`.

### NOT-S-02
Не требуется immediate split of `PRG_Safety.st` into multiple POUs.

### NOT-S-03
Не требуется менять `PRG_Command_Arbitration.st` just because it consumes safety intents.

### NOT-S-04
Не требуется system-wide interlock redesign.

## Следующий рекомендуемый документ
- `82_SAFETY_PRODUCER_OWNERSHIP_CLEANUP_PLAN.md`

Его задача:
- зафиксировать минимальный cleanup scope вокруг ownership concentration inside `PRG_Safety.st`;
- определить, как двигаться к cleaner producer boundary без premature redesign.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения