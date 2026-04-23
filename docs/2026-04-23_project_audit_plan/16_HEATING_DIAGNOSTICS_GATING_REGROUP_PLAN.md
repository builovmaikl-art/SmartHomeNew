# Heating Diagnostics Gating Regroup Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ фиксирует **конкретный план внутренней перегруппировки** diagnostics / maintenance gating cluster внутри текущего `PRG_Heating.st`.

Это уже не boundary-решение, а практическая схема будущего упорядочивания файла без введения нового helper-layer на данном шаге.

## Основание
План опирается на:
- `14_HEATING_DIAGNOSTICS_GATING_CLEANUP_PLAN.md`
- `15_HEATING_DIAGNOSTICS_GATING_BOUNDARY_DECISION.md`
- текущее состояние `PRG_Heating.st`

## Цель перегруппировки
Сделать `PRG_Heating.st` структурно читаемым по внутренним секциям так, чтобы:
- orchestration-path был отделен от diagnostics/gating хвоста;
- diagnostics projection, maintenance gating и freeze-support logic не смешивались между собой;
- следующий шаг по возможному физическому выносу можно было принимать уже на чистой структуре.

## Целевая внутренняя структура `PRG_Heating.st`
После перегруппировки файл должен читаться в следующем порядке:

### Секция S1. Inputs / local arbitration context
Сюда входят:
- локальные переменные и таймеры;
- чтение `AI_Boiler_Modulation`;
- вычисление `L_Heating_Emergency_Stop`, `L_Heating_Gas_Safety_Stop`, `L_Heating_DHW_Demand`;
- consolidated heating arbitration/stabilization;
- запись `GVL_STATE.G_Target_Temperature`.

Назначение:
- собрать весь верхний локальный decision-context в одном месте.

### Секция S2. Heating/DHW orchestration calls
Сюда входят:
- вызов `fbHeatingManager(...)`;
- вызов `fbDHWManager(...)`.

Назначение:
- сделать manager orchestration центральным и непрерывным ядром файла.

### Секция S3. Diagnostics projection
Сюда входят только публикации статусов `..._Out_Of_Service` в `GVL_STATUS.G_Diagnostics`.

Конкретно:
- `Backup_Pump_Out_Of_Service`
- `Electric_Heater_Out_Of_Service`
- `Manifold_Pump_Out_Of_Service[*]`
- `DHW_Heating_Pump_Out_Of_Service`
- `DHW_Circ_Pump_Out_Of_Service`

Назначение:
- отделить «описание недоступности оборудования» от силовых ограничений.

### Секция S4. Maintenance gating
Сюда входят только availability-based clamps, которые физически запрещают недоступному оборудованию оставаться включенным.

Конкретно:
- отключение `G_Backup_Circulation_Pump` при out-of-service;
- отключение `G_Electric_Heater_Enable` при out-of-service;
- отключение `G_Manifold_Pumps[*]` при out-of-service;
- отключение `G_DHW_Heating_Pump` при out-of-service;
- отключение `G_DHW_Circ_Pump` при out-of-service.

Назначение:
- сделать единым и очевидным слой maintenance-based clamps.

### Секция S5. Freeze hardware support logic
Сюда входят:
- `G_Freeze_Hardware_Degraded`
- `G_Freeze_Hardware_Failed`
- связанные protective reactions при полном отказе anti-freeze hardware.

Назначение:
- изолировать anti-freeze degradation/failure behavior от общего diagnostics/gating массива.

### Секция S6. Adapter copy-out
Сюда входит:
- `L_Zone_Valves_8 -> GVL_STATE.G_Zone_Valves`

Назначение:
- оставить внизу чистый adapter tail без смешения с диагностикой.

## Карта текущих фрагментов -> будущих секций

### RG-01
Текущий блок:
- вычисление `L_Heating_Emergency_Stop`, `L_Heating_Gas_Safety_Stop`, `L_Heating_DHW_Demand`
- mode hold timer
- `L_Last_Mode`
- `G_Target_Temperature`

Должен попасть в:
- **S1. Inputs / local arbitration context**

### RG-02
Текущий блок:
- `fbHeatingManager(...)`
- `fbDHWManager(...)`

Должен попасть в:
- **S2. Heating/DHW orchestration calls**

### RG-03
Текущий блок:
- все записи `..._Out_Of_Service` в `GVL_STATUS.G_Diagnostics`

Должен попасть в:
- **S3. Diagnostics projection**

### RG-04
Текущий блок:
- все `IF NOT ..._In_Service THEN ... := FALSE;`
- все отключения насосов/нагревателя по недоступности

Должен попасть в:
- **S4. Maintenance gating**

### RG-05
Текущий блок:
- `G_Freeze_Hardware_Degraded`
- `G_Freeze_Hardware_Failed`
- отключения и freeze-risk reaction при полном отказе hardware

Должен попасть в:
- **S5. Freeze hardware support logic**

### RG-06
Текущий блок:
- copy-out `L_Zone_Valves_8 -> GVL_STATE.G_Zone_Valves`

Должен попасть в:
- **S6. Adapter copy-out**

## Безопасный порядок перегруппировки

### Шаг RGP-1
Сначала добавить четкие секционные комментарии в `PRG_Heating.st` без изменения логики.

Результат:
- файл получает явный скелет будущих смысловых блоков.

### Шаг RGP-2
Затем собрать подряд обе orchestration-секции:
- S1
- S2

Результат:
- верхняя часть файла становится непрерывным main-flow.

### Шаг RGP-3
После этого собрать отдельно весь diagnostics projection в S3.

Результат:
- публикации `Out_Of_Service` больше не размазаны между clamps.

### Шаг RGP-4
Затем собрать все availability-based clamps в S4.

Результат:
- maintenance gating становится единым блоком, читаемым как фильтр команд.

### Шаг RGP-5
Потом изолировать freeze hardware degraded/failed logic в S5.

Результат:
- anti-freeze support behavior становится отдельной видимой подсистемной секцией.

### Шаг RGP-6
Оставить adapter copy-out внизу файла как S6.

Результат:
- хвост файла перестает быть смешанным техническим остатком.

## Что нельзя менять во время перегруппировки

### RGP-NO-01
Нельзя менять смысл логики при чистой перегруппировке.

### RGP-NO-02
Нельзя менять owner для `G_Target_Temperature`.

### RGP-NO-03
Нельзя вводить новый helper-layer на этом шаге.

### RGP-NO-04
Нельзя менять интерфейсы `FB_Heating_System_Manager` и `FB_DHW_Manager`.

### RGP-NO-05
Нельзя перестраивать `MAIN.st`.

## Критерий успеха regroup-этапа
Этап считается успешным, если:
1. `PRG_Heating.st` становится явно разбит на секции S1-S6;
2. orchestration-path читается отдельно от diagnostics/gating;
3. diagnostics projection и maintenance gating не смешаны между собой;
4. freeze-support logic отделен в самостоятельную секцию;
5. после перегруппировки можно осмысленно решить, нужен ли отдельный helper-layer.

## Следующий рекомендуемый документ
- `17_HEATING_DIAGNOSTICS_GATING_REGROUP_EXECUTION_PLAN.md`

Его задача:
- перевести эту структуру в конкретный исполнительный план изменения `PRG_Heating.st`.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения