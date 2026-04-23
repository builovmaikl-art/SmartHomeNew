# Security / Access Local Fix Execution Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ переводит `57_SECURITY_ACCESS_LOCAL_FIX_PLAN.md` в **исполнительный порядок** для локального исправления связки `PRG_Security.st` -> `FB_Access_Control.st`.

Это не redesign security/access boundary.

Это строго:
- локальная правка call-site `fbAccessControl(...)`;
- устранение подтвержденного missing required parameter;
- repository-state verification после изменения.

## Основание
План опирается на:
- `54_SECURITY_ACCESS_CALLSITE_VS_INTERFACE_COMPARISON.md`
- `55_SECURITY_ACCESS_BOUNDARY_CHECK.md`
- `56_SECURITY_ACCESS_FIX_DIRECTION_DECISION.md`
- `57_SECURITY_ACCESS_LOCAL_FIX_PLAN.md`
- текущее состояние `PRG_Security.st`
- текущее состояние `FB_Access_Control.st`

## Цель исполнения
Получить такой вызов `fbAccessControl(...)` в `PRG_Security.st`, при котором:
- mandatory input `VI_System_Mode` больше не отсутствует;
- `FB_Access_Control` получает полный требуемый system/security context;
- остальные части security/access boundary остаются неизменными.

## Execution Mode
- Режим исполнения: Direct Repository Modification Mode.
- Тип проверки: repository state verification.
- Ограничение: без compile/run подтверждения.

## Зафиксированные инварианты перед изменением
Во время этого этапа нельзя менять:
- интерфейс `FB_Access_Control.st`;
- интерфейс `FB_Security_System_Manager.st`;
- состав остальных параметров `fbAccessControl(...)`, если это не требуется для устранения уже подтвержденного mismatch;
- источники `VI_Gate_Open_Req`, `VI_Wicket_Open_Req`, `VI_Lock_*`;
- публикацию `VO_*` результатов в `GVL_INTENT_USER`;
- broader security/access responsibility split.

Допустим только минимальный local call-site fix.

## Исполнительный порядок

### Шаг SFE-01. Подтвердить текущий live call-site
Действие:
- перечитать `PRG_Security.st`;
- подтвердить, что в `fbAccessControl(...)` отсутствует `VI_System_Mode`.

Ожидаемый результат:
- changeset вносится по подтвержденному live-root состоянию, а не по памяти.

### Шаг SFE-02. Добавить недостающий input в call-site
Действие:
- в вызов `fbAccessControl(...)` добавить строку:
  - `VI_System_Mode := GVL_STATE.G_System_Mode,`

Предпочтительно расположить ее рядом с остальным system/security context, то есть после:
- `VI_Armed := GVL_ALARM.G_Security_Armed`

или в ближайшем логически согласованном месте среди VI-параметров.

Ожидаемый результат:
- call-site покрывает declared block contract по обязательному system-mode input.

### Шаг SFE-03. Не менять остальной вызов без подтвержденной необходимости
Действие:
- оставить без изменений:
  - HMI/config request inputs,
  - credential inputs,
  - `VAR_IN_OUT` stores,
  - `VO_*` outputs.

Ожидаемый результат:
- changeset остается минимальным и локальным.

### Шаг SFE-04. Выполнить repository-state verification после правки
Действие:
- перечитать `PRG_Security.st` после изменения.

Нужно подтвердить:
1. `fbAccessControl(...)` теперь содержит `VI_System_Mode := GVL_STATE.G_System_Mode`;
2. остальные параметры вызова не были произвольно изменены;
3. `FB_Access_Control.st` не изменялся;
4. `FB_Security_System_Manager.st` не изменялся;
5. issue остается локально закрытым, без расширения scope.

Ожидаемый результат:
- confirmed fixed call-site defect.

### Шаг SFE-05. Только при необходимости выполнить короткий documentary pass
Действие:
- если после правки локальный comment рядом с access boundary будет вводить в заблуждение, допустим короткий documentary cleanup.

Но:
- это optional secondary action;
- не основная часть fix.

## Что считается допустимым изменением
Допустимо:
- добавить один недостающий `VI_System_Mode` input;
- при необходимости слегка выровнять форматирование списка параметров;
- опционально уточнить локальный comment, если он станет явно misleading.

## Что запрещено на этом шаге
Запрещено:
- менять block contracts;
- менять logic внутри `FB_Access_Control.st`;
- менять logic внутри `FB_Security_System_Manager.st`;
- менять intent/config source model;
- делать broader boundary cleanup под видом local fix.

## Критерии успешного завершения execution plan
Этап считается успешно выполненным, если:
1. missing required parameter устранен;
2. fix остается минимальным;
3. security/access boundary не подверглась ненужному redesign;
4. подтвержденный mismatch превращается в подтвержденный fixed issue.

## Следующий документ после исполнения
После выполнения этого плана должен появиться:
- `59_SECURITY_ACCESS_LOCAL_FIX_RESULT.md`

В нем нужно будет зафиксировать:
- какую именно строку добавили в call-site;
- что mismatch по `VI_System_Mode` больше не остается открытым;
- что еще остается следующим шагом в security/access scope.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения