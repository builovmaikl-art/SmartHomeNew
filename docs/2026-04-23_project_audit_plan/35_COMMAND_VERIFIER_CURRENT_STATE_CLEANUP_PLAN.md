# Command Verifier Current-State Cleanup Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ переводит `34_COMMAND_VERIFIER_SEMANTICS_DECISION.md` в следующий практический шаг:
**локальный cleanup verifier semantics**.

Цель:
- привести `Command_Mismatch_Active` к симметричному current-state contract;
- не менять роль verifier как temporary migration guard;
- не затрагивать broader command-layer migration beyond verifier.

## Основание
План опирается на:
- `27_COMMAND_VERIFIER_BEHAVIOR_AUDIT.md`
- `29_COMMAND_LAYER_REMEDIATION_DECISION.md`
- `30_COMMAND_LAYER_CLEANUP_PLAN.md`
- `34_COMMAND_VERIFIER_SEMANTICS_DECISION.md`
- текущее состояние `PRG_Command_Verifier.st`

## Уже принятое базовое решение
На текущем этапе уже зафиксировано:
- verifier остается temporary migration guard;
- `Command_Mismatch_Count` — current-state / current-cycle indicator;
- `Command_Match_OK` — current-state flag;
- `Command_Mismatch_Active` должен стать current-state mismatch flag;
- текущий set-only behavior `Command_Mismatch_Active` признан transitional artifact.

## Цель cleanup-этапа
Получить такой verifier contract, при котором:
- `Command_Mismatch_Active = TRUE`, когда mismatch есть сейчас;
- `Command_Mismatch_Active = FALSE`, когда mismatch сейчас нет;
- verifier остается простым comparison-layer;
- semantics трех publish-сигналов становится внутренне однородной.

## Что именно нужно изменить

### VCP-01. Сделать `Command_Mismatch_Active` симметричным current-state flag
Текущее состояние:
- флаг устанавливается в `TRUE` при `L_Mismatch_Count > 0`;
- явного `FALSE` path в подтвержденном live root нет.

Целевое состояние:
- `Command_Mismatch_Active := (L_Mismatch_Count > 0)`
или эквивалентная симметричная форма.

Приоритет: CRITICAL.

### VCP-02. Не менять semantics остальных publish-полей
`Command_Mismatch_Count` и `Command_Match_OK` уже согласуются с current-state model.

Следовательно:
- их поведение не должно усложняться;
- не нужен дополнительный latch/memory behavior.

Приоритет: HIGH.

### VCP-03. Сохранить verifier как comparison guard, а не расширять его в alarm subsystem
На этом этапе не нужно:
- добавлять reset-owner,
- добавлять history memory,
- добавлять acknowledge logic,
- добавлять отдельную alarm semantics.

Почему:
- это уже другой слой ответственности и другой архитектурный шаг.

Приоритет: HIGH.

## Что НЕ входит в этот cleanup

### VCP-NO-01
Не менять поля сравнения между `GVL_COMMAND` и `GVL_COMMAND_SHADOW`.

### VCP-NO-02
Не менять writer/readers command-layer.

### VCP-NO-03
Не делать rename verifier signals.

### VCP-NO-04
Не удалять verifier.

### VCP-NO-05
Не объявлять migration formally closed.

## Практический safe changeset
На уровне кода cleanup должен быть минимальным:

### Предпочтительная форма
Вместо set-only pattern:
```st
IF L_Mismatch_Count > 0 THEN
    GVL_COMMAND_VERIFY.Command_Mismatch_Active := TRUE;
END_IF;
```

нужна симметричная current-state форма:
```st
GVL_COMMAND_VERIFY.Command_Mismatch_Active := (L_Mismatch_Count > 0);
```

или функционально эквивалентная запись.

## Почему changeset должен быть именно таким маленьким
- он устраняет только подтвержденную semantic проблему;
- он не меняет область сравнения;
- он не затрагивает wider migration direction;
- его легко проверить по repository state;
- он не превращает cleanup в redesign.

## Критерии успешного завершения этапа
Этап считается успешно выполненным, если:
1. `Command_Mismatch_Active` становится симметричным current-state flag;
2. verifier semantics становится внутренне однородной;
3. `Command_Mismatch_Count` и `Command_Match_OK` сохраняют текущее поведение;
4. verifier остается temporary migration guard без новой alarm-contract complexity.

## Следующий рекомендуемый документ
- `36_COMMAND_VERIFIER_CURRENT_STATE_CLEANUP_EXECUTION_PLAN.md`

Его задача:
- перевести этот cleanup-план в конкретный исполнительный шаг изменения `PRG_Command_Verifier.st`.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения