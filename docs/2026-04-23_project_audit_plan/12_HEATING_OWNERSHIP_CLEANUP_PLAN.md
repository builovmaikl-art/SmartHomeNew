# Heating Ownership Cleanup Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ фиксирует следующий этап после recovery:
**очистку ownership внутри heating cluster** без повторного смешения source recovery и архитектурного cleanup.

## Основание
План опирается на:
- `10_HEATING_RECOVERY_RESULT.md`
- `11_HEATING_POST_RECOVERY_OWNERSHIP_AUDIT.md`

## Цель этапа
Привести heating cluster к более чистому ownership-состоянию, при котором:
- `PRG_Heating` остается понятным orchestration-wrapper,
- ownership для heating requests и target arbitration становится однозначным,
- diagnostics / maintenance gating перестают чрезмерно раздувать wrapper,
- `GVL_STATE` и `GVL_STATUS` получают более дисциплинированные публикации.

## Главный принцип
На этом этапе уже можно делать архитектурный cleanup, но нельзя терять рабочую границу, достигнутую recovery.

То есть:
- recovery source уже восстановлен,
- теперь допустимы структурные улучшения,
- но каждое улучшение должно сохранять прозрачный ownership, а не снова размывать его.

## Что уже считается допустимым базовым состоянием
После recovery допустимо, что `PRG_Heating`:
- читает system/safety/heating request state;
- вызывает `FB_Heating_System_Manager` и `FB_DHW_Manager`;
- маршрутизирует cluster outputs;
- делает ограниченный adapter copy-out.

Это считается нормальным orchestration-ядром и не должно разрушаться ради «чистоты любой ценой».

## Что подлежит cleanup в первую очередь

### HC-CL-01. Ownership для `G_Target_Temperature`
Текущее состояние:
- `PRG_Heating` сам пишет `GVL_STATE.G_Target_Temperature` на основе `L_Last_Mode`.

Проблема:
- target arbitration живет внутри wrapper, а не в более явном policy/system ownership-слое.

Решение, которое нужно принять на cleanup-этапе:
- либо формально закрепить `PRG_Heating` как owner target arbitration;
- либо вынести target arbitration выше, в отдельный policy/system слой.

Рекомендация:
- не оставлять этот вопрос implicit;
- оформить отдельное ownership-решение.

Приоритет: HIGH.

### HC-CL-02. Maintenance / diagnostics gating внутри wrapper
Текущее состояние:
`PRG_Heating` напрямую занимается:
- `Backup_Pump_Out_Of_Service`
- `Electric_Heater_Out_Of_Service`
- `Manifold_Pump_Out_Of_Service[*]`
- `DHW_Heating_Pump_Out_Of_Service`
- `DHW_Circ_Pump_Out_Of_Service`
- protective shutdowns и hardware degraded/failed flags.

Проблема:
- в одном wrapper смешаны orchestration, maintenance gating, diagnostics publication и protective clamping.

Рекомендация:
- выделить этот участок как отдельный cleanup-кластер;
- решить, что должно остаться в `PRG_Heating`, а что лучше вынести в отдельный subsystem-support layer или manager.

Приоритет: HIGH.

### HC-CL-03. Объем прямых публикаций в `GVL_STATE`
Текущее состояние:
через `PRG_Heating` и вызовы его FB идет большой объем прямых записей в `GVL_STATE`.

Проблема:
- wrapper становится слишком широким writer-узлом;
- усложняется понимание ownership и testability.

Рекомендация:
- сгруппировать публикации по типам:
  1. actuator commands,
  2. subsystem state,
  3. diagnostics / degradation,
  4. derived arbitration state.
- после группировки решить, что допустимо оставлять в wrapper, а что требует выноса.

Приоритет: MEDIUM-HIGH.

### HC-CL-04. DHW как подкластер внутри heating wrapper
Текущее состояние:
`PRG_Heating` маршрутизирует вызов `FB_DHW_Manager` и публикацию его результатов.

Проблема:
- не до конца ясно, должен ли DHW оставаться частью heating wrapper навсегда или нуждается в более самостоятельной orchestration-границе.

Рекомендация:
- пока не выносить автоматически;
- сначала зафиксировать явный ownership contract между heating и DHW.

Приоритет: MEDIUM.

## Что пока НЕ нужно трогать

### HC-HOLD-01
Не возвращаться к вопросу source recovery — он уже закрыт.

### HC-HOLD-02
Не перестраивать `MAIN.st`, если для этого нет отдельного архитектурного основания.

### HC-HOLD-03
Не менять сигнатуры `FB_Heating_System_Manager.st` и `FB_DHW_Manager.st` без отдельного интерфейсного аудита.

### HC-HOLD-04
Не смешивать cleanup ownership с functional tuning отопления, антизамерзания или DHW-алгоритмов.

## Очередность cleanup-работ

### Этап C1. Решение по owner для target arbitration
Результат этапа:
- явное решение, кто owner для `G_Target_Temperature`.

### Этап C2. Разделение orchestration vs diagnostics/maintenance
Результат этапа:
- понятная граница между тем, что остается в wrapper, и тем, что выносится из него.

### Этап C3. Нормализация глобальных публикаций heating cluster
Результат этапа:
- уменьшение «ширины» `PRG_Heating` как writer-узла без поломки общей orchestration-схемы.

### Этап C4. Уточнение контракта heating <-> DHW
Результат этапа:
- решение, остается ли DHW внутри current wrapper model или требует отдельного orchestration-слоя позже.

## Формат следующего шага
Следующий документ должен быть уже не общим планом, а узким решением по самой важной точке:
- `13_HEATING_TARGET_OWNERSHIP_DECISION.md`

Его задача:
- принять решение по owner для `GVL_STATE.G_Target_Temperature`,
- зафиксировать аргументы за сохранение target arbitration в `PRG_Heating` или за его вынос.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения