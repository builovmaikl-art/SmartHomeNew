# Next Scope Selection

Дата фиксации: 2026-04-23

## Назначение
Этот документ фиксирует, куда двигаться после завершения текущей волны работ по heating cluster.

Цель:
- зафиксировать, что именно уже достигнуто по heating;
- перечислить оставшиеся крупные направления;
- выбрать следующий scope не по инерции, а по текущему приоритету риска и архитектурной полезности.

## Что уже завершено по heating cluster
К текущему моменту по heating cluster выполнено:
- подтверждение, что live-root `PRG_Heating.st` был поврежден как source-представление;
- выбор и проверка recovery source;
- восстановление полного `PRG_Heating.st` в корне;
- post-recovery ownership audit;
- решение по owner для `GVL_STATE.G_Target_Temperature`;
- секционная перегруппировка diagnostics / maintenance gating / freeze support logic;
- локальная non-functional полировка `PRG_Heating.st`.

Практический итог:
- heating cluster временно стабилизирован как живой, читаемый и документированно разобранный контур;
- следующие шаги можно делать уже вне heating, не оставляя там аварийного architectural debt первого порядка.

## Три главных оставшихся направления

### Scope A. Command-layer migration audit
Область:
- `PRG_Command_Arbitration.st`
- `PRG_Command_Verifier.st`
- `GVL_COMMAND.gvl`
- `GVL_COMMAND_SHADOW.gvl`
- связанные точки в `PRG_IO_Write.st`, `PRG_Ventilation.st`, `PRG_System.st`

Почему это важно:
- именно здесь ранее был зафиксирован один из самых системных переходных дефектов;
- command-layer касается не одной подсистемы, а всей архитектуры ownership и записи команд;
- здесь есть риск скрытого рассогласования между legacy command layer и shadow layer.

Риск, если отложить:
- проект может продолжать жить с не до конца завершенной migration-моделью команд, что опаснее локального subsystem-debt.

### Scope B. Security / Access interface audit
Область:
- `PRG_Security.st`
- `FB_Access_Control.st`
- `FB_Security_System_Manager.st`
- связанные safety/security bridges

Почему это важно:
- ранее был зафиксирован вероятный interface mismatch между `PRG_Security` и `FB_Access_Control`;
- это менее широкий scope, чем command-layer, но потенциально более compile-sensitive.

Риск, если отложить:
- можно оставить в проекте интерфейсный разрыв в security/access контуре.

### Scope C. Следующая subsystem wave
Область:
- `PRG_Ventilation.st` / `FB_Ventilation_System_Manager.st`
или
- `PRG_Lighting.st` и связанный scenario/override слой

Почему это важно:
- после heating логично продолжать последовательный subsystem-by-subsystem audit.

Риск, если отложить:
- subsystem debt останется, но по текущим данным это выглядит менее острым, чем command-layer migration и security/access mismatch.

## Критерии выбора следующего scope
Следующий scope должен одновременно давать:
1. максимальное снижение архитектурного риска;
2. максимальную cross-cutting пользу для нескольких подсистем;
3. минимальный шанс, что мы будем строить последующие решения на неустойчивом базовом слое.

## Решение
Следующим приоритетным scope выбирается:

# Scope A — Command-layer migration audit

## Почему выбран именно он

### NS-01. Это самый cross-cutting слой из оставшихся
Command-layer влияет сразу на:
- arbitration ownership,
- shadow vs legacy commands,
- запись в физические выходы,
- верификацию команд,
- subsystem requests.

То есть это не локальная подсистема, а общий архитектурный шов проекта.

### NS-02. Здесь ранее уже были подтвержденные признаки незавершенной миграции
Ранее уже были зафиксированы признаки, что:
- `GVL_COMMAND_SHADOW` реально используется в live root;
- комментарии и фактическое использование shadow layer расходятся;
- verifier и migration semantics требуют отдельного приведения к непротиворечивому состоянию.

### NS-03. Это лучший следующий слой перед security/access и следующими subsystem waves
Если сначала вычистить command-layer, то:
- дальше проще анализировать subsystem ownership;
- проще проверять `IO_Write` и shadow-command semantics;
- уменьшается риск строить следующие аудиты на переходной command-модели.

## Что выбрать вторым после command-layer
После завершения command-layer audit приоритет №2:
- **Security / Access interface audit**

Только после этого:
- следующая subsystem wave (`Ventilation` как наиболее логичное продолжение).

## Рекомендуемый следующий документ
- `24_COMMAND_LAYER_AUDIT_PLAN.md`

Его задача:
- зафиксировать область command-layer audit;
- разложить анализ по ownership, shadow migration, verifier semantics и physical IO write path;
- определить первый исполнительный порядок для следующего цикла аудита.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения