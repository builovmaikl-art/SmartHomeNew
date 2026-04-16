# PLC First Run Packet

## 1. Цель первого прогона
Первый прогон нужен не для полного тестирования, а для подтверждения, что:
- проект компилируется и стартует;
- ядро системы живо;
- scenario/policy/dangerous/safety/gateway не дают явных логических сбоев;
- dry-run слой не вмешивается в production path.

## 2. Что открыть в CODESYS первым
Открыть и наблюдать:
- `GVL_STATE.G_System_Mode`
- `GVL_STATE.G_System_Mode_Text`
- `GVL_STATUS.G_System_Mode_Cause`
- `GVL_STATUS.G_Current_Scenario`
- `GVL_STATUS.G_Previous_Scenario`
- `GVL_STATUS.G_Diagnostics.HMI_Last_Message`

Дополнительно:
- `GVL_ALARM.G_Flood_Alarm_Active`
- `GVL_ALARM.G_Gas_Alarm_Active`
- `GVL_ALARM.G_Fire_Alarm_Active`
- `GVL_ALARM.G_Security_Armed`

## 3. Норма сразу после старта
Ожидаем:
- проект стартует без compile/runtime аварии;
- `G_System_Mode` осмысленный;
- `G_System_Mode_Text` заполнен;
- `G_Current_Scenario` осмысленный;
- нет самопроизвольного цикла сценариев;
- dry-run helpers нигде не активируют production path.

## 4. Порядок первого прогона

### Фаза A. Безопасное наблюдение
1. Запустить проект.
2. Проверить `G_System_Mode / Text / Cause`.
3. Проверить `G_Current_Scenario / G_Previous_Scenario`.
4. Убедиться, что `HMI_Last_Message` не указывает на неожиданный guard deny сразу после старта.
5. Убедиться, что dry-run layer не активен сам по себе.

### Фаза B. Scenario / policy
1. Запросить штатную смену сценария.
2. Проверить, что сценарий меняется один раз.
3. Проверить, что history/event фиксирует переход.
4. Включить охрану.
5. Проверить форсирование `AWAY`.
6. Проверить soft guard: попытка `AWAY -> PARTY` не должна менять текущий сценарий.

### Фаза C. Dangerous action
1. Подать dangerous request.
2. Проверить single-arm поведение.
3. Проверить timeout path.
4. Проверить deny path.
5. Проверить, что apply проходит только в `NORMAL/DEGRADED`.

### Фаза D. Safety
1. Проверить flood response.
2. Проверить gas response.
3. Проверить fire/smoke response.
4. Проверить, что confirm/recover paths блокируются под активной аварией.

### Фаза E. Events / health
1. Проверить mode event.
2. Проверить scenario event.
3. Проверить policy events 5/6/7 без флуда.
4. Проверить watchdog event 11/12 если доступно.
5. Проверить IO fault events 2/3 если доступно.

### Фаза F. Gateway
1. Проверить one-shot `VO_*` поведение.
2. Проверить, что telegram не запускает sync time.
3. Проверить отдельность `sync/reset/config`.

## 5. Что считать красным флагом
Сразу стоп и разбор, если:
- сценарий прыгает сам по себе;
- dangerous окно не истекает;
- guard deny не удерживает запрещённый переход;
- policy events сыпятся циклически;
- gateway-команды дублируются;
- dry-run слой почему-либо влияет на production state.

## 6. Что фиксировать по результату первого прогона
После первого запуска нужно отдельно записать:
- что увидели по mode;
- что увидели по scenario;
- что увидели по safety;
- что увидели по gateway;
- что реально требует следующего шага.

## 7. Статус пакета
Этот пакет предназначен для первого реального запуска на ПЛК после логической доводки проекта.
