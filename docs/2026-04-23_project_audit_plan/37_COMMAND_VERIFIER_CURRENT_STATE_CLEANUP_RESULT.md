# Command Verifier Current-State Cleanup Result

Дата фиксации: 2026-04-23

## Что было сделано
В `PRG_Command_Verifier.st` выполнен локальный semantic cleanup verifier contract.

Изменение ограничено одним узким участком:
- `Command_Mismatch_Active` переведен из set-only поведения в симметричную current-state форму.

## Какой участок был изменен

### Было
```st
IF L_Mismatch_Count > 0 THEN
    GVL_COMMAND_VERIFY.Command_Mismatch_Active := TRUE;
END_IF;
```

### Стало
```st
GVL_COMMAND_VERIFY.Command_Mismatch_Active := (L_Mismatch_Count > 0);
```

## Подтвержденные результаты по состоянию репозитория

### VCR-01. `Command_Mismatch_Active` больше не является set-only latch
Теперь флаг:
- `TRUE`, когда mismatch есть сейчас;
- `FALSE`, когда mismatch сейчас нет.

Вывод:
- verifier contract стал симметричным по этому сигналу.

### VCR-02. `Command_Mismatch_Count` не изменен
Подсчет `L_Mismatch_Count` и публикация:
- `GVL_COMMAND_VERIFY.Command_Mismatch_Count := L_Mismatch_Count;`

остались без изменения.

Вывод:
- count сохраняет роль current-cycle / current-state indicator.

### VCR-03. `Command_Match_OK` не изменен
Строка:
- `GVL_COMMAND_VERIFY.Command_Match_OK := (L_Mismatch_Count = 0);`

осталась без изменения.

Вывод:
- verifier по-прежнему публикует current-state match flag.

### VCR-04. Список сравниваемых сигналов не изменен
По состоянию репозитория:
- перечень сравнений между `GVL_COMMAND` и `GVL_COMMAND_SHADOW` сохранен;
- broader verifier scope не расширялся и не сокращался.

Вывод:
- changeset остался минимальным и локальным.

### VCR-05. Verifier остается temporary migration guard
После правки verifier:
- не превращен в alarm subsystem;
- не получил reset-owner/acknowledge contract;
- не был удален;
- не изменил свою общую роль в command-layer.

Вывод:
- cleanup сделал verifier semantics внутренне более однородной, но не изменил его архитектурную позицию.

## Главный практический эффект этапа
После правки verifier теперь публикует три согласованных current-state сигнала:
- `Command_Mismatch_Count`
- `Command_Match_OK`
- `Command_Mismatch_Active`

Это убирает прежнюю mixed semantics, где два сигнала были current-state, а третий — set-only latch без подтвержденного clear-path.

## Что еще не закрыто после этого этапа
Этот этап не закрывает:
- formal migration close;
- legacy bridge boundary cleanup;
- bridge migration для `PRG_System` / `PRG_Security`;
- возможное future simplification/remove decision для verifier после завершения migration.

## Следующий рекомендуемый документ
- `38_COMMAND_LEGACY_BRIDGE_BOUNDARY_PLAN.md`

Его задача:
- зафиксировать остаточную роль `GVL_COMMAND` как legacy bridge / compatibility surface;
- разложить следующую cleanup-волну вокруг `PRG_System` и `PRG_Security`.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения