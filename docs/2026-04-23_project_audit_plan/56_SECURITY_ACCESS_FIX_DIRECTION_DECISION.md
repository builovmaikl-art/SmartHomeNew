# Security / Access Fix Direction Decision

Дата фиксации: 2026-04-23

## Назначение
Этот документ выполняет этап `SA-A5` из `51_SECURITY_ACCESS_AUDIT_PLAN.md`:
**принятие remediation direction для security/access interface scope**.

Цель:
- зафиксировать, что считать правильным следующим исправлением;
- отделить локальный interface fix от более широкого boundary cleanup;
- не расширять scope раньше, чем это реально подтверждено кодом.

## Основание
Документ опирается на:
- `52_SECURITY_ACCESS_LIVE_CALLSITE_AUDIT.md`
- `53_SECURITY_ACCESS_BLOCK_INTERFACE_AUDIT.md`
- `54_SECURITY_ACCESS_CALLSITE_VS_INTERFACE_COMPARISON.md`
- `55_SECURITY_ACCESS_BOUNDARY_CHECK.md`

## Что уже подтверждено
К текущему моменту по live root подтверждено:
- live call-site `fbAccessControl(...)` в `PRG_Security.st` не передает `VI_System_Mode`;
- `FB_Access_Control.st` требует `VI_System_Mode` как обязательный `VAR_INPUT`;
- `VI_System_Mode` реально используется внутри блока как behavioral gate для `MODE_SAFE_STOP`;
- основная responsibility boundary между `FB_Security_System_Manager` и `FB_Access_Control` в целом остается читаемой;
- текущая проблема лучше всего описывается как local call-site contract drift, а не как полный architectural collapse boundary.

## Варианты remediation direction

### Option A. Local call-site fix in `PRG_Security.st`
Суть:
- скорректировать вызов `fbAccessControl(...)`;
- передать корректный источник для `VI_System_Mode`;
- не трогать роли блоков и не менять их broader contracts.

### Option B. Adapter-style boundary cleanup around `PRG_Security`
Суть:
- не только добавить недостающий параметр,
- но и дополнительно перегруппировать/прояснить orchestration boundary и локальные comments вокруг security/access coupling.

### Option C. Broader redesign of security/access responsibilities
Суть:
- пересматривать, где должна жить system-aware gating logic,
- надо ли менять сам контракт `FB_Access_Control`,
- нужно ли сильнее разводить или, наоборот, по-другому собирать security/access layers.

## Решение
На текущем этапе принимается:

# Decision: Option A — локальный interface fix в `PRG_Security.st`

## Почему выбран именно этот вариант

### FDD-01. Подтвержден только один load-bearing mismatch
На текущем этапе подтвержден конкретный mismatch:
- отсутствующий `VI_System_Mode` в call-site.

Не подтверждено, что:
- output-side contract сломан;
- auth/request surface системно неверна;
- `FB_Access_Control` требует wholesale redesign.

Вывод:
- пропорциональный ответ на проблему — именно локальный fix.

### FDD-02. `VI_System_Mode` выглядит осмысленным параметром, а не ошибкой блока
Внутри `FB_Access_Control.st` этот параметр реально используется для safe-stop gating.

Вывод:
- нет оснований лечить проблему удалением этого параметра из блока;
- логичнее довести orchestration call-site до actual block contract.

### FDD-03. Boundary problem пока выглядит ограниченной orchestration-layer drift
`PRG_Security.st` сейчас передает security-context subset, но block contract уже требует wider system context.

Вывод:
- это естественно чинится локально на orchestration boundary;
- пока нет достаточных оснований поднимать scope до broader redesign.

### FDD-04. Это минимальный безопасный fix с высоким payoff
Локальная правка:
- устраняет подтвержденный mismatch;
- не меняет доменные роли блоков;
- не тянет за собой новый архитектурный хвост без необходимости.

Вывод:
- это лучший следующий шаг по отношению risk/value.

## Что именно считается правильным remediation direction

### RD-SEC-01. Исправить call-site `fbAccessControl(...)`
Нужно:
- добавить передачу `VI_System_Mode` в `PRG_Security.st`.

### RD-SEC-02. Взять source из already-established system state layer
На текущем этапе наиболее естественный кандидат:
- `GVL_STATE.G_System_Mode`

Причина:
- это уже established aggregated system mode, используемый в других местах проекта как текущий system-level mode source.

### RD-SEC-03. Не менять `FB_Access_Control.st` контракт без дополнительных оснований
Текущий block contract пока не требует изменения только потому, что call-site отстал.

### RD-SEC-04. Не расширять fix до redesign security/access split
На текущем этапе не нужно:
- переносить safe-stop logic из access block;
- менять роли `FB_Security_System_Manager` и `FB_Access_Control`;
- перепридумывать orchestration boundary шире, чем это требует текущий mismatch.

## Что пока не требуется

### NOT-01
Не требуется redesign `FB_Access_Control.st`.

### NOT-02
Не требуется redesign `FB_Security_System_Manager.st`.

### NOT-03
Не требуется broad security/access cleanup beyond local fix.

### NOT-04
Не требуется command-layer side change для этого issue.

## Что может идти сразу после локального fix
После локального interface fix уже имеет смысл:
- сделать короткую repository-state verification;
- при необходимости слегка выровнять comments в `PRG_Security.st`, если после добавления `VI_System_Mode` boundary wording останется неочевидной.

Но это secondary step, не основная часть remediation.

## Практический итог решения
На текущем этапе security/access issue считается:
- **локально исправляемым integration defect**,
а не:
- доказанным поводом для крупного redesign.

Это позволяет двигаться дальше быстро и точно:
- без раздувания scope,
- без избыточных архитектурных движений,
- с понятным минимальным changeset.

## Следующий рекомендуемый документ
- `57_SECURITY_ACCESS_LOCAL_FIX_PLAN.md`

Его задача:
- зафиксировать минимальный changeset для `PRG_Security.st`;
- описать безопасный порядок внесения локального interface fix.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения