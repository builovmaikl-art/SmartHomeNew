# 08. Стресс‑тест всей системы: What‑if / Fault Injection / Behavior Stress

## 1. Назначение

Документ фиксирует полный стресс‑тест текущей архитектуры SmartHomeNew по сценариям отказов, конфликтов, деградации входов, safety‑событий, поведения scenario engine и HMI/debug.

Это не build‑лог и не runtime‑тест на PLC. Это code‑first архитектурный stress‑audit по актуальному состоянию репозитория.

## 2. Проверяемый pipeline

Актуальный порядок MAIN:

```text
PRG_Time_Service
→ PRG_IO_Read
→ PRG_Input_Processing
→ PRG_User_Adapt_Control
→ PRG_Behavior_Adapt_Profile
→ PRG_Safety
→ PRG_Safety_Operator
→ PRG_Safety_Shutdown
→ PRG_Safety_Recovery
→ system/support PRGs
→ PRG_Scenario_Engine
→ PRG_Command_Arbitration
→ PRG_Command_Verifier
→ domain PRGs
→ PRG_Explainability
→ PRG_Debug_View
→ PRG_IO_Write
```

Ключевой runtime pipeline:

```text
IO → INPUT → SAFETY/SCENARIO → COMMAND → DOMAIN OUTPUT → IO
                         ↓
          TRACE / EXPLAINABILITY / DEBUG_VIEW / ADAPT
```

## 3. Методика stress‑test

Для каждого сценария проверяется:

1. Входное событие.
2. Ожидаемая реакция INPUT/SAFETY/SCENARIO.
3. Ожидаемая команда в COMMAND.
4. Ожидаемый доменный/IO результат.
5. Диагностика/HMI.
6. Статус: PASS / PARTIAL / FAIL / NEEDS FIX.

## 4. Матрица сценариев

| ID | Сценарий | Ожидаемое поведение | Текущий статус |
|---|---|---|---|
| ST‑01 | Пожар / дым | FIRE, evacuation, locks/gate/wicket open, heating/boiler stop, vent stop | PARTIAL |
| ST‑02 | Газ | GAS, gas close, boiler stop, vent boost, exits open | PASS по gate/wicket, PARTIAL по locks |
| ST‑03 | Протечка воды | WATER_LEAK, water block, valves close | PASS |
| ST‑04 | Global stop | heating/vent/water block | PASS |
| ST‑05 | Input degraded | GLOBAL_STOP | PARTIAL: shutdown поддерживает, input validation regression |
| ST‑06 | PLC inactive | safe commands forced | PASS в command layer |
| ST‑07 | User close при эвакуации | close must be blocked | NEEDS FIX: текущий command файл потерял close-block clamp |
| ST‑08 | Sensor spike | confidence ↓, no immediate emergency | PASS |
| ST‑09 | Sensor stuck | confidence ↓ after timeout | PASS |
| ST‑10 | Repeated bad sensor | reputation ↓, influence ↓ | PASS |
| ST‑11 | Sensor recovery | reputation slowly recovers | PASS |
| ST‑12 | Scenario high humidity | vent boost weighted by input confidence | PASS |
| ST‑13 | Bad humidity sensor high value | score reduced by confidence/reputation | PASS |
| ST‑14 | HMI dashboard | read-only quality/safety/scenario/debug fields | PASS |
| ST‑15 | Recovery confirm | operator → recovery flag → recovery state-machine | PASS |

## 5. Детальные сценарии

### ST‑01. Пожар / дым

**Вход:** smoke/fire active.

**Ожидается:**

```text
Safety → FIRE
Evacuation active
Locks open
Gate/Wicket open
Lock close blocked
Boiler stop
Heating block
Vent stop
```

**Проверка:**

- `PRG_Safety` формирует evacuation/lock force open intent.
- `PRG_Safety_Shutdown` выбирает `FIRE`.
- `PRG_Command_Arbitration` в ветке `FIRE` открывает locks/gate/wicket и останавливает heating/boiler/vent.

**Статус:** PARTIAL.

**Причина:** текущий `PRG_Command_Arbitration` содержит FIRE open, но после последней перезаписи потерян повторный close‑block clamp после user pass-through и command sanity. Для полной гарантии нужен возврат final safety-access clamp.

### ST‑02. Газ

**Вход:** gas active / gas close required.

**Ожидается:**

```text
Gas valve close
Boiler stop
Heating gas safety stop
Vent boost / supply 100
Gate/Wicket open
```

**Статус:** PASS/PARTIAL.

**PASS:** gas close, boiler stop, vent boost, gate/wicket open есть.

**PARTIAL:** locks не открываются в GAS режиме. Это может быть политикой проекта, но для эвакуационного safety‑подхода рекомендуется открыть Lock 1/2 или явно документировать, почему не открывать.

### ST‑03. Протечка воды

**Вход:** leak active / water close required.

**Ожидается:**

```text
Safety → WATER_LEAK
Water block
Water emergency stop
Valve 35/36 close
Access не затрагивается
```

**Статус:** PASS.

### ST‑04. Global stop

**Вход:** system safe stop required или input degraded.

**Ожидается:**

```text
Heating block
Boiler stop
Vent stop
Water block
```

**Статус:** PASS для command behavior.

### ST‑05. Input degraded

**Вход:** `GVL_INPUT.IN_Input_Degraded = TRUE`.

**Ожидается:**

```text
PRG_Safety_Shutdown → GLOBAL_STOP
```

**Статус:** PARTIAL.

**Что хорошо:** `PRG_Safety_Shutdown` уже переводит degraded input в `GLOBAL_STOP`.

**Проблема:** актуальный `PRG_Input_Processing` после внедрения self-learning confidence больше не выставляет `IN_Input_Degraded` по validation/range failure. Валидационные поля и причины тоже частично потеряны из runtime logic.

**Corrective Action:** вернуть в `PRG_Input_Processing` полный validation block:

```text
range failure → IN_Validation_Failed := TRUE
range failure → IN_Input_Degraded := TRUE
reason/zone заполнены
```

### ST‑06. PLC inactive

**Вход:** `GVL_STATUS.G_Is_Active_PLC = FALSE`.

**Ожидается:**

```text
Gas close
Boiler stop
Heating block
Vent stop
Water block
```

**Статус:** PASS.

`PRG_Command_Arbitration` не просто RETURN, а выставляет safe commands.

### ST‑07. User close при эвакуации

**Вход:** FIRE/evacuation + user lock close request.

**Ожидается:**

```text
Lock open remains TRUE
Lock close forced FALSE
```

**Статус:** NEEDS FIX.

**Причина:** текущая версия `PRG_Command_Arbitration` после последней перезаписи не содержит полного user pass-through и повторного close-block clamp. Это означает, что сценарий надо закрыть отдельным corrective patch.

**Corrective Action:** восстановить в `PRG_Command_Arbitration`:

```text
I_Lock_*_Force_Close_Block → G_Lock_*_Close := FALSE
Evacuation → close := FALSE
Open + Close conflict → Close := FALSE
re-apply safety clamp after user intent
```

### ST‑08. Sensor spike

**Вход:** резкий скачок температуры/влажности.

**Ожидается:**

```text
instant confidence ↓
anomaly flag/reason visible
no immediate emergency stop
```

**Статус:** PASS для confidence impact; PARTIAL для anomaly reason после self-learning rewrite.

### ST‑09. Sensor stuck

**Вход:** значение не меняется дольше configured timeout.

**Ожидается:**

```text
instant confidence ↓
zone confidence ↓
worst zone updated
```

**Статус:** PASS.

### ST‑10. Repeated bad sensor

**Вход:** повторяющиеся spikes/stuck.

**Ожидается:**

```text
reputation постепенно падает
final confidence падает
scenario influence падает
```

**Статус:** PASS.

### ST‑11. Sensor recovery

**Вход:** датчик стабилизировался.

**Ожидается:**

```text
reputation постепенно восстанавливается через decay
```

**Статус:** PASS.

### ST‑12. Scenario high humidity

**Вход:** высокая влажность в зоне.

**Ожидается:**

```text
VentBoost score = base × behavior weight × zone weight × adapt confidence × input confidence
```

**Статус:** PASS.

### ST‑13. Bad humidity sensor high value

**Вход:** влажность высокая, но confidence низкий.

**Ожидается:**

```text
VentBoost score снижается
плохой датчик не доминирует
```

**Статус:** PASS.

### ST‑14. HMI dashboard

**Вход:** любой safety/anomaly/scenario state.

**Ожидается:**

```text
DEBUG_VIEW показывает safety, scenario, confidence, anomaly, worst zone, reasons
```

**Статус:** PASS.

### ST‑15. Recovery confirm

**Вход:** safety cleared + operator reset.

**Ожидается:**

```text
GVL_INTENT_USER → PRG_Safety_Operator → GVL_SAFETY_RECOVERY → PRG_Safety_Recovery
```

**Статус:** PASS.

## 6. Критические findings

### CF‑01. Validation regression в PRG_Input_Processing

Self-learning версия input layer упростила обработку и потеряла часть range validation/anomaly reason/degraded logic.

**Риск:** invalid sensor values могут не перевести систему в `GLOBAL_STOP`, несмотря на поддержку `IN_Input_Degraded` в shutdown.

**Приоритет:** HIGH.

### CF‑02. Safety-access clamp regression в PRG_Command_Arbitration

Последняя версия command layer потеряла повторный safety clamp после user pass-through и sanity conflict block.

**Риск:** user/access конфликт в режиме эвакуации может быть недозащищён.

**Приоритет:** HIGH.

### CF‑03. GAS access policy неполная

Gate/Wicket открываются при GAS, но Lock 1/2 не открываются.

**Риск:** зависит от физической архитектуры входа/выхода. Если Lock 1/2 являются эвакуационными, это gap.

**Приоритет:** MEDIUM/HIGH после уточнения физики.

## 7. Рекомендуемый corrective patch

Следующий технический проход должен сделать:

1. Восстановить полный validation block в `PRG_Input_Processing` без удаления self-learning reputation.
2. Восстановить полный safety-access clamp в `PRG_Command_Arbitration`.
3. Принять решение по GAS → Lock open policy.
4. После исправления повторить ST‑01/ST‑05/ST‑07/ST‑08.

## 8. Итоговая оценка

Система находится на уровне:

```text
industrial adaptive safety control platform
```

Но перед production baseline нужно закрыть два regression findings:

```text
CF‑01 input validation regression
CF‑02 safety-access clamp regression
```

После закрытия этих пунктов стресс‑тест можно считать PASS по safety/behavior/input confidence цепочке.
