# Command Layer Live Ownership Audit

Дата фиксации: 2026-04-23

## Назначение
Этот документ открывает этап C-A1 из `24_COMMAND_LAYER_AUDIT_PLAN.md`:
**live command-chain ownership audit**.

Цель:
- пройти command-layer сверху вниз по живому корню репозитория;
- зафиксировать реальных writers/readers;
- определить, какой слой уже является operational truth в текущем live root.

## Область аудита
- `MAIN.st`
- `PRG_Command_Arbitration.st`
- `PRG_Command_Verifier.st`
- `PRG_IO_Write.st`
- `PRG_Ventilation.st`
- `GVL_COMMAND.gvl`
- `GVL_COMMAND_SHADOW.gvl`

## Главный вывод этапа C-A1
По текущему live root command-chain уже фактически построена вокруг `GVL_COMMAND_SHADOW` как operational downstream layer.

При этом `GVL_COMMAND` в рамках подтвержденной command-chain выглядит не как основной текущий downstream source of truth, а как legacy-comparison layer, который verifier все еще использует для сопоставления.

То есть migration уже зашла достаточно далеко, чтобы shadow layer был реальным operational path, но ownership и документация вокруг него еще не доведены до формально непротиворечивого состояния.

## Live command-chain сверху вниз

### CLA-01. Место command-layer в верхнем call order
В `MAIN.st` текущий вызовной порядок таков:
- `PRG_Policy()`
- `PRG_Command_Arbitration()`
- `PRG_Command_Verifier()`
- subsystem layers
- `PRG_IO_Write()`

Вывод:
- command arbitration и verifier уже встроены в основной live loop до downstream subsystem/IO write path;
- это подтверждает, что command-layer является живым core-layer, а не побочным экспериментальным хвостом.

### CLA-02. Реальный writer для shadow layer
`PRG_Command_Arbitration.st` в начале цикла:
- сбрасывает поля `GVL_COMMAND_SHADOW`;
- затем заполняет их из `GVL_INTENT_USER`, `GVL_INTENT_SAFETY`, `GVL_INTENT_SYSTEM`.

Подтвержденные operational outputs этого слоя:
- газовый клапан,
- stop/boost/airflow requests вентиляции,
- водяные клапаны,
- locks/gate/wicket.

Вывод:
- в текущем live root именно `PRG_Command_Arbitration` является подтвержденным активным writer-слоем для `GVL_COMMAND_SHADOW`.

### CLA-03. Реальные подтвержденные readers shadow layer
Подтверждено по live root:
- `PRG_IO_Write.st` пишет в физические выходы water/gas/access напрямую из `GVL_COMMAND_SHADOW`;
- `PRG_Ventilation.st` читает ventilation requests напрямую из `GVL_COMMAND_SHADOW` и использует их как входы в `FB_Ventilation_System_Manager`.

Вывод:
- `GVL_COMMAND_SHADOW` уже является operational input layer как минимум для:
  - physical IO write path,
  - ventilation command consumption.

### CLA-04. Роль verifier в текущей цепочке
`PRG_Command_Verifier.st` не пишет operational commands downstream.

Он:
- сравнивает поля `GVL_COMMAND` и `GVL_COMMAND_SHADOW`;
- считает mismatch count;
- выставляет `Command_Match_OK`;
- активирует `Command_Mismatch_Active` при расхождении.

Вывод:
- verifier в подтвержденной live command-chain является наблюдающим/сравнивающим слоем;
- он не выглядит owner-слоем operational commands.

### CLA-05. Роль legacy `GVL_COMMAND` в текущей подтвержденной цепочке
В пределах подтвержденной live chain:
- `GVL_COMMAND` используется verifier-слоем как объект сравнения;
- не подтверждено, что `PRG_IO_Write` использует `GVL_COMMAND` как текущий source для water/gas/access outputs;
- не подтверждено, что `PRG_Ventilation` использует `GVL_COMMAND` как текущий operational input.

Вывод:
- в пределах уже подтвержденной цепочки `GVL_COMMAND` выглядит как legacy comparison layer, а не как активный downstream owner-layer.

## Ownership-карта по состоянию live root

### Writers
#### W-01
`PRG_Command_Arbitration` -> `GVL_COMMAND_SHADOW`

Статус:
- confirmed active writer.

### Readers
#### R-01
`PRG_Command_Verifier` reads:
- `GVL_COMMAND`
- `GVL_COMMAND_SHADOW`

Статус:
- confirmed comparison reader.

#### R-02
`PRG_IO_Write` reads:
- `GVL_COMMAND_SHADOW`

Статус:
- confirmed operational downstream reader.

#### R-03
`PRG_Ventilation` reads:
- `GVL_COMMAND_SHADOW`

Статус:
- confirmed subsystem downstream reader.

## Подтвержденные проблемные точки уже на этом этапе

### CLA-ISSUE-01. Комментарий в `GVL_COMMAND_SHADOW.gvl` уже не соответствует live root
В файле по-прежнему записано:
- `Not connected to IO_Write yet.`

Но live root подтверждает обратное:
- `PRG_IO_Write` уже пишет ряд физических выходов именно из `GVL_COMMAND_SHADOW`.

Вывод:
- документация прямо внутри кода уже устарела относительно фактической operational model.

### CLA-ISSUE-02. Shadow layer operationally живой, но formally migration semantics еще не закреплены
Даже при том, что `GVL_COMMAND_SHADOW` уже используется downstream, verifier продолжает сравнивать его с legacy `GVL_COMMAND`.

Вывод:
- текущая модель выглядит как переходная:
  - operational truth уже смещен в shadow;
  - legacy layer и verifier semantics еще не доведены до окончательного решения.

### CLA-ISSUE-03. В arbitration есть подтвержденный незавершенный water-zone участок
В `PRG_Command_Arbitration.st` цикл по `I_Water_Zone_Close_Required[1..32]` содержит пустое действие.

Вывод:
- часть command-layer migration действительно не завершена даже внутри active writer-layer.

### CLA-ISSUE-04. Verifier mismatch-latch риск остается активным кандидатом на подтверждение
На текущем этапе уже видно:
- `Command_Mismatch_Active := TRUE` при mismatch;
- явного симметричного сброса в показанном коде нет.

Вывод:
- этот риск остается подтверждаемым кандидатом для следующего verifier audit.

## Практическое решение этапа C-A1
На текущем этапе принимается как рабочий live-root факт:

### Ownership decision for current audit baseline
`GVL_COMMAND_SHADOW` рассматривается как текущий **operational downstream command layer**.

Это не означает, что migration уже formally closed.

Это означает только, что:
- при следующих command-layer решениях нельзя притворяться, будто legacy `GVL_COMMAND` остается главным downstream source of truth для подтвержденной цепочки.

## Что остается непокрытым этим этапом
Этот документ еще не решает:
- нужна ли окончательная ликвидация legacy-layer;
- должен ли verifier остаться постоянным слоем;
- кто еще кроме уже подтвержденных readers/writers использует `GVL_COMMAND` или `GVL_COMMAND_SHADOW` вне этой базовой цепочки;
- как formalize migration end-state.

## Следующий рекомендуемый документ
- `26_COMMAND_LAYER_LEGACY_VS_SHADOW_SEMANTIC_AUDIT.md`

Его задача:
- открыть этап C-A2;
- определить semantic end-state для legacy vs shadow model;
- зафиксировать, что должно остаться временным, а что должно стать финальным source of truth.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения