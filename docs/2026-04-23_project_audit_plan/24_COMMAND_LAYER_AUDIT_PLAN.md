# Command Layer Audit Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ открывает следующий цикл аудита после стабилизации heating cluster:
**command-layer migration audit**.

Цель:
- зафиксировать область анализа;
- определить главные architectural risks command-layer;
- разложить следующий аудит на управляемые шаги;
- не смешивать command-layer cleanup с subsystem-specific работами.

## Почему command-layer выбран следующим
По текущему состоянию репозитория это самый cross-cutting слой из оставшихся.

Он влияет одновременно на:
- arbitration ownership;
- legacy vs shadow command model;
- physical IO write path;
- verifier semantics;
- subsystem request publication и downstream actuation.

Если этот слой оставить переходным, последующие audits по security/access, ventilation и другим подсистемам будут опираться на не до конца устойчивую command-модель.

## Область command-layer audit

### Основные файлы
- `PRG_Command_Arbitration.st`
- `PRG_Command_Verifier.st`
- `GVL_COMMAND.gvl`
- `GVL_COMMAND_SHADOW.gvl`

### Связанные live-root точки
- `PRG_IO_Write.st`
- `PRG_Ventilation.st`
- `PRG_System.st`
- `MAIN.st`

### При необходимости
- другие файлы, где legacy command layer и shadow layer реально читаются или пишутся.

## Уже известные риски, которые нужно перепроверить по live root

### CL-01. Незавершенная migration semantics между legacy и shadow layer
Ранее уже были признаки, что:
- `GVL_COMMAND_SHADOW` реально используется в live root;
- комментарии и фактическая роль shadow layer расходятся;
- migration еще не доведена до полностью непротиворечивого состояния.

### CL-02. Возможное залипание mismatch-сигнала в verifier
Ранее уже был признак, что `PRG_Command_Verifier` может выставлять mismatch-флаг без явного симметричного сброса.

Этот вывод нужно подтвердить заново по текущему живому коду.

### CL-03. Legacy/shadow ownership может быть не до конца формализован
Нужно явно ответить:
- кто owner для итоговой operational command model;
- что считается source of truth — legacy layer или shadow layer;
- какова роль verifier после завершения migration.

### CL-04. Physical IO write path может опираться на layer, который еще документально не закреплен
Если `PRG_IO_Write` уже пишет из shadow layer, а документы/комментарии проекта еще описывают старую модель, это создает архитектурную двусмысленность.

## Цель следующего аудита
Привести command-layer к такой картине, где можно однозначно ответить на вопросы:
1. кто пишет legacy commands;
2. кто пишет shadow commands;
3. кто читает shadow commands как operational truth;
4. зачем нужен verifier после текущего этапа миграции;
5. какой слой должен остаться итоговым owner-слоем;
6. какие старые comments/docs нужно будет вычистить после подтверждения live-model.

## Порядок аудита

### Этап C-A1. Call-path and ownership map
Область:
- `MAIN.st`
- `PRG_Command_Arbitration.st`
- `PRG_Command_Verifier.st`
- `PRG_IO_Write.st`

Задача:
- восстановить живую command-chain сверху вниз;
- зафиксировать, где command layer реально входит в call order;
- определить, как flows проходят от arbitration до physical outputs.

Ожидаемый результат:
- первичная live ownership map command-layer.

### Этап C-A2. Legacy vs Shadow semantic audit
Область:
- `GVL_COMMAND.gvl`
- `GVL_COMMAND_SHADOW.gvl`
- связанные readers/writers

Задача:
- определить, какая часть legacy layer еще жива;
- определить, является ли shadow layer уже operational source of truth;
- зафиксировать переходные и устаревшие элементы.

Ожидаемый результат:
- semantic map legacy/shadow model.

### Этап C-A3. Verifier behavior audit
Область:
- `PRG_Command_Verifier.st`
- mismatch flags / counters / reset semantics

Задача:
- проверить, как именно verifier должен работать в текущей migration model;
- подтвердить или опровергнуть риск залипания mismatch-состояния;
- понять, нужен ли verifier как временный guard или как постоянный слой наблюдения.

Ожидаемый результат:
- решение по текущей роли verifier.

### Этап C-A4. Downstream consumers audit
Область:
- `PRG_IO_Write.st`
- `PRG_Ventilation.st`
- другие живые consumers command shadow

Задача:
- определить, какие подсистемы уже читают shadow layer как real operational input;
- понять, есть ли смешанная модель, где часть downstream еще сидит на legacy layer.

Ожидаемый результат:
- карта downstream command consumers.

### Этап C-A5. Cleanup / migration decision
Задача:
- на основе C-A1..C-A4 принять решение:
  - дожимать ли migration до полного dominance shadow layer;
  - что делать с legacy layer;
  - как упростить verifier semantics;
  - какие docs/comments устарели и должны быть обновлены.

Ожидаемый результат:
- command-layer remediation plan.

## Что пока НЕ делать
- не менять subsystem-specific heating/ventilation logic без прямой связи с command-layer;
- не переписывать `MAIN.st` без подтвержденного ownership-основания;
- не чистить старые docs раньше, чем подтверждена фактическая live-model;
- не смешивать command-layer migration audit с security/access interface fixes.

## Практический следующий документ
- `25_COMMAND_LAYER_LIVE_OWNERSHIP_AUDIT.md`

Его задача:
- открыть этап C-A1;
- пройти live command-chain сверху вниз;
- зафиксировать реальных writers/readers и точки ownership.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения