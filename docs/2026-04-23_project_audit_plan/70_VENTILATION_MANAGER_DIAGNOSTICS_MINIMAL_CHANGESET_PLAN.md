# Ventilation Manager Diagnostics Minimal Changeset Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ переводит `69_VENTILATION_MANAGER_DIAGNOSTICS_OWNERSHIP_DECISION.md` в следующий практический шаг:
**минимальный changeset plan для manager-side diagnostics ownership cleanup**.

Цель:
- уменьшить direct global-state ownership внутри `FB_Ventilation_System_Manager.st`;
- не трогать clean request/output paths;
- не превращать локальный cleanup в ventilation-wide redesign.

## Основание
План опирается на:
- `66_VENTILATION_OWNERSHIP_STATUS_DIAGNOSTICS_AUDIT.md`
- `67_VENTILATION_FIX_DIRECTION_DECISION.md`
- `68_VENTILATION_MANAGER_DIAGNOSTICS_CLEANUP_PLAN.md`
- `69_VENTILATION_MANAGER_DIAGNOSTICS_OWNERSHIP_DECISION.md`
- текущее состояние `PRG_Ventilation.st`
- текущее состояние `FB_Ventilation_System_Manager.st`

## Уже принятое базовое решение
К текущему моменту уже зафиксировано:
- `GVL_STATE.G_Ventilation_IO_Fault` внутри manager — explicit cleanup target;
- `GVL_STATE.G_Ventilation_Subsystem_Degraded` внутри manager — explicit cleanup target;
- request ingestion path clean и не должен меняться;
- main outputs path clean и не должен меняться;
- broader manager decomposition на этом этапе не требуется.

Следовательно, правильный следующий шаг — минимальный changeset, который выведет diagnostics publication из direct global writes в более явную boundary publication path.

## Цель changeset-этапа
Получить такую форму ventilation diagnostics publication, при которой:
- manager перестает напрямую мутировать ventilation diagnostics flags в `GVL_STATE`;
- diagnostics/degraded state становятся частью более явного output/publication boundary;
- runtime behavior меняется минимально или не меняется вовсе;
- scope остается локальным и безопасным.

## Предпочтительное направление changeset

### VMCP-01. Вынести diagnostics flags в declared outputs manager-блока
Предпочтительный путь:
- добавить в `FB_Ventilation_System_Manager.st` явные outputs, например по смыслу:
  - ventilation IO fault flag,
  - ventilation degraded flag;
- перестать писать их напрямую в `GVL_STATE` внутри manager;
- публиковать их наружу через `PRG_Ventilation.st`.

Почему это предпочтительно:
- это сохраняет manager как источник диагностики,
- но делает publication path явным и boundary-bounded.

## Минимальная целевая модель publication boundary

### Внутри manager
Manager должен:
- вычислять diagnostics/degraded состояние;
- отдавать его через явные `VO_*` outputs;
- не трогать `GVL_STATE` напрямую по этим двум полям.

### Внутри wrapper
`PRG_Ventilation.st` должен:
- принять новые `VO_*` diagnostics outputs;
- опубликовать их в:
  - `GVL_STATE.G_Ventilation_IO_Fault`
  - `GVL_STATE.G_Ventilation_Subsystem_Degraded`

Почему wrapper:
- именно wrapper уже выполняет роль boundary-point для вентиляционного кластера;
- это согласуется с тем, как уже публикуются fan outputs, heater power и status message.

## Что именно должно попасть в minimal changeset

### VMCP-02. Добавить два diagnostics outputs в `FB_Ventilation_System_Manager.st`
Нужно добавить outputs по смыслу для:
- IO fault
- subsystem degraded

Точные имена нужно выбрать в одном стиле с остальным block contract.

Критерий выбора имен:
- они должны быть семантически ясными;
- не конфликтовать с уже существующими `VO_*` outputs;
- явно обозначать diagnostics/state nature сигналов.

### VMCP-03. Заменить direct writes внутри manager на локальную output assignment logic
Нужно:
- убрать direct mutation этих двух полей в `GVL_STATE` из manager;
- вычислять те же состояния локально и публиковать через новые outputs.

### VMCP-04. Добавить publication в `PRG_Ventilation.st`
Нужно:
- расширить call-site `fbVentilationManager(...)` новыми `VO_*` bindings;
- в wrapper проецировать эти outputs в соответствующие поля `GVL_STATE`.

## Что НЕ должно входить в minimal changeset

### VMCP-NO-01
Не менять request ingestion path из `GVL_COMMAND_SHADOW`.

### VMCP-NO-02
Не менять fan output path.

### VMCP-NO-03
Не менять heater power output path.

### VMCP-NO-04
Не менять `VO_Status_Msg` semantics.

### VMCP-NO-05
Не менять scenario/policy/control logic за пределами diagnostics publication.

### VMCP-NO-06
Не дробить manager на несколько блоков.

## Почему changeset должен быть именно таким узким
- он бьет точно в подтвержденный ownership smell;
- он улучшает boundary clarity;
- он не ломает already-clean paths;
- его можно проверить repository-state verification without compile/run;
- он не раздувает ventilation wave в redesign project.

## Критерии успешного завершения этапа
Этап считается успешно подготовленным, если:
1. direct writes по двум diagnostics flags больше не считаются единственным вариантом;
2. proposed publication path становится explicit and wrapper-bounded;
3. minimal changeset остается локальным;
4. ventilation cleanup сохраняет proportional scope.

## Практический следующий документ
- `71_VENTILATION_MANAGER_DIAGNOSTICS_OUTPUT_CONTRACT_DECISION.md`

Его задача:
- зафиксировать точный target contract для новых diagnostics outputs manager-блока;
- после этого можно будет переходить к execution plan и реальной правке.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения