# Command Security Bridge Audit

Дата фиксации: 2026-04-23

## Назначение
Этот документ продолжает program-level разбор legacy bridge boundary после `41_COMMAND_SYSTEM_BRIDGE_AUDIT.md`:
**security-side audit legacy bridge fields в `PRG_Security.st`**.

Цель:
- подтвердить, какие поля `GVL_COMMAND` реально остаются нужны на стороне security/access контура;
- отделить живой security bridge-tail от уже выведенного из legacy-layer access/intents path;
- подготовить сводную bridge-карту для следующей cleanup-волны.

## Основание
Документ опирается на:
- `38_COMMAND_LEGACY_BRIDGE_BOUNDARY_PLAN.md`
- `40_COMMAND_LEGACY_BRIDGE_FIELD_MAP_AUDIT.md`
- `41_COMMAND_SYSTEM_BRIDGE_AUDIT.md`
- текущее состояние `PRG_Security.st`

## Главный вывод
`PRG_Security.st` подтверждает, что security-side остаточная зависимость от `GVL_COMMAND` в текущем live root уже **узкая**, а не широкая.

Фактически legacy `GVL_COMMAND` здесь остается нужен главным образом для:
- outbound 2FA exchange from security manager.

При этом основные security/access requests уже не живут на legacy command surface:
- arm/disarm, PIN, RFID и access open/close path уже подаются через `GVL_INTENT_USER`.

Это означает, что security-side bridge-tail уже значительно уже, чем system-side bridge-tail.

## Подтвержденные security-side bridge зависимости

### SCBA-01. 2FA outbound bridge
В `PRG_Security.st` подтверждено использование:
- `GVL_COMMAND.G_Send_2FA_Req`
- `GVL_COMMAND.G_2FA_Code_Out`

как выходов `fbSecurityManager(...)`:
- `VO_Send_Code_Req => GVL_COMMAND.G_Send_2FA_Req`
- `VO_Code_To_Send => GVL_COMMAND.G_2FA_Code_Out`

Вывод:
- эти два поля действительно имеют security-side bridge/use-case;
- их нельзя считать чистым legacy residue на текущем этапе.

## Что в `PRG_Security.st` уже НЕ зависит от legacy `GVL_COMMAND`

### SCBA-02. Arm / Disarm / PIN / RFID / 2FA input path
В `fbSecurityManager(...)` confirmed inputs приходят из:
- `GVL_INTENT_USER.I_Arm_Request`
- `GVL_INTENT_USER.I_Disarm_Request`
- `GVL_INTENT_USER.I_PIN_Code`
- `GVL_INTENT_USER.I_RFID_Tag`
- `GVL_INTENT_USER.I_2FA_Code_In`

а не из `GVL_COMMAND`.

Вывод:
- incoming security/user command path уже migrated away from legacy command surface.

### SCBA-03. Access control open/close path
В `fbAccessControl(...)` confirmed inputs/outputs уже идут через:
- HMI/config request fields,
- `GVL_INTENT_USER` input/output fields,
- retain/config structures,
а не через legacy `GVL_COMMAND` open/close fields.

Вывод:
- access open/close path не подтверждает необходимость legacy `G_Gate_Open`, `G_Wicket_Open`, `G_Lock_*` на security-side уровне.

## Обновленная security-side интерпретация field map

### Подтвержденные security bridge fields
- `G_Send_2FA_Req`
- `G_2FA_Code_Out`

### Поля, чья security-side bridge роль не подтверждена этим этапом
- `G_Arm_Req`
- `G_Disarm_Req`
- `G_PIN_Code`
- `G_RFID_Tag`
- `G_2FA_Code_In`
- `G_Gate_Open`
- `G_Wicket_Open`
- `G_Lock_1_Open`
- `G_Lock_1_Close`
- `G_Lock_2_Open`
- `G_Lock_2_Close`

Важно:
- это не означает, что перечисленные поля бесполезны вообще;
- это означает только, что `PRG_Security.st` не подтверждает их как legacy security-side bridge dependencies.

## Сопоставление с предыдущей картой
После `41_COMMAND_SYSTEM_BRIDGE_AUDIT.md` и этого документа можно различить:

### System-side bridge-tail
Широкий, включает:
- reset,
- operator scenario,
- gateway identity,
- 2FA exchange,
- overrides,
- часть sync/redundancy fields.

### Security-side bridge-tail
Узкий, подтвержденно включает:
- только outbound 2FA fields.

Вывод:
- future cleanup не должен симметрично трактовать `PRG_System` и `PRG_Security`;
- security-side legacy migration, вероятно, будет проще и уже.

## Практический эффект этапа
После этого аудита уже можно говорить, что:
- `PRG_Security` не является главным держателем остаточной legacy command-surface;
- главный объем legacy bridge-value сосредоточен в `PRG_System`, а не в `PRG_Security`;
- security-side cleanup, вероятно, сможет быть коротким и targeted.

## Что пока не закрыто
Этот этап не закрывает:
- сводную bridge shortlist across system + security;
- program-level проверку `CMD_*` группы;
- судьбу `G_Scenario_Request`;
- future migration plan для confirmed system bridge fields.

## Следующий рекомендуемый документ
- `43_COMMAND_BRIDGE_SHORTLIST_DECISION.md`

Его задача:
- свести system-side и security-side выводы;
- зафиксировать shortlist полей и направлений следующей cleanup-волны:
  - что оставлять как bridge-only временно,
  - что считать comparison-only residue,
  - что проверять следующим targeted шагом.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения