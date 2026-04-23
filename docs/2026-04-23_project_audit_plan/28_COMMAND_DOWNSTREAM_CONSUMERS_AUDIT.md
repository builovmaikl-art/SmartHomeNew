# Command Downstream Consumers Audit

Дата фиксации: 2026-04-23

## Назначение
Этот документ открывает этап C-A4 из `24_COMMAND_LAYER_AUDIT_PLAN.md`:
**downstream consumers audit**.

Цель:
- определить, какие live-root consumers уже читают `GVL_COMMAND_SHADOW` как operational input;
- определить, где `GVL_COMMAND` еще остается живым слоем;
- отделить execution-consumers от upstream bridges, compatibility tails и comparison layers.

## Проверенные объекты
- `PRG_IO_Write.st`
- `PRG_Ventilation.st`
- `PRG_Command_Verifier.st`
- `PRG_System.st`
- `PRG_Security.st`
- live-root search по `GVL_COMMAND_SHADOW`
- live-root search по `GVL_COMMAND`

## Главный вывод
В текущем live root уже сформировалась **асимметричная mixed model**:

- **downstream execution-consumers** уже читают `GVL_COMMAND_SHADOW`;
- **legacy `GVL_COMMAND`** остается живым, но главным образом в system/security/gateway bridges и comparison semantics;
- то есть shadow layer уже доминирует именно в execution path, но проект в целом еще не избавился от legacy command surface.

## Подтвержденные consumers shadow layer

### DCA-01. `PRG_IO_Write` — physical execution consumer
`PRG_IO_Write.st` подтвержденно читает `GVL_COMMAND_SHADOW` и пишет в физические выходы water/gas/access.

Semantic role:
- physical actuation consumer.

Вывод:
- в physical IO path operational truth уже смещен в shadow layer.

### DCA-02. `PRG_Ventilation` — subsystem execution consumer
`PRG_Ventilation.st` подтвержденно читает ventilation-related requests из `GVL_COMMAND_SHADOW` и передает их в `FB_Ventilation_System_Manager`.

Semantic role:
- subsystem command consumer.

Вывод:
- для ventilation cluster shadow layer уже является реальным command input surface.

### DCA-03. `PRG_Command_Verifier` — comparison consumer, не execution consumer
`PRG_Command_Verifier.st` читает и `GVL_COMMAND`, и `GVL_COMMAND_SHADOW`, но только для сравнения.

Semantic role:
- comparison / migration guard consumer.

Вывод:
- verifier не опровергает dominance shadow layer в downstream execution path;
- он лишь поддерживает переходную comparison semantics.

## Подтвержденные live-root users legacy `GVL_COMMAND`

### DCA-04. `PRG_System` — legacy bridge / coordination layer
В `PRG_System.st` `GVL_COMMAND` остается живым в нескольких ролях:
- redundancy sync (`G_Gas_Valve_Close`, `G_Close_Valve_36`);
- safety reset (`G_Reset_Errors`);
- gateway outputs/inputs (`G_Arm_Req`, `G_Disarm_Req`, `G_PIN_Code`, `G_RFID_Tag`, `G_2FA_Code_In`, overrides);
- scenario request operator path;
- 2FA send/request fields.

Semantic role:
- system/gateway/bridge surface, а не подтвержденный downstream execution layer для уже проверенной command-chain.

Вывод:
- legacy layer все еще структурно живой;
- но его роль уже больше похожа на coordination/bridge tail, чем на основной execution surface.

### DCA-05. `PRG_Security` — legacy producer/bridge tail
В `PRG_Security.st` подтверждено использование `GVL_COMMAND` для:
- `VO_Send_Code_Req => GVL_COMMAND.G_Send_2FA_Req`
- `VO_Code_To_Send => GVL_COMMAND.G_2FA_Code_Out`

Semantic role:
- security/access bridge into legacy command surface.

Вывод:
- security cluster еще не переведен на shadow-centric command publication model;
- это подтверждает, что migration закрыта не полностью, даже если execution path уже в основном shadow-based.

## Что не подтверждено как legacy downstream execution path
На текущем этапе не подтверждено, что:
- `PRG_IO_Write` использует `GVL_COMMAND` как primary physical actuation source;
- `PRG_Ventilation` использует `GVL_COMMAND` как primary operational command input.

Вывод:
- для подтвержденной execution chain dominance legacy layer уже не наблюдается.

## Сводная карта command consumers

### Execution consumers of `GVL_COMMAND_SHADOW`
- `PRG_IO_Write`
- `PRG_Ventilation`

### Comparison consumer
- `PRG_Command_Verifier`

### Legacy bridge / coordination users of `GVL_COMMAND`
- `PRG_System`
- `PRG_Security`

## Архитектурный смысл текущей mixed model
Текущая модель не является полностью хаотичной. Она уже показывает направление миграции:
- execution path ушел в shadow layer;
- legacy layer остался вокруг bridge/coordination функций и verifier comparison semantics.

Но эта модель еще не финализирована, потому что:
- название `shadow` больше не соответствует его execution-роли;
- legacy `GVL_COMMAND` еще не сведен к четкой остаточной роли;
- mixed model не оформлена как explicit architectural end-state.

## Подтвержденные проблемные точки этапа C-A4

### DCA-ISSUE-01. Shadow dominance подтверждена только частично по execution-consumers
Да, IO write и ventilation уже на shadow.

Но это еще не означает, что весь проект semantic-complete migrated.

### DCA-ISSUE-02. Legacy layer still alive around system/security bridges
`PRG_System` и `PRG_Security` продолжают использовать `GVL_COMMAND`.

Риск:
- project может зависнуть в промежуточной mixed model без formal end-state.

### DCA-ISSUE-03. Execution layer и bridge layer семантически расходятся
Сейчас уже видно разбиение:
- execution downstream живет на shadow;
- bridge/admin/security хвост еще живет на legacy.

Риск:
- без отдельного remediation decision это останется неочевидной и плохо документированной архитектурной двусмысленностью.

## Практическое решение этапа C-A4
На текущем этапе принимается как live-root baseline:

### Downstream baseline
`GVL_COMMAND_SHADOW` уже доминирует в подтвержденном execution-consumer path.

### Legacy baseline
`GVL_COMMAND` еще не мертв, но его текущая подтвержденная роль уже смещена в сторону bridge / coordination / compatibility surface.

## Что остается нерешенным после этого этапа
Этот документ еще не решает:
- должен ли `GVL_COMMAND` быть сохранен как bridge-layer или устранен после migration close;
- как перевести security/system bridges в новую model;
- нужно ли rename/promote `GVL_COMMAND_SHADOW` после закрытия migration;
- как упростить verifier после формального определения final command model.

## Следующий рекомендуемый документ
- `29_COMMAND_LAYER_REMEDIATION_DECISION.md`

Его задача:
- открыть этап C-A5;
- принять решение по final migration direction;
- зафиксировать, что делать с shadow layer, legacy layer, verifier и устаревшими inline-comments/docs.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения