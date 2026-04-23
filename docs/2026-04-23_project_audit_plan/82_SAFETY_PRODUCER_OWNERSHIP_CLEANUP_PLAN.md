# Safety Producer Ownership Cleanup Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ переводит `81_SAFETY_FIX_DIRECTION_DECISION.md` в следующий практический шаг:
**локальный cleanup-plan вокруг producer-side ownership concentration в `PRG_Safety.st`**.

Цель:
- сузить remediation scope до подтвержденного smell;
- не ломать already-working publication boundary через `GVL_INTENT_SAFETY`;
- подготовить безопасную следующую волну safety cleanup без premature redesign.

## Основание
План опирается на:
- `78_SAFETY_OWNERSHIP_AND_PUBLICATION_AUDIT.md`
- `79_SAFETY_CROSS_SUBSYSTEM_DEPENDENCY_AUDIT.md`
- `80_SAFETY_BOUNDARY_ARCHITECTURE_INTERPRETATION.md`
- `81_SAFETY_FIX_DIRECTION_DECISION.md`

## Уже принятое базовое решение
К текущему моменту уже зафиксировано:
- `GVL_INTENT_SAFETY` не является текущим problem-center;
- publication boundary safety layer meaningful and operationally grounded;
- главный confirmed smell сосредоточен в ownership concentration inside `PRG_Safety.st`;
- broad safety redesign на текущем этапе не требуется.

Следовательно, safety cleanup должен идти не в dismantling boundary model, а в узкий producer-side ownership scope.

## Цель cleanup-этапа
Привести safety cluster к более чистой producer boundary, при которой:
- semantic/interlock/test-flow ownership inside `PRG_Safety.st` становится более явной и лучше ограниченной;
- publication model через `GVL_INTENT_SAFETY` сохраняется;
- cross-subsystem dependency-chain не ломается;
- scope остается локальным и управляемым.

## Что именно входит в cleanup первой волны

### SPCP-01. Разобрать core safety semantics vs operator/test semantics
Нужно:
- отделить в рамках анализа и дальнейшего plan-а
  - core hazard/interlock projection,
  - operator/test/recover flows.

Почему это first priority:
- сейчас именно смешение этих двух семантических слоев делает `PRG_Safety.st` тяжелым producer block.

Приоритет: HIGH.

### SPCP-02. Разобрать lock-force and access-related safety semantics как отдельный sub-scope
Нужно:
- отдельно зафиксировать role `I_Lock_1_Force_Open`, `I_Lock_1_Force_Close_Block`, `I_Lock_2_Force_Open`, `I_Lock_2_Force_Close_Block`;
- понять, должны ли они естественно оставаться в общем safety producer scope или являются отдельным safety-access coupling subset.

Почему это важно:
- access/lock semantics добавляют cross-domain ownership concentration внутри одного producer program.

Приоритет: HIGH.

### SPCP-03. Разобрать producer-heavier tail внутри publication surface
Нужно:
- отделить intent fields с хорошо подтвержденным downstream-consumer path
от полей, для которых checked scope пока не дал столь же явного consumer confirmation.

Почему это важно:
- часть тяжести `PRG_Safety.st` может быть justified,
- а часть может быть producer-heavier publication tail.

Приоритет: HIGH.

### SPCP-04. Не трогать already-confirmed healthy publication model
Нужно зафиксировать, что на этой волне не трогаются:
- publication through `GVL_INTENT_SAFETY` как таковая;
- downstream consumption through `PRG_Command_Arbitration.st`;
- direct subsystem consumers safety state, если нет отдельного defect.

Почему это важно:
- cleanup должен быть focused on ownership concentration, not on dismantling a working boundary.

Приоритет: HIGH.

## Что пока НЕ входит в cleanup первой волны

### SPCP-NO-01
Не делать broad redesign safety architecture.

### SPCP-NO-02
Не перепридумывать `GVL_INTENT_SAFETY` model.

### SPCP-NO-03
Не менять `PRG_Command_Arbitration.st` без отдельного подтвержденного дефекта.

### SPCP-NO-04
Не менять `PRG_Heating.st`, `PRG_Ventilation.st`, `PRG_Security.st` только из-за существования safety dependencies.

### SPCP-NO-05
Не дробить `PRG_Safety.st` на новые POUs до более узкого локального решения.

## Очередность cleanup-работ

### Этап SCP-1. Ownership segmentation inside `PRG_Safety.st`
Результат:
- появится более точная карта того, какие части producer logic являются:
  - core safety semantics,
  - test/recover workflow semantics,
  - access/lock coupling semantics,
  - producer-heavier publication tail.

### Этап SCP-2. Decide which subset is the best minimal cleanup target
Результат:
- из нескольких ownership clusters будет выбран один наиболее узкий и ценный cleanup subset.

### Этап SCP-3. Только после этого решать, нужен ли реальный code cleanup
Результат:
- remediation останется пропорциональной подтвержденной проблеме.

## Критерии успеха cleanup-плана
Этап считается правильно запущенным, если:
1. safety cleanup не уходит в broad redesign;
2. working publication boundary сохраняется;
3. ownership concentration smell вынесен в explicit sub-scopes;
4. следующий шаг становится достаточно узким для безопасного code-level решения.

## Практический следующий документ
- `83_SAFETY_PRODUCER_OWNERSHIP_SEGMENTATION.md`

Его задача:
- разложить `PRG_Safety.st` по ownership-clusters;
- подготовить выбор наиболее подходящего minimal cleanup target.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения