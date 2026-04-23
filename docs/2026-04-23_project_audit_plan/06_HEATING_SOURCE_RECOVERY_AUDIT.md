# Heating Source Recovery Audit

Дата фиксации: 2026-04-23

## Цель документа
Зафиксировать результаты шагов H-R1/H-R2:
- подтвердить, что проблема `PRG_Heating.st` относится к реальному live-root source,
- найти и ранжировать кандидатов на восстановление полного heating wrapper,
- выбрать основной кандидат для следующего шага совместимости и восстановления.

## Объекты сравнения
- live root: `PRG_Heating.st`
- snapshot candidate A: `snapshots/2026-04-23/PRG_Heating.st`
- snapshot candidate B: `snapshots/2026-04-22/PRG_Heating.st`
- snapshot candidate C: `snapshots/project_clean_state_2026_04_16/PRG_Heating.st`
- текущие интерфейсы `FB_Heating_System_Manager.st` и `FB_DHW_Manager.st`
- текущие live-root globals `GVL_HEATING_REQUEST.gvl` и `GVL_STATE.gvl`

## Результат H-R1

### SR-001. Проблема действительно относится к live root
Текущий `PRG_Heating.st` в корне и `snapshots/2026-04-23/PRG_Heating.st` совпадают по дефектному признаку: оба содержат сокращенный placeholder-like текст с вставками `omitted for brevity` и `rest unchanged`.

Вывод:
- это не ошибка чтения только одного инструмента;
- это не частный дефект только архивного слепка;
- проблема действительно относится к текущему состоянию heating wrapper в верхней части репозитория.

Статус: CONFIRMED.

## Результат H-R2

### SR-002. Candidate A (`snapshots/2026-04-23/PRG_Heating.st`) исключается
Причина:
- кандидат повторяет тот же сокращенный placeholder-like вид, что и текущий live root.

Вывод:
- использовать его как источник восстановления нельзя.

Статус: REJECTED.

### SR-003. Candidate C (`snapshots/project_clean_state_2026_04_16/PRG_Heating.st`) является полным, но более старым совместимым кандидатом
Плюсы:
- файл полный и непрерывный;
- содержит связный heating wrapper;
- использует текущие базовые live-root связи heating/DHW/system mode.

Минусы:
- выглядит более ранней стадией cluster;
- не содержит более поздний слой consolidated heating request / stabilization;
- не передает `VI_Preheat_Request` в `FB_Heating_System_Manager`, хотя текущий интерфейс FB такой вход уже содержит.

Вывод:
- это пригодный резервный кандидат;
- использовать его как основной источник восстановления нежелательно, если найден более поздний и лучше согласованный вариант.

Статус: BACKUP CANDIDATE.

### SR-004. Candidate B (`snapshots/2026-04-22/PRG_Heating.st`) является лучшим основным кандидатом
Плюсы:
- файл полный и непрерывный;
- он ближе по времени к текущему live root;
- содержит тот же верхний слой переменных `L_Last_Mode` и `L_Mode_Hold_Timer`, что и сокращенный текущий root-файл;
- содержит consolidated heating request / arbitration / stabilization слой;
- передает `VI_Preheat_Request := GVL_HEATING_REQUEST.G_Preheat_Request` в `FB_Heating_System_Manager`, что лучше соответствует текущему live-root интерфейсу блока;
- использует `GVL_HEATING_REQUEST.gvl`, который присутствует в текущем корне;
- использует `GVL_STATE.G_Target_Temperature`, `GVL_STATE.G_Preheat_Request`, `GVL_STATE.G_Freeze_Request`, которые присутствуют в текущем корне;
- использует `GVL_INTENT_USER.I_Reset_Errors` для `FB_DHW_Manager`, что согласуется с общей intent-ориентацией текущего проекта лучше, чем старое использование legacy command-layer reset.

Минусы / что нужно отдельно проверить на следующем шаге:
- не все side effects кандидата еще сверены с текущим live-root ownership;
- нужно проверить, не возникает ли скрытого конфликта между `GVL_HEATING_REQUEST.*` и `GVL_STATE.*` heating request publication.

Вывод:
- это основной кандидат на восстановление полного `PRG_Heating.st`.

Статус: PRIMARY CANDIDATE.

## Сводное ранжирование кандидатов

### 1 место — основной кандидат
`snapshots/2026-04-22/PRG_Heating.st`

Причина:
лучшее сочетание полноты, свежести и совместимости с текущими live-root heating interfaces.

### 2 место — резервный кандидат
`snapshots/project_clean_state_2026_04_16/PRG_Heating.st`

Причина:
полный и связный, но более старый и менее согласованный с текущим heating request / preheat интерфейсом.

### исключен
`snapshots/2026-04-23/PRG_Heating.st`

Причина:
повторяет дефектный сокращенный вид текущего корня.

## Ключевой вывод этапа source recovery audit
Этап H-R1/H-R2 можно считать выполненным.

Подтверждено:
1. текущий live-root `PRG_Heating.st` действительно нецелостен;
2. найден основной кандидат на восстановление;
3. найден резервный кандидат;
4. основной кандидат логически лучше согласуется с текущим live-root heating request слоем.

## Следующий обязательный шаг
Перейти к H-R3 и оформить документ:
`07_HEATING_RECOVERY_COMPATIBILITY_CHECK.md`

В нем нужно проверить:
- текущие сигнатуры вызовов heating/DHW FB,
- требуемые адаптации при возврате кандидата в корень,
- отсутствие rollback к более старому ownership-паттерну,
- список минимальных изменений, которые допустимы именно как recovery, а не как redesign.

## Решение текущего этапа
Базовый кандидат на восстановление полного `PRG_Heating.st`:
`snapshots/2026-04-22/PRG_Heating.st`

Резервный кандидат:
`snapshots/project_clean_state_2026_04_16/PRG_Heating.st`