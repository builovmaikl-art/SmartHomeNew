# Heating Recovery Execution Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ фиксирует **точный порядок выполнения recovery-изменений** для восстановления полного `PRG_Heating.st` в живом корне репозитория.

Это уже не документ общего анализа, а документ исполнительного порядка действий.

## Основание
План опирается на ранее зафиксированные документы:
- `04_HEATING_CLUSTER_AUDIT.md`
- `05_HEATING_REMEDIATION_PLAN.md`
- `06_HEATING_SOURCE_RECOVERY_AUDIT.md`
- `07_HEATING_RECOVERY_COMPATIBILITY_CHECK.md`
- `08_HEATING_RECOVERY_CHANGESET_PLAN.md`

## Цель исполнения
Вернуть в живой корень полный непрерывный `PRG_Heating.st`, сохранив текущий архитектурный вектор проекта и не смешивая recovery с redesign.

## Execution Mode
- Режим исполнения: Direct Repository Modification Mode.
- Тип проверки: repository state verification.
- Ограничение: без заявлений о runtime-успехе до отдельной compile/run проверки.

## Исходные материалы

### Базовый recovery source
- `snapshots/2026-04-22/PRG_Heating.st`

### Живые файлы, с которыми нужно сверять восстановление
- `PRG_Heating.st`
- `MAIN.st`
- `FB_Heating_System_Manager.st`
- `FB_DHW_Manager.st`
- `GVL_STATE.gvl`
- `GVL_HEATING_REQUEST.gvl`
- `GVL_INTENT_USER.gvl`

## Исполнительный порядок

### Шаг E-01. Подготовить recovery copy `PRG_Heating.st`
Действие:
- взять `snapshots/2026-04-22/PRG_Heating.st` как основу будущего корневого файла;
- не переносить его в корень без адаптации.

Ожидаемый результат:
- есть рабочая recovery copy полного wrapper-файла.

### Шаг E-02. Выполнить owner-layer adaptation для heating request
Действие:
- в recovery copy заменить использование owner-точек так, чтобы live owner-слой heating requests оставался в `GVL_STATE`;
- не возвращать ownership в `GVL_HEATING_REQUEST` в рамках этого этапа.

Минимальное требование:
- источник `VI_Preheat_Request` должен быть согласован с current-live owner-слоем.

Рабочее recovery-решение:
- использовать `GVL_STATE.G_Preheat_Request`;
- не делать `GVL_HEATING_REQUEST` обязательным writer-owner слоем для recovery.

Ожидаемый результат:
- recovery copy перестает зависеть от rollback ownership вокруг `GVL_HEATING_REQUEST`.

### Шаг E-03. Сохранить current-live publication model для target/freeze/preheat
Действие:
- не переносить owner-публикации `Preheat / Freeze / Target Temperature` назад в другой слой;
- сохранить совместимость с текущим live root, где эти данные уже живут в `GVL_STATE`.

Ожидаемый результат:
- восстановление не ломает текущую publication-model heating cluster.

### Шаг E-04. Сохранить intent-based reset path для DHW
Действие:
- в вызове `fbDHWManager(...)` оставить `VI_Reset_Errors := GVL_INTENT_USER.I_Reset_Errors`;
- не возвращать legacy reset через `GVL_COMMAND.G_Reset_Errors`.

Ожидаемый результат:
- DHW reset path остается согласованным с текущим intent-oriented live root.

### Шаг E-05. Не менять `MAIN.st`
Действие:
- не перестраивать верхний call order;
- `PRG_Heating()` остается в текущем месте.

Ожидаемый результат:
- recovery локализован в heating wrapper и не затрагивает orchestration верхнего уровня.

### Шаг E-06. Не менять интерфейсы FB
Действие:
- не править сигнатуры `FB_Heating_System_Manager.st` и `FB_DHW_Manager.st`;
- править только сам wrapper `PRG_Heating.st`.

Ожидаемый результат:
- recovery остается program-layer restoration, а не интерфейсным redesign.

### Шаг E-07. Заменить корневой `PRG_Heating.st`
Действие:
- после выполнения минимальных адаптаций заменить текущий сокращенный live-root файл на полный непрерывный `PRG_Heating.st`.

Обязательное условие:
- в новом корневом файле не должно остаться placeholder-вставок вида:
  - `omitted for brevity`
  - `rest unchanged`

Ожидаемый результат:
- в корне лежит полноценный source-файл `PRG_Heating.st`.

### Шаг E-08. Выполнить repository-state verification
Действие:
- проверить, что новый корневой `PRG_Heating.st`:
  - читается как непрерывный полный файл;
  - согласуется по вызовам с текущими `FB_Heating_System_Manager.st` и `FB_DHW_Manager.st`;
  - не требует перестройки `MAIN.st`.

Ожидаемый результат:
- факт восстановления подтвержден состоянием репозитория.

### Шаг E-09. Зафиксировать post-recovery boundary
Действие:
- отдельно зафиксировать, что recovery завершен, но ownership cleanup и functional cleanup еще не выполнены.

Ожидаемый результат:
- восстановление источника не будет ошибочно принято за завершенный heating refactor.

## Что НЕ входит в execution plan
Следующие действия не должны выполняться в рамках этого этапа:
- redesign heating arbitration;
- cleanup diagnostics publications;
- перенос ownership между `GVL_STATE`, `GVL_HEATING_REQUEST` и другими слоями beyond minimal recovery adaptation;
- переработка `FB_Heating_System_Manager.st`;
- переработка `FB_DHW_Manager.st`;
- перестройка `MAIN.st`.

## Критерии успешного завершения execution plan
Этап считается выполненным, если:
1. в корне лежит полный `PRG_Heating.st` без placeholder-вставок;
2. recovery выполнен на базе основного кандидата с минимальными адаптациями;
3. ownership heating request layer не откатился назад скрытым образом;
4. `MAIN.st` не изменялся;
5. интерфейсы heating/DHW FB не изменялись;
6. можно переходить к отдельному post-recovery ownership audit.

## Следующий документ после исполнения
После выполнения этого плана должен появиться:
- `10_HEATING_RECOVERY_RESULT.md`

В нем нужно будет зафиксировать:
- что именно было изменено в корне;
- какие минимальные адаптации были внесены;
- что осталось на следующий post-recovery этап.