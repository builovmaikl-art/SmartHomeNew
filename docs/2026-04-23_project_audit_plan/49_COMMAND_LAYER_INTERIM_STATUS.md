# Command Layer Interim Status

Дата фиксации: 2026-04-23

## Назначение
Этот документ фиксирует промежуточное состояние command-layer wave после текущего цикла аудита и локального cleanup.

Цель:
- кратко свести completed / clarified / unresolved части;
- зафиксировать, что уже реально изменено в репозитории;
- обозначить безопасную точку остановки перед переходом к следующему крупному scope.

## Общий статус wave
На текущем этапе command-layer wave можно считать:
- **архитектурно хорошо вскрытой**;
- **частично очищенной документально**;
- **локально исправленной по verifier semantics**;
- **временно стабилизированной** для перехода к следующему high-value scope.

Это еще не final close command-layer migration.

Но это уже и не сырая переходная область без понятной модели.

## Что уже подтверждено и зафиксировано

### CLS-01. Operational truth смещен в `GVL_COMMAND_SHADOW`
Подтверждено, что:
- `PRG_Command_Arbitration` является active writer для `GVL_COMMAND_SHADOW`;
- `PRG_IO_Write` и `PRG_Ventilation` уже используют `GVL_COMMAND_SHADOW` как operational downstream layer.

Вывод:
- shadow-centered model уже является фактической live-root моделью execution path.

### CLS-02. Legacy `GVL_COMMAND` больше не трактуется как основной execution layer
Подтверждено, что:
- legacy `GVL_COMMAND` сохраняет остаточную роль,
- но эта роль сосредоточена вокруг bridge / coordination / compatibility surface,
- а не вокруг главного downstream execution path.

### CLS-03. Verifier больше не имеет mixed semantics
До cleanup verifier имел неоднородность:
- `Command_Mismatch_Count` и `Command_Match_OK` были current-state,
- `Command_Mismatch_Active` был set-only latch-like flag.

После локальной правки:
- `Command_Mismatch_Active` приведен к current-state semantics.

Вывод:
- verifier contract стал внутренне согласованным как temporary migration guard.

### CLS-04. Bridge boundary между execution-path и legacy-tail теперь описана явно
Зафиксировано:
- execution-path живет на `GVL_COMMAND_SHADOW`;
- system/security/gateway/operator tail живет вокруг `GVL_COMMAND`.

Это устранило прежнюю размытость между двумя слоями.

### CLS-05. Legacy bridge-tail разложен по meaningful subsets
Собрана field/program-level картина:
- bridge-only subset;
- comparison-only residue;
- service/admin subgroup;
- dangerous-action/admin subcluster;
- maintenance candidate subcluster;
- documented unresolved narrow tail.

## Что реально изменено в репозитории кодом
В рамках command-layer wave уже внесены реальные изменения в live root.

### CODE-01. Documentary cleanup comments/docs
Изменены:
- `GVL_COMMAND_SHADOW.gvl`
- `PRG_Command_Arbitration.st`
- `PRG_Command_Verifier.st`

Что сделано:
- устранены comments, противоречившие live root;
- выровнены semantic labels под shadow-centered model;
- verifier comments приведены к migration-guard wording.

### CODE-02. Functional verifier cleanup
Изменен:
- `PRG_Command_Verifier.st`

Что сделано:
- `GVL_COMMAND_VERIFY.Command_Mismatch_Active` переведен из set-only поведения в симметричный current-state flag.

Вывод:
- command-layer wave уже включает не только audit/planning, но и реальные правки репозитория.

## Что оставлено намеренно без изменений

### HOLD-01
`GVL_COMMAND_SHADOW` не переименовывался.

### HOLD-02
`GVL_COMMAND` не удалялся и не сворачивался целиком.

### HOLD-03
`PRG_System` и `PRG_Security` не переводились вслепую на новую model.

### HOLD-04
Verifier не удалялся и не превращался в alarm subsystem.

### HOLD-05
Valve-test / selective-recover tail не подвергался blind cleanup.

## Что остается осознанно незакрытым

### UNR-01. Formal migration close
Не зафиксировано окончательное закрытие migration command-layer.

### UNR-02. Rename/promote decision для `GVL_COMMAND_SHADOW`
Semantic promotion уже принята, но naming decision пока отложен.

### UNR-03. Full bridge migration for `PRG_System` / `PRG_Security`
Bridge-tail описан, но еще не перенесен и не редуцирован кодово.

### UNR-04. Documented unresolved tail
Остаются unresolved:
- `CMD_Valve_Test_*`
- `CMD_Water_Valve_Test_*`
- `CMD_Gas_Valve_Test_*`
- `CMD_Water_Selective_Recover`
- `CMD_Gas_Selective_Recover`

Их текущий статус:
- documented unresolved,
- not safe for blind removal,
- not prioritized for immediate deep follow-up.

## Практическая оценка зрелости wave
На текущем этапе command-layer wave можно оценить как:
- **примерно 80–85% завершенности** в рамках текущего audit/remediation цикла.

Это означает:
- core ambiguity снята;
- ключевые ownership и semantics вопросы разобраны;
- минимально нужные cleanup-правки уже внесены;
- remaining uncertainty сосредоточена в narrow tail и future migration decisions, а не в core command architecture.

## Что это означает для общего проекта
После фиксации этого interim status command-layer уже не выглядит scope первого архитектурного риска.

Его можно оставить в текущем documented state и:
- либо позже вернуться к bridge-tail reduction,
- либо перейти к следующему high-value project scope.

## Рекомендуемый следующий документ
- `50_NEXT_MAJOR_SCOPE_AFTER_COMMAND_LAYER.md`

Его задача:
- зафиксировать, куда проект идет после текущей command-layer wave;
- выбрать следующий крупный priority scope между security/access interface audit и следующей subsystem wave.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения