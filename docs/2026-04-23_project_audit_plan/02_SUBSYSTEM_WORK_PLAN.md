# Subsystem Work Plan

Дата фиксации: 2026-04-23

## Цель
Разобрать проект небольшими контролируемыми шагами, чтобы:
- не смешивать архитектурный аудит и частные правки,
- не опираться на устаревшие snapshots и старые audit-файлы,
- двигаться от самых рискованных мест к более локальным.

## Общий порядок работ

### Этап 1. Core orchestration и ownership
Область:
- `MAIN.st`
- `PRG_System.st`
- `PRG_Policy.st`
- `GVL_POLICY.gvl`
- `GVL_INTENT_SYSTEM.gvl`
- `PRG_Command_Arbitration.st`
- `PRG_Command_Verifier.st`
- `GVL_COMMAND.gvl`
- `GVL_COMMAND_SHADOW.gvl`

Цель этапа:
- зафиксировать реальный ownership,
- определить целевое состояние command bus,
- отделить завершенные migration-слои от незавершенных,
- убрать противоречия между live-кодом и migration-комментариями.

Ожидаемый результат:
- единая карта ownership по system mode, scenario intent, command shadow и physical IO.

### Этап 2. Safety + Security + Access
Область:
- `PRG_Safety.st`
- `PRG_Security.st`
- `FB_Access_Control.st`
- `FB_Security_System_Manager.st`
- `FB_Gas_Smoke_Manager.st`
- `FB_Water_Leakage_Manager.st`

Цель этапа:
- проверить интерфейсы между security/access блоками,
- подтвердить отсутствие скрытого ownership-конфликта,
- выделить compile-risk места,
- уточнить, что именно идет через user intent, а что через safety intent.

Ожидаемый результат:
- список интерфейсных несостыковок и карта security/access ownership.

### Этап 3. Heating + DHW
Область:
- `PRG_Heating.st`
- `FB_Heating_System_Manager.st`
- `FB_DHW_Manager.st`
- связанные heating diagnostics и anti-freeze path

Цель этапа:
- выяснить статус корневого `PRG_Heating.st`,
- подтвердить, является ли файл исполняемым live-root кодом,
- отделить реальную heating logic от сокращенных или поврежденных фрагментов,
- после этого проверить ownership по heating diagnostics.

Ожидаемый результат:
- решение по статусу `PRG_Heating.st` и отдельный heating remediation plan.

### Этап 4. Ventilation
Область:
- `PRG_Ventilation.st`
- `FB_Ventilation_System_Manager.st`
- command shadow inputs для вентиляции

Цель этапа:
- проверить policy semantics для `NORMAL / DEGRADED / FREEZE_PROTECTION / SAFE_STOP`,
- понять, какие operational requests действительно должны входить через command shadow,
- сократить прямую зависимость subsystem FB от глобальных слоев.

Ожидаемый результат:
- вентиляционный policy-contract и список точек очистки ownership.

### Этап 5. Lighting / Sockets / Scenarios
Область:
- `PRG_Lighting.st`
- `FB_Lighting_Blinds_Manager.st`
- `FB_Socket_Manager.st`
- `FB_Scenario_Manager.st`
- simulation / rules / override gating

Цель этапа:
- проверить override-block semantics,
- убедиться, что lighting/scenario слой корректно подчиняется system intent,
- отделить пользовательские overrides от system safety clamps.

Ожидаемый результат:
- карта override ownership и список возможных cleanup-изменений.

### Этап 6. Очистка документации и карт зависимостей
Область:
- dated planning docs,
- старые `AUDIT_*`,
- `workspace/*graph*`,
- migration-комментарии внутри кода.

Цель этапа:
- обновить только после подтверждения живого состояния корня,
- не править документы раньше, чем подтверждено фактическое состояние subsystem layers.

Ожидаемый результат:
- актуальная карта зависимостей и чистый набор документов без противоречий.

## Приоритеты

### Priority 1
- Heating + DHW
- Core orchestration / command ownership

### Priority 2
- Safety + Security + Access
- Ventilation

### Priority 3
- Lighting / Sockets / Scenarios
- Documentation cleanup

## Рабочие правила на следующие шаги
- Каждый следующий документ создается в этой dated-папке.
- Каждый документ должен ссылаться только на текущий корень как на источник истины.
- Старые snapshots можно использовать для сравнения, но не для автоматического принятия решений.
- Если найден конфликт между live root и старым audit-материалом, конфликт отдельно фиксируется в progress log.

## Рекомендуемый следующий шаг
Начать с детального документа по heating cluster, потому что именно там выявлен самый грубый признак поврежденного или сокращенного live-root файла.