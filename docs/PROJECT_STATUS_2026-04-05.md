# PROJECT STATUS — SmartHomeNew
Дата фиксации: 2026-04-05

## 1. Текущее состояние проекта

Проект переведён из набора разрозненных FB в централизованную архитектуру с единым контуром принятия решений:

- `MAIN.st`
  - `PRG_Safety`
  - `PRG_System`

Текущий управляющий поток:

1. `PRG_Safety`
   - обработка safety manager-ов
   - публикация bridge-сигналов
2. `PRG_System`
   - watchdog
   - system health
   - state manager
   - HMI / fault logger
   - gateway
   - blackbox
   - history
   - alarm manager

---

## 2. Архитектурный контур

### 2.1 Safety layer
Safety-контур построен через manager-ы и bridge, а не прямыми связями в alarm:

- `FB_Water_Leakage_Manager`
- `FB_Gas_Smoke_Manager`
- `GVL_HEALTH_BRIDGE`
- `GVL_ALARM`

Результат:
- smoke / gas / CO / leak доходят до bridge
- alarm строится от новых сигналов
- safety-защёлкиваются через `fbSafety` в `PRG_System`

### 2.2 Health layer
`FB_System_Health` агрегирует:
- `Smoke`
- `Gas`
- `CO warning`
- `CO critical`
- `Leak`
- `Sensor fault`
- `IO offline`
- `Comm fault`
- `Watchdog fault`
- `Subsystem fault`

Выходы:
- `VO_System_Severity`
- `VO_Root_Cause`
- compatibility outputs `VO_First_Fault_*`

### 2.3 State layer
`FB_State_Manager` формирует системный режим:
- `MODE_NORMAL`
- `MODE_DEGRADED`
- `MODE_FREEZE_PROTECTION`
- `MODE_SAFE_STOP`

Правило по протечке зафиксировано:
- протечка = локальная авария
- не эскалируется в SAFE_STOP
- остаётся в ветке WARNING / DEGRADED

### 2.4 Watchdog layer
`FB_Watchdog` переработан в реальный cycle-gap watchdog.

Текущее поведение:
- измеряет разрыв между последовательными вызовами
- выдаёт `VO_Cycle_DT_MS`
- выдаёт `VO_Watchdog_Fault` при превышении `VI_Timeout_MS`

Ограничение:
- не может поймать «абсолютно мёртвый PLC», если код вообще не исполняется
- но корректно ловит аномальный разрыв цикла / long pause / overrun after resume

### 2.5 Gateway layer
Gateway интегрирован в `PRG_System` и теперь защищён двумя слоями:

1. `SAFE_STOP` guard
2. mode-based command priority

Текущая матрица разрешений:
- `MODE_NORMAL`
  - разрешены scenario / temp / vent / config / time sync
- `MODE_DEGRADED`
  - разрешён только scenario
- `MODE_SAFE_STOP`
  - dangerous gateway writes блокируются
- `MODE_FREEZE_PROTECTION`
  - gateway writes effectively запрещены текущей матрицей

Финальный `COMMAND GATE` остаётся после gateway-обработки и жёстко чистит:
- `G_Scenario_Request`
- `G_Lighting_Override`
- `G_Blinds_Override`
- `G_Socket_Override`

---

## 3. Состояние ключевых блоков

### 3.1 `FB_Gas_Smoke_Manager`
Статус: рабочий

Содержит:
- smoke debounce
- methane detection
- CO warning / critical separation
- CO time-based logic
- отдельные выходы:
  - `VO_Smoke_Detected`
  - `VO_Gas_Detected`
  - `VO_CO_Warning_Level`
  - `VO_CO_Alarm_Level`

### 3.2 `FB_Water_Leakage_Manager`
Статус: рабочий

Содержит:
- warning/alarm logic
- valve close commands
- bridge outputs:
  - `VO_Leak_Detected`
  - `VO_Leak_Warning_Level`

### 3.3 Detector blocks
Статус: упрощённые

Замечание:
- detector-ы остаются thin-wrapper уровнем
- основная safety-логика живёт в manager-ах
- это допустимо, но должно считаться осознанным архитектурным решением

### 3.4 `FB_System_Health`
Статус: рабочий и центральный

Приоритеты сейчас:
- `FIRE`
- `GAS`
- `CO_CRITICAL`
- `CO_WARNING`
- `WATER`
- `WATCHDOG`
- `IO`
- `COMM`
- `SENSOR`
- `SUBSYSTEM`

### 3.5 `FB_State_Manager`
Статус: рабочий

Преобразует:
- Severity
- Root Cause
- Freeze Risk

в:
- `VO_System_Mode`
- `VO_Status_Msg`

### 3.6 `FB_HMI_Interface`
Статус: рабочий

Используется как publisher текстового состояния наружу.

### 3.7 `FB_Fault_Logger`
Статус: рабочий

Реализован ring buffer на 16 событий:

- `VO_Event_Time_MS[1..16]`
- `VO_Event_Severity[1..16]`
- `VO_Event_RootCause[1..16]`
- `VO_Event_Text[1..16]`
- `VO_Event_Count`
- `VO_Last_Index`

Последнее событие публикуется в:
- `GVL_HEALTH_BRIDGE.G_Last_Fault_Event_Text`

### 3.8 `FB_BlackBox_Recorder`
Статус: расширен и согласован с новой моделью

BlackBox snapshot теперь включает:
- `System_Mode`
- `First_Fault_*`
- `System_Severity`
- `Root_Cause`
- `Watchdog_Fault`

Тип `ST_BlackBox_Record` зафиксирован явно отдельным файлом.

### 3.9 `FB_History_Manager`
Статус: согласован с RootCause-моделью

История теперь логирует:
- смену режима системы
- смену `Root_Cause`
- смену source
- alarm events
- scenario transitions
- operator journal

Есть anti-flood / dedup логика.

### 3.10 `FB_Alarm_Manager`
Статус: интегрирован и рабочий

Использует:
- `GVL_ALARM.*`
- compatibility `VO_First_Fault_*`

---

## 4. Экспорт и публикация диагностик

В `PRG_System.st` наружу публикуются diagnostic flags:

- `GVL_STATUS.G_Diagnostics.Sensor_Fault`
- `GVL_STATUS.G_Diagnostics.IO_Offline`
- `GVL_STATUS.G_Diagnostics.Subsystem_Degraded`

Назначение:
- HMI
- Gateway
- diagnostics / service layer
- последующее расширение журналирования

---

## 5. Что уже закрыто

Закрытые системные задачи:

- [x] выделение severity/root-cause модели
- [x] интеграция health в основной цикл
- [x] интеграция state manager в основной цикл
- [x] интеграция HMI interface
- [x] интеграция fault logger
- [x] переработка watchdog в рабочую модель
- [x] command gate для SAFE_STOP
- [x] mode-based gateway command priority
- [x] расширение blackbox severity/root/watchdog
- [x] перевод history с first fault type на root cause
- [x] export diagnostic flags
- [x] ring buffer в fault logger
- [x] явная фиксация `ST_BlackBox_Record`

---

## 6. Оценка готовности по слоям

### Safety
Статус: высокий уровень готовности

### Health
Статус: высокий уровень готовности

### State
Статус: высокий уровень готовности

### Watchdog
Статус: рабочий с понятным ограничением

### Gateway
Статус: безопаснее прежнего, базовый command priority введён

### History
Статус: консистентен с новой моделью

### BlackBox
Статус: согласован с новой моделью

### Diagnostics export
Статус: базовый слой закрыт

---

## 7. Открытые ограничения / не блокеры

### 7.1 Detector blocks
Остаются упрощёнными.
Решение:
- либо оставить thin-wrapper официально
- либо позже усиливать физическую логику detector-ов

### 7.2 Operator > Gateway arbitration
Сейчас введён базовый слой:
- `SAFETY > SYSTEM MODE > GATEWAY`

Но ещё не доведён общий слой:
- `SAFETY > SYSTEM > OPERATOR > GATEWAY`

### 7.3 HMI model
Пока HMI в основном текстовая.
Можно расширить:
- severity code
- root cause code
- structured status object

### 7.4 Alarm model
`Alarm_Manager` всё ещё опирается на compatibility `VO_First_Fault_*`.
Это допустимо сейчас, но является слоем совместимости, который позже можно упростить.

### 7.5 Watchdog strategy
Текущий watchdog уже полезен и реален, но не hardware-level.
Это нормальное ограничение текущей архитектуры.

---

## 8. Рекомендуемые следующие шаги

### Приоритет 1
Сформировать полноценную матрицу arbitration:
- `SAFETY > SYSTEM > OPERATOR > GATEWAY`

### Приоритет 2
Уточнить правила для `MODE_FREEZE_PROTECTION` отдельно, явно документировать допустимые команды

### Приоритет 3
Решить судьбу detector-ов:
- thin-wrapper officially
или
- усиление логики

### Приоритет 4
Расширить HMI в сторону структурированного статуса

### Приоритет 5
Постепенно уменьшать compatibility-layer (`VO_First_Fault_*`) там, где downstream уже переведён на `Root_Cause`

---

## 9. Общий вывод

На дату 2026-04-05 проект находится в состоянии:

- ядро архитектуры собрано
- основные разрывы между safety / health / state / gateway закрыты
- критические риски внешнего управления существенно уменьшены
- проект пригоден как baseline production-architecture
- дальнейшие задачи — это в основном не «спасение архитектуры», а доведение и эксплуатационная полировка

Итоговый статус:
**архитектурно собранный проект со стабилизированным управляющим контуром**
