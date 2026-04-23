# Ventilation Wrapper vs Manager Boundary Audit

Дата фиксации: 2026-04-23

## Назначение
Этот документ выполняет этап `V-A3` из `62_VENTILATION_AUDIT_PLAN.md`:
**boundary audit** между `PRG_Ventilation.st` и `FB_Ventilation_System_Manager.st`.

Цель:
- сравнить responsibilities wrapper и manager;
- понять, где проходит фактическая boundary вентиляционного кластера;
- определить, есть ли boundary drift, mixed ownership или явный architecture smell.

## Основание
Документ опирается на:
- `63_VENTILATION_LIVE_WRAPPER_AUDIT.md`
- `64_VENTILATION_MANAGER_CONTRACT_AUDIT.md`
- текущее состояние `PRG_Ventilation.st`
- текущее состояние `FB_Ventilation_System_Manager.st`

## Главный вывод
На текущем live root boundary между `PRG_Ventilation.st` и `FB_Ventilation_System_Manager.st` в целом **читается и является рабочей**, но асимметрия responsibilities уже заметна:
- wrapper остается тонким adapter/orchestration layer;
- manager несет не только core ventilation control, но и policy, fault reaction, status interpretation и часть global-state side effects.

То есть полного boundary collapse не видно.

Но видно другое:
- **manager является существенно более широким responsibility-center, чем просто domain executor**.

Это не обязательно баг прямо сейчас, но это основной архитектурный риск вентиляционного кластера на следующем уровне детализации.

## Что делает wrapper

### VBA-01. Нормализация входов и локальные adapters
`PRG_Ventilation.st` выполняет:
- wet-zone adapter;
- копирование command requests из `GVL_COMMAND_SHADOW` в локальные флаги;
- буферизацию byte outputs для fans.

Вывод:
- wrapper действительно ведет себя как boundary adapter.

### VBA-02. Централизованный manager call
Wrapper делает один основной вызов `fbVentilationManager(...)`, собирая:
- system context,
- telemetry,
- config,
- safety signals,
- command requests,
- wet-zone activity,
- rule actions.

Вывод:
- orchestration точка у wrapper одна и она явная.

### VBA-03. Copy-out публикация наружу
После manager-call wrapper:
- копирует fan outputs обратно в `GVL_STATE`;
- напрямую принимает от manager `VO_Heater_Power` и `VO_Status_Msg` в глобальные слои.

Вывод:
- wrapper отвечает за boundary publication, но не за сложную доменную интерпретацию.

## Что делает manager

### VBA-04. Policy routing по system mode
Manager:
- интерпретирует `VI_System_Mode`;
- реализует `SAFE_STOP`, `DEGRADED`, `FREEZE_PROTECTION` behaviors;
- делает early returns и final clamps.

Вывод:
- system-policy слой уже находится внутри manager.

### VBA-05. Fault reaction по IO modules
Manager:
- проверяет `VI_IO_Modules_Online`;
- выставляет `GVL_STATE.G_Ventilation_IO_Fault`;
- переводит outputs в safe state;
- публикует error status.

Вывод:
- manager несет не только domain control, но и fault handling с global side effects.

### VBA-06. Scenario / control / status interpretation
Manager:
- выбирает base speed и target temp по scenario;
- управляет heaters через PID;
- строит wet-zone exhaust behavior;
- применяет rule-action overrides;
- формирует `VO_Status_Msg`.

Вывод:
- manager является главным смысловым owner ventilation behavior.

## Где boundary выглядит здоровой

### VBA-07. Wrapper и manager не дублируют одну и ту же orchestration logic
Wrapper не пытается повторно решать:
- scenario logic,
- policy routing,
- PID control,
- wet-zone timing.

Manager не занимается:
- raw reading из глобальных структур напрямую для большинства входов;
- внешним assembling command requests из разных глобальных слоев;
- post-call fan copy-out adapters.

Вывод:
- прямого дублирования responsibilities пока не видно.

### VBA-08. Командный intake расположен в wrapper, а не внутри manager
Wrapper уже получает ventilation requests из `GVL_COMMAND_SHADOW` и передает их в manager как явные `VI_*_Req`.

Вывод:
- это хороший признак boundary hygiene:
- manager не привязан напрямую к command-layer globals.

## Где boundary уже выглядит напряженной

### VBA-09. Manager пишет в global state напрямую
Внутри `FB_Ventilation_System_Manager.st` подтверждено:
- `GVL_STATE.G_Ventilation_IO_Fault := ...`
- `GVL_STATE.G_Ventilation_Subsystem_Degraded := ...`

Вывод:
- manager уже не purely contract-bounded block;
- он имеет global-state side effects beyond declared outputs.

Это важный boundary smell.

### VBA-10. Policy and diagnostics сконцентрированы в manager вместе с control logic
В одном блоке сосредоточены:
- safe-stop/degraded/freeze policy;
- IO fault reaction;
- scenario interpretation;
- actuator outputs;
- status publication.

Вывод:
- manager становится доменным super-block;
- boundary между control core и diagnostics/policy interpretation здесь уже не очень тонкая.

### VBA-11. Wrapper почти не несет ownership balancing layer
В отличие от позднего очищенного heating wrapper, здесь wrapper практически не делает:
- diagnostics projection,
- availability gating,
- explicit ownership stabilization above manager.

Вывод:
- вся ownership gravity смещена вниз, внутрь manager.

## Интерпретация boundary

### Boundary diagnosis
Текущая вентиляционная boundary лучше всего описывается так:
- **wrapper is clean but thin**;
- **manager is coherent but heavy**.

Это важно:
- проблема не в том, что wrapper перегружен;
- и не в том, что interface call-site явно broken;
- проблема потенциально в том, что too much policy/fault/status ownership already lives inside manager.

## Что пока НЕ подтверждено как defect

### VBA-NO-01. Full boundary mismatch
Не подтвержден.

### VBA-NO-02. Immediate need to split manager now
Тоже не подтвержден.

### VBA-NO-03. Need for wrapper-heavy cleanup like heating had
Не подтвержден.

Наоборот, wrapper пока выглядит аккуратным.

## Практический вывод
На текущем этапе ventilation risk surface выглядит иначе, чем в heating:
- heating risk был заметен в wrapper ownership/structure;
- ventilation risk больше сосредоточен в **manager-side concentration of policy + fault + control responsibilities**.

Следовательно, следующий этап должен идти не в wrapper refactor, а в ownership audit по:
- requests,
- status/diagnostics,
- global-state writes,
- manager-side policy concentration.

## Следующий рекомендуемый документ
- `66_VENTILATION_OWNERSHIP_STATUS_DIAGNOSTICS_AUDIT.md`

Его задача:
- выполнить этап `V-A4`;
- разобрать ownership вентиляционных requests, status publication, diagnostics и global-state side effects.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения