# Heating Diagnostics Gating Regroup Result

Дата фиксации: 2026-04-23

## Что было сделано
В `PRG_Heating.st` выполнена внутренняя структурная перегруппировка diagnostics / maintenance gating cluster без изменения логики и без введения нового helper-layer.

## Подтвержденные результаты по состоянию репозитория

### RR-GR-01. В файле появились явные секции S1-S6
Текущий `PRG_Heating.st` теперь структурно разделен на:
- `S1. Inputs / local arbitration context`
- `S2. Heating / DHW orchestration calls`
- `S3. Diagnostics projection`
- `S4. Maintenance gating`
- `S5. Freeze hardware support logic`
- `S6. Adapter copy-out`

### RR-GR-02. Верхний orchestration-path стал непрерывным
В верхней части файла теперь подряд расположены:
- локальный arbitration/stabilization context,
- запись `GVL_STATE.G_Target_Temperature`,
- вызов `fbHeatingManager(...)`,
- вызов `fbDHWManager(...)`.

Вывод:
- main-flow heating wrapper читается отдельно от diagnostics/gating хвоста.

### RR-GR-03. Diagnostics projection отделен от maintenance gating
Публикации `..._Out_Of_Service` теперь собраны отдельно и не смешаны напрямую с отключениями оборудования.

Вывод:
- слой описания недоступности оборудования стал видимым отдельно от слоя защитных clamp-действий.

### RR-GR-04. Availability-based clamps собраны в единый maintenance block
Отключения оборудования по `..._In_Service = FALSE` теперь расположены в одной отдельной секции.

Вывод:
- maintenance gating теперь читается как единый downstream filter, а не как разрозненные хвосты по файлу.

### RR-GR-05. Freeze support logic изолирован в собственной секции
Агрегация:
- `G_Freeze_Hardware_Degraded`
- `G_Freeze_Hardware_Failed`

и protective reaction при полном отказе anti-freeze hardware теперь выделены отдельно.

Вывод:
- anti-freeze support logic больше не растворяется среди diagnostics publications и обычных maintenance clamps.

### RR-GR-06. Ownership-решения не изменены
Во время перегруппировки сохранено:
- owner для `GVL_STATE.G_Target_Temperature` остается в `PRG_Heating`;
- coarse heating intents остаются за `PRG_Policy`;
- интерфейсы `FB_Heating_System_Manager` и `FB_DHW_Manager` не менялись;
- call order в `MAIN.st` не менялся;
- новый helper-layer не вводился.

## Что НЕ утверждается после regroup

### NR-GR-01
Не утверждается runtime-успех без отдельной compile/run проверки.

### NR-GR-02
Не утверждается, что diagnostics/gating cluster уже окончательно очищен архитектурно.

### NR-GR-03
Не утверждается, что helper-layer больше никогда не понадобится.

## Главный практический эффект этапа
После перегруппировки `PRG_Heating.st` стал заметно лучше подготовлен к следующему архитектурному решению:
- теперь уже можно осмысленно решать, нужен ли отдельный helper-layer,
- потому что внутренняя граница между orchestration, diagnostics, maintenance gating и freeze-support стала видимой.

## Следующий рекомендуемый документ
- `19_HEATING_HELPER_LAYER_NEED_DECISION.md`

Его задача:
- решить, достаточно ли текущей внутренней секционной перегруппировки,
- или diagnostics/gating cluster уже действительно стоит выносить в отдельный helper-layer.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения