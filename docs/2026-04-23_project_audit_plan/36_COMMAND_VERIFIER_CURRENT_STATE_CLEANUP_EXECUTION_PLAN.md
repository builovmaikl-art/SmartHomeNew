# Command Verifier Current-State Cleanup Execution Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ переводит `35_COMMAND_VERIFIER_CURRENT_STATE_CLEANUP_PLAN.md` в **исполнительный порядок** для минимального cleanup-изменения `PRG_Command_Verifier.st`.

Это не redesign verifier и не закрытие всей migration-модели.

Это строго:
- локальная правка current-state semantics для `Command_Mismatch_Active`;
- сохранение verifier как temporary migration guard;
- отсутствие изменений в broader command-layer behavior.

## Основание
План опирается на:
- `27_COMMAND_VERIFIER_BEHAVIOR_AUDIT.md`
- `29_COMMAND_LAYER_REMEDIATION_DECISION.md`
- `34_COMMAND_VERIFIER_SEMANTICS_DECISION.md`
- `35_COMMAND_VERIFIER_CURRENT_STATE_CLEANUP_PLAN.md`
- текущее состояние `PRG_Command_Verifier.st`

## Цель исполнения
Получить такой verifier contract, при котором:
- `Command_Mismatch_Count` остается current-state / current-cycle indicator;
- `Command_Match_OK` остается current-state flag;
- `Command_Mismatch_Active` становится симметричным current-state mismatch flag;
- verifier остается простым comparison guard без alarm-memory semantics.

## Execution Mode
- Режим исполнения: Direct Repository Modification Mode.
- Тип проверки: repository state verification.
- Ограничение: без compile/run подтверждения.

## Зафиксированные инварианты перед изменением
Во время этого этапа нельзя менять:
- список сравниваемых полей между `GVL_COMMAND` и `GVL_COMMAND_SHADOW`;
- логику подсчета `L_Mismatch_Count`;
- семантику `Command_Match_OK`;
- writers/readers command-layer;
- роль verifier как comparison-layer;
- naming глобальных полей;
- broader migration direction.

Допустим только минимальный verifier-local semantic cleanup.

## Исполнительный порядок

### Шаг VCE-01. Подтвердить текущий set-only участок в `PRG_Command_Verifier.st`
Действие:
- перечитать текущий хвост verifier;
- подтвердить, что сейчас используется set-only pattern вида:
  - `IF L_Mismatch_Count > 0 THEN`
  - `Command_Mismatch_Active := TRUE;`
  - без симметричного clear-path.

Ожидаемый результат:
- changeset вносится не по предположению, а по подтвержденному live-root состоянию.

### Шаг VCE-02. Заменить set-only pattern на current-state assignment
Действие:
- заменить текущий set-only участок на симметричную current-state запись.

Предпочтительная форма:
```st
GVL_COMMAND_VERIFY.Command_Mismatch_Active := (L_Mismatch_Count > 0);
```

Допустима эквивалентная по смыслу форма, если она не усложняет код.

Ожидаемый результат:
- `Command_Mismatch_Active` становится `TRUE` при текущем mismatch и `FALSE` при его отсутствии.

### Шаг VCE-03. Не менять остальные publish-поля
Действие:
- оставить без изменений:
  - `GVL_COMMAND_VERIFY.Command_Mismatch_Count := L_Mismatch_Count;`
  - `GVL_COMMAND_VERIFY.Command_Match_OK := (L_Mismatch_Count = 0);`

Ожидаемый результат:
- changeset остается минимальным и не расширяется без необходимости.

### Шаг VCE-04. Не добавлять alarm/reset semantics
Действие:
- не вводить reset-owner;
- не вводить acknowledge logic;
- не вводить historical memory;
- не превращать verifier в latched alarm subsystem.

Ожидаемый результат:
- verifier остается migration comparison guard с внутренне однородной current-state semantics.

### Шаг VCE-05. Выполнить repository-state verification после правки
Действие:
- перечитать итоговый `PRG_Command_Verifier.st`.

Нужно подтвердить:
1. список полей сравнения не изменился;
2. `L_Mismatch_Count` по-прежнему пересчитывается заново;
3. `Command_Match_OK` по-прежнему current-state flag;
4. `Command_Mismatch_Active` теперь симметричный current-state flag;
5. никакая другая command-layer logic не была затронута.

Ожидаемый результат:
- cleanup подтвержден как локальный semantic fix без broader redesign.

## Что считается допустимым изменением
Допустимо:
- заменить set-only участок на симметричную current-state запись;
- при необходимости минимально подправить локальный comment рядом с этим участком, если он будет вводить в заблуждение после правки.

## Что запрещено на этом шаге
Запрещено:
- менять список сравниваемых сигналов;
- менять count logic;
- менять `Command_Match_OK` semantics;
- добавлять latch/reset contract;
- удалять verifier;
- вмешиваться в `PRG_Command_Arbitration`, `PRG_IO_Write`, `PRG_Ventilation`, `PRG_System`, `PRG_Security`.

## Критерии успешного завершения execution plan
Этап считается успешно выполненным, если:
1. `Command_Mismatch_Active` больше не является set-only latch;
2. verifier semantics становится внутренне однородной;
3. changeset остается минимальным и локальным;
4. broader migration model не изменяется.

## Следующий документ после исполнения
После выполнения этого плана должен появиться:
- `37_COMMAND_VERIFIER_CURRENT_STATE_CLEANUP_RESULT.md`

В нем нужно будет зафиксировать:
- какая именно строка/участок был изменен;
- что verifier contract теперь стал current-state consistent;
- что осталось следующей задачей в command-layer cleanup wave.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения