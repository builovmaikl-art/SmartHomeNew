# Heating Diagnostics Gating Cleanup Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ фиксирует следующий ownership-cleanup кластер после решения по `G_Target_Temperature`:
**разделение diagnostics / maintenance gating и основного orchestration внутри `PRG_Heating`.**

## Основание
План опирается на:
- `11_HEATING_POST_RECOVERY_OWNERSHIP_AUDIT.md`
- `12_HEATING_OWNERSHIP_CLEANUP_PLAN.md`
- `13_HEATING_TARGET_OWNERSHIP_DECISION.md`

## Цель этапа
Сократить архитектурный шум внутри `PRG_Heating` без разрушения его роли как orchestration-wrapper.

Итоговое желаемое состояние:
- `PRG_Heating` остается читаемым wrapper-слоем для heating/DHW orchestration;
- diagnostics publication и maintenance gating перестают быть неструктурированным смешанным хвостом внутри wrapper;
- protective clamping и out-of-service логика становятся более локализованными и предсказуемыми.

## Что именно сейчас образует diagnostics/gating cluster
На текущем этапе внутри `PRG_Heating` смешаны:

### DG-01. Out-of-service публикации в `GVL_STATUS.G_Diagnostics`
Сюда входят:
- `Backup_Pump_Out_Of_Service`
- `Electric_Heater_Out_Of_Service`
- `Manifold_Pump_Out_Of_Service[*]`
- `DHW_Heating_Pump_Out_Of_Service`
- `DHW_Circ_Pump_Out_Of_Service`

### DG-02. Protective clamping в `GVL_STATE`
Сюда входят прямые защитные коррекции:
- отключение backup circulation pump,
- отключение electric heater,
- отключение manifold pumps,
- отключение DHW pumps при out-of-service.

### DG-03. Freeze hardware degraded/failed aggregation
Сюда входят:
- `GVL_STATE.G_Freeze_Hardware_Degraded`
- `GVL_STATE.G_Freeze_Hardware_Failed`
- связанные защитные действия при полном отказе anti-freeze hardware.

## Главный вывод
Текущий diagnostics/gating cluster не является сломанным, но он **слишком плотно встроен в `PRG_Heating`**.

Проблема не в самих действиях, а в том, что в одном участке кода смешаны:
- публикация диагностики,
- maintenance availability,
- protective output clamping,
- anti-freeze failover behavior.

Это увеличивает размер wrapper и ухудшает читаемость ownership.

## Cleanup-принцип
На этом этапе не нужно убирать из `PRG_Heating` всё подряд.

Нужно разделить:
1. что является допустимой orchestration-ответственностью wrapper;
2. что лучше оформлять как отдельный diagnostics/gating support-layer.

## Что можно оставить в `PRG_Heating`

### DG-KEEP-01. Вызовы `FB_Heating_System_Manager` и `FB_DHW_Manager`
Это ядро orchestration и должно оставаться в wrapper.

### DG-KEEP-02. Минимальные защитные реакции, завязанные на прямой локальный результат wrapper
Например:
- передача safety context вниз,
- локальная маршрутизация команд в heating/DHW cluster.

### DG-KEEP-03. Adapter copy-out, если он остается простым и прозрачным
Например:
- `L_Zone_Valves_8 -> GVL_STATE.G_Zone_Valves`

## Что является кандидатом на вынос или локализацию

### DG-MOVE-01. Out-of-service publication layer
Рекомендуемое решение:
- вынести формирование `..._Out_Of_Service` в отдельный supporting-layer или helper block,
- чтобы `PRG_Heating` не был прямым owner каждого диагностического флага вручную.

Причина:
- это больше похоже на diagnostics projection, чем на heating orchestration.

Приоритет: HIGH.

### DG-MOVE-02. Protective clamping по availability
Рекомендуемое решение:
- отделить availability-based clamping от основного orchestration flow;
- сгруппировать эти правила в отдельный maintenance-gating слой.

Причина:
- это упрощает reasoning: сначала orchestration вырабатывает команду, затем отдельный gating-слой решает, что из неё вообще допустимо пропустить дальше.

Приоритет: HIGH.

### DG-MOVE-03. Freeze hardware degraded/failed aggregation
Рекомендуемое решение:
- собрать degraded/failed aggregation в отдельную компактную секцию или отдельный helper-layer;
- не смешивать её с остальными diagnostics publications и ручными pump clamps.

Причина:
- эта логика относится к anti-freeze support behavior, а не к базовой маршрутизации heating wrapper.

Приоритет: MEDIUM-HIGH.

## Какой целевой shape нужен после cleanup
Рекомендуемая структура по смыслу:

### Секция 1. Heating/DHW orchestration
- входные чтения,
- arbitration,
- вызовы manager blocks,
- adapter copy-out.

### Секция 2. Diagnostics projection
- вычисление и публикация `Out_Of_Service` статусов.

### Секция 3. Maintenance gating
- clamp логика, запрещающая недоступному оборудованию оставаться включенным.

### Секция 4. Freeze hardware support logic
- aggregated degraded/failed status,
- связанные protective reactions.

Даже если всё это еще будет оставаться в одном файле, смысловые границы должны стать явными.

## Что НЕ делать на этом этапе

### DG-NO-01
Не менять ownership для `G_Target_Temperature` — это уже решено в `13_HEATING_TARGET_OWNERSHIP_DECISION.md`.

### DG-NO-02
Не выносить DHW из wrapper автоматически.

### DG-NO-03
Не переписывать `FB_Heating_System_Manager` и `FB_DHW_Manager` без отдельного интерфейсного основания.

### DG-NO-04
Не смешивать diagnostics cleanup с functional retuning отопления, DHW и anti-freeze алгоритмов.

## Практический порядок cleanup

### Этап DG-C1
Отделить список diagnostics publications от списка protective clamps.

Результат:
- явная карта «публикация статуса» vs «силовое ограничение команды».

### Этап DG-C2
Собрать availability-based clamps в единый компактный maintenance-gating блок.

Результат:
- сокращение разрозненных отключений оборудования по файлу.

### Этап DG-C3
Собрать freeze hardware degraded/failed aggregation в отдельную логическую группу.

Результат:
- anti-freeze support logic перестает растворяться среди остальных публикаций.

### Этап DG-C4
После логической группировки решить, нужен ли отдельный helper block / support program layer.

Результат:
- решение о физическом выносе логики принимается уже на основе понятной структуры, а не наугад.

## Следующий рекомендуемый документ
- `15_HEATING_DIAGNOSTICS_GATING_BOUNDARY_DECISION.md`

Его задача:
- решить, ограничиваемся ли логической перегруппировкой в одном `PRG_Heating.st`,
- или diagnostics/maintenance gating уже пора выносить в отдельный helper-layer.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения