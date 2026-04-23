# Security / Access Interim Status

Дата фиксации: 2026-04-23

## Назначение
Этот документ фиксирует промежуточное состояние security/access wave после локального исправления в `PRG_Security.st`.

Цель:
- кратко свести completed / clarified / unresolved части security/access scope;
- зафиксировать, что уже реально изменено в репозитории;
- обозначить безопасную точку остановки перед переходом к следующему major scope.

## Общий статус wave
На текущем этапе security/access wave можно считать:
- локально вскрытой по interface boundary;
- доведенной до подтвержденного mismatch and confirmed local fix;
- временно стабилизированной без расширения в broader redesign.

Это еще не большой security redesign cycle.

Но это уже и не зона с неподтвержденным interface-risk.

## Что уже подтверждено и зафиксировано

### SAS-01. Live call-site `fbAccessControl(...)` был снят точно
Подтверждено, что current call-site в `PRG_Security.st`:
- получает security state,
- использует HMI/config access requests,
- берет PIN/RFID из `GVL_INTENT_USER`,
- публикует access results обратно в `GVL_INTENT_USER`.

### SAS-02. Формальный интерфейс `FB_Access_Control.st` был снят точно
Подтверждено, что block contract включает:
- обязательный `VI_System_Mode`,
- `VAR_IN_OUT` stores,
- full access output surface.

### SAS-03. Mismatch был подтвержден, а не предполагался
Подтверждено, что:
- в call-site отсутствовал `VI_System_Mode`;
- этот параметр в block contract обязателен;
- он реально используется внутри блока как behavioral gate для `MODE_SAFE_STOP`.

### SAS-04. Проблема была классифицирована как local integration defect
После boundary check зафиксировано, что:
- responsibility split между `FB_Security_System_Manager` и `FB_Access_Control` в целом читается;
- mismatch лучше трактовать как local call-site contract drift в `PRG_Security.st`, а не как полный architectural collapse.

### SAS-05. Локальный fix выполнен
В `PRG_Security.st` в вызов `fbAccessControl(...)` добавлено:
- `VI_System_Mode := GVL_STATE.G_System_Mode`

Вывод:
- primary confirmed mismatch security/access scope закрыт по состоянию репозитория.

## Что реально изменено в репозитории кодом

### CODE-SEC-01. Local call-site fix
Изменен:
- `PRG_Security.st`

Что сделано:
- в `fbAccessControl(...)` добавлен обязательный input `VI_System_Mode := GVL_STATE.G_System_Mode`.

## Что оставлено намеренно без изменений

### HOLD-SEC-01
`FB_Access_Control.st` не менялся.

### HOLD-SEC-02
`FB_Security_System_Manager.st` не менялся.

### HOLD-SEC-03
Источники `VI_Gate_Open_Req`, `VI_Wicket_Open_Req`, `VI_Lock_*` не менялись.

### HOLD-SEC-04
Output publication в `GVL_INTENT_USER` не менялась.

### HOLD-SEC-05
Security/access boundary не подвергалась broader redesign.

## Что остается осознанно незакрытым

### UNR-SEC-01. Compile/run подтверждение
В текущем цикле его нет.

### UNR-SEC-02. Дополнительный documentary polish
При желании можно позже чуть отполировать comments вокруг security/access orchestration boundary, если это даст смысловую выгоду.

### UNR-SEC-03. Broader security/access redesign
Он не проводился и не требуется по текущим подтвержденным данным.

## Практическая оценка зрелости wave
На текущем этапе security/access wave можно оценить как:
- примерно **85–90% завершенности** в рамках текущего interface audit/remediation цикла.

Это означает:
- главный integration-risk подтвержден и локально закрыт;
- broader redesign не потребовался;
- remaining uncertainty уже не находится в core mismatch area.

## Что это означает для общего проекта
После фиксации этого interim status security/access scope больше не выглядит major scope первого риска.

Его можно оставить в текущем documented state и переходить к следующему крупному направлению.

## Рекомендуемый следующий документ
- `61_NEXT_MAJOR_SCOPE_AFTER_SECURITY_ACCESS.md`

Его задача:
- зафиксировать, что после heating + command-layer + security/access проект логично переводить в следующую subsystem wave;
- выбрать следующий major scope, ожидаемо — ventilation.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения