# Ventilation Audit Plan

Дата фиксации: 2026-04-23

## Назначение
Этот документ открывает следующий major scope после `61_NEXT_MAJOR_SCOPE_AFTER_SECURITY_ACCESS.md`:
**ventilation subsystem wave**.

Цель:
- зафиксировать область нового цикла анализа;
- определить главные риски ventilation boundary;
- разложить следующий audit на управляемые этапы;
- не смешивать ventilation wave с already-narrowed tails command-layer и security/access.

## Почему этот scope выбран следующим
После heating wave, command-layer wave и security/access local fix именно ventilation выглядит следующим наиболее ценным domain-level scope.

Это логично, потому что:
- ventilation уже частично всплывала во время command-layer wave как downstream consumer shadow command layer;
- это естественное продолжение subsystem-by-subsystem аудита после heating;
- architectural payoff следующего шага здесь выше, чем у возврата к narrow tails уже стабилизированных scope.

## Область ventilation audit

### Основные файлы
- `PRG_Ventilation.st`
- `FB_Ventilation_System_Manager.st`

### Связанные точки
- `GVL_COMMAND_SHADOW`
- `GVL_STATE`
- `GVL_STATUS`
- ventilation-related config / diagnostics / policy interactions

### При необходимости
- дополнительные helper/config/struct files, если boundary вентиляции уводит глубже.

## Уже известная отправная точка
Во время command-layer wave уже было подтверждено:
- `PRG_Ventilation` читает `GVL_COMMAND_SHADOW` как operational downstream input surface.

Это означает, что ventilation subsystem уже встроена в clarified command-layer reality и теперь может разбираться на собственной доменной границе.

## Главные вопросы следующего аудита
Следующий цикл должен ответить на вопросы:
1. как устроен live ventilation flow сверху вниз;
2. где проходит boundary между `PRG_Ventilation` и `FB_Ventilation_System_Manager`;
3. кто является owner-слоем для ventilation requests / modes / overrides;
4. нет ли внутри ventilation cluster тех же проблем, что ранее были в heating: mixed ownership, wrapper drift, unclear diagnostics/gating хвост;
5. требуется ли ventilation только documentation/structure cleanup или там вероятны реальные code fixes.

## Порядок аудита

### Этап V-A1. Live wrapper audit
Область:
- `PRG_Ventilation.st`

Задача:
- снять текущую структуру live wrapper;
- понять, какие inputs он берет сверху и что публикует вниз/наружу.

Ожидаемый результат:
- точная wrapper map ventilation layer.

### Этап V-A2. Manager contract audit
Область:
- `FB_Ventilation_System_Manager.st`

Задача:
- снять фактический контракт manager-блока;
- понять, какая логика реально живет внутри manager, а что оставлено wrapper-слою.

Ожидаемый результат:
- contract/ownership map manager-layer.

### Этап V-A3. Wrapper vs manager boundary audit
Область:
- `PRG_Ventilation.st`
- `FB_Ventilation_System_Manager.st`

Задача:
- сравнить responsibilities wrapper и manager;
- подтвердить, нет ли boundary drift, interface mismatch или mixed ownership.

Ожидаемый результат:
- ventilation boundary interpretation.

### Этап V-A4. Requests / status / diagnostics ownership audit
Область:
- ventilation-related `GVL_COMMAND_SHADOW`, `GVL_STATE`, `GVL_STATUS`

Задача:
- понять, где именно живет ownership ventilation requests, effective mode, diagnostics и status publication.

Ожидаемый результат:
- ownership map вентиляционного кластера.

### Этап V-A5. Fix direction decision
Задача:
- на основе V-A1..V-A4 принять решение:
  - нужен ли только structural/docs cleanup,
  - нужен ли local code fix,
  - или требуется более широкая ventilation cleanup wave.

Ожидаемый результат:
- remediation direction for ventilation subsystem.

## Что пока НЕ делать
- не возвращаться сразу в command-layer tail;
- не смешивать ventilation audit с broader redesign unrelated subsystems;
- не править `PRG_Ventilation` или `FB_Ventilation_System_Manager` до подтвержденной boundary/ownership картины.

## Практический следующий документ
- `63_VENTILATION_LIVE_WRAPPER_AUDIT.md`

Его задача:
- открыть этап `V-A1`;
- снять текущую live structure `PRG_Ventilation.st`.

## Режим проверки
- Direct Repository Modification Mode
- repository state verification only
- без compile/run подтверждения