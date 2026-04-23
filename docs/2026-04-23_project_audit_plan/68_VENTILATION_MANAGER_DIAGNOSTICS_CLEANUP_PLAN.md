# Ventilation Manager Diagnostics Cleanup Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ переводит `67_VENTILATION_FIX_DIRECTION_DECISION.md` в следующий практический шаг:
**локальный cleanup-plan вокруг manager-side diagnostics/global-state ownership в вентиляционном кластере**.

Цель:
- сузить remediation scope до подтвержденного smell;
- не трогать clean request/output paths без необходимости;
- подготовить безопасную следующую волну ventilation cleanup без premature redesign.

## Основание
План опирается на:
- `64_VENTILATION_MANAGER_CONTRACT_AUDIT.md`
- `65_VENTILATION_WRAPPER_VS_MANAGER_BOUNDARY_AUDIT.md`
- `66_VENTILATION_OWNERSHIP_STATUS_DIAGNOSTICS_AUDIT.md`
- `67_VENTILATION_FIX_DIRECTION_DECISION.md`

## Уже принятое базовое решение
К текущему моменту уже зафиксировано:
- `PRG_Ventilation.st` не является текущим problem-center;
- request path через `GVL_COMMAND_SHADOW` clean;
- main outputs path через declared manager outputs clean;
- основной confirmed smell сосредоточен в direct global writes внутри `FB_Ventilation_System_Manager.st`.

Следовательно, ventilation cleanup должен идти не в broad refactor, а в узкий manager-side diagnostics ownership scope.

## Цель cleanup-этапа
Привести ventilation cluster к более чистой ownership boundary, при которой:
- diagnostics/degraded semantics становятся более явными;
- direct global-state writes внутри manager переоцениваются как intentional или undesirable;
- requests и нормальные outputs не затрагиваются без подтвержденной причины.

## Что именно входит в cleanup первой волны

### VMDC-01. Разобрать ownership `G_Ventilation_IO_Fault`
Нужно:
- зафиксировать текущую роль этого флага;
- определить, должен ли он оставаться direct manager write;
- или должен публиковаться через более явный boundary/output contract.

Почему это first priority:
- это подтвержденный direct global write в active live code.

Приоритет: HIGH.

### VMDC-02. Разобрать ownership `G_Ventilation_Subsystem_Degraded`
Нужно:
- зафиксировать текущую роль этого флага;
- определить, является ли manager правильным owner его публикации;
- или degraded state должен проецироваться наружу более явно.

Почему это first priority:
- это второй подтвержденный direct global write и часть policy ownership concentration.

Приоритет: HIGH.

### VMDC-03. Отделить diagnostics ownership от normal output ownership
Нужно:
- явно развести clean contract outputs:
  - `VO_Supply_Fans`
  - `VO_Exhaust_Fans`
  - `VO_Heater_Power`
  - `VO_Status_Msg`
- и smell-prone diagnostics writes в globals.

Почему это важно:
- иначе ventilation manager продолжит восприниматься как единый неразделенный super-block.

Приоритет: HIGH.

### VMDC-04. Не трогать clean paths без новых оснований
Нужно зафиксировать, что на этой волне не трогаются:
- request ingestion path;
- fan output publication path;
- heater power output path;
- normal status message output path.

Почему это важно:
- cleanup должен оставаться точечным и управляемым.

Приоритет: HIGH.

## Что пока НЕ входит в cleanup первой волны

### VMDC-NO-01
Не делать wrapper refactor `PRG_Ventilation.st`.

### VMDC-NO-02
Не декомпозировать `FB_Ventilation_System_Manager.st` на несколько блоков.

### VMDC-NO-03
Не менять request intake из `GVL_COMMAND_SHADOW`.

### VMDC-NO-04
Не менять нормальные manager outputs только ради симметрии.

### VMDC-NO-05
Не поднимать ventilation wave до full subsystem redesign.

## Очередность cleanup-работ

### Этап VCP-1. Diagnostics ownership decision
Результат:
- станет ясно, считать ли direct global writes acceptable transitional pattern или cleanup target.

### Этап VCP-2. Boundary cleanup plan for diagnostics flags
Результат:
- появится минимальный changeset plan вокруг diagnostics/degraded publication.

### Этап VCP-3. Только после этого решать, нужен ли реальный code cleanup
Результат:
- remediation останется пропорциональной подтвержденной проблеме.

## Критерии успеха cleanup-плана
Этап считается правильно запущенным, если:
1. ventilation cleanup не уходит в broad redesign;
2. clean request/output paths не затрагиваются без нужды;
3. diagnostics ownership smell вынесен в отдельный explicit scope;
4. следующий шаг становится достаточно узким для безопасного code-level решения.

## Практический следующий документ
- `69_VENTILATION_MANAGER_DIAGNOSTICS_OWNERSHIP_DECISION.md`

Его задача:
- принять явное решение по судьбе direct writes:
  - оставить как допустимый pattern,
  - или признать их cleanup target для следующего минимального changeset.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения