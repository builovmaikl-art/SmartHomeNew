# Ventilation Live Wrapper Audit

Дата фиксации: 2026-04-23

## Назначение
Этот документ выполняет этап `V-A1` из `62_VENTILATION_AUDIT_PLAN.md`:
**live wrapper audit** для `PRG_Ventilation.st`.

Цель:
- зафиксировать текущую структуру live ventilation wrapper;
- понять, какие inputs wrapper берет сверху и что публикует вниз/наружу;
- определить, выглядит ли `PRG_Ventilation` как тонкий orchestration-layer или уже несет заметный ownership/logic хвост.

## Проверенный объект
- `PRG_Ventilation.st`

## Главный вывод этапа V-A1
В текущем live root `PRG_Ventilation.st` выглядит как **относительно тонкий wrapper вокруг `FB_Ventilation_System_Manager`**, а не как перегруженный orchestration-монолит по типу старого heating wrapper до cleanup.

Структура читается линейно:
1. локальный wet-zone adapter;
2. intake ventilation requests из `GVL_COMMAND_SHADOW`;
3. один основной вызов `fbVentilationManager(...)`;
4. copy-out adapters обратно в `GVL_STATE`.

Это хороший стартовый признак: wrapper пока не выглядит архитектурно «разросшимся» уже на первом чтении.

## Структура wrapper

### VWA-01. Локальные переменные и adapter buffers
`PRG_Ventilation.st` использует локальные буферы:
- `L_Supply_Fans_Byte`
- `L_Exhaust_Fans_Byte`
- `L_Wet_Zone_Active`
- request flags:
  - `L_Vent_PV3_Boost_Req`
  - `L_Supply_100_Req`
  - `L_Exhaust_100_Req`
  - `L_Supply_80_Req`
  - `L_Vent_Stop_Req`

Вывод:
- wrapper явно выполняет adapter-role между глобальными слоями и manager-block contract.

### VWA-02. Wet-zone adapter
Перед основным manager-call wrapper заполняет:
- `L_Wet_Zone_Active`

на основе:
- `GVL_STATUS.G_Wet_Zone_Light_Active`

Вывод:
- здесь есть небольшой локальный adapter/normalization step;
- пока он выглядит компактным и не перегруженным доменной логикой.

### VWA-03. Request intake уже идет из `GVL_COMMAND_SHADOW`
Wrapper берет ventilation-related requests из:
- `GVL_COMMAND_SHADOW.G_Vent_PV3_Boost`
- `GVL_COMMAND_SHADOW.G_Supply_100_Req`
- `GVL_COMMAND_SHADOW.G_Exhaust_100_Req`
- `GVL_COMMAND_SHADOW.G_Supply_80_Req`
- `GVL_COMMAND_SHADOW.G_Vent_Stop`

Вывод:
- ventilation wrapper уже полностью встроен в shadow-centered command reality;
- здесь не подтверждается возврат к legacy `GVL_COMMAND` execution-path.

### VWA-04. Основной manager-call один и централизованный
`fbVentilationManager(...)` получает из wrapper:
- system context,
- temperatures/humidity/CO2,
- current scenario,
- system mode,
- config,
- fire/gas safety signals,
- arbitration requests,
- IO modules online,
- wet-zone activity,
- rule actions.

Вывод:
- manager-call является реальным центром вентиляционного orchestration/decision logic;
- wrapper пока выглядит как upstream/downstream adapter-layer вокруг него.

### VWA-05. Copy-out adapters обратно в `GVL_STATE`
После manager-call wrapper делает copy-out:
- `L_Supply_Fans_Byte -> GVL_STATE.G_Supply_Fans[...]`
- `L_Exhaust_Fans_Byte -> GVL_STATE.G_Exhaust_Fans[...]`

через `BYTE_TO_REAL`.

Вывод:
- это явный downstream adapter/publication step;
- он находится в wrapper, а не внутри manager.

## Что именно проходит через wrapper boundary

### Входной контекст сверху
`PRG_Ventilation` берет сверху:
- command requests из `GVL_COMMAND_SHADOW`;
- environmental signals из `GVL_STATE`;
- status/scenario/time/IO online из `GVL_STATUS`;
- config из `GVL_CONFIG`;
- safety latched alarms из `GVL_STATE`.

### Выходной контекст наружу
`PRG_Ventilation` публикует наружу:
- `GVL_STATE.G_Vent_Heater_Power`
- `GVL_STATUS.G_Vent_Status_Msg`
- `GVL_STATE.G_Supply_Fans[...]`
- `GVL_STATE.G_Exhaust_Fans[...]`

Вывод:
- wrapper выполняет роль явной boundary-point между manager-layer и глобальными project-wide layers.

## Первая интерпретация ownership/boundary

### VWA-06. Wrapper пока не выглядит перегруженным business logic
В `PRG_Ventilation.st` на текущем уровне не видно:
- длинного policy tail;
- большого diagnostics/gating хвоста;
- множества scattered writes beyond obvious adapter outputs.

Вывод:
- по первой оценке это скорее tidy wrapper, чем problem-wrapper.

### VWA-07. Manager, вероятно, является основным owner сложной вентиляционной логики
Так как wrapper сам по себе линеен и короток, основная ventilation logic, скорее всего, сосредоточена в:
- `FB_Ventilation_System_Manager.st`

Вывод:
- следующий этап действительно должен идти в manager contract audit, а не в premature wrapper cleanup.

## Что пока НЕ утверждается этим этапом
Этот документ не утверждает:
- что ventilation cluster уже полностью чист архитектурно;
- что внутри manager нет ownership drift;
- что requests/status ownership уже идеально устроены.

Он утверждает только:
- `PRG_Ventilation.st` по текущему live root выглядит как сравнительно аккуратный wrapper with adapter responsibilities.

## Практический эффект этапа V-A1
После этого шага уже можно уверенно сказать:
- ventilation wave, вероятно, будет разбираться в первую очередь через contract и logic manager-блока;
- wrapper-level risk на первом чтении выглядит ниже, чем это было у heating до recovery/regroup phases.

Это хороший сигнал для следующего шага:
- смотреть глубже в `FB_Ventilation_System_Manager.st`.

## Следующий рекомендуемый документ
- `64_VENTILATION_MANAGER_CONTRACT_AUDIT.md`

Его задача:
- выполнить этап `V-A2`;
- снять фактический контракт `FB_Ventilation_System_Manager.st` и понять, где реально живет сложная ventilation logic.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения