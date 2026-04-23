# Ventilation Interim Status

Дата фиксации: 2026-04-23

## Назначение
Этот документ фиксирует промежуточное состояние ventilation wave после текущего цикла аудита и локального cleanup.

Цель:
- кратко свести completed / clarified / unresolved части вентиляционного кластера;
- зафиксировать, что уже реально изменено в репозитории;
- обозначить безопасную точку остановки перед переходом к следующему major scope.

## Общий статус wave
На текущем этапе ventilation wave можно считать:
- архитектурно хорошо вскрытой;
- boundary-wise проясненной;
- локально очищенной по diagnostics ownership;
- временно стабилизированной без раздувания в broad redesign.

Это еще не full ventilation redesign cycle.

Но это уже и не subsystem с неясной ownership картиной.

## Что уже подтверждено и зафиксировано

### VIS-01. `PRG_Ventilation.st` является тонким и в целом аккуратным wrapper
Подтверждено, что wrapper:
- делает wet-zone adapter;
- принимает requests из `GVL_COMMAND_SHADOW`;
- вызывает один `fbVentilationManager(...)`;
- делает copy-out fan outputs обратно в `GVL_STATE`.

Вывод:
- wrapper не является текущим problem-center вентиляционного кластера.

### VIS-02. `FB_Ventilation_System_Manager.st` является главным центром ventilation logic
Подтверждено, что manager несет:
- system-policy gating;
- active/standby gating;
- IO fault handling;
- scenario-based baseline behavior;
- heater PID control;
- wet-zone exhaust behavior;
- rule-action overrides;
- status publication.

Вывод:
- основная complexity/risk surface вентиляции сосредоточена именно в manager.

### VIS-03. Boundary wrapper vs manager в целом рабочая
Подтверждено, что:
- wrapper clean but thin;
- manager coherent but heavy;
- full boundary collapse или interface mismatch не подтвержден.

Вывод:
- вентиляционная проблема не heating-style wrapper-centric, а manager-centric.

### VIS-04. Requests path и normal outputs path выглядят clean
Подтверждено, что clean paths включают:
- request ingestion path через `GVL_COMMAND_SHADOW` -> wrapper -> manager;
- fan outputs path;
- heater power path;
- status message path.

Вывод:
- эти части не требовали текущего code cleanup.

### VIS-05. Главный ownership smell был локализован в diagnostics/global-state writes
Подтверждено, что direct writes внутри manager затрагивали:
- `GVL_STATE.G_Ventilation_IO_Fault`
- `GVL_STATE.G_Ventilation_Subsystem_Degraded`

Вывод:
- ventilation remediation удалось сузить до точечного diagnostics ownership scope.

## Что реально изменено в репозитории кодом

### CODE-VIS-01. Local diagnostics ownership cleanup
Изменены:
- `FB_Ventilation_System_Manager.st`
- `PRG_Ventilation.st`

Что сделано:
- в manager добавлены explicit outputs:
  - `VO_Ventilation_IO_Fault`
  - `VO_Ventilation_Subsystem_Degraded`
- direct writes этих двух флагов в `GVL_STATE` из manager убраны;
- wrapper `PRG_Ventilation.st` теперь публикует эти flags в `GVL_STATE` через явный output binding.

Вывод:
- подтвержденный local ownership smell закрыт по состоянию репозитория.

## Что оставлено намеренно без изменений

### HOLD-VIS-01
Не менялся request ingestion path из `GVL_COMMAND_SHADOW`.

### HOLD-VIS-02
Не менялся fan outputs path.

### HOLD-VIS-03
Не менялся heater power output path.

### HOLD-VIS-04
Не менялась semantics `VO_Status_Msg`.

### HOLD-VIS-05
Не выполнялись wrapper refactor и manager decomposition.

### HOLD-VIS-06
Не поднимался вопрос о broad ventilation redesign.

## Что остается осознанно незакрытым

### UNR-VIS-01. Compile/run подтверждение
В текущем цикле его нет.

### UNR-VIS-02. Broader manager decomposition question
На текущем этапе не подтверждена необходимость декомпозиции manager, но вопрос как future architecture topic остается открытым.

### UNR-VIS-03. Возможный later polish по policy/control/status concentration
Хотя diagnostics ownership cleanup уже выполнен, внутри manager по-прежнему сосредоточено много policy/control logic. Пока это зафиксировано как acceptable documented concentration, а не как immediate defect.

## Практическая оценка зрелости wave
На текущем этапе ventilation wave можно оценить как:
- примерно **85–90% завершенности** в рамках текущего audit/remediation цикла.

Это означает:
- core ownership ambiguity снята;
- boundary понята;
- подтвержденный local smell исправлен;
- remaining uncertainty уже не находится в critical path текущей subsystem wave.

## Что это означает для общего проекта
После фиксации этого interim status ventilation scope больше не выглядит следующим scope первого риска.

Его можно оставить в текущем documented state и переходить к следующему крупному направлению проекта.

## Рекомендуемый следующий документ
- `75_NEXT_MAJOR_SCOPE_AFTER_VENTILATION.md`

Его задача:
- зафиксировать, куда проект идет после heating + command-layer + security/access + ventilation waves;
- выбрать следующий major scope проекта.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения