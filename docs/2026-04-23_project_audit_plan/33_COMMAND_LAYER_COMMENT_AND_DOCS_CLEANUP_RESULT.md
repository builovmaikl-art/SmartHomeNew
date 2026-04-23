# Command Layer Comment and Docs Cleanup Result

Дата фиксации: 2026-04-23

## Что было сделано
Выполнена первая documentary cleanup-волна по command-layer.

Изменения ограничены:
- исправлением устаревших inline-comments;
- выравниванием локальных semantic labels;
- удалением documented contradictions относительно текущего live root.

Логика, ownership и runtime behavior не изменялись.

## Какие файлы реально были изменены
- `GVL_COMMAND_SHADOW.gvl`
- `PRG_Command_Arbitration.st`
- `PRG_Command_Verifier.st`

## Подтвержденные результаты по состоянию репозитория

### CDR-01. Устранено главное documented contradiction в `GVL_COMMAND_SHADOW.gvl`
Удалена устаревшая формулировка:
- `Not connected to IO_Write yet.`

Вместо нее теперь зафиксировано, что:
- `GVL_COMMAND_SHADOW` является operational command layer,
- используется downstream execution consumers,
- legacy `GVL_COMMAND` еще жив вокруг bridge / compatibility flows.

Вывод:
- file-level self-description теперь согласована с live-root reality.

### CDR-02. `PRG_Command_Arbitration.st` теперь комментируется как writer shadow operational layer
Локальные comments в `PRG_Command_Arbitration.st` выровнены так, чтобы:
- reset был описан как reset shadow operational commands;
- user intent section не выглядела как временный mirror pass-through без execution-role;
- safety/system arbitration явно относилась к shadow operational layer.

Вывод:
- active writer-layer теперь описан в терминах текущей live model, а не старой переходной риторики.

### CDR-03. `PRG_Command_Verifier.st` больше не содержит лишнего `NEW`/historical wording
В verifier:
- комментарий `// NEW: gate/wicket verification` заменен на нейтральный и актуальный;
- добавлен краткий label, что mismatch count — current-cycle comparison between legacy and shadow layers.

Вывод:
- verifier comments теперь лучше согласованы с его текущей ролью как migration comparison guard.

### CDR-04. Логика не изменилась
Подтверждено по состоянию репозитория:
- branch semantics не менялись;
- writers/readers не менялись;
- `GVL_COMMAND_SHADOW` не переименовывался;
- `GVL_COMMAND` не удалялся;
- verifier behavior не менялся.

Вывод:
- cleanup носит purely documentary / non-functional характер.

## Что принципиально осталось без изменений

### CDR-STILL-01
`GVL_COMMAND_SHADOW` по-прежнему остается shadow-named layer, even though semantic promotion already зафиксирована документами.

### CDR-STILL-02
`GVL_COMMAND` по-прежнему остается legacy bridge / compatibility layer и не был затронут кодово.

### CDR-STILL-03
`PRG_Command_Verifier` по-прежнему имеет ту же runtime semantics, включая set-only behavior для `Command_Mismatch_Active` в подтвержденном live root.

## Главный практический эффект этапа
После этого cleanup command-layer уже меньше противоречит сам себе на уровне comments/docs:
- current live-root ownership map теперь лучше согласована с inline-comments;
- дальнейшие решения по verifier semantics и legacy bridge boundary можно принимать без очевидных documentary contradictions.

## Что еще не закрыто после этой волны
Этот этап не закрывает:
- verifier semantics decision;
- legacy bridge boundary cleanup;
- bridge migration для `PRG_System` / `PRG_Security`;
- formal migration close.

## Следующий рекомендуемый документ
- `34_COMMAND_VERIFIER_SEMANTICS_DECISION.md`

Его задача:
- принять явное решение по дальнейшей судьбе `Command_Mismatch_Active` и overall verifier contract.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения