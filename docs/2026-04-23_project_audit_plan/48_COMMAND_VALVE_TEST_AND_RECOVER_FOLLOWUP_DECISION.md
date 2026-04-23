# Command Valve-Test and Recover Follow-up Decision

Дата фиксации: 2026-04-23

## Назначение
Этот документ фиксирует решение после `47_COMMAND_MAINTENANCE_TEST_CLUSTER_AUDIT.md`:
нужно ли прямо сейчас углубляться в отдельный follow-up по:
- valve-test cluster,
- selective-recover cluster,

или текущей степени детализации уже достаточно для временной фиксации legacy command shortlist.

## Основание
Решение опирается на:
- `45_COMMAND_SERVICE_ADMIN_GROUP_AUDIT.md`
- `46_COMMAND_MAINTENANCE_TEST_CLUSTER_PLAN.md`
- `47_COMMAND_MAINTENANCE_TEST_CLUSTER_AUDIT.md`
- текущую общую картину command-layer cleanup wave

## Что уже подтверждено до этого решения
К текущему моменту по live root уже зафиксировано:
- dangerous-action/admin subcluster — живой и не подлежит слепой чистке;
- `CMD_Set_*_In_Service` — confirmed maintenance bridge/use-case candidate;
- `CMD_Valve_Test_*` и `CMD_*Selective_Recover` — все еще не получили столь же сильного program-level подтверждения readers/writers;
- remaining ambiguity внутри legacy `CMD_*` группы уже сужена до узкого tail.

## Варианты дальнейшего движения

### Option A. Идти сразу в deeper valve-test/recover follow-up
Это означает:
- отдельно искать workflow-level readers/writers для valve-test/recover;
- проходить maintenance/recovery логику глубже;
- пытаться довести классификацию этих полей до confirmed live-use или residue candidate.

### Option B. Временно зафиксировать текущую детализацию как достаточную
Это означает:
- признать, что для текущего этапа cleanup мы уже достаточно сузили неопределенность;
- не тратить следующую волну сразу на еще более узкий tail;
- перейти к другому high-value scope проекта, оставив valve-test/recover cluster как documented unresolved tail.

## Решение
На текущем этапе принимается:

# Decision: Option B — текущая детализация временно достаточна

## Почему принято именно это решение

### D-01. Неопределенность уже сужена до малого хвоста
До последних шагов `CMD_*` группа выглядела как большой неясный блок.

Сейчас картина уже существенно лучше:
- dangerous-action/admin cluster отделен;
- in-service maintenance cluster отделен;
- неясность осталась только вокруг valve-test/recover tail.

Вывод:
- основной аналитический выигрыш уже получен.

### D-02. Следующий deep follow-up даст локальное уточнение, но не такой же большой architectural gain
Да, отдельный valve-test/recover deep audit может дать дополнительную ясность.

Но по сравнению с уже пройденными шагами его architectural payoff заметно ниже, потому что:
- речь идет уже о narrow tail,
- а не о core ownership / execution / bridge boundary вопросах.

Вывод:
- это полезный, но уже не first-priority next step.

### D-03. Для текущего audit cycle достаточно честно зафиксировать unresolved tail
Мы уже можем формулировать состояние честно:
- shortlist очищен;
- bridge-only subset выделен;
- comparison-only residue выделен;
- dangerous-action и maintenance candidate выделены;
- valve-test/recover tail остаётся documented unresolved subset.

Вывод:
- этого достаточно, чтобы не блокировать переход к следующему более ценному scope.

## Что именно фиксируется как текущий baseline

### Confirmed stable conclusions
1. dangerous-action/admin subcluster не трогать без отдельного contract-review;
2. `CMD_Set_*_In_Service` считать maintenance-oriented live candidate;
3. `CMD_Valve_Test_*` и `CMD_*Selective_Recover` оставить как documented unresolved tail;
4. не делать blind cleanup этой узкой подгруппы.

### Temporary unresolved subset
Остаются unresolved:
- `CMD_Valve_Test_Open`
- `CMD_Valve_Test_Close`
- `CMD_Valve_Test_Confirm`
- `CMD_Water_Valve_Test_Open`
- `CMD_Water_Valve_Test_Close`
- `CMD_Water_Valve_Test_Confirm`
- `CMD_Gas_Valve_Test_Open`
- `CMD_Gas_Valve_Test_Close`
- `CMD_Gas_Valve_Test_Confirm`
- `CMD_Water_Selective_Recover`
- `CMD_Gas_Selective_Recover`

Их текущий статус:
- `documented unresolved / not safe for blind removal`.

## Что это решение НЕ означает
Это решение не означает:
- что valve-test/recover tail больше не важен;
- что он признан useless residue;
- что deep follow-up никогда не понадобится.

Это означает только:
- на текущем этапе command-layer audit его можно оставить как clearly documented unresolved subset и двигаться дальше.

## Практический эффект решения
После этого документа command-layer cleanup wave можно считать достаточно зрелой для временной остановки на текущем уровне детализации.

То есть мы уже имеем:
- operational truth for shadow layer,
- clarified verifier semantics,
- bridge boundary,
- field map,
- system/security bridge split,
- service/admin subgroup split,
- documented unresolved narrow tail.

Этого уже достаточно, чтобы:
- либо перейти к обновлению общего progress/state документации,
- либо вернуться к следующему high-value project scope вне command-layer.

## Рекомендуемый следующий документ
- `49_COMMAND_LAYER_INTERIM_STATUS.md`

Его задача:
- зафиксировать, в каком состоянии command-layer wave оставляется после текущего цикла;
- кратко свести completed / clarified / unresolved части перед переходом к следующему крупному scope.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения