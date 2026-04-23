# Heating Post-Recovery Ownership Audit

Дата фиксации: 2026-04-23

## Назначение
Этот документ фиксирует состояние ownership в heating wrapper **после recovery-восстановления** `PRG_Heating.st`.

Цель:
- отделить успешно восстановленный source от оставшихся архитектурных вопросов;
- зафиксировать, кто сейчас является reader и writer в heating cluster;
- определить, какие ownership-паттерны допустимы на текущем этапе, а какие подлежат следующему cleanup.

## Область аудита
- `PRG_Heating.st`
- взаимодействие с `PRG_Policy.st`
- публикации в `GVL_STATE`
- публикации в `GVL_STATUS`
- интеграция с `FB_Heating_System_Manager.st`
- интеграция с `FB_DHW_Manager.st`

## Главный вывод
После recovery heating wrapper стал снова обозримым и пригодным для ownership-аудита.

При этом ownership в heating cluster сейчас **частично выровнен, но не полностью очищен**:
- heating request layer сверху уже приходит через `GVL_STATE`, а не через rollback в отдельный legacy-like owner;
- сам `PRG_Heating` остается крупным writer-узлом для ряда полей в `GVL_STATE` и `GVL_STATUS`;
- это допустимо как пост-recovery состояние, но еще не является целевым архитектурно чистым состоянием.

## Ownership-карта: что читает `PRG_Heating`

### O-READ-01. System / safety state
`PRG_Heating` читает:
- `GVL_STATE.G_Safety_Emergency_Stop`
- `GVL_STATE.G_Safety_Gas_Latched`
- `GVL_STATE.G_System_Mode`
- `GVL_STATE.G_Freeze_Request`
- `GVL_STATE.G_Preheat_Request`

Вывод:
- owner heating requests и system mode находятся вне `PRG_Heating`;
- это соответствует текущему recovery-направлению и лучше старого варианта с откатом ownership в `GVL_HEATING_REQUEST`.

### O-READ-02. Runtime measurements / process inputs
`PRG_Heating` читает технологические входы из:
- `GVL_IO`
- `GVL_STATE`
- `GVL_STATUS`
- `GVL_CONFIG`

Это включает:
- модуляцию котлов,
- температуры,
- давления,
- статусы IO,
- сценарий,
- конфигурацию зон, тарифов и насосов.

Вывод:
- как orchestration-wrapper `PRG_Heating` остается aggregator-reader для cluster inputs.

### O-READ-03. User intent reset path
`PRG_Heating` читает `GVL_INTENT_USER.I_Reset_Errors` и передает это в `FB_DHW_Manager`.

Вывод:
- user reset ownership не находится в heating wrapper;
- wrapper только маршрутизирует его вниз в DHW block.

## Ownership-карта: что пишет `PRG_Heating`

### O-WRITE-01. Heating target temperature publication
`PRG_Heating` пишет:
- `GVL_STATE.G_Target_Temperature`

Это делается через локальный arbitration/stabilization слой (`L_Last_Mode`).

Вывод:
- после recovery owner итоговой целевой температуры фактически остается внутри `PRG_Heating`;
- это уже лучше, чем скрытая разорванность wrapper-файла, но ownership здесь еще требует отдельного решения: оставлять ли target arbitration в wrapper или поднимать его выше в policy/system layer.

Статус: ACCEPTABLE AFTER RECOVERY, NOT FINAL.

### O-WRITE-02. Команды и статусы от `FB_Heating_System_Manager`
Через `fbHeatingManager(...)` wrapper публикует в `GVL_STATE`:
- `G_Manifold_Valves`
- `G_Manifold_Pumps`
- `G_Boiler_OT_Enable`
- `G_Boiler_OT_Setpoint`
- `G_Backup_Circulation_Pump`
- `G_Electric_Heater_Enable`
- `G_Safety_Freeze_Risk`

и в `GVL_STATUS`:
- `G_Manifold_Status`
- `G_Boiler_Status`

Вывод:
- `PRG_Heating` остается легитимным orchestration-writer для cluster outputs/status publications;
- это нормально для текущего этапа, но позже стоит проверить, не слишком ли много прямых глобальных publications сосредоточено в одном wrapper.

Статус: ACCEPTABLE AFTER RECOVERY.

### O-WRITE-03. Публикации от `FB_DHW_Manager`
Через `fbDHWManager(...)` wrapper публикует:
- `GVL_STATE.G_DHW_Heating_Pump`
- `GVL_STATE.G_DHW_Circ_Pump`
- `GVL_STATUS.G_DHW_Status`

Вывод:
- ownership DHW-command/status publication остается в heating cluster через wrapper;
- это допустимо, но после recovery стоит отдельно проверить, не надо ли вынести DHW-wrapper в более самостоятельный слой.

Статус: ACCEPTABLE AFTER RECOVERY.

### O-WRITE-04. Maintenance / diagnostics gating
`PRG_Heating` напрямую пишет и корректирует:
- `GVL_STATUS.G_Diagnostics.*`
- `GVL_STATE.G_Backup_Circulation_Pump`
- `GVL_STATE.G_Electric_Heater_Enable`
- `GVL_STATE.G_Freeze_Hardware_Degraded`
- `GVL_STATE.G_Freeze_Hardware_Failed`
- `GVL_STATE.G_DHW_Heating_Pump`
- `GVL_STATE.G_DHW_Circ_Pump`
- `GVL_STATE.G_Manifold_Pumps[*]`

Вывод:
- именно этот участок сейчас является самым «шумным» ownership-кластером внутри wrapper;
- после recovery он допустим как pragmatic orchestration layer;
- но это главный кандидат на следующий cleanup ownership, потому что здесь смешиваются:
  - диагностика,
  - maintenance gating,
  - защитные обнуления выходов,
  - subsystem publication.

Статус: REQUIRES CLEANUP LATER.

### O-WRITE-05. Adapter copy-out layer
`PRG_Heating` выполняет copy-out:
- `L_Zone_Valves_8 -> GVL_STATE.G_Zone_Valves`

Вывод:
- это простой adapter ownership;
- сам по себе он не выглядит архитектурной проблемой.

Статус: ACCEPTABLE.

## Что уже улучшилось после recovery

### O-IMPROVE-01
Снят самый грубый ownership-риск: больше нет ситуации, когда heating wrapper нельзя было полноценно прочитать из-за разорванного/сокращенного source.

### O-IMPROVE-02
Не допущен скрытый rollback ownership heating request layer в `GVL_HEATING_REQUEST` как обязательный current-live owner.

### O-IMPROVE-03
Сохранен intent-based reset path, то есть recovery не вернул cluster обратно к более legacy command ownership.

## Что остается проблемой после recovery

### O-ISSUE-01. Target temperature ownership не полностью очищен
Сейчас итоговая `G_Target_Temperature` формируется в самом `PRG_Heating`.

Вопрос на следующий этап:
- должен ли wrapper продолжать быть owner целевой температуры,
- или target arbitration должен жить выше — в policy/system layer.

### O-ISSUE-02. Wrapper совмещает orchestration и diagnostics gating
Сейчас в одном месте смешаны:
- routing в heating FB,
- routing в DHW FB,
- maintenance gating,
- diagnostics publication,
- anti-freeze protective shutdowns.

Это рабочее состояние, но не минимально-чистое по ownership.

### O-ISSUE-03. GVL_STATE и GVL_STATUS остаются перегруженными прямыми публикациями
Даже после recovery heating wrapper продолжает быть writer для большого количества глобальных полей.

Это не блокирует работу дальше, но делает следующий ownership-cleanup обязательным.

## Практическое решение по post-recovery этапу
На текущем этапе ownership heating cluster считается:
- **достаточно восстановленным**, чтобы двигаться дальше;
- **недостаточно очищенным**, чтобы считать heating architecture завершенной.

## Рекомендуемый следующий шаг
Следующим логичным документом должен быть:
- `12_HEATING_OWNERSHIP_CLEANUP_PLAN.md`

Его задача:
- определить, что выносить из `PRG_Heating` в первую очередь,
- решить судьбу ownership для `G_Target_Temperature`,
- разделить pragmatic orchestration и diagnostics/maintenance publication layer.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения