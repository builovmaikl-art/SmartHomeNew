# Security / Access Local Fix Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ переводит `56_SECURITY_ACCESS_FIX_DIRECTION_DECISION.md` в следующий практический шаг:
**локальный interface fix для связки `PRG_Security.st` -> `FB_Access_Control.st`**.

Цель:
- устранить подтвержденный load-bearing mismatch;
- ограничить changeset одним локальным исправлением call-site;
- не расширять scope до ненужного redesign security/access boundary.

## Основание
План опирается на:
- `52_SECURITY_ACCESS_LIVE_CALLSITE_AUDIT.md`
- `53_SECURITY_ACCESS_BLOCK_INTERFACE_AUDIT.md`
- `54_SECURITY_ACCESS_CALLSITE_VS_INTERFACE_COMPARISON.md`
- `55_SECURITY_ACCESS_BOUNDARY_CHECK.md`
- `56_SECURITY_ACCESS_FIX_DIRECTION_DECISION.md`

## Уже принятое базовое решение
К текущему моменту зафиксировано:
- в live call-site `fbAccessControl(...)` отсутствует обязательный `VI_System_Mode`;
- `FB_Access_Control.st` требует `VI_System_Mode` как обязательный `VAR_INPUT`;
- параметр реально используется внутри блока как behavioral gate для `MODE_SAFE_STOP`;
- проблема трактуется как **local call-site contract drift**, а не как повод для broader redesign.

Следовательно, правильный следующий шаг:
- локально довести call-site до фактического block contract.

## Цель fix-этапа
Получить такой вызов `fbAccessControl(...)` в `PRG_Security.st`, при котором:
- формальный mismatch с `FB_Access_Control.st` устранен;
- access block получает полный требуемый system/security context;
- роли `PRG_Security`, `FB_Security_System_Manager` и `FB_Access_Control` не меняются.

## Что именно нужно изменить

### SAF-01. Добавить недостающий параметр `VI_System_Mode`
В вызов `fbAccessControl(...)` нужно добавить:
- `VI_System_Mode := GVL_STATE.G_System_Mode`

Это и есть минимальный подтвержденный fix.

## Почему выбран именно этот source

### SAF-02. `GVL_STATE.G_System_Mode` — естественный current system-mode source
На текущем этапе это наиболее логичный источник, потому что:
- это уже established aggregated system mode layer;
- он используется как текущий system-level mode source в других частях проекта;
- он соответствует semantic ожиданию access block, который должен уметь гасить outputs в `MODE_SAFE_STOP`.

## Что НЕ нужно менять

### SAF-NO-01
Не менять интерфейс `FB_Access_Control.st`.

### SAF-NO-02
Не менять интерфейс `FB_Security_System_Manager.st`.

### SAF-NO-03
Не менять состав остальных параметров `fbAccessControl(...)`, если новый audit не подтвердит дополнительный mismatch.

### SAF-NO-04
Не переводить access request inputs с `GVL_CONFIG.G_HMI_*` на другой source в рамках этого fix.

### SAF-NO-05
Не менять публикацию outputs в `GVL_INTENT_USER` в рамках этого fix.

### SAF-NO-06
Не смешивать этот local fix с broader command-layer или security redesign.

## Практический safe changeset
На уровне кода changeset должен быть минимальным:
- найти вызов `fbAccessControl(...)` в `PRG_Security.st`;
- добавить в input list строку:
  - `VI_System_Mode := GVL_STATE.G_System_Mode,`
- не менять остальной вызов без отдельного подтверждения.

## Порядок выполнения

### Шаг SFL-01. Подтвердить текущий live call-site
Нужно:
- перечитать `PRG_Security.st`;
- подтвердить, что `VI_System_Mode` действительно отсутствует в текущем вызове.

### Шаг SFL-02. Внести минимальную правку
Нужно:
- добавить `VI_System_Mode := GVL_STATE.G_System_Mode` в `fbAccessControl(...)`.

### Шаг SFL-03. Выполнить repository-state verification
После правки нужно подтвердить:
1. `fbAccessControl(...)` теперь покрывает обязательный `VI_System_Mode`;
2. остальные параметры вызова не изменены без необходимости;
3. `FB_Access_Control.st` не менялся;
4. security/access responsibility split не менялся.

### Шаг SFL-04. Только при необходимости сделать короткий comment pass
Если после правки локальный comment рядом с access boundary станет misleading или устаревшим, допустим короткий documentary cleanup.

Но:
- это secondary step,
- не обязательная часть самого interface fix.

## Критерии успешного завершения этапа
Этап считается успешно выполненным, если:
1. missing required parameter больше не отсутствует;
2. changeset остается локальным и минимальным;
3. broader security/access boundary не подвергается ненужному redesign;
4. issue из confirmed mismatch превращается в confirmed fixed call-site defect.

## Следующий рекомендуемый документ
- `58_SECURITY_ACCESS_LOCAL_FIX_EXECUTION_PLAN.md`

Его задача:
- перевести этот plan в конкретный исполнительный порядок изменения `PRG_Security.st` и последующей проверки.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения