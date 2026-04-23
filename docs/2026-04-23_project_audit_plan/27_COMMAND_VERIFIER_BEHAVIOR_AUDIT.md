# Command Verifier Behavior Audit

Дата фиксации: 2026-04-23

## Назначение
Этот документ открывает этап C-A3 из `24_COMMAND_LAYER_AUDIT_PLAN.md`:
**verifier behavior audit**.

Цель:
- зафиксировать текущую роль `PRG_Command_Verifier` в live root;
- проверить mismatch semantics, включая set/reset behavior;
- определить, является ли verifier временным migration-guard или постоянным monitoring-layer.

## Проверенные объекты
- `PRG_Command_Verifier.st`
- `GVL_COMMAND_VERIFY.gvl`
- live-root search по `Command_Mismatch_Active`

## Главный вывод
В текущем live root `PRG_Command_Verifier` ведет себя как **migration comparison guard**, а не как полноценный завершенный monitoring-layer.

Причина:
- он сравнивает legacy `GVL_COMMAND` и `GVL_COMMAND_SHADOW`;
- считает текущий mismatch count заново каждый цикл;
- выставляет `Command_Match_OK` по текущему count;
- но `Command_Mismatch_Active` в подтвержденном live root выглядит как latch-like флаг без явного симметричного сброса.

Вывод:
- verifier сейчас семантически больше похож на временный transition guard;
- его поведение еще не доведено до полностью законченной и самодокументируемой модели.

## Что делает verifier в текущем live root

### V-01. Сравнение legacy и shadow layer
`PRG_Command_Verifier` выполняет попарное сравнение полей:
- gas / boiler / ventilation requests,
- water valves,
- lock/gate/wicket commands
между:
- `GVL_COMMAND`
- `GVL_COMMAND_SHADOW`

Вывод:
- verifier не производит новых команд;
- он является исключительно comparison-layer.

### V-02. Текущий mismatch count пересчитывается каждый цикл
В начале программы:
- `L_Mismatch_Count := 0;`

Затем счетчик увеличивается на каждом несовпадении.

Вывод:
- `Command_Mismatch_Count` отражает текущую observed divergence за цикл;
- это поведение не является latch-like.

### V-03. `Command_Match_OK` является текущим derived-status флагом
В конце программы:
- `GVL_COMMAND_VERIFY.Command_Match_OK := (L_Mismatch_Count = 0);`

Вывод:
- этот флаг корректно ведет себя как current-state indicator;
- он симметрично отражает текущее состояние совпадения/расхождения.

### V-04. `Command_Mismatch_Active` выглядит как latch-like flag без clear path
В live root подтверждено:
- при `L_Mismatch_Count > 0` выполняется:
  - `GVL_COMMAND_VERIFY.Command_Mismatch_Active := TRUE;`
- явного присваивания `FALSE` в `PRG_Command_Verifier.st` нет;
- по live-root search отдельного clear-path для `Command_Mismatch_Active` не подтверждено.

Вывод:
- этот флаг сейчас выглядит как set-only latch в рамках подтвержденного live root;
- если это было задумано как текущий status-flag, то реализация неполная;
- если это было задумано как latched alarm, то в проекте не зафиксирован явный reset-contract.

## Интерпретация текущей semantics

### VB-01. Verifier не является owner operational truth
Operational truth уже смещен в `GVL_COMMAND_SHADOW`, а verifier только наблюдает расхождение.

Вывод:
- verifier не управляет командной моделью;
- он служит контрольным guard-слоем migration-фазы.

### VB-02. Verifier сейчас не дотягивает до clean monitoring contract
Для чистого monitoring-layer ожидалось бы одно из двух:
1. либо все флаги отражают **текущее** состояние симметрично;
2. либо latched alarm semantics явно оформлена через reset policy.

В текущем live root наблюдается смешанная картина:
- `Command_Mismatch_Count` и `Command_Match_OK` ведут себя как current-state indicators;
- `Command_Mismatch_Active` ведет себя как set-only latch.

Вывод:
- contract verifier сейчас внутренне неоднороден.

### VB-03. Это подтверждает переходный характер verifier
Такая неоднородность хорошо согласуется именно с migration-stage utility layer:
- слой добавлен, чтобы видеть divergences;
- но его semantics еще не доведена до финального стабильного режима.

## Подтвержденные проблемные точки

### VB-ISSUE-01. Set-only behavior для `Command_Mismatch_Active`
Подтверждено по live root:
- `TRUE` устанавливается;
- `FALSE` в подтвержденном коде не возвращается.

Риск:
- флаг может остаться активным даже после исчезновения mismatch.

### VB-ISSUE-02. Неявный reset contract
В проекте не зафиксировано, кто и когда должен сбрасывать `Command_Mismatch_Active`, если latch semantics задумана намеренно.

Риск:
- оператор/разработчик не понимает, является ли это тревогой, текущим статусом или историческим маркером ошибки.

### VB-ISSUE-03. Mixed semantics внутри одного verify-layer
Сейчас в одном и том же блоке одновременно существуют:
- current-state count,
- current-state OK flag,
- latch-like active flag.

Риск:
- downstream interpretation verifier-state становится неоднозначной.

## Практическое interim-решение для текущего audit baseline
На текущем этапе verifier следует считать:

### Current baseline classification
**temporary migration guard / comparison layer**

а не fully finalized monitoring subsystem.

Это рабочее baseline-решение означает:
- verifier нельзя пока считать завершенным и архитектурно стабилизированным слоем;
- его semantics требует отдельного cleanup decision.

## Какие варианты решения просматриваются дальше

### Option A. Сделать verifier полностью current-state based
Тогда нужно:
- симметрично сбрасывать `Command_Mismatch_Active := FALSE`, когда mismatch исчез;
- оставить verifier как обычный real-time monitoring layer.

### Option B. Формализовать verifier как latched alarm layer
Тогда нужно:
- явно определить reset-owner и reset-condition;
- документировать `Command_Mismatch_Active` как latched flag, а не как current-state flag.

### Option C. Упростить verifier после formal migration close
Если migration будет признана завершенной, verifier может:
- быть удален,
- или остаться только как временный diagnostic mode.

## Что пока не решает этот документ
Этот документ еще не выбирает окончательно между Option A / B / C.

Он только фиксирует, что:
- текущая semantics verifier неполна или переходна;
- без отдельного решения этот слой остается архитектурно неоднозначным.

## Следующий рекомендуемый документ
- `28_COMMAND_DOWNSTREAM_CONSUMERS_AUDIT.md`

Его задача:
- открыть этап C-A4;
- зафиксировать все downstream consumers shadow/legacy command model;
- подтвердить, насколько глубоко shadow layer уже доминирует в live root beyond IO_Write and Ventilation.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения