# Heating Diagnostics Gating Regroup Execution Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ переводит `16_HEATING_DIAGNOSTICS_GATING_REGROUP_PLAN.md` в **исполнительный порядок изменений** для `PRG_Heating.st`.

Это уже не концептуальная схема, а последовательность безопасных шагов, по которым можно реально перестраивать файл, не меняя логику и не ломая ранее принятые ownership-решения.

## Основание
План опирается на:
- `15_HEATING_DIAGNOSTICS_GATING_BOUNDARY_DECISION.md`
- `16_HEATING_DIAGNOSTICS_GATING_REGROUP_PLAN.md`
- текущее состояние `PRG_Heating.st`

## Цель исполнения
Преобразовать текущий `PRG_Heating.st` в структурно читаемый файл с явными секциями S1-S6, сохранив:
- действующую логику,
- текущее ownership-решение по `G_Target_Temperature`,
- текущий orchestration-path heating/DHW,
- отсутствие нового helper-layer на этом шаге.

## Execution Mode
- Режим исполнения: Direct Repository Modification Mode.
- Тип проверки: repository state verification.
- Ограничение: без утверждений о runtime-успехе до отдельной compile/run проверки.

## Зафиксированные инварианты перед изменением
Во время перегруппировки нельзя менять:
- owner для `GVL_STATE.G_Target_Temperature`;
- owner coarse heating intents в `PRG_Policy`;
- интерфейсы `FB_Heating_System_Manager.st`;
- интерфейсы `FB_DHW_Manager.st`;
- call order в `MAIN.st`;
- существующую прикладную логику diagnostics/gating.

## Исполнительный порядок

### Шаг EGR-01. Вставить секционные маркеры без логических изменений
Действие:
- в `PRG_Heating.st` добавить явные комментарии/разделители для секций:
  - S1 Inputs / local arbitration context
  - S2 Heating/DHW orchestration calls
  - S3 Diagnostics projection
  - S4 Maintenance gating
  - S5 Freeze hardware support logic
  - S6 Adapter copy-out

Ожидаемый результат:
- файл получает стабильный структурный скелет.

### Шаг EGR-02. Собрать orchestration upper-flow в верхней части файла
Действие:
- убедиться, что подряд и без вкраплений diagnostics/gating стоят:
  - локальный arbitration context,
  - mode stabilization,
  - запись `G_Target_Temperature`,
  - `fbHeatingManager(...)`,
  - `fbDHWManager(...)`.

Ожидаемый результат:
- верхний main-flow читается непрерывно от входного контекста до manager calls.

### Шаг EGR-03. Вынести все `..._Out_Of_Service` публикации в отдельную секцию S3
Действие:
- собрать в одном непрерывном блоке только диагностические публикации недоступности оборудования.

В этот блок должны войти:
- `Backup_Pump_Out_Of_Service`
- `Electric_Heater_Out_Of_Service`
- `Manifold_Pump_Out_Of_Service[*]`
- `DHW_Heating_Pump_Out_Of_Service`
- `DHW_Circ_Pump_Out_Of_Service`

Ожидаемый результат:
- diagnostics projection отделен от clamp-логики.

### Шаг EGR-04. Собрать все availability-based clamps в отдельную секцию S4
Действие:
- после diagnostics projection собрать все отключения оборудования по признаку unavailable/out-of-service в единый maintenance gating блок.

В этот блок должны войти:
- `G_Backup_Circulation_Pump := FALSE` при недоступности;
- `G_Electric_Heater_Enable := FALSE` при недоступности;
- `G_Manifold_Pumps[*] := FALSE` при недоступности;
- `G_DHW_Heating_Pump := FALSE` при недоступности;
- `G_DHW_Circ_Pump := FALSE` при недоступности.

Ожидаемый результат:
- все maintenance clamps читаются как единый downstream filter.

### Шаг EGR-05. Изолировать freeze hardware degraded/failed aggregation в секцию S5
Действие:
- собрать в одной секции:
  - `G_Freeze_Hardware_Degraded`
  - `G_Freeze_Hardware_Failed`
  - shutdown/reaction при полном отказе anti-freeze hardware

Ожидаемый результат:
- freeze-support behavior перестает быть размазан между diagnostics и maintenance logic.

### Шаг EGR-06. Оставить adapter copy-out отдельным хвостом S6
Действие:
- сохранить в нижней части файла только простой adapter copy-out:
  - `L_Zone_Valves_8 -> GVL_STATE.G_Zone_Valves`

Ожидаемый результат:
- хвост файла становится технически чистым и коротким.

### Шаг EGR-07. Выполнить repository-state verification после перегруппировки
Действие:
- перепроверить `PRG_Heating.st` по состоянию репозитория.

Нужно подтвердить:
1. секции S1-S6 реально видны и идут в правильном порядке;
2. orchestration-path не перемешан с diagnostics/gating;
3. owner `G_Target_Temperature` не изменен;
4. не появился новый helper-layer;
5. интерфейсы manager blocks не менялись.

Ожидаемый результат:
- структурная перегруппировка подтверждена как repository-state change без логического redesign.

## Что считается допустимым изменением на этом шаге
Допустимо:
- переставлять блоки кода местами в пределах файла;
- вводить секционные комментарии;
- собирать однотипные куски в единые логические группы;
- делать код заметно более читаемым.

## Что запрещено на этом шаге
Запрещено:
- менять формулы, условия и branch semantics;
- переносить ownership в другие программы;
- вводить новый helper block/program;
- менять `MAIN.st`;
- менять сигнатуры manager blocks.

## Критерии успешного завершения execution plan
Этап считается успешно выполненным, если:
1. `PRG_Heating.st` явно секционирован на S1-S6;
2. diagnostics projection, maintenance gating и freeze-support logic не смешаны между собой;
3. orchestration-path занимает отдельную непрерывную верхнюю часть файла;
4. логика не была переписана, а только перегруппирована;
5. после этого можно принимать следующее решение — нужен ли физический helper-layer вообще.

## Следующий документ после исполнения
После выполнения этого плана должен появиться:
- `18_HEATING_DIAGNOSTICS_GATING_REGROUP_RESULT.md`

В нем нужно будет зафиксировать:
- какие секции реально появились в `PRG_Heating.st`;
- что именно было перегруппировано;
- какие вопросы остались для следующего architectural cleanup step.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения